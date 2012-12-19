require 'minitest/autorun'

class TestAMQPInput < MiniTest::Unit::TestCase
  include TestHelper

  def test_amqp_consumer
    setup_amqp_input
    rabbitmq = HotBunnies.connect
    amq = rabbitmq.create_channel
    exchange = amq.exchange("graphite", :type => "topic", :durable => false)
    sample_metrics.each do |metric|
      exchange.publish(metric, :routing_key => "recognizer")
    end
    assert_equal(sample_metrics.first, @input_queue.shift)
    assert_equal(sample_metrics.last, @input_queue.shift)
    timestamp = Time.now.to_i
    exchange.publish("42 #{timestamp}", :routing_key => "foo")
    assert_equal("foo 42 #{timestamp}", @input_queue.shift)
    amq.close
    rabbitmq.close
  end
end
