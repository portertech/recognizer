require "rubygems"
require "recognizer/version"
require "thread"
require "librato/metrics"

require File.join(File.dirname(__FILE__), 'patches', 'float')

module Recognizer
  class Librato
    def initialize(carbon_queue, logger, options)
      unless carbon_queue && options.is_a?(Hash)
        raise "You must provide a thread queue and options"
      end
      unless options[:librato][:email] && options[:librato][:api_key]
        raise "You must provide a Librato Metrics account email and API key"
      end

      ::Librato::Metrics.authenticate(options[:librato][:email], options[:librato][:api_key])
      ::Librato::Metrics.agent_identifier("recognizer", Recognizer::VERSION, "portertech")
      librato = ::Librato::Metrics::Queue.new

      mutex = Mutex.new
      Thread.abort_on_exception = true

      Thread.new do
        loop do
          sleep(options[:librato][:flush_interval] || 10)
          unless librato.empty?
            logger.info("Attempting to flush metrics to Librato")
            mutex.synchronize do
              begin
                librato.submit
                logger.info("Successfully flushed metrics to Librato")
              rescue => error
                logger.error("Encountered an error when flushing metrics to Librato :: #{error}")
              end
            end
          end
        end
      end

      get_source = case options[:librato][:metric_source]
      when String
        if options[:librato][:metric_source].match("^/.*/$")
          @source_pattern = Regexp.new(options[:librato][:metric_source].delete("/"))
          Proc.new { |path| (matched = path.grep(@source_pattern).first) ? matched : "recognizer" }
        else
          Proc.new { options[:librato][:metric_source] }
        end
      when Integer
        Proc.new { |path| path.slice(options[:librato][:metric_source]) }
      else
        Proc.new { "recognizer" }
      end

      Thread.new do
        loop do
          graphite_formated = carbon_queue.pop
          begin
            parts = graphite_formated.split("\s")

            unless parts.first =~ /^[A-Za-z0-9\._-]*$/
              raise "metric name must only consist of alpha-numeric characters, periods, underscores, and dashes"
            end

            unless parts.last =~ /^[0-9]{10}$/
              raise "metric timestamp must be epoch, 10 digits"
            end

            path      = parts.shift.split(".")
            value     = Float(parts.shift).pretty
            timestamp = Float(parts.shift).pretty
            source    = get_source.call(path)

            path.delete(source)

            name = path.join(".")

            unless name.size <= 63
              raise "metric name must be 63 or fewer characters"
            end

            metric = {name => {:value => value, :measure_time => timestamp, :source => source}}

            mutex.synchronize do
              logger.info("Adding metric to queue :: #{metric.inspect}")
              librato.add(metric)
            end
          rescue => error
            logger.info("Invalid metric :: #{graphite_formated} :: #{error}")
          end
        end
      end
    end
  end
end
