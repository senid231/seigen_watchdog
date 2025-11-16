# frozen_string_literal: true

# rbs_inline: enabled

module SeigenWatchdog
  # Monitor class that checks limiters and invokes the killer when needed
  class Monitor
    # @rbs @check_interval: Numeric?
    # @rbs @killer: Killers::Base
    # @rbs @limiters: Hash[Symbol | String, Limiters::Base]
    # @rbs @logger: Logger?
    # @rbs @on_exception: Proc?
    # @rbs @before_kill: Proc?
    # @rbs @checks: Integer
    # @rbs @last_check_time: Float? | nil
    # @rbs @thread: Thread? | nil
    # @rbs @running: bool
    # @rbs @mutex: Thread::Mutex

    # @rbs!
    #   attr_reader checks: Integer
    attr_reader :checks

    # Interval in seconds between checks, nil to disable background thread
    # @rbs check_interval: Numeric?
    # The killer to invoke when a limit is exceeded
    # @rbs killer: Killers::Base
    # Hash of limiters to check
    # @rbs limiters: Hash[Symbol | String, Limiters::Base]
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
      @limiters.each_value(&:started)

      if @check_interval
        log_info('Monitor started with background thread')
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

      exceeded_limiter = @limiters.values.find(&:exceeded?)
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
      @limiters.each_value(&:stopped)
    end

    # Checks if the background thread is running
    # Returns true if the background thread is running
    # @rbs return: bool
    def running?
      @running && @thread&.alive?
    end

    # Returns a limiter by name
    # @rbs name: Symbol | String
    # @rbs return: Limiters::Base
    def limiter(name)
      @limiters.fetch(name)
    end

    # Returns a hash of all limiters
    # Returns a new hash with the same keys and values
    # Modifications to the hash won't affect internal state, but limiter instances are shared
    # @rbs return: Hash[Symbol | String, Limiters::Base]
    def limiters
      @limiters.to_h { |k, v| [k, v] }
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
      log_error("Exception in monitor: #{exception.class}: #{exception.message}")
      @on_exception&.call(exception)
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
