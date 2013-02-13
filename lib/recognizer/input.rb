module Recognizer
  module Input
    class Base
      def initialize(options={})
        @enabled     = true
        @logger      = options[:logger]
        @options     = options[:options]
        @input_queue = options[:input_queue]
      end

      def enabled?
        !!@enabled
      end

      def run
        true
      end

      def self.descendants
        ObjectSpace.each_object(Class).select do |klass|
          klass < self
        end
      end
    end
  end
end
