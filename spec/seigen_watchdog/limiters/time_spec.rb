# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Limiters::Time do
  describe '#started' do
    subject { limiter.started }

    let(:limiter) { described_class.new(max_duration: max_duration) }
    let(:max_duration) { 0.1 }

    it 'sets the start time' do
      subject
      expect(limiter.exceeded?).to be false
    end

    context 'when called multiple times' do
      it 'resets the timer each time' do
        limiter.started
        sleep 0.05
        expect(limiter.exceeded?).to be false

        limiter.started # Reset timer
        expect(limiter.exceeded?).to be false
      end
    end

    context 'when called after time has passed' do
      it 'resets elapsed time to 0' do
        limiter.started
        sleep max_duration + 0.05
        expect(limiter.exceeded?).to be true

        limiter.started # Reset timer
        expect(limiter.exceeded?).to be false
      end
    end
  end

  describe '#exceeded?' do
    subject { limiter.exceeded? }

    let(:limiter) { described_class.new(max_duration: max_duration) }
    let(:max_duration) { 0.1 } # 0.1 second

    before do
      limiter.started
    end

    context 'when duration is below max' do
      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when duration exceeds max' do
      before do
        sleep max_duration + 0.05
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end
end
