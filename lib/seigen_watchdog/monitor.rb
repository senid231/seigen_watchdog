# frozen_string_literal: true

# rbs_inline: enabled

module SeigenWatchdog
  # Monitor class that checks limiters and invokes the killer when needed
  class Monitor
    # @rbs @check_interval: Numeric?
    # @rbs @killer: Killers::Base
    # @rbs @limiters: Array[Limiters::Base]
    # @rbs @logger: Logger?
    # @rbs @on_exception: Proc?
    # @rbs @before_kill: Proc?
    # @rbs @checks: Integer
    # @rbs @last_check_time: Float? | nil
    # @rbs @thread: Thread? | nil
    # @rbs @running: bool
    # @rbs @mutex: Thread::Mutex

    attr_reader :checks #: Integer

    # Interval in seconds between checks, nil to disable background thread
    # @rbs check_interval: Numeric?
    # The killer to invoke when a limit is exceeded
    # @rbs killer: Killers::Base
    # Array of limiters to check
    # @rbs limiters: Array[Limiters::Base]
    # Optional logger for debugging
    # @rbs logger: Logger?
    # Optional callback when an exception occurs
    # @rbs on_exception: Proc?
    # Optional callback invoked before killing, receives exceeded limiter
    # @rbs before_kill: Proc?
    # @rbs return: void
    def initialize(check_interval:, killer:, limiters:, logger: nil, on_exception: nil, before_kill: nil)
      @check_interval = check_interval
      @killer = killer
      @limiters = limiters
      @logger = logger
      @on_exception = on_exception
      @before_kill = before_kill
      @checks = 0
      @last_check_time = nil
      @thread = nil
      @running = false
      @mutex = Mutex.new

      # Call started on all limiters to initialize their state
      @limiters.each(&:started)

      if @check_interval
        start_background_thread
      else
        log_info('Monitor initialized without background thread; manual checks required')
      end
    end

    # Performs a single check of all limiters
    # Returns true if any limiter exceeded and killer was invoked
    # @rbs return: bool
    def check_once
      increment_checks
      log_debug("Performing check ##{@checks}")

      exceeded_limiter = @limiters.find(&:exceeded?)
      if exceeded_limiter
        log_info("Limit exceeded: #{exceeded_limiter.class.name}, invoking killer")
        run_before_kill(exceeded_limiter)
        @killer.kill!
        true
      else
        log_debug('All limiters within bounds')
        false
      end
    rescue StandardError => e
      handle_exception(e)
      false
    end

    # Returns the number of seconds since the last check
    # Seconds since last check, or nil if no check has been performed
    # @rbs return: Float?
    def seconds_after_last_check
      return nil if @last_check_time.nil?

      Process.clock_gettime(Process::CLOCK_MONOTONIC) - @last_check_time
    end

    # Stops the background thread if running
    # @rbs return: void
    def stop
      if @thread
        @mutex.synchronize { @running = false }
        @thread.join(5) # Wait up to 5 seconds for thread to finish
        @thread = nil
        log_debug('Monitor stopped')
      end

      # Call stopped on all limiters to clean up their state
      @limiters.each(&:stopped)
    end

    # Checks if the background thread is running
    # Returns true if the background thread is running
    # @rbs return: bool
    def running?
      @running && @thread&.alive?
    end

    private

    def run_before_kill(exceeded_limiter)
      @before_kill&.call(exceeded_limiter)
    rescue StandardError => e
      handle_exception(e)
    end

    def increment_checks
      @mutex.synchronize do
        @checks += 1
        @last_check_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end

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
