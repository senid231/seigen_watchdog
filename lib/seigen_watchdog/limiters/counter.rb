# frozen_string_literal: true

# rbs_inline: enabled

module SeigenWatchdog
  module Limiters
    # Limiter based on iteration count
    class Counter < Base
      # @rbs REGISTRY: Registry
      REGISTRY = Registry.new

      class << self
        # Increments the counter for the given name
        # @rbs name: Symbol | String
        # @rbs return: void
        def increment(name)
          REGISTRY.replace(name) { |value| value + 1 }
        end

        # Decrements the counter for the given name
        # @rbs name: Symbol | String
        # @rbs return: void
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

      attr_reader :name #: Symbol | String
      attr_reader :max_count #: Integer

      # @param name [Symbol, String] the name of the counter
      # @param max_count [Integer] maximum count allowed
      def initialize(name, max_count:)
        super()
        @name = name
        @max_count = max_count
      end

      # Called when monitor starts - creates/resets the counter in registry
      def started
        # Delete existing counter if present (handles reusing same limiter instance)
        REGISTRY.delete(@name, safe: true)
        # Create fresh counter at 0
        REGISTRY.create(@name, 0)
      end

      # Called when monitor stops - removes the counter from registry
      def stopped
        REGISTRY.delete(@name, safe: true)
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
