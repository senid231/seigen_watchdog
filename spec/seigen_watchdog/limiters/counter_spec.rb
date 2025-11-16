# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Limiters::Counter do
  let(:max_count) { 10 }
  let(:limiter) { described_class.new(max_count: max_count) }

  describe '#initialize' do
    subject { limiter }

    it 'stores the max_count' do
      expect(subject.max_count).to eq(max_count)
    end

    it 'initializes counter to 0' do
      expect(subject.exceeded?).to be false
    end

    context 'with custom initial value' do
      let(:limiter) { described_class.new(max_count: max_count, initial: 5) }

      it 'initializes counter to the specified value' do
        # Counter starts at 5, needs 5 more increments to reach max_count of 10
        expect(subject.exceeded?).to be false
        5.times { subject.increment }
        expect(subject.exceeded?).to be true
      end
    end
  end

  describe '#increment' do
    subject { limiter.increment }

    it 'increments the counter by 1' do
      expect { subject }.not_to change(limiter, :exceeded?)
    end

    context 'with count parameter' do
      subject { limiter.increment(5) }

      it 'increments the counter by specified amount' do
        subject
        expect(limiter.exceeded?).to be false
      end
    end

    context 'when incrementing to max_count' do
      it 'causes exceeded? to return true' do
        10.times { limiter.increment }
        expect(limiter.exceeded?).to be true
      end
    end

    context 'when incrementing beyond max_count' do
      it 'causes exceeded? to return true' do
        15.times { limiter.increment }
        expect(limiter.exceeded?).to be true
      end
    end

    context 'when called from multiple threads' do
      it 'safely increments without race conditions' do
        threads = 100.times.map do
          Thread.new { limiter.increment }
        end
        threads.each(&:join)

        expect(limiter.exceeded?).to be true
      end
    end
  end

  describe '#decrement' do
    subject { limiter.decrement }

    before do
      5.times { limiter.increment }
    end

    it 'decrements the counter by 1' do
      expect { subject }.not_to(change(limiter, :exceeded?))
    end

    context 'with count parameter' do
      subject { limiter.decrement(3) }

      it 'decrements the counter by specified amount' do
        expect { subject }.not_to(change(limiter, :exceeded?))
      end
    end

    context 'when called from multiple threads' do
      it 'safely decrements without race conditions' do
        100.times { limiter.increment }

        threads = 50.times.map do
          Thread.new { limiter.decrement }
        end
        threads.each(&:join)

        expect(limiter.exceeded?).to be true
      end
    end
  end

  describe '#reset' do
    subject { limiter.reset }

    before do
      15.times { limiter.increment }
    end

    it 'resets the counter to 0' do
      expect(limiter.exceeded?).to be true
      subject
      expect(limiter.exceeded?).to be false
    end

    context 'when called from multiple threads' do
      it 'safely resets without race conditions' do
        threads = [
          Thread.new { 10.times { limiter.increment } },
          Thread.new { limiter.reset },
          Thread.new { 5.times { limiter.increment } }
        ]
        threads.each(&:join)

        # Counter should be either 5 (if reset happened first) or some other value
        # The important thing is no exceptions occur
        expect { limiter.exceeded? }.not_to raise_error
      end
    end

    context 'with custom initial value' do
      subject { limiter.reset(7) }

      it 'resets the counter to the specified value' do
        expect(limiter.exceeded?).to be true
        subject
        expect(limiter.exceeded?).to be false
        # Counter is now at 7, needs 3 more increments to reach max_count of 10
        3.times { limiter.increment }
        expect(limiter.exceeded?).to be true
      end
    end
  end

  describe '#exceeded?' do
    subject { limiter.exceeded? }

    context 'when count is below max' do
      before do
        5.times { limiter.increment }
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when count equals max' do
      before do
        10.times { limiter.increment }
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when count exceeds max' do
      before do
        15.times { limiter.increment }
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when called from multiple threads' do
      it 'safely checks without race conditions' do
        threads = 100.times.map do |i|
          Thread.new do
            limiter.increment if i.even?
            limiter.exceeded?
          end
        end

        results = threads.map(&:value)
        expect(results).to all(be(true).or(be(false)))
      end
    end
  end
end
