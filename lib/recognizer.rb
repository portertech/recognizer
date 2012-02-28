require "recognizer/cli"
require "recognizer/config"
require "recognizer/librato"
require "recognizer/amqp"

module Recognizer
  def self.run
    cli = Recognizer::CLI.new
    cli_options = cli.read
    config = Recognizer::Config.new(cli_options)
    config_options = config.read
    thread_queue = Queue.new
    Recognizer::Librato.new(thread_queue, config_options)
    Recognizer::AMQP.new(thread_queue, config_options)
  end
end
