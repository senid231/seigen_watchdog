# frozen_string_literal: true

require 'logger'

RSpec.describe SeigenWatchdog::Monitor do
  let(:killer) { instance_double(SeigenWatchdog::Killers::Signal, kill!: nil) }
  let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false, started: nil, stopped: nil) }
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

    context 'with limiters' do
      subject do
        described_class.new(
          check_interval: check_interval,
          killer: killer,
          limiters: limiters
        )
      end

      let(:check_interval) { nil }
      let(:first_limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false, started: nil, stopped: nil) }
      let(:second_limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false, started: nil, stopped: nil) }
      let(:limiters) { [first_limiter, second_limiter] }

      it 'calls started on all limiters' do
        subject
        expect(first_limiter).to have_received(:started)
        expect(second_limiter).to have_received(:started)
      end
    end

    context 'when initialized and stopped with same limiter instances' do
      let(:check_interval) { nil }
      let(:limiters) do
        [
          SeigenWatchdog::Limiters::Counter.new(:test_counter1, max_count: 10),
          SeigenWatchdog::Limiters::Counter.new(:test_counter2, max_count: 20),
          SeigenWatchdog::Limiters::Time.new(max_duration: 60),
          SeigenWatchdog::Limiters::RSS.new(max_rss: 1024 * 1024 * 100),
          SeigenWatchdog::Limiters::Custom.new(checker: -> { false })
        ]
      end

      after do
        # Cleanup registry
        SeigenWatchdog::Limiters::Counter::REGISTRY.delete(:test_counter1, safe: true)
        SeigenWatchdog::Limiters::Counter::REGISTRY.delete(:test_counter2, safe: true)
      end

      it 'allows reusing same limiter instances across monitor lifecycles' do
        # First monitor
        monitor1 = described_class.new(
          check_interval: check_interval,
          killer: killer,
          limiters: limiters
        )
        monitor1.stop

        # Second monitor with same limiter instances (same array object)
        expect do
          described_class.new(
            check_interval: check_interval,
            killer: killer,
            limiters: limiters
          )
        end.not_to raise_error
      end
    end

    context 'when initialized and stopped with new limiters with same config' do
      let(:check_interval) { nil }

      after do
        # Cleanup registry
        SeigenWatchdog::Limiters::Counter::REGISTRY.delete(:test_counter1, safe: true)
        SeigenWatchdog::Limiters::Counter::REGISTRY.delete(:test_counter2, safe: true)
      end

      it 'allows creating new limiters with same name after stop' do
        # First monitor with all types of limiters
        monitor1 = described_class.new(
          check_interval: check_interval,
          killer: killer,
          limiters: [
            SeigenWatchdog::Limiters::Counter.new(:test_counter1, max_count: 10),
            SeigenWatchdog::Limiters::Counter.new(:test_counter2, max_count: 20),
            SeigenWatchdog::Limiters::Time.new(max_duration: 60),
            SeigenWatchdog::Limiters::RSS.new(max_rss: 1024 * 1024 * 100),
            SeigenWatchdog::Limiters::Custom.new(checker: -> { false })
          ]
        )
        monitor1.stop

        # Second monitor with new limiter instances using same names/config
        expect do
          described_class.new(
            check_interval: check_interval,
            killer: killer,
            limiters: [
              SeigenWatchdog::Limiters::Counter.new(:test_counter1, max_count: 15),
              SeigenWatchdog::Limiters::Counter.new(:test_counter2, max_count: 25),
              SeigenWatchdog::Limiters::Time.new(max_duration: 120),
              SeigenWatchdog::Limiters::RSS.new(max_rss: 1024 * 1024 * 200),
              SeigenWatchdog::Limiters::Custom.new(checker: -> { true })
            ]
          )
        end.not_to raise_error
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
      expect { subject }.to change(monitor, :checks).from(0).to(1)
    end

    context 'when no limiter exceeded' do
      let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false, started: nil, stopped: nil) }

      it 'does not invoke killer' do
        subject
        expect(killer).not_to have_received(:kill!)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when a limiter is exceeded' do
      let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true, started: nil, stopped: nil) }

      it 'invokes killer' do
        subject
        expect(killer).to have_received(:kill!)
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when limiter raises an exception' do
      let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, started: nil, stopped: nil) }

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
        let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true, started: nil, stopped: nil) }

        it 'logs info message' do
          subject
          expect(logger).to have_received(:info).with(/Limit exceeded/)
        end
      end
    end

    context 'with on_exception callback' do
      let(:on_exception) { instance_double(Proc, call: nil) }
      let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, started: nil, stopped: nil) }
      let(:error) { StandardError.new('test error') }

      before do
        allow(limiter).to receive(:exceeded?).and_raise(error)
      end

      it 'calls on_exception when an error occurs' do
        subject
        expect(on_exception).to have_received(:call).with(error)
      end
    end

    context 'with before_kill callback' do
      subject { monitor.check_once }

      let(:before_kill) { instance_double(Proc, call: nil) }
      let(:monitor) do
        described_class.new(
          check_interval: nil,
          killer: killer,
          limiters: [limiter],
          before_kill: before_kill
        )
      end

      context 'when limiter is exceeded' do
        let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true, started: nil, stopped: nil) }

        it 'calls before_kill with exceeded limiter' do
          subject
          expect(before_kill).to have_received(:call).with(limiter)
        end

        it 'calls before_kill before killer' do
          call_order = []
          allow(before_kill).to receive(:call) { call_order << :before_kill }
          allow(killer).to receive(:kill!) { call_order << :killer }

          subject
          expect(call_order).to eq(%i[before_kill killer])
        end
      end

      context 'when no limiter is exceeded' do
        let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false, started: nil, stopped: nil) }

        it 'does not call before_kill' do
          subject
          expect(before_kill).not_to have_received(:call)
        end
      end

      context 'when before_kill raises an exception' do
        let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true, started: nil, stopped: nil) }
        let(:error) { StandardError.new('before_kill error') }

        before do
          allow(before_kill).to receive(:call).and_raise(error)
        end

        it 'still invokes killer' do
          subject
          expect(killer).to have_received(:kill!)
        end

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when before_kill raises exception with on_exception callback' do
        subject { monitor.check_once }

        let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: true, started: nil, stopped: nil) }
        let(:before_kill) { instance_double(Proc, call: nil) }
        let(:on_exception) { instance_double(Proc, call: nil) }
        let(:error) { StandardError.new('before_kill error') }
        let(:monitor) do
          described_class.new(
            check_interval: nil,
            killer: killer,
            limiters: [limiter],
            before_kill: before_kill,
            on_exception: on_exception
          )
        end

        before do
          allow(before_kill).to receive(:call).and_raise(error)
        end

        it 'calls on_exception with the error' do
          subject
          expect(on_exception).to have_received(:call).with(error)
        end
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

    context 'with multiple limiters' do
      let(:first_limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false, started: nil, stopped: nil) }
      let(:second_limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false, started: nil, stopped: nil) }
      let(:limiters) { [first_limiter, second_limiter] }

      let(:monitor) do
        described_class.new(check_interval: nil, killer: killer, limiters: limiters)
      end

      it 'calls stopped on all limiters' do
        subject
        expect(first_limiter).to have_received(:stopped)
        expect(second_limiter).to have_received(:stopped)
      end
    end

    context 'when called multiple times' do
      let(:single_limiter) { instance_double(SeigenWatchdog::Limiters::Base, exceeded?: false, started: nil, stopped: nil) }

      let(:monitor) do
        described_class.new(check_interval: nil, killer: killer, limiters: [single_limiter])
      end

      it 'calls stopped on limiters each time' do
        monitor.stop
        monitor.stop

        expect(single_limiter).to have_received(:stopped).twice
      end
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
        let(:limiter) { instance_double(SeigenWatchdog::Limiters::Base, started: nil, stopped: nil) }

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
