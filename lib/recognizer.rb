require "recognizer/version"
require "recognizer/cli"
require "recognizer/config"
require "recognizer/librato"
require "recognizer/amqp"

module Recognizer
  def self.run
    cli = Recognizer::CLI.new
    cli.parse_options
    config = Recognizer::Config.new(cli.config)
    options = config.read
    thread_queue = Queue.new
    Recognizer::Librato.new(thread_queue, options)
    Recognizer::AMQP.new(thread_queue, options)
  end
end
