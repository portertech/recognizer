require "recognizer/cli"
require "recognizer/config"
require "recognizer/librato"
require "recognizer/inputs/tcp"
require "recognizer/inputs/amqp"

module Recognizer
  def self.run
    logger      = Logger.new(STDOUT)
    input_queue = Queue.new
    cli         = Recognizer::CLI.new
    config      = Recognizer::Config.new(cli.read)

    librato = Recognizer::Librato.new(
      :logger      => logger,
      :options     => config.read,
      :input_queue => input_queue
    )
    librato.run

    tcp = Recognizer::Input::TCP.new(
      :logger      => logger,
      :options     => config.read,
      :input_queue => input_queue
    )
    tcp.run

    amqp = Recognizer::Input::AMQP.new(
      :logger      => logger,
      :options     => config.read,
      :input_queue => input_queue
    )
    amqp.run

    loop do
      sleep 30
    end
  end
end
