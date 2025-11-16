# frozen_string_literal: true

# rbs_inline: enabled

module SeigenWatchdog
  # Monitor class that checks limiters and invokes the killer when needed
  class Monitor
    # @rbs @check_interval: Numeric?
    # @rbs @killer: Killers::Base
    # @rbs @limiters: Hash[Symbol, Limiters::Base]
    # @rbs @logger: Logger?
    # @rbs @on_exception: Proc?
    # @rbs @before_kill: Proc?
    # @rbs @checks: Integer
    # @rbs @last_check_time: Float? | nil
    # @rbs @time_killed: Float? | nil
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
    # @rbs limiters: Hash[Symbol, Limiters::Base]
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
      @limiters = limiters.transform_keys(&:to_sym)
      @logger = logger
      @on_exception = on_exception
      @before_kill = before_kill
      @checks = 0
      @last_check_time = nil
      @time_killed = nil
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

      name, limiter = @limiters.find { |_k, v| v.exceeded? }
      if limiter
        if killed?
          log_debug("Limit exceeded but killer already invoked #{seconds_since_killed} seconds ago")
        else
          log_info("Limit exceeded: #{name}, invoking killer")
          perform_kill(name, limiter)
        end
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

    # Returns true if the killer has been invoked
    # @rbs return: bool
    def killed?
      !@time_killed.nil?
    end

    # Returns the number of seconds since the killer was invoked
    # Seconds since killer was invoked, or nil if killer has not been invoked
    # @rbs return: Float?
    def seconds_since_killed
      return nil if @time_killed.nil?

      Process.clock_gettime(Process::CLOCK_MONOTONIC) - @time_killed
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
      @limiters.fetch(name.to_sym)
    end

    # Returns a hash of all limiters
    # Returns a new hash with the same keys and values
    # Modifications to the hash won't affect internal state, but limiter instances are shared
    # @rbs return: Hash[Symbol | String, Limiters::Base]
    def limiters
      @limiters.to_h { |k, v| [k, v] }
    end

    private

    # @rbs name: Symbol
    # @rbs limiter: Limiters::Base
    # @rbs return: void
    def perform_kill(name, limiter)
      run_before_kill(name, limiter)
      @killer.kill!
      @time_killed = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # @rbs name: Symbol
    # @rbs limiter: Limiters::Base
    # @rbs return: void
    def run_before_kill(name, limiter)
      @before_kill&.call(name, limiter)
    rescue StandardError => e
      handle_exception(e)
    end

    # @rbs return: void
    def increment_checks
      @mutex.synchronize do
        @checks += 1
        @last_check_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end

    # @rbs return: void
    def start_background_thread
      @running = true
      @thread = Thread.new { background_loop }
      @thread.abort_on_exception = false
    end

    # @rbs return: void
    def background_loop
      while @running
        check_once
        sleep(@check_interval) if @running
      end
    rescue StandardError => e
      handle_exception(e)
    end

    # @rbs exception: StandardError
    # @rbs return: void
    def handle_exception(exception)
      log_error("Exception in monitor: #{exception.class}: #{exception.message}")
      @on_exception&.call(exception)
    end

    # @rbs message: String
    # @rbs return: void
    def log_debug(message)
      @logger&.debug { "SeigenWatchdog: #{message}" }
    end

    # @rbs message: String
    # @rbs return: void
    def log_info(message)
      @logger&.info("SeigenWatchdog: #{message}")
    end

    # @rbs message: String
    # @rbs return: void
    def log_error(message)
      @logger&.error("SeigenWatchdog: #{message}")
    end
  end
end
