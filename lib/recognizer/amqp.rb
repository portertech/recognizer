require "rubygems"
require "bunny"

module Recognizer
  class AMQP
    def initialize(queue, options)
      unless queue && options.is_a?(Hash)
        raise "You must provide a thread queue and options"
      end
    end
  end
end
