require "recognizer/version"
require "recognizer/patches/float"
require "recognizer/patches/openssl"
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

    private

    def setup_publisher
      Thread.new do
        loop do
          sleep(@options[:librato][:flush_interval] || 10)
          unless @librato_queue.empty?
            @logger.info("Attempting to flush metrics to Librato")
            @librato_mutex.synchronize do
              begin
                @librato_queue.submit
                @logger.info("Successfully flushed metrics to Librato")
              rescue => error
                @logger.error("Encountered an error when flushing metrics to Librato :: #{error}")
              end
            end
          end
        end
      end
    end

    def invalid_metric(metric, message)
      @logger.warn("Invalid metric :: #{metric.inspect} :: #{message}")
      false
    end

    def valid_carbon_metric?(carbon_formatted)
      parts = carbon_formatted.split("\s")
      if !parts[0] =~ /^[A-Za-z0-9\._-]*$/
        invalid_metric(carbon_formatted, "Metric name must only consist of alpha-numeric characters, periods, underscores, and dashes")
      elsif !parts[1] =~ /^[0-9]*\.?[0-9]*$/
        invalid_metric(carbon_formatted, "Metric value must be an integer or float")
      elsif !parts[2] =~ /^[0-9]{10}$/
        invalid_metric(carbon_formatted, "Metric timestamp must be epoch, 10 digits")
      else
        true
      end
    end

    def metric_source(path)
      @metric_source ||= case @options[:librato][:metric_source]
      when String
        if @options[:librato][:metric_source].match("^/.*/$")
          @source_pattern = Regexp.new(@options[:librato][:metric_source].delete("/"))
          Proc.new { |path| (matched = path.grep(@source_pattern).first) ? matched : "recognizer" }
        else
          Proc.new { @options[:librato][:metric_source] }
        end
      when Integer
        Proc.new { |path| path.slice(@options[:librato][:metric_source]) }
      else
        Proc.new { "recognizer" }
      end
      @metric_source.call(path)
    end

    def create_metric(carbon_formatted)
      if valid_carbon_metric?(carbon_formatted)
        parts     = carbon_formatted.split("\s")

        path      = parts.shift.split(".")
        value     = Float(parts.shift).pretty
        timestamp = Float(parts.shift).pretty
        source    = metric_source(path)

        path.delete(source)

        name = path.join(".")

        metric = {
          name => {
            :value => value,
            :measure_time => timestamp,
            :source => source
          }
        }

        unless name.size <= 63
          invalid_metric(metric, "Metric name must be 63 or fewer characters")
        else
          metric
        end
      else
        false
      end
    end

    def setup_consumer
      Thread.new do
        loop do
          if metric = create_metric(@input_queue.shift)
            @logger.info("Adding metric to Librato queue :: #{metric.inspect}")
            @librato_mutex.synchronize do
              @librato_queue.add(metric)
            end
          end
        end
      end
    end
  end
end
