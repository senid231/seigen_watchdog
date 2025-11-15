# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Limiters::Custom do
  describe '#exceeded?' do
    subject { limiter.exceeded? }

    let(:limiter) { described_class.new(checker: checker) }

    context 'when checker returns false' do
      let(:checker) { -> { false } }

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when checker returns true' do
      let(:checker) { -> { true } }

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'with dynamic condition' do
      let(:value) { [0] }
      let(:checker) { -> { value[0] > 5 } }

      it 'returns result based on current condition' do
        expect(subject).to be false
        value[0] = 10
        expect(limiter.exceeded?).to be true
      end
    end
  end
end
