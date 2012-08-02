require "recognizer/cli"
require "recognizer/config"
require "recognizer/librato"
require "recognizer/inputs/tcp"
require "recognizer/inputs/amqp"

module Recognizer
  def self.run
    logger = Logger.new(STDOUT)
    queue  = Queue.new
    cli    = Recognizer::CLI.new
    config = Recognizer::Config.new(cli.options)

    librato = Recognizer::Librato.new(
      :logger       => logger,
      :options      => config.options,
      :carbon_queue => queue
    )
    librato.run

    tcp = Recognizer::TCP.new(
      :logger       => logger,
      :options      => config.options,
      :carbon_queue => queue
    )
    tcp.run

    amqp = Recognizer::AMQP.new(
      :logger       => logger,
      :options      => config.options,
      :carbon_queue => queue
    )
    amqp.run

    loop do
      sleep 30
    end
  end
end
