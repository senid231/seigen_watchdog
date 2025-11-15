# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Limiters::Time do
  describe '#exceeded?' do
    subject { limiter.exceeded? }

    let(:limiter) { described_class.new(max_duration: max_duration) }
    let(:max_duration) { 0.1 } # 0.1 second

    before { limiter } # initialize starts the timer

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
