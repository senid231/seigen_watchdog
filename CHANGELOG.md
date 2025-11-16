# 0.1.0
- initial release with basic functionality:
  - RSS memory limiter
  - Execution time limiter
  - Iteration count limiter
  - Custom condition limiter
  - Signal-based killer strategy
  - Threadsafe background watchdog
  - Configurable check interval
  - Optional logging and exception handling
# 0.2.0
- store limiters as Hash, access specific limiter by it's name, for ex. `monitor.limiter(:rss)`
- counter limiter all init, increment/decrement, and reset with specified value
# 0.3.0
- monitor prevents multiple kill calls (only calls `killer.kill!` once even if limiters continue to be exceeded)
- added `killed?` method to check if killer was invoked
- added `seconds_since_killed` method to track time elapsed since kill
- `before_kill` callback now receives limiter name and limiter instance: `->(name, limiter)`
- limiter keys are now standardized to Symbol type
