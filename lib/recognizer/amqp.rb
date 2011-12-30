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
          routing_key = message[:routing_key]
          lines = payload.split("\n")
          lines.each do |line|
            line = line.strip
            case line.split(" ").count
            when 3
              thread_queue.push(line)
            when 2
              thread_queue.push("#{routing_key} #{line}")
            end
          end
        end
      end
      consumer.join
    end
  end
end
