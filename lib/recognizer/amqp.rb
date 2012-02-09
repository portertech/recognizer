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

      
      if options.has_key?(:amqp) && options[:amqp].has_key?(:exchange)
        exchange_name = options[:amqp][:exchange][:name]        || "graphite"
        durable       = options[:amqp][:exchange][:durable]     || false
        routing_key   = options[:amqp][:exchange][:routing_key] || "*"
        exchange_type = options[:amqp][:exchange][:type].to_sym || :topic
      else
        exchange_name = "graphite"
        durable       = true
        routing_key   = "*"
        exchange_type = :topic
      end

      exchange = amqp.exchange(exchange_name, :type => exchange_type, :durable => durable)
      queue.bind(exchange, :key => routing_key)
      
      Thread.abort_on_exception = true
      consumer = Thread.new do
        puts "Awaiting the metrics with impatience ..."
        queue.subscribe do |message|
          payload         = message[:payload]
          msg_routing_key = message[:delivery_details][:routing_key]
          
          lines = payload.split("\n")
          lines.each do |line|
            line = line.strip
            case line.split(/\s/).count
            when 3
              thread_queue.push(line)
            when 2
              thread_queue.push("#{msg_routing_key} #{line}")
            end
          end
        end
      end
      consumer.join
    end
  end
end
