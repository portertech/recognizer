require "logger"
require "recognizer/cli"
require "recognizer/config"
require "recognizer/librato"
require "recognizer/inputs/tcp"
require "recognizer/inputs/amqp"

module Recognizer
  def self.run
    cli         = Recognizer::CLI.new
    config      = Recognizer::Config.new(cli.read)
    input_queue = Queue.new

    options = cli.read.merge(config.read)

    logger = Logger.new(STDOUT)

    logger.level = options[:verbose] ? Logger::DEBUG : Logger::INFO

    librato = Recognizer::Librato.new(
      :logger      => logger,
      :options     => options,
      :input_queue => input_queue
    )
    librato.run

    tcp = Recognizer::Input::TCP.new(
      :logger      => logger,
      :options     => options,
      :input_queue => input_queue
    )
    tcp.run

    if options.has_key?(:amqp)
      amqp = Recognizer::Input::AMQP.new(
        :logger      => logger,
        :options     => options,
        :input_queue => input_queue
      )
      amqp.run
    end

    loop do
      sleep 30
    end
  end
end
