# frozen_string_literal: true

module SeigenWatchdog
  module Limiters
    # Limiter based on iteration count
    class Counter < Base
      REGISTRY = Registry.new

      class << self
        # Increments the counter for the given name
        # @param name [Symbol, String] the name of the counter
        # @raise [Registry::NotFoundError] if the counter doesn't exist
        def increment(name)
          REGISTRY.replace(name) { |value| value + 1 }
        end

        # Decrements the counter for the given name
        # @param name [Symbol, String] the name of the counter
        # @raise [Registry::NotFoundError] if the counter doesn't exist
        def decrement(name)
          REGISTRY.replace(name) { |value| value - 1 }
        end

        # Resets the counter for the given name to 0
        # @param name [Symbol, String] the name of the counter
        # @raise [Registry::NotFoundError] if the counter doesn't exist
        def reset(name)
          REGISTRY.replace(name) { 0 }
        end
      end

      # @param name [Symbol, String] the name of the counter
      # @param max_count [Integer] maximum count allowed
      # @raise [Registry::AlreadyExistsError] if a counter with this name already exists
      def initialize(name, max_count:)
        super()
        @name = name
        @max_count = max_count
        REGISTRY.create(name, 0)
      end

      # @return [Boolean] true if current count exceeds or equals the maximum
      def exceeded?
        current_count >= @max_count
      end

      private

      def current_count
        REGISTRY.get(@name) || 0
      end
    end
  end
end
