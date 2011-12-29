require "rubygems"
require "librato/metrics"

module Recognizer
  class Librato
    def initialize(queue, options)
      unless queue && options.is_a?(Hash)
        raise "You must provide a thread queue and options"
      end
      unless options[:librato][:email] && options[:librato][:api_key]
        raise "You must provide a Librato Metrics account email and API key"
      end
      Thread.new do
        Librato::Metrics.authenticate(options[:librato][:email], options[:librato][:api_key])
        librato = Librato::Metrics::Queue.new
        last_flush = Time.now.to_i
        loop do
          graphite_formated = queue.pop
          metric = graphite_formated.split(" ")
          librato.add metric[0].to_sym => {:value => metric[1].to_f, :measure_time => metric[2].to_i}
          if Time.now.to_i - last_flush >= (options[:librato][:flush_interval] || 10)
            librato.submit
            last_flush = Time.now.to_i
          end
        end
      end
    end
  end
end
