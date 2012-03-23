require "rubygems"
require "timeout"
require "thread"
require "socket"

module Recognizer
  class TCP
    def initialize(carbon_queue, logger, options)
      unless carbon_queue && options.is_a?(Hash)
        raise "You must provide a thread queue and options"
      end

      options[:tcp] ||= Hash.new

      threads = options[:tcp][:threads] || 20
      port    = options[:tcp][:port]    || 2003

      tcp_server      = TCPServer.new("0.0.0.0", port)
      tcp_connections = Queue.new

      Thread.abort_on_exception = true

      threads.times do
        Thread.new do
          loop do
            if connection = tcp_connections.shift
              begin
                lines = timeout(12) do
                  connection.gets.split("\n")
                end
                lines.each do |line|
                  line = line.strip
                  if line.split("\s").count == 3
                    carbon_queue.push(line)
                  end
                end
              rescue Timeout::Error
                logger.warn("TCP -- A connection has timed out")
                connection.close
              end
            end
          end
        end
      end

      Thread.new do
        logger.info("TCP -- Awaiting metrics with impatience ...")
        loop do
          tcp_connections.push(tcp_server.accept)
        end
      end
    end
  end
end
