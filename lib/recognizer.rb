require "recognizer/cli"
require "recognizer/config"
require "recognizer/librato"
require "recognizer/tcp"
require "recognizer/amqp"

module Recognizer
  def self.run
    cli = Recognizer::CLI.new
    cli_options = cli.read
    config = Recognizer::Config.new(cli_options)
    config_options = config.read
    carbon_queue = Queue.new
    logger = Logger.new(STDOUT)
    Recognizer::Librato.new(carbon_queue, logger, config_options)
    Recognizer::TCP.new(carbon_queue, logger, config_options)
    Recognizer::AMQP.new(carbon_queue, logger, config_options)
    loop do
      sleep 30
    end
  end
end
