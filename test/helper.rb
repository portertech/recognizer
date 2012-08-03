require "recognizer"

module TestHelper
  def setup
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::ERROR
    @input_queue  = Queue.new
  end

  def tcp_input
    tcp = Recognizer::Input::TCP.new(
      :logger      => @logger,
      :options     => Hash.new,
      :input_queue => @input_queue
    )
    tcp.run
  end

  def amqp_input
    amqp = Recognizer::Input::AMQP.new(
      :logger      => @logger,
      :options     => {:amqp => Hash.new},
      :input_queue => @input_queue
    )
    amqp.run
  end
end
