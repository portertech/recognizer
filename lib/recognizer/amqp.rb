require "rubygems"
require "thread"
require "bunny"

module Recognizer
  class AMQP
    def initialize(carbon_queue, logger, options)
      unless carbon_queue && options.is_a?(Hash)
        raise "You must provide a thread queue and options"
      end

      if options.has_key?(:amqp)
        options[:amqp][:exchange] ||= Hash.new

        exchange_name = options[:amqp][:exchange][:name]        || "graphite"
        durable       = options[:amqp][:exchange][:durable]     || false
        routing_key   = options[:amqp][:exchange][:routing_key] || "#"
        exchange_type = options[:amqp][:exchange][:type]        || :topic

        amqp = Bunny.new(options[:amqp].reject { |key, value| key == :exchange })
        amqp.start

        exchange = amqp.exchange(exchange_name, :type => exchange_type.to_sym, :durable => durable)
        queue    = amqp.queue("recognizer")
        queue.bind(exchange, :key => routing_key)

        Thread.abort_on_exception = true

        Thread.new do
          logger.info("AMQP -- Awaiting metrics with impatience ...")
          queue.subscribe do |message|
            payload         = message[:payload]
            msg_routing_key = message[:routing_key] || message[:delivery_details][:routing_key]
            lines = payload.split("\n")
            lines.each do |line|
              line = line.strip
              case line.split("\s").count
              when 3
                carbon_queue.push(line)
              when 2
                carbon_queue.push("#{msg_routing_key} #{line}")
              end
            end
          end
        end
      else
        logger.warn("AMQP -- Not configured")
      end
    end
  end
end
