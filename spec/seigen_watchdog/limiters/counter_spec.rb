# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Limiters::Counter do
  let(:max_count) { 10 }

  after do
    described_class::REGISTRY.delete(:test_counter)
  rescue SeigenWatchdog::Registry::NotFoundError
    # Counter already deleted
  end

  describe '#initialize' do
    subject { described_class.new(:test_counter, max_count: max_count) }

    context 'when counter does not exist' do
      it 'creates a counter in the registry' do
        subject
        expect(described_class::REGISTRY.get(:test_counter)).to eq(0)
      end
    end

    context 'when counter already exists' do
      before do
        described_class.new(:test_counter, max_count: max_count)
      end

      it 'raises AlreadyExistsError' do
        expect { subject }.to raise_error(SeigenWatchdog::Registry::AlreadyExistsError)
      end
    end
  end

  describe '.increment' do
    subject { described_class.increment(:test_counter) }

    context 'when counter exists' do
      before do
        described_class.new(:test_counter, max_count: max_count)
      end

      it 'increments the counter' do
        expect { subject }.to change {
          described_class::REGISTRY.get(:test_counter)
        }.from(0).to(1)
      end
    end

    context 'when counter does not exist' do
      let(:subject) { described_class.increment(:nonexistent) }

      it 'raises NotFoundError' do
        expect { subject }.to raise_error(SeigenWatchdog::Registry::NotFoundError)
      end
    end
  end

  describe '.decrement' do
    subject { described_class.decrement(:test_counter) }

    before do
      described_class.new(:test_counter, max_count: max_count)
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
      described_class.new(:test_counter, max_count: max_count)
      described_class.increment(:test_counter)
      described_class.increment(:test_counter)
    end

    it 'resets the counter to 0' do
      expect { subject }.to change {
        described_class::REGISTRY.get(:test_counter)
      }.from(2).to(0)
    end
  end

  describe '#exceeded?' do
    subject { limiter.exceeded? }

    let(:limiter) { described_class.new(:test_counter, max_count: max_count) }

    context 'when count is below max' do
      before do
        limiter # ensure limiter is created
        5.times { described_class.increment(:test_counter) }
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when count equals max' do
      before do
        limiter # ensure limiter is created
        10.times { described_class.increment(:test_counter) }
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when count exceeds max' do
      before do
        limiter # ensure limiter is created
        15.times { described_class.increment(:test_counter) }
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end
end
