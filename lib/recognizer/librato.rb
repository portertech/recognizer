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
      Thread.new do
        loop do
          sleep(options[:librato][:flush_interval] || 10)
          unless librato.queued.empty?
            puts "Attempting to flush #{librato.queued.count} metrics to Librato"
            librato.submit
            puts "Successfully flushed #{librato.queued.count} metrics to Librato"
          end
        end
      end
      Thread.new do
        loop do
          graphite_formated = thread_queue.pop
          puts "Adding metric to queue: #{graphite_formated}"
          metric = graphite_formated.split(" ")
          librato.add metric[0].to_sym => {:value => metric[1].to_f, :measure_time => metric[2].to_i}
        end
      end
    end
  end
end
