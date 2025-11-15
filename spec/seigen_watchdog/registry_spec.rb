# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Registry do
  let(:registry) { described_class.new }

  describe '#create' do
    subject { registry.create(key, *args) }

    context 'with default value' do
      let(:key) { :foo }
      let(:args) { [] }

      it 'creates a new entry with value 0' do
        subject
        expect(registry.get(:foo)).to eq(0)
      end
    end

    context 'with custom value' do
      let(:key) { :bar }
      let(:args) { [42] }

      it 'creates a new entry with the custom value' do
        subject
        expect(registry.get(:bar)).to eq(42)
      end
    end

    context 'when entry already exists' do
      let(:key) { :foo }
      let(:args) { [] }

      before do
        registry.create(:foo)
      end

      it 'raises AlreadyExistsError' do
        expect { subject }.to raise_error(SeigenWatchdog::Registry::AlreadyExistsError)
      end
    end
  end

  describe '#replace' do
    subject { registry.replace(key, &block) }

    let(:key) { :counter }

    context 'when replacing with incremented value' do
      let(:block) { ->(old) { old + 1 } }

      before do
        registry.create(:counter, 0)
      end

      it 'replaces the value using the block' do
        subject
        expect(registry.get(:counter)).to eq(1)
      end
    end

    context 'when block uses old value' do
      let(:block) { ->(old) { old * 2 } }
      let(:key) { :value }

      before do
        registry.create(:value, 10)
      end

      it 'yields the old value to the block and stores new value' do
        subject
        expect(registry.get(:value)).to eq(20)
      end
    end

    context 'when entry does not exist' do
      let(:key) { :nonexistent }
      let(:block) { ->(old) { old } }

      it 'raises NotFoundError' do
        expect { subject }.to raise_error(SeigenWatchdog::Registry::NotFoundError)
      end
    end

    context 'with concurrent access' do
      let(:key) { :counter }
      let(:block) { ->(old) { old + 1 } }

      before do
        registry.create(:counter, 0)
        threads = 10.times.map do
          Thread.new do
            100.times { registry.replace(:counter) { |old| old + 1 } }
          end
        end
        threads.each(&:join)
      end

      it 'handles concurrent increments correctly' do
        expect(registry.get(:counter)).to eq(1000)
      end
    end
  end

  describe '#delete' do
    subject { registry.delete(key) }

    let(:key) { :foo }

    context 'when entry exists' do
      before do
        registry.create(:foo)
      end

      it 'deletes the entry' do
        subject
        expect(registry.get(:foo)).to be_nil
      end
    end

    context 'when entry does not exist' do
      let(:key) { :nonexistent }

      it 'raises NotFoundError' do
        expect { subject }.to raise_error(SeigenWatchdog::Registry::NotFoundError)
      end
    end
  end

  describe '#get' do
    subject { registry.get(key) }

    context 'when entry does not exist' do
      let(:key) { :nonexistent }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when entry exists' do
      let(:key) { :foo }

      before do
        registry.create(:foo, 123)
      end

      it 'returns the value' do
        expect(subject).to eq(123)
      end
    end
  end
end
