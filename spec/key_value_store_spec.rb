require_relative '../key_value_store'

RSpec.describe KeyValueStore do
  let(:store) { KeyValueStore.new }

  describe '#initialize' do
    it 'creates a new instance' do
      expect(store).to be_an_instance_of(KeyValueStore)
    end
  end

  describe '#get' do
    context 'when key exists' do
      before { store.set('key1', 42) }
      
      it 'returns the value' do
        expect(store.get('key1')).to eq(42)
      end
    end

    context 'when key does not exist' do
      it 'returns nil' do
        expect(store.get('nonexistent')).to be_nil
      end
    end

    context 'within a transaction' do
      it 'returns the value from the transaction layer' do
        store.set('key1', 10)
        store.begin
        store.set('key1', 20)
        expect(store.get('key1')).to eq(20)
      end

      it 'falls back to committed store if key not in transaction' do
        store.set('key1', 10)
        store.begin
        expect(store.get('key1')).to eq(10)
      end

      it 'returns nil if key is deleted in transaction' do
        store.set('key1', 10)
        store.begin
        store.delete('key1')
        expect(store.get('key1')).to be_nil
      end
    end

    context 'with nested transactions' do
      it 'returns value from the most recent transaction' do
        store.set('key1', 10)
        store.begin
        store.set('key1', 20)
        store.begin
        store.set('key1', 30)
        expect(store.get('key1')).to eq(30)
      end

      it 'falls back through transaction layers' do
        store.set('key1', 10)
        store.begin
        store.set('key1', 20)
        store.begin
        expect(store.get('key1')).to eq(20)
      end
    end
  end

  describe '#set' do
    it 'sets a key-value pair' do
      store.set('key1', 42)
      expect(store.get('key1')).to eq(42)
    end

    it 'updates an existing key' do
      store.set('key1', 10)
      store.set('key1', 20)
      expect(store.get('key1')).to eq(20)
    end

    it 'accepts various value types' do
      store.set('string_key', 'string_value')
      store.set('float_key', 3.14)
      store.set('nil_key', nil)
      store.set('boolean_key', true)
      store.set('array_key', [1, 2, 3])
      store.set('hash_key', { nested: 'hash' })

      expect(store.get('string_key')).to eq('string_value')
      expect(store.get('float_key')).to eq(3.14)
      expect(store.get('nil_key')).to be_nil
      expect(store.get('boolean_key')).to be true
      expect(store.get('array_key')).to eq([1, 2, 3])
      expect(store.get('hash_key')).to eq({ nested: 'hash' })
    end

    context 'within a transaction' do
      it 'sets the value in the transaction layer' do
        store.set('key1', 10)
        store.begin
        store.set('key1', 20)
        expect(store.get('key1')).to eq(20)
        store.rollback
        expect(store.get('key1')).to eq(10)
      end
    end
  end

  describe '#delete' do
    context 'when key exists' do
      before { store.set('key1', 42) }

      it 'removes the key from the store' do
        store.delete('key1')
        expect(store.get('key1')).to be_nil
      end
    end

    context 'when key does not exist' do
      it 'does not raise an error' do
        expect { store.delete('nonexistent') }.not_to raise_error
      end
    end

    context 'within a transaction' do
      it 'marks the key for deletion in the transaction layer' do
        store.set('key1', 10)
        store.begin
        store.delete('key1')
        expect(store.get('key1')).to be_nil
        store.rollback
        expect(store.get('key1')).to eq(10)
      end

      it 'can delete a key set in the same transaction' do
        store.begin
        store.set('key1', 10)
        store.delete('key1')
        expect(store.get('key1')).to be_nil
      end
    end
  end

  describe '#begin' do
    it 'starts a new transaction' do
      expect(store.begin).to be true
    end

    it 'allows nested transactions' do
      expect(store.begin).to be true
      expect(store.begin).to be true
    end

    it 'isolates changes within transactions' do
      store.set('key1', 10)
      store.begin
      store.set('key1', 20)
      store.set('key2', 30)
      
      # Changes are visible within transaction
      expect(store.get('key1')).to eq(20)
      expect(store.get('key2')).to eq(30)
    end
  end

  describe '#commit' do
    context 'when in a transaction' do
      it 'applies changes and returns true' do
        store.set('key1', 10)
        store.begin
        store.set('key1', 20)
        store.set('key2', 30)
        
        expect(store.commit).to be true
        expect(store.get('key1')).to eq(20)
        expect(store.get('key2')).to eq(30)
      end

      it 'applies deletions' do
        store.set('key1', 10)
        store.begin
        store.delete('key1')
        
        expect(store.commit).to be true
        expect(store.get('key1')).to be_nil
      end

      it 'commits to parent transaction when nested' do
        store.set('key1', 10)
        store.begin
        store.set('key1', 20)
        store.begin
        store.set('key1', 30)
        
        expect(store.commit).to be true
        expect(store.get('key1')).to eq(30)
        
        # Still in first transaction
        store.rollback
        expect(store.get('key1')).to eq(10)
      end
    end

    context 'when not in a transaction' do
      it 'returns false' do
        expect(store.commit).to be false
      end
    end
  end

  describe '#rollback' do
    context 'when in a transaction' do
      it 'discards changes and returns true' do
        store.set('key1', 10)
        store.begin
        store.set('key1', 20)
        store.set('key2', 30)
        
        expect(store.rollback).to be true
        expect(store.get('key1')).to eq(10)
        expect(store.get('key2')).to be_nil
      end

      it 'restores deleted keys' do
        store.set('key1', 10)
        store.begin
        store.delete('key1')
        
        expect(store.rollback).to be true
        expect(store.get('key1')).to eq(10)
      end

      it 'rolls back only the innermost transaction when nested' do
        store.set('key1', 10)
        store.begin
        store.set('key1', 20)
        store.begin
        store.set('key1', 30)
        
        expect(store.rollback).to be true
        expect(store.get('key1')).to eq(20) # Back to first transaction value
        
        store.commit
        expect(store.get('key1')).to eq(20)
      end
    end

    context 'when not in a transaction' do
      it 'returns false' do
        expect(store.rollback).to be false
      end
    end
  end

  describe 'complex transaction scenarios' do
    it 'handles multiple nested transactions with mixed operations' do
      store.set('a', 1)
      store.set('b', 2)
      
      store.begin
      store.set('a', 10)
      store.delete('b')
      store.set('c', 30)
      
      store.begin
      store.set('a', 100)
      store.set('b', 200)
      
      expect(store.get('a')).to eq(100)
      expect(store.get('b')).to eq(200)
      expect(store.get('c')).to eq(30)
      
      store.rollback # Roll back inner transaction
      expect(store.get('a')).to eq(10)
      expect(store.get('b')).to be_nil
      expect(store.get('c')).to eq(30)
      
      store.commit # Commit outer transaction
      expect(store.get('a')).to eq(10)
      expect(store.get('b')).to be_nil
      expect(store.get('c')).to eq(30)
    end

    it 'handles transaction operations on the same key' do
      store.begin
      store.set('key', 10)
      store.set('key', 20)
      store.delete('key')
      store.set('key', 30)
      
      expect(store.get('key')).to eq(30)
      
      store.commit
      expect(store.get('key')).to eq(30)
    end
  end
end