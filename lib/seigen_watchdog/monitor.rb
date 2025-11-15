# frozen_string_literal: true

module SeigenWatchdog
  # Monitor class that checks limiters and invokes the killer when needed
  class Monitor
    attr_reader :checks

    # @param check_interval [Numeric, nil] interval in seconds between checks, nil to disable background thread
    # @param killer [Killers::Base] the killer to invoke when a limit is exceeded
    # @param limiters [Array<Limiters::Base>] array of limiters to check
    # @param logger [Logger, nil] optional logger for debugging
    # @param on_exception [Proc, nil] optional callback when an exception occurs
    def initialize(check_interval:, killer:, limiters:, logger: nil, on_exception: nil)
      @check_interval = check_interval
      @killer = killer
      @limiters = limiters
      @logger = logger
      @on_exception = on_exception
      @checks = 0
      @last_check_time = nil
      @thread = nil
      @running = false
      @mutex = Mutex.new

      if @check_interval
        start_background_thread
      else
        log_info('Monitor initialized without background thread; manual checks required')
      end
    end

    # Performs a single check of all limiters
    # @return [Boolean] true if any limiter exceeded and killer was invoked
    def check_once
      @mutex.synchronize do
        @checks += 1
        @last_check_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      log_debug("Performing check ##{@checks}")

      exceeded_limiter = @limiters.find(&:exceeded?)

      if exceeded_limiter
        log_info("Limit exceeded: #{exceeded_limiter.class.name}, invoking killer")
        @killer.kill!
        true
      else
        log_debug("All limiters within bounds")
        false
      end
    rescue StandardError => e
      handle_exception(e)
      false
    end

    # Returns the number of seconds since the last check
    # @return [Float, nil] seconds since last check, or nil if no check has been performed
    def seconds_after_last_check
      return nil if @last_check_time.nil?

      Process.clock_gettime(Process::CLOCK_MONOTONIC) - @last_check_time
    end

    # Stops the background thread if running
    def stop
      return unless @thread

      @mutex.synchronize { @running = false }
      @thread.join(5) # Wait up to 5 seconds for thread to finish
      @thread = nil
      log_debug('Monitor stopped')
    end

    # Checks if the background thread is running
    # @return [Boolean] true if the background thread is running
    def running?
      @running && @thread&.alive?
    end

    private

    def start_background_thread
      @running = true
      @thread = Thread.new { background_loop }
      @thread.abort_on_exception = false
      log_debug('Monitor started with background thread')
    end

    def background_loop
      while @running
        check_once
        sleep(@check_interval) if @running
      end
    rescue StandardError => e
      handle_exception(e)
    end

    def handle_exception(exception)
      @on_exception&.call(exception)
      log_error("Exception in monitor: #{exception.class}: #{exception.message}")
    end

    def log_debug(message)
      @logger&.debug { "SeigenWatchdog: #{message}" }
    end

    def log_info(message)
      @logger&.info("SeigenWatchdog: #{message}")
    end

    def log_error(message)
      @logger&.error("SeigenWatchdog: #{message}")
    end
  end
end
