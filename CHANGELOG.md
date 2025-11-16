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
