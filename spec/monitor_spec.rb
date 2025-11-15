# frozen_string_literal: true

require 'logger'

RSpec.describe SeigenWatchdog::Monitor do
  describe '#initialize' do
    it 'starts background thread when check_interval is set' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)

      monitor = described_class.new(
        check_interval: 0.1,
        killer: killer,
        limiters: [limiter]
      )

      expect(monitor.running?).to be true
      monitor.stop
    end

    it 'does not start background thread when check_interval is nil' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)

      monitor = described_class.new(
        check_interval: nil,
        killer: killer,
        limiters: [limiter]
      )

      expect(monitor.running?).to be false
    end
  end

  describe '#check_once' do
    it 'increments the checks counter' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter])

      expect { monitor.check_once }.to change { monitor.checks }.from(0).to(1)
    end

    it 'does not invoke killer when no limiter exceeded' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter])

      monitor.check_once
      expect(killer).not_to have_received(:kill!)
    end

    it 'invokes killer when a limiter is exceeded' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter])

      monitor.check_once
      expect(killer).to have_received(:kill!)
    end

    it 'returns true when killer was invoked' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter])

      expect(monitor.check_once).to be true
    end

    it 'returns false when killer was not invoked' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter])

      expect(monitor.check_once).to be false
    end

    it 'handles exceptions from limiters' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base)
      allow(limiter).to receive(:exceeded?).and_raise(StandardError, 'test error')
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter])

      expect { monitor.check_once }.not_to raise_error
    end
  end

  describe '#seconds_after_last_check' do
    it 'returns nil before first check' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter])

      expect(monitor.seconds_after_last_check).to be_nil
    end

    it 'returns time elapsed after check' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter])

      monitor.check_once
      sleep 0.05
      expect(monitor.seconds_after_last_check).to be >= 0.05
    end
  end

  describe '#stop' do
    it 'stops the background thread' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)
      monitor = described_class.new(check_interval: 0.1, killer: killer, limiters: [limiter])

      monitor.stop
      expect(monitor.running?).to be false
    end
  end

  describe 'background thread' do
    it 'performs checks at regular intervals' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)
      monitor = described_class.new(check_interval: 0.1, killer: killer, limiters: [limiter])

      sleep 0.35
      expect(monitor.checks).to be >= 3
      monitor.stop
    end

    it 'invokes killer when limiter exceeds in background' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base)
      allow(limiter).to receive(:exceeded?).and_return(false, false, true)

      monitor = described_class.new(check_interval: 0.1, killer: killer, limiters: [limiter])

      sleep 0.35
      expect(killer).to have_received(:kill!).at_least(:once)
      monitor.stop
    end
  end

  describe 'with logger' do
    it 'logs debug message on check' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false)
      logger = instance_double(Logger, debug: nil, info: nil, error: nil)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter], logger: logger)

      allow(logger).to receive(:debug)
      monitor.check_once
      expect(logger).to have_received(:debug).at_least(:once)
    end

    it 'logs info message when killer is invoked' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true)
      logger = instance_double(Logger, debug: nil, info: nil, error: nil)
      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter], logger: logger)

      monitor.check_once
      expect(logger).to have_received(:info).with(/Limit exceeded/)
    end
  end

  describe 'with on_exception callback' do
    it 'calls on_exception when an error occurs' do
      killer = instance_double(SeigenWatchdog::Killers::Signal, kill!: nil)
      limiter = instance_double(SeigenWatchdog::Limiters::Base)
      on_exception = instance_double(Proc, call: nil)
      error = StandardError.new('test error')
      allow(limiter).to receive(:exceeded?).and_raise(error)

      monitor = described_class.new(check_interval: nil, killer: killer, limiters: [limiter], on_exception: on_exception)
      monitor.check_once

      expect(on_exception).to have_received(:call).with(error)
    end
  end
end
