# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Limiters::Counter do
  let(:max_count) { 10 }

  after do
    described_class::REGISTRY.delete(:test_counter, safe: true)
  end

  describe '#initialize' do
    subject { described_class.new(:test_counter, max_count: max_count) }

    it 'stores the name and max_count' do
      expect { subject }.not_to raise_error
    end

    it 'does not create counter in registry yet' do
      subject
      expect(described_class::REGISTRY.get(:test_counter)).to be_nil
    end
  end

  describe '.increment' do
    subject { described_class.increment(:test_counter) }

    context 'when counter exists' do
      before do
        limiter = described_class.new(:test_counter, max_count: max_count)
        limiter.started
      end

      it 'increments the counter' do
        expect { subject }.to change {
          described_class::REGISTRY.get(:test_counter)
        }.from(0).to(1)
      end
    end

    context 'when counter does not exist' do
      it 'raises NotFoundError' do
        expect { described_class.increment(:nonexistent) }.to raise_error(SeigenWatchdog::Registry::NotFoundError)
      end
    end
  end

  describe '.decrement' do
    subject { described_class.decrement(:test_counter) }

    before do
      limiter = described_class.new(:test_counter, max_count: max_count)
      limiter.started
      described_class.increment(:test_counter)
    end

    it 'decrements the counter' do
      expect { subject }.to change {
        described_class::REGISTRY.get(:test_counter)
      }.from(1).to(0)
    end
  end

  describe '.reset' do
    subject { described_class.reset(:test_counter) }

    before do
      limiter = described_class.new(:test_counter, max_count: max_count)
      limiter.started
      described_class.increment(:test_counter)
      described_class.increment(:test_counter)
    end

    it 'resets the counter to 0' do
      expect { subject }.to change {
        described_class::REGISTRY.get(:test_counter)
      }.from(2).to(0)
    end
  end

  describe '#started' do
    subject { limiter.started }

    let(:limiter) { described_class.new(:test_counter, max_count: max_count) }

    it 'creates counter in registry with initial value 0' do
      subject
      expect(described_class::REGISTRY.get(:test_counter)).to eq(0)
    end

    context 'when counter already exists in registry' do
      before do
        described_class::REGISTRY.create(:test_counter, 5)
      end

      it 'resets counter to 0' do
        subject
        expect(described_class::REGISTRY.get(:test_counter)).to eq(0)
      end
    end

    context 'when called multiple times' do
      it 'resets counter each time' do
        limiter.started
        described_class.increment(:test_counter)
        described_class.increment(:test_counter)
        expect(described_class::REGISTRY.get(:test_counter)).to eq(2)

        limiter.started
        expect(described_class::REGISTRY.get(:test_counter)).to eq(0)
      end
    end
  end

  describe '#stopped' do
    subject { limiter.stopped }

    let(:limiter) { described_class.new(:test_counter, max_count: max_count) }

    before do
      limiter.started
    end

    it 'removes counter from registry' do
      subject
      expect(described_class::REGISTRY.get(:test_counter)).to be_nil
    end

    context 'when counter does not exist in registry' do
      before do
        described_class::REGISTRY.delete(:test_counter, safe: true)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when called multiple times' do
      it 'does not raise error' do
        limiter.stopped
        expect { limiter.stopped }.not_to raise_error
      end
    end
  end

  describe '#exceeded?' do
    subject { limiter.exceeded? }

    let(:limiter) { described_class.new(:test_counter, max_count: max_count) }

    before do
      limiter.started
    end

    context 'when count is below max' do
      before do
        5.times { described_class.increment(:test_counter) }
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when count equals max' do
      before do
        10.times { described_class.increment(:test_counter) }
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when count exceeds max' do
      before do
        15.times { described_class.increment(:test_counter) }
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end
end
