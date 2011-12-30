require "rubygems"
require "thread"
require "librato/metrics"

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
          unless librato.queued.empty?
            puts "Attempting to flush metrics to Librato"
            mutex.synchronize do
              librato.submit
            end
            puts "Successfully flushed metrics to Librato"
          end
        end
      end
      Thread.new do
        loop do
          graphite_formated = thread_queue.pop
          puts "Adding metric to queue: #{graphite_formated}"
          metric, value, timestamp = graphite_formated.split(" ")
          mutex.synchronize do
            librato.add metric.to_sym => {:value => value.to_f, :measure_time => timestamp.to_i}
          end
        end
      end
    end
  end
end
