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

## Usage

```ruby
require 'seigen_watchdog'

SeigenWatchdog.setup(
 check_interval: 5, # seconds
 killer: SeigenWatchdog::Killers::Signal.new(signal: 'INT'),
 limiters: [
    SeigenWatchdog::Limiters::RSS.new(max_rss: 200 * 1024 * 1024), # 200 MB
    SeigenWatchdog::Limiters::Time.new(max_duration: 24 * 60 * 60), # 24 hours
    SeigenWatchdog::Limiters::Counter.new(:main, max_count: 1_000_000), # 1 million iterations
    SeigenWatchdog::Limiters::Custom.new(checker: -> { SomeCondition.met? }) # custom condition
 ],
 logger: Logger.new($stdout), # optional logger, logs DEBUG for each check, INFO when killer is invoked
 on_exception: ->(e) { Sentry.capture_exception(e) } # optional exception handler
)
  
# somewhere in your application code here
SeigenWatchdog::Limiters::Counter.increment(:main) # Example of incrementing the counter limiter
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/seigen_watchdog.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
