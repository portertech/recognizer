require 'minitest/autorun'

class TestTCPInput < MiniTest::Unit::TestCase
  include TestHelper

  def test_tcp_server
    tcp_input
    sleep 2
    metric = "foo 42 #{Time.now.to_i}"
    socket = TCPSocket.new("127.0.0.1", 2003)
    socket.puts(metric)
    socket.close
    assert_equal(metric, @input_queue.shift)
  end
end
