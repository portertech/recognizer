require 'minitest/autorun'

class TestAMQPInput < MiniTest::Unit::TestCase
  include TestHelper

  def test_amqp_consumer
    setup_amqp_input
    sleep 2
    metrics = [
      "foo 42 #{Time.now.to_i}",
      "malformed",
      "bar 73 #{Time.now.to_i}"
    ]
    rabbitmq = HotBunnies.connect
    amq = rabbitmq.create_channel
    exchange = amq.exchange("graphite", :type => "topic", :durable => false)
    metrics.each do |metric|
      exchange.publish(metric, :routing_key => "recognizer")
    end
    results = Array.new
    2.times do
      results << @input_queue.shift
    end
    metrics.delete("malformed")
    assert_equal(metrics, results)
    exchange.publish("42 #{Time.now.to_i}", :routing_key => "foo")
    assert_equal("foo 42 #{Time.now.to_i}", @input_queue.shift)
    amq.close
    rabbitmq.close
  end
end
