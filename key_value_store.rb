class KeyValueStore
  def initialize
    @store = {}          # The main committed store
    @transactions = []   # Stack of transaction layers
  end

  def get(key)
    if in_transaction?
      # Look in the most recent transaction first
      @transactions.reverse_each do |txn|
        return txn[key] if txn.key?(key)  
      end
    end
    @store[key]
  end

  def set(key, value)
    if in_transaction?
      @transactions.last[key] = value
    else
      @store[key] = value
    end
  end

  def delete(key)
    if in_transaction?
      @transactions.last[key] = nil
    else
      @store.delete(key)
    end
  end

  def begin
    @transactions.push({})
    true
  end

  def commit
    return false unless in_transaction?

    changes = @transactions.pop
    target = in_transaction? ? @transactions.last : @store

    changes.each do |key, value|
      if value.nil?
        target.delete(key)
      else
        target[key] = value
      end
    end

    true
  end

  def rollback
    return false unless in_transaction?

    @transactions.pop
    true
  end

  private

  def in_transaction?
    !@transactions.empty?
  end
end