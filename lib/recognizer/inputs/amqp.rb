require "hot_bunnies"

module Recognizer
  module Input
    class AMQP < Base
      def initialize(options={})
        super

        @enabled = @options.has_key?(:amqp)

        @options[:amqp]                          ||= Hash.new
        @options[:amqp][:exchange]               ||= Hash.new
        @options[:amqp][:exchange][:name]        ||= "graphite"
        @options[:amqp][:exchange][:durable]     ||= false
        @options[:amqp][:exchange][:routing_key] ||= "#"
        @options[:amqp][:exchange][:type]        ||= (@options[:amqp][:exchange][:type] || "topic").to_sym
      end

      def run
        setup_consumer
      end

      private

      def setup_consumer
        connection_options = @options[:amqp].reject { |key, value| key == :exchange }

        rabbitmq = HotBunnies.connect(connection_options)
        amq      = rabbitmq.create_channel

        amq.prefetch = 10

        exchange = amq.exchange(@options[:amqp][:exchange][:name], {
          :type    => @options[:amqp][:exchange][:type],
          :durable => @options[:amqp][:exchange][:durable]
        })

        queue = amq.queue("recognizer")
        queue.bind(exchange, {
          :routing_key => @options[:amqp][:exchange][:routing_key]
        })

        @logger.info("AMQP -- Awaiting metrics with impatience ...")

        subscription = queue.subscribe(:ack => true, :blocking => false) do |header, message|
          msg_routing_key = header.routing_key
          lines           = message.split("\n")
          lines.each do |line|
            line = line.strip
            case line.split("\s").count
            when 3
              @input_queue.push(line)
            when 2
              @input_queue.push("#{msg_routing_key} #{line}")
            else
              @logger.warn("AMQP -- Received malformed metric :: #{msg_routing_key} :: #{line}")
            end
          end
          header.ack
        end

        at_exit do
          subscription.cancel
          amq.close
          rabbitmq.close
        end
      end
    end
  end
end
