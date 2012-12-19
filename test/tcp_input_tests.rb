require 'minitest/autorun'

class TestTCPInput < MiniTest::Unit::TestCase
  include TestHelper

  def test_tcp_server
    setup_tcp_input
    socket = TCPSocket.new("127.0.0.1", 2003)
    sample_metrics.each do |metric|
      socket.puts(metric)
    end
    socket.close
    assert_equal(sample_metrics.first, @input_queue.shift)
    assert_equal(sample_metrics.last, @input_queue.shift)
  end
end
