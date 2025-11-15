# frozen_string_literal: true

RSpec.describe 'Limiters' do
  describe SeigenWatchdog::Limiters::RSS do
    subject(:limiter) { described_class.new(max_rss: max_rss) }

    let(:max_rss) { 100 * 1024 * 1024 } # 100 MB

    describe '#exceeded?' do
      it 'returns false when RSS is below max' do
        allow_any_instance_of(GetProcessMem).to receive(:bytes).and_return(50 * 1024 * 1024)
        expect(limiter.exceeded?).to be false
      end

      it 'returns true when RSS is at or above max' do
        allow_any_instance_of(GetProcessMem).to receive(:bytes).and_return(100 * 1024 * 1024)
        expect(limiter.exceeded?).to be true
      end
    end
  end

  describe SeigenWatchdog::Limiters::Time do
    subject(:limiter) { described_class.new(max_duration: max_duration) }

    before { limiter } # initialize starts the timer

    let(:max_duration) { 0.1 } # 0.1 second

    describe '#exceeded?' do
      it 'returns false when duration is below max' do
        expect(limiter.exceeded?).to be false
      end

      it 'returns true when duration exceeds max' do
        sleep max_duration + 0.05
        expect(limiter.exceeded?).to be true
      end
    end
  end

  describe SeigenWatchdog::Limiters::Counter do
    subject(:limiter) { described_class.new(:test_counter, max_count: max_count) }

    let(:max_count) { 10 }

    after do
      described_class::REGISTRY.delete(:test_counter)
    rescue SeigenWatchdog::Registry::NotFoundError
      # Counter already deleted
    end

    describe '#initialize' do
      it 'creates a counter in the registry' do
        limiter
        expect(described_class::REGISTRY.get(:test_counter)).to eq(0)
      end

      it 'raises error if counter already exists' do
        limiter
        expect { described_class.new(:test_counter, max_count: 20) }.to raise_error(
          SeigenWatchdog::Registry::AlreadyExistsError
        )
      end
    end

    describe '.increment' do
      it 'increments the counter' do
        limiter
        expect { described_class.increment(:test_counter) }.to change {
          described_class::REGISTRY.get(:test_counter)
        }.from(0).to(1)
      end

      it 'raises error if counter does not exist' do
        expect { described_class.increment(:nonexistent) }.to raise_error(
          SeigenWatchdog::Registry::NotFoundError
        )
      end
    end

    describe '.decrement' do
      it 'decrements the counter' do
        limiter
        described_class.increment(:test_counter)
        expect { described_class.decrement(:test_counter) }.to change {
          described_class::REGISTRY.get(:test_counter)
        }.from(1).to(0)
      end
    end

    describe '.reset' do
      it 'resets the counter to 0' do
        limiter
        described_class.increment(:test_counter)
        described_class.increment(:test_counter)
        expect { described_class.reset(:test_counter) }.to change {
          described_class::REGISTRY.get(:test_counter)
        }.from(2).to(0)
      end
    end

    describe '#exceeded?' do
      it 'returns false when count is below max' do
        limiter
        5.times { described_class.increment(:test_counter) }
        expect(limiter.exceeded?).to be false
      end

      it 'returns true when count equals max' do
        limiter
        10.times { described_class.increment(:test_counter) }
        expect(limiter.exceeded?).to be true
      end

      it 'returns true when count exceeds max' do
        limiter
        15.times { described_class.increment(:test_counter) }
        expect(limiter.exceeded?).to be true
      end
    end
  end

  describe SeigenWatchdog::Limiters::Custom do
    subject(:limiter) { described_class.new(checker: checker) }

    describe '#exceeded?' do
      context 'when checker returns false' do
        let(:checker) { -> { false } }

        it 'returns false' do
          expect(limiter.exceeded?).to be false
        end
      end

      context 'when checker returns true' do
        let(:checker) { -> { true } }

        it 'returns true' do
          expect(limiter.exceeded?).to be true
        end
      end

      context 'with dynamic condition' do
        let(:value) { [0] }
        let(:checker) { -> { value[0] > 5 } }

        it 'returns result based on current condition' do
          expect(limiter.exceeded?).to be false
          value[0] = 10
          expect(limiter.exceeded?).to be true
        end
      end
    end
  end
end
