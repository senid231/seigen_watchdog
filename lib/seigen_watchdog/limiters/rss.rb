# frozen_string_literal: true

# rbs_inline: enabled

require 'get_process_mem'

module SeigenWatchdog
  module Limiters
    # Limiter based on RSS memory usage
    class RSS < Base
      attr_reader :max_rss #: Integer

      # @rbs @max_rss: Integer
      # @rbs @mem: GetProcessMem
      # @rbs max_rss: Integer
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
