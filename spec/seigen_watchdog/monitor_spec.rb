# frozen_string_literal: true

require 'logger'

RSpec.describe SeigenWatchdog::Monitor do
  let(:killer) { instance_double(SeigenWatchdog::Killers::Signal, kill!: nil) }
  let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false) }
  let(:logger) { nil }
  let(:on_exception) { nil }

  describe '#initialize' do
    subject do
      described_class.new(
        check_interval: check_interval,
        killer: killer,
        limiters: [limiter],
        logger: logger,
        on_exception: on_exception
      )
    end

    context 'when check_interval is set' do
      let(:check_interval) { 0.1 }

      it 'starts background thread' do
        monitor = subject
        expect(monitor.running?).to be true
        monitor.stop
      end
    end

    context 'when check_interval is nil' do
      let(:check_interval) { nil }

      it 'does not start background thread' do
        monitor = subject
        expect(monitor.running?).to be false
      end
    end
  end

  describe '#check_once' do
    subject { monitor.check_once }

    let(:monitor) do
      described_class.new(
        check_interval: nil,
        killer: killer,
        limiters: [limiter],
        logger: logger,
        on_exception: on_exception
      )
    end

    it 'increments the checks counter' do
      expect { subject }.to change { monitor.checks }.from(0).to(1)
    end

    context 'when no limiter exceeded' do
      let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false) }

      it 'does not invoke killer' do
        subject
        expect(killer).not_to have_received(:kill!)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when a limiter is exceeded' do
      let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true) }

      it 'invokes killer' do
        subject
        expect(killer).to have_received(:kill!)
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when limiter raises an exception' do
      let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base) }

      before do
        allow(limiter).to receive(:exceeded?).and_raise(StandardError, 'test error')
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with logger' do
      let(:logger) { instance_double(Logger, debug: nil, info: nil, error: nil) }

      before do
        allow(logger).to receive(:debug)
      end

      it 'logs debug message on check' do
        subject
        expect(logger).to have_received(:debug).at_least(:once)
      end

      context 'when killer is invoked' do
        let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true) }

        it 'logs info message' do
          subject
          expect(logger).to have_received(:info).with(/Limit exceeded/)
        end
      end
    end

    context 'with on_exception callback' do
      let(:on_exception) { instance_double(Proc, call: nil) }
      let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base) }
      let(:error) { StandardError.new('test error') }

      before do
        allow(limiter).to receive(:exceeded?).and_raise(error)
      end

      it 'calls on_exception when an error occurs' do
        subject
        expect(on_exception).to have_received(:call).with(error)
      end
    end
  end

  describe '#seconds_after_last_check' do
    subject { monitor.seconds_after_last_check }

    let(:monitor) do
      described_class.new(check_interval: nil, killer: killer, limiters: [limiter])
    end

    context 'when no check has been performed' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when a check has been performed' do
      before do
        monitor.check_once
        sleep 0.05
      end

      it 'returns time elapsed' do
        expect(subject).to be >= 0.05
      end
    end
  end

  describe '#stop' do
    subject { monitor.stop }

    let(:monitor) do
      described_class.new(check_interval: 0.1, killer: killer, limiters: [limiter])
    end

    it 'stops the background thread' do
      subject
      expect(monitor.running?).to be false
    end
  end

  describe 'background thread behavior' do
    context 'with background thread enabled' do
      let(:monitor) do
        described_class.new(check_interval: 0.1, killer: killer, limiters: [limiter])
      end

      after do
        monitor.stop
      end

      it 'performs checks at regular intervals' do
        monitor # ensure monitor is created and started
        sleep 0.35
        expect(monitor.checks).to be >= 3
      end

      context 'when limiter exceeds in background' do
        let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base) }

        before do
          allow(limiter).to receive(:exceeded?).and_return(false, false, true)
        end

        it 'invokes killer' do
          monitor # ensure monitor is created and started
          sleep 0.35
          expect(killer).to have_received(:kill!).at_least(:once)
        end
      end
    end
  end
end
