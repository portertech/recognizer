require "rubygems"
require "thread"
require "bunny"

module Recognizer
  class AMQP
    def initialize(thread_queue, options)
      unless thread_queue && options.is_a?(Hash)
        raise "You must provide a thread queue and options"
      end
      amqp = Bunny.new(options[:amqp])
      amqp.start
      queue = amqp.queue("recognizer")
      exchange = amqp.exchange("graphite", :type => :topic, :durable => true)
      queue.bind(exchange, :key => "*")
      Thread.abort_on_exception = true
      consumer = Thread.new do
        puts "Awaiting the metrics with impatience ..."
        queue.subscribe do |message|
          payload = message[:payload]
          begin
            metrics = JSON.parse(payload)
            if metrics.is_a?(Array)
              metrics.each do |metric|
                if metric.split(" ").count == 3
                  thread_queue.push(metric)
                end
              end
            end
          rescue JSON::ParserError
            metric = payload
            if metric.split(" ").count == 3
              thread_queue.push(metric)
            end
          end
        end
      end
      consumer.join
    end
  end
end
