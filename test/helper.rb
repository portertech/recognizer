require "recognizer"

module TestHelper
  def setup
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::ERROR
    @input_queue  = Queue.new
  end

  def setup_librato(options={})
    config = {
      :librato => {
        :email   => "foo@bar.com",
        :api_key => "foobar"
      }
    }
    config[:librato].merge!(options)
    @librato = Recognizer::Librato.new(
      :logger      => @logger,
      :options     => config,
      :input_queue => @input_queue
    )
  end

  def setup_tcp_input(options={})
    config = {
      :tcp => Hash.new
    }
    config[:tcp].merge!(options)
    tcp = Recognizer::Input::TCP.new(
      :logger      => @logger,
      :options     => config,
      :input_queue => @input_queue
    )
    tcp.run
  end

  def setup_amqp_input(options={})
    config = {
      :amqp => Hash.new
    }
    config[:amqp].merge!(options)
    amqp = Recognizer::Input::AMQP.new(
      :logger      => @logger,
      :options     => config,
      :input_queue => @input_queue
    )
    amqp.run
  end
end
