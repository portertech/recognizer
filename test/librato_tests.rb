require 'minitest/autorun'

class TestLibrato < MiniTest::Unit::TestCase
  include TestHelper

  def test_valid_plain_text
    setup_librato
    assert(@librato.valid_plain_text?("foo 42 #{Time.now.to_i}"))
    refute(@librato.valid_plain_text?("cash$ 42 #{Time.now.to_i}"))
    refute(@librato.valid_plain_text?("foo bar #{Time.now.to_i}"))
    refute(@librato.valid_plain_text?("foo 42 bar"))
  end

  def test_extract_metric_source
    setup_librato
    metric_path = %w[production i-424242 cpu user]
    assert_equal(@librato.extract_metric_source(metric_path), "recognizer")
    assert_equal(@librato.extract_metric_source(metric_path, "/i-.*/"), "i-424242")
    assert_equal(@librato.extract_metric_source(metric_path, "/foobar/"), "recognizer")
    assert_equal(@librato.extract_metric_source(metric_path, 1), "i-424242")
    assert_equal(@librato.extract_metric_source(metric_path, 5), "recognizer")
  end

  def test_pretty_number
    setup_librato
    assert(@librato.pretty_number(1.0).is_a?(Integer))
    assert(@librato.pretty_number(1.50).is_a?(Float))
  end

  def test_create_librato_metric
    setup_librato(:metric_source => "/i-.*/")
    timestamp = Time.now.to_i
    expected = {
      "production.cpu.user" => {
        :value        => 0.5,
        :measure_time => timestamp,
        :source       => "i-424242"
      }
    }
    result = @librato.create_librato_metric("production.i-424242.cpu.user 0.50 #{timestamp}")
    assert_equal(expected, result)
    refute(@librato.create_librato_metric("malformed"))
  end
end
