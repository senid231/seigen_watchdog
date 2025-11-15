# frozen_string_literal: true

require_relative 'seigen_watchdog/version'

module SeigenWatchdog
  class Error < StandardError; end

  class << self
    attr_reader :monitor

    # Starts the SeigenWatchdog monitor
    # @param check_interval [Numeric, nil] interval in seconds between checks, nil to disable background thread
    # @param killer [Killers::Base] the killer to invoke when a limit is exceeded
    # @param limiters [Array<Limiters::Base>] array of limiters to check
    # @param logger [Logger, nil] optional logger for debugging
    # @param on_exception [Proc, nil] optional callback when an exception occurs
    # @return [Monitor] the monitor instance
    def start(check_interval:, killer:, limiters:, logger: nil, on_exception: nil)
      stop if started?

      @monitor = Monitor.new(
        check_interval: check_interval,
        killer: killer,
        limiters: limiters,
        logger: logger,
        on_exception: on_exception
      )
    end

    # Stops the SeigenWatchdog monitor
    def stop
      return unless @monitor

      @monitor.stop
      @monitor = nil
    end

    # Checks if the monitor has been started
    # @return [Boolean] true if the monitor is started
    def started?
      !@monitor.nil?
    end
  end
end

require_relative 'seigen_watchdog/registry'
require_relative 'seigen_watchdog/limiters/base'
require_relative 'seigen_watchdog/limiters/rss'
require_relative 'seigen_watchdog/limiters/time'
require_relative 'seigen_watchdog/limiters/counter'
require_relative 'seigen_watchdog/limiters/custom'
require_relative 'seigen_watchdog/killers/base'
require_relative 'seigen_watchdog/killers/signal'
require_relative 'seigen_watchdog/monitor'
