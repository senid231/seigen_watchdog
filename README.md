# SeigenWatchdog

Seigen (制限 — “limit, restriction”).

Monitors and gracefully terminates a Ruby application based on configurable memory usage, execution time, iteration count, or custom conditions. Threadsafe and easy to integrate.

How it works:
After setting up SeigenWatchdog with desired limiters and a killer strategy, it spawns a background thread that periodically checks the defined conditions. If any limiter exceeds its threshold, the specified killer strategy is invoked to terminate the application gracefully.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add seigen_watchdog
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install seigen_watchdog
```

## Requirements

- Ruby >= 3.3.0
- Dependencies:
  - `get_process_mem` - for RSS memory monitoring
  - `logger` - for optional debug logging

## Usage

```ruby
require 'seigen_watchdog'

SeigenWatchdog.start(
 check_interval: 5, # seconds or nil for no periodic checks
 killer: SeigenWatchdog::Killers::Signal.new(signal: 'INT'),
 limiters: [
    SeigenWatchdog::Limiters::RSS.new(max_rss: 200 * 1024 * 1024), # 200 MB
    SeigenWatchdog::Limiters::Time.new(max_duration: 24 * 60 * 60), # 24 hours
    SeigenWatchdog::Limiters::Counter.new(:main, max_count: 1_000_000), # 1 million iterations
    SeigenWatchdog::Limiters::Custom.new(checker: -> { SomeCondition.met? }) # custom condition
 ],
 logger: Logger.new($stdout), # optional logger, logs DEBUG for each check, INFO when killer is invoked
 on_exception: ->(e) { Sentry.capture_exception(e) }, # optional exception handler
 before_kill: ->(limiter) { Prometheus::KillInstrument.send_metrics(limiter.class.name) } # optional callback before kill
)
  
# to increment particular count limiter
SeigenWatchdog::Limiters::Counter.increment(:main) # Example of incrementing the counter limiter

# to perform check manually (if check_interval is nil)
SeigenWatchdog.monitor.check_once

# to stop the watchdog
SeigenWatchdog.stop

# to check if watchdog is running
SeigenWatchdog.started? # => true or false
```

## API Reference

### Module Methods

#### `SeigenWatchdog.start(check_interval:, killer:, limiters:, logger: nil, on_exception: nil, before_kill: nil)`
Starts the watchdog monitor with the specified configuration.

**Parameters:**
- `check_interval` - Interval in seconds between checks, or `nil` for manual checks only
- `killer` - Killer strategy instance (e.g., `SeigenWatchdog::Killers::Signal.new(signal: 'INT')`)
- `limiters` - Array of limiter instances
- `logger` - Optional logger instance for debug/info logging
- `on_exception` - Optional callback proc for exception handling (receives exception as argument)
- `before_kill` - Optional callback proc invoked before killing (receives exceeded limiter as argument)

**Returns:** Monitor instance

#### `SeigenWatchdog.stop`
Stops the watchdog monitor and terminates the background thread.

#### `SeigenWatchdog.started?`
Returns `true` if the watchdog is currently running, `false` otherwise.

#### `SeigenWatchdog.monitor`
Returns the current monitor instance, or `nil` if not started.

### Monitor Instance Methods

#### `monitor.check_once`
Performs a single manual check of all limiters. Useful when `check_interval` is `nil`.

**Returns:** `true` if a limit was exceeded and killer was invoked, `false` otherwise.

### Limiters

#### `SeigenWatchdog::Limiters::RSS.new(max_rss:)`
Monitors RSS (Resident Set Size) memory usage.
- `max_rss` - Maximum RSS in bytes

#### `SeigenWatchdog::Limiters::Time.new(max_duration:)`
Monitors execution time since limiter creation.
- `max_duration` - Maximum duration in seconds

#### `SeigenWatchdog::Limiters::Counter.new(name, max_count:)`
Monitors iteration count with manual incrementing.
- `name` - Symbol identifier for the counter
- `max_count` - Maximum count before exceeding

**Class Methods:**
- `Counter.increment(name)` - Increments the counter
- `Counter.decrement(name)` - Decrements the counter
- `Counter.reset(name)` - Resets the counter to 0

#### `SeigenWatchdog::Limiters::Custom.new(checker:)`
Custom condition limiter using a proc.
- `checker` - Proc that returns `true` when limit is exceeded

### Killers

#### `SeigenWatchdog::Killers::Signal.new(signal:)`
Terminates the process by sending a signal.
- `signal` - Signal name as string or symbol (e.g., `'INT'`, `:TERM`)

## Callbacks

### `before_kill` Callback

The `before_kill` callback is invoked immediately before the killer strategy is executed when a limiter exceeds its threshold. This allows you to perform cleanup operations, send metrics, or log information about which limit was exceeded.

**Callback signature:**
```ruby
->(exceeded_limiter) { ... }
```

**Arguments:**
- `exceeded_limiter` - The limiter instance that exceeded its threshold

**Example use cases:**
```ruby
# Send metrics to monitoring system
before_kill: ->(limiter) {
  Prometheus::KillInstrument.send_metrics(limiter.class.name)
}

# Log detailed information
before_kill: ->(limiter) {
  Rails.logger.warn("Process killed due to #{limiter.class.name} limit exceeded")
}

# Send alert
before_kill: ->(limiter) {
  Sentry.capture_message("Watchdog killing process: #{limiter.class.name}")
}

# Perform cleanup based on limiter type
before_kill: ->(limiter) {
  case limiter
  when SeigenWatchdog::Limiters::RSS
    Rails.logger.warn("Memory limit exceeded: #{limiter.max_rss / 1024 / 1024} MB")
  when SeigenWatchdog::Limiters::Time
    Rails.logger.warn("Time limit exceeded: #{limiter.max_duration} seconds")
  end
}
```

**Exception handling:**
If the `before_kill` callback raises an exception, it will be handled by the `on_exception` callback (if provided) and the killer will still be invoked to ensure the process terminates as expected.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/seigen_watchdog.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
