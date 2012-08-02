require "recognizer/patches/openssl"
require "thread"
require "bunny"

module Recognizer
  module Input
    class AMQP
      def initialize(options={})
        @logger       = options[:logger]
        @options      = options[:options]
        @carbon_queue = options[:carbon_queue]

        Thread.abort_on_exception = true
      end

      def run
        if @options.has_key?(:amqp)
          setup_amqp_options
          setup_amqp_consumer
        else
          @logger.warn("AMQP -- Not configured")
        end
      end

      private

      def setup_amqp_options
        @options[:amqp][:exchange]               ||= Hash.new
        @options[:amqp][:exchange][:name]        ||= "graphite"
        @options[:amqp][:exchange][:durable]     ||= false
        @options[:amqp][:exchange][:routing_key] ||= "#"
        @options[:amqp][:exchange][:type]        ||= (@options[:amqp][:exchange][:type] || "topic").to_sym
      end

      def setup_amqp_consumer
        amqp = Bunny.new(@options[:amqp].reject { |key, value| key == :exchange })
        amqp.start

        exchange = amqp.exchange(@options[:amqp][:exchange][:name], {
          :type    => @options[:amqp][:exchange][:type],
          :durable => @options[:amqp][:exchange][:durable]
        })

        queue = amqp.queue("recognizer")
        queue.bind(exchange, {
          :key => @options[:amqp][:exchange][:routing_key]
        })

        Thread.new do
          @logger.info("AMQP -- Awaiting metrics with impatience ...")
          queue.subscribe do |message|
            msg_routing_key = message[:routing_key] || message[:delivery_details][:routing_key]
            lines           = message[:payload].split("\n")
            lines.each do |line|
              line = line.strip
              case line.split("\s").count
              when 3
                @carbon_queue.push(line)
              when 2
                @carbon_queue.push("#{msg_routing_key} #{line}")
              else
                @logger.warn("AMQP -- Received malformed metric :: #{msg_routing_key} :: #{line}")
              end
            end
          end
        end
      end
    end
  end
end
