# frozen_string_literal: true

# rbs_inline: enabled

require 'get_process_mem'

module SeigenWatchdog
  module Limiters
    # Limiter based on RSS memory usage
    class RSS < Base
      # @rbs @max_rss: Integer
      # @rbs @mem: GetProcessMem

      attr_reader :max_rss #: Integer

      # @rbs max_rss: Integer
      # @rbs return: void
      def initialize(max_rss:)
        super()
        @max_rss = max_rss
        @mem = GetProcessMem.new
      end

      # @rbs return: bool
      def exceeded?
        @mem.bytes >= @max_rss
      end
    end
  end
end
