require "recognizer/version"
require "thread"
require "librato/metrics"

module Recognizer
  class Librato
    def initialize(options={})
      @logger      = options[:logger]
      @options     = options[:options]
      @input_queue = options[:input_queue]

      ::Librato::Metrics.authenticate(@options[:librato][:email], @options[:librato][:api_key])
      ::Librato::Metrics.agent_identifier("recognizer", Recognizer::VERSION, "portertech")

      @librato_queue = ::Librato::Metrics::Queue.new
      @librato_mutex = Mutex.new

      Thread.abort_on_exception = true
    end

    def run
      setup_publisher
      setup_consumer
    end

    def invalid_metric(plain_text, message)
      @logger.warn("Invalid metric :: #{plain_text} :: #{message}")
      false
    end

    def valid_plain_text?(plain_text)
      segments = plain_text.split("\s")
      if segments[0] !~ /^[A-Za-z0-9\._-]*$/
        message = "Metric name must only consist of alpha-numeric characters, periods, underscores, and dashes"
        invalid_metric(plain_text, message)
      elsif segments[1] !~ /^[0-9]*\.?[0-9]*$/
        invalid_metric(plain_text, "Metric value must be an integer or float")
      elsif segments[2] !~ /^[0-9]{10}$/
        invalid_metric(plain_text, "Metric timestamp must be epoch, 10 digits")
      else
        true
      end
    end

    def extract_metric_source(metric_path, metric_source=nil)
      metric_source ||= @options[:librato][:metric_source]
      fallback_source = "recognizer"
      case metric_source
      when String
        if metric_source =~ /^\/.*\/$/
          metric_path.grep(Regexp.new(metric_source.slice(1..-2))).first || fallback_source
        else
          metric_source
        end
      when Integer
        metric_path.slice(metric_source) || fallback_source
      else
        fallback_source
      end
    end

    def pretty_number(number)
      float = Float(number)
      float == float.to_i ? float.to_i : float
    end

    def create_librato_metric(plain_text)
      if valid_plain_text?(plain_text)
        segments  = plain_text.split("\s")

        path      = segments.shift.split(".")
        value     = pretty_number(segments.shift)
        timestamp = pretty_number(segments.shift)
        source    = extract_metric_source(path)

        path.slice!(path.index(source))

        name = path.join(".")

        if name.size <= 63
          {
            name => {
              :value => value,
              :measure_time => timestamp,
              :source => source
            }
          }
        else
          message = "Metric name must be 63 or fewer characters after source extraction"
          invalid_metric(plain_text, message)
        end
      else
        false
      end
    end

    private

    def setup_publisher
      Thread.new do
        loop do
          sleep(@options[:librato][:flush_interval] || 10)
          unless @librato_queue.empty?
            @logger.info("Attempting to flush metrics to Librato")
            @librato_mutex.synchronize do
              begin
                metric_count = @librato_queue.size
                @librato_queue.submit
                @logger.info("Successfully flushed #{metric_count} metrics to Librato")
              rescue => error
                @logger.error("Encountered an error when flushing metrics to Librato :: #{error}")
              end
            end
          end
        end
      end
    end

    def setup_consumer
      Thread.new do
        loop do
          if metric = create_librato_metric(@input_queue.shift)
            @logger.debug("Adding metric to Librato queue :: #{metric.inspect}")
            @librato_mutex.synchronize do
              @librato_queue.add(metric)
            end
          end
        end
      end
    end
  end
end
