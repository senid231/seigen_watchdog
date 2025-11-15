# frozen_string_literal: true

RSpec.describe SeigenWatchdog do
  after do
    SeigenWatchdog.stop if SeigenWatchdog.started?
  end

  it 'has a version number' do
    expect(SeigenWatchdog::VERSION).not_to be_nil
  end

  describe '.start' do
    it 'starts the monitor' do
      killer = SeigenWatchdog::Killers::Signal.new(signal: 'INT')
      limiters = [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)]

      monitor = SeigenWatchdog.start(
        check_interval: 1,
        killer: killer,
        limiters: limiters
      )

      expect(monitor).to be_a(SeigenWatchdog::Monitor)
      expect(SeigenWatchdog.started?).to be true
      expect(SeigenWatchdog.monitor).to eq(monitor)
    end

    it 'starts without background thread when check_interval is nil' do
      killer = SeigenWatchdog::Killers::Signal.new(signal: 'INT')
      limiters = [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)]

      monitor = SeigenWatchdog.start(
        check_interval: nil,
        killer: killer,
        limiters: limiters
      )

      expect(monitor).to be_a(SeigenWatchdog::Monitor)
      expect(monitor.running?).to be false
    end
  end

  describe '.stop' do
    it 'stops the monitor' do
      killer = SeigenWatchdog::Killers::Signal.new(signal: 'INT')
      limiters = [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)]

      SeigenWatchdog.start(
        check_interval: 1,
        killer: killer,
        limiters: limiters
      )

      SeigenWatchdog.stop

      expect(SeigenWatchdog.started?).to be false
      expect(SeigenWatchdog.monitor).to be_nil
    end
  end

  describe '.started?' do
    it 'returns false when not started' do
      expect(SeigenWatchdog.started?).to be false
    end

    it 'returns true when started' do
      killer = SeigenWatchdog::Killers::Signal.new(signal: 'INT')
      limiters = [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)]

      SeigenWatchdog.start(
        check_interval: 1,
        killer: killer,
        limiters: limiters
      )

      expect(SeigenWatchdog.started?).to be true
    end
  end

  describe '.monitor' do
    it 'returns nil when not started' do
      expect(SeigenWatchdog.monitor).to be_nil
    end

    it 'returns the monitor instance when started' do
      killer = SeigenWatchdog::Killers::Signal.new(signal: 'INT')
      limiters = [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)]

      monitor = SeigenWatchdog.start(
        check_interval: 1,
        killer: killer,
        limiters: limiters
      )

      expect(SeigenWatchdog.monitor).to eq(monitor)
    end
  end
end
