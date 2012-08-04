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
    amqp = Bunny.new
    amqp.start
    exchange = amqp.exchange("graphite", :type => "topic", :durable => false)
    metrics.each do |metric|
      exchange.publish(metric, :key => "recognizer")
    end
    result = Array.new
    2.times do
      result << @input_queue.shift
    end
    metrics.delete("malformed")
    assert_equal(metrics, result)
    exchange.publish("42 #{Time.now.to_i}", :key => "foo")
    assert_equal("foo 42 #{Time.now.to_i}", @input_queue.shift)
  end
end
