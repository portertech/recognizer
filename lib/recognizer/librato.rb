require "rubygems"
require "thread"
require "librato/metrics"

require File.join(File.dirname(__FILE__), 'patches', 'float')

module Recognizer
  class Librato
    def initialize(thread_queue, options)
      unless thread_queue && options.is_a?(Hash)
        raise "You must provide a thread queue and options"
      end
      unless options[:librato][:email] && options[:librato][:api_key]
        raise "You must provide a Librato Metrics account email and API key"
      end

      ::Librato::Metrics.authenticate(options[:librato][:email], options[:librato][:api_key])
      librato = ::Librato::Metrics::Queue.new

      mutex = Mutex.new
      Thread.abort_on_exception = true

      Thread.new do
        loop do
          sleep(options[:librato][:flush_interval] || 10)
          unless librato.empty?
            puts "Attempting to flush metrics to Librato"
            mutex.synchronize do
              librato.submit
            end
            puts "Successfully flushed metrics to Librato"
          end
        end
      end

      get_source = case options[:librato][:source]
      when String
        if options[:librato][:source].match("^/.*/$")
          @source_pattern = Regexp.new(options[:librato][:source].delete("/"))
          Proc.new { |path| (matched = path.grep(@source_pattern).first) ? matched : "recognizer" }
        else
          Proc.new { options[:librato][:source] }
        end
      when Integer
        Proc.new { |path| path.slice(options[:librato][:source]) }
      else
        Proc.new { "recognizer" }
      end

      Thread.new do
        loop do
          graphite_formated = thread_queue.pop
          begin
            path, value, timestamp = graphite_formated.split(" ").inject([]) do |result, part|
              result << (result.empty? ? part.split(".") : Float(part).pretty)
              result
            end
            source = get_source.call(path)
            path.delete(source)
            metric = {path.join(".") => {:value => value, :measure_time => timestamp, :source => source}}
            mutex.synchronize do
              puts "Adding metric to queue: #{metric.inspect}"
              librato.add(metric)
            end
          rescue ArgumentError
            puts "Invalid metric: #{graphite_formated}"
          end
        end
      end
    end
  end
end
