require "recognizer/version"
require "recognizer/patches/float"
require "recognizer/patches/openssl"
require "thread"
require "librato/metrics"

module Recognizer
  class Librato
    def initialize(options={})
      @logger       = options[:logger]
      @options      = options[:options]
      @carbon_queue = options[:carbon_queue]

      ::Librato::Metrics.authenticate(@options[:librato][:email], @options[:librato][:api_key])
      ::Librato::Metrics.agent_identifier("recognizer", Recognizer::VERSION, "portertech")
      @librato_queue = ::Librato::Metrics::Queue.new
      @librato_mutex = Mutex.new

      Thread.abort_on_exception = true
    end

    def run
      setup_librato_publisher
      setup_carbon_consumer
    end

    private

    def setup_librato_publisher
      Thread.new do
        loop do
          sleep(@options[:librato][:flush_interval] || 10)
          unless @librato_queue.empty?
            @librato_mutex.synchronize do
              @logger.info("Attempting to flush metrics to Librato")
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

    def source_pattern
      return @source_pattern if @source_pattern
      @source_pattern = Regexp.new(@options[:librato][:metric_source].delete("/"))
    end

    def get_source
      return @get_source if @get_source
      @get_source = case @options[:librato][:metric_source]
      when String
        if @options[:librato][:metric_source].match("^/.*/$")
          Proc.new { |path| (matched = path.grep(source_pattern).first) ? matched : "recognizer" }
        else
          Proc.new { @options[:librato][:metric_source] }
        end
      when Integer
        Proc.new { |path| path.slice(@options[:librato][:metric_source]) }
      else
        Proc.new { "recognizer" }
      end
    end

    def invalid_metric(carbon_formatted, message)
      @logger.warn("Invalid metric :: #{carbon_formatted} :: #{message}")
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

    def create_metric(carbon_formatted)
      if valid_carbon_metric?(carbon_formatted)
        parts     = carbon_formatted.split("\s")
        path      = parts.shift.split(".")
        value     = Float(parts.shift).pretty
        timestamp = Float(parts.shift).pretty
        source    = get_source.call(path)

        path.delete(source)

        name = path.join(".")

        if name.size <= 63
          { name => { :value => value, :measure_time => timestamp, :source => source } }
        else
          invalid_metric(carbon_formatted, "Metric name must be 63 or fewer characters")
        end
      else
        false
      end
    end

    def setup_carbon_consumer
      Thread.new do
        loop do
          if metric = create_metric(@carbon_queue.shift)
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
