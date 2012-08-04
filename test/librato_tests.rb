require 'minitest/autorun'

class TestAMQPInput < MiniTest::Unit::TestCase
  include TestHelper

  def test_valid_carbon_metric
    setup_librato
    assert(@librato.valid_carbon_metric?("foo 42 #{Time.now.to_i}"))
    refute(@librato.valid_carbon_metric?("cash$ 42 #{Time.now.to_i}"))
    refute(@librato.valid_carbon_metric?("foo bar #{Time.now.to_i}"))
    refute(@librato.valid_carbon_metric?("foo 42 bar"))
  end

  def test_metric_source
    metric_path = %w[production i-424242 cpu user]
    setup_librato
    assert_equal(@librato.metric_source(metric_path), "recognizer")
    setup_librato(:metric_source => "/i-.*/")
    assert_equal(@librato.metric_source(metric_path), "i-424242")
    setup_librato(:metric_source => "/foobar/")
    assert_equal(@librato.metric_source(metric_path), "recognizer")
    setup_librato(:metric_source => 1)
    assert_equal(@librato.metric_source(metric_path), "i-424242")
    setup_librato(:metric_source => 5)
    assert_equal(@librato.metric_source(metric_path), "recognizer")
  end

  def test_create_metric
    setup_librato(:metric_source => "/i-.*/")
    timestamp = Time.now.to_i
    expected = {
      "production.cpu.user" => {
        :value        => 0.5,
        :measure_time => timestamp,
        :source       => "i-424242"
      }
    }
    result = @librato.create_metric("production.i-424242.cpu.user 0.5 #{timestamp}")
    assert_equal(expected, result)
    refute(@librato.create_metric("malformed"))
  end
end
