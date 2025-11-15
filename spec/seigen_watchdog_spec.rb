# frozen_string_literal: true

RSpec.describe SeigenWatchdog do
  after do
    described_class.stop if described_class.started?
  end

  it 'has a version number' do
    expect(SeigenWatchdog::VERSION).not_to be_nil
  end

  describe '.start' do
    subject { described_class.start(check_interval: check_interval, killer: killer, limiters: limiters) }

    let(:killer) { SeigenWatchdog::Killers::Signal.new(signal: 'INT') }
    let(:limiters) { [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)] }

    context 'with background thread' do
      let(:check_interval) { 1 }

      it 'starts the monitor and returns it' do
        monitor = subject
        expect(monitor).to be_a(SeigenWatchdog::Monitor)
        expect(described_class.started?).to be true
        expect(described_class.monitor).to eq(monitor)
      end
    end

    context 'without background thread' do
      let(:check_interval) { nil }

      it 'starts the monitor without running background thread' do
        monitor = subject
        expect(monitor).to be_a(SeigenWatchdog::Monitor)
        expect(monitor.running?).to be false
      end
    end
  end

  describe '.stop' do
    subject { described_class.stop }

    let(:killer) { SeigenWatchdog::Killers::Signal.new(signal: 'INT') }
    let(:limiters) { [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)] }

    before do
      described_class.start(check_interval: 1, killer: killer, limiters: limiters)
    end

    it 'stops the monitor' do
      subject
      expect(described_class.started?).to be false
      expect(described_class.monitor).to be_nil
    end
  end

  describe '.started?' do
    subject { described_class.started? }

    context 'when not started' do
      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when started' do
      let(:killer) { SeigenWatchdog::Killers::Signal.new(signal: 'INT') }
      let(:limiters) { [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)] }

      before do
        described_class.start(check_interval: 1, killer: killer, limiters: limiters)
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end

  describe '.monitor' do
    subject { described_class.monitor }

    context 'when not started' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when started' do
      let(:killer) { SeigenWatchdog::Killers::Signal.new(signal: 'INT') }
      let(:limiters) { [SeigenWatchdog::Limiters::Time.new(max_duration: 1000)] }
      let(:monitor) { described_class.start(check_interval: 1, killer: killer, limiters: limiters) }

      before do
        monitor
      end

      it 'returns the monitor instance' do
        expect(subject).to eq(monitor)
      end
    end
  end
end
