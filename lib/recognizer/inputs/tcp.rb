require "thread"
require "socket"

module Recognizer
  module Input
    class TCP < Base
      def initialize(options={})
        super

        @options[:tcp] ||= Hash.new
        @tcp_connections = Queue.new

        Thread.abort_on_exception = true
      end

      def run
        setup_server
        setup_thread_pool
      end

      private

      def setup_server
        port       = @options[:tcp][:port] || 2003
        tcp_server = TCPServer.new("0.0.0.0", port)
        Thread.new do
          @logger.info("TCP -- Awaiting metrics with impatience ...")
          loop do
            @tcp_connections.push(tcp_server.accept)
          end
        end
      end

      def create_server_thread
        Thread.new do
          loop do
            if connection = @tcp_connections.shift
              while line = connection.gets
                line = line.strip
                if line.split("\s").count == 3
                  @input_queue.push(line)
                else
                  @logger.warn("TCP -- Received malformed metric :: #{line}")
                end
              end
            end
          end
        end
      end

      def setup_thread_pool
        threads = @options[:tcp][:threads] || 20
        threads.times do
          create_server_thread
        end
      end
    end
  end
end
