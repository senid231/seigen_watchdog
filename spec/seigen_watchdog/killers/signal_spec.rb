# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Killers::Signal do
  describe '#kill!' do
    subject { killer.kill! }

    let(:killer) { described_class.new(signal: signal) }

    before do
      allow(Process).to receive(:kill)
    end

    context 'when signal is a string' do
      let(:signal) { 'INT' }

      it 'sends the signal to the current process' do
        subject
        expect(Process).to have_received(:kill).with('INT', Process.pid)
      end
    end

    context 'when signal is a symbol' do
      let(:signal) { :TERM }

      it 'converts symbol to string and sends signal' do
        subject
        expect(Process).to have_received(:kill).with('TERM', Process.pid)
      end
    end
  end
end
