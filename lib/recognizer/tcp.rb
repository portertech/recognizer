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

      worker_count = options.has_key?(:tcp) ? options[:tcp][:workers] || 20 : 20
      tcp_server = TCPServer.new("0.0.0.0", 2003)
      tcp_connections = Queue.new

      Thread.abort_on_exception = true

      worker_count.times do
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
                connection.close
              end
            end
          end
        end
      end

      Thread.new do
        loop do
          tcp_connections.push(tcp_server.accept)
        end
      end
    end
  end
end
