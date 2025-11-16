# frozen_string_literal: true

require_relative 'seigen_watchdog/version'

# Monitoring and watchdog module for Ruby applications
module SeigenWatchdog
  # @rbs self.@monitor: Monitor?

  class Error < StandardError; end

  class << self
    attr_reader :monitor #: Monitor?

    # Starts the SeigenWatchdog monitor
    # @rbs check_interval: Numeric?
    # @rbs killer: Killers::Base
    # @rbs limiters: Hash[Symbol | String, Limiters::Base]
    # @rbs logger: Logger?
    # @rbs on_exception: Proc?
    # @rbs before_kill: Proc?
    # @rbs return: Monitor
    def start(check_interval:, killer:, limiters:, logger: nil, on_exception: nil, before_kill: nil)
      stop if started?

      @monitor = Monitor.new(
        check_interval: check_interval,
        killer: killer,
        limiters: limiters,
        logger: logger,
        on_exception: on_exception,
        before_kill: before_kill
      )
    end

    # Stops the SeigenWatchdog monitor
    # @rbs return: void
    def stop
      return unless @monitor

      @monitor.stop
      @monitor = nil
    end

    # Checks if the monitor has been started
    # Returns true if the monitor is started
    # @rbs return: bool
    def started?
      !@monitor.nil?
    end
  end
end

require_relative 'seigen_watchdog/limiters/base'
require_relative 'seigen_watchdog/limiters/rss'
require_relative 'seigen_watchdog/limiters/time'
require_relative 'seigen_watchdog/limiters/counter'
require_relative 'seigen_watchdog/limiters/custom'
require_relative 'seigen_watchdog/killers/base'
require_relative 'seigen_watchdog/killers/signal'
require_relative 'seigen_watchdog/monitor'
