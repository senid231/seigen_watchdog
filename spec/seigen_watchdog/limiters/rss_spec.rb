# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Limiters::RSS do
  describe '#exceeded?' do
    subject { limiter.exceeded? }

    let(:limiter) { described_class.new(max_rss: max_rss) }
    let(:max_rss) { 100 * 1024 * 1024 } # 100 MB

    context 'when RSS is below max' do
      before do
        allow_any_instance_of(GetProcessMem).to receive(:bytes).and_return(50 * 1024 * 1024)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when RSS is at or above max' do
      before do
        allow_any_instance_of(GetProcessMem).to receive(:bytes).and_return(100 * 1024 * 1024)
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end
end
