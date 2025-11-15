# frozen_string_literal: true

RSpec.describe SeigenWatchdog::Registry do
  subject(:registry) { described_class.new }

  describe '#create' do
    it 'creates a new entry with default value' do
      registry.create(:foo)
      expect(registry.get(:foo)).to eq(0)
    end

    it 'creates a new entry with custom value' do
      registry.create(:bar, 42)
      expect(registry.get(:bar)).to eq(42)
    end

    it 'raises error if entry already exists' do
      registry.create(:foo)
      expect { registry.create(:foo) }.to raise_error(SeigenWatchdog::Registry::AlreadyExistsError)
    end
  end

  describe '#replace' do
    it 'replaces the value using a block' do
      registry.create(:counter, 0)
      registry.replace(:counter) { |old| old + 1 }
      expect(registry.get(:counter)).to eq(1)
    end

    it 'yields the old value to the block' do
      registry.create(:value, 10)
      old_value = nil
      registry.replace(:value) do |old|
        old_value = old
        old * 2
      end
      expect(old_value).to eq(10)
      expect(registry.get(:value)).to eq(20)
    end

    it 'raises error if entry does not exist' do
      expect { registry.replace(:nonexistent) { |old| old } }.to raise_error(
        SeigenWatchdog::Registry::NotFoundError
      )
    end
  end

  describe '#delete' do
    it 'deletes an existing entry' do
      registry.create(:foo)
      registry.delete(:foo)
      expect(registry.get(:foo)).to be_nil
    end

    it 'raises error if entry does not exist' do
      expect { registry.delete(:nonexistent) }.to raise_error(SeigenWatchdog::Registry::NotFoundError)
    end
  end

  describe '#get' do
    it 'returns nil for non-existent entry' do
      expect(registry.get(:nonexistent)).to be_nil
    end

    it 'returns the value for existing entry' do
      registry.create(:foo, 123)
      expect(registry.get(:foo)).to eq(123)
    end
  end

  describe 'thread safety' do
    it 'handles concurrent increments correctly' do
      registry.create(:counter, 0)
      threads = 10.times.map do
        Thread.new do
          100.times { registry.replace(:counter) { |old| old + 1 } }
        end
      end
      threads.each(&:join)
      expect(registry.get(:counter)).to eq(1000)
    end
  end
end
