module Recognizer
  def self.generate_config(node)
    config = {:version => node.recognizer.version}
    config.merge!(:librato => node.recognizer.librato.to_hash)
    config.merge!(:tcp => node.recognizer.tcp.to_hash)

    amqp = node.recognizer.amqp.to_hash.reject { |key, value| %w[use_ssl].include?(key) || (value.is_a?(Hash) && value.empty?) }
    unless amqp.empty?
      config.merge!(:amqp => amqp)
    end

    JSON.pretty_generate(config)
  end
end
