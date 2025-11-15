# frozen_string_literal: true

RSpec.describe 'Killers' do
  describe SeigenWatchdog::Killers::Signal do
    subject(:killer) { described_class.new(signal: signal) }

    let(:signal) { 'INT' }

    describe '#kill!' do
      it 'sends the signal to the current process' do
        allow(Process).to receive(:kill)
        killer.kill!
        expect(Process).to have_received(:kill).with('INT', Process.pid)
      end

      it 'converts symbol signal to string' do
        killer = described_class.new(signal: :TERM)
        allow(Process).to receive(:kill)
        killer.kill!
        expect(Process).to have_received(:kill).with('TERM', Process.pid)
      end
    end
  end
end
