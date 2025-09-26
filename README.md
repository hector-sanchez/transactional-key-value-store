# Transactional Key-Value Store

A Ruby implementation of an in-memory key-value store with support for nested transactions. This data structure allows you to store and retrieve key-value pairs while providing transactional capabilities including commit, rollback, and nested transaction support.

## Features

- **Basic Operations**: Get, set, and delete key-value pairs
- **Transactional Support**: Begin, commit, and rollback operations
- **Nested Transactions**: Support for multiple levels of nested transactions
- **Flexible Value Types**: Store any Ruby object as values (strings, integers, arrays, hashes, etc.)
- **Transaction Isolation**: Changes within transactions are isolated until committed

## Installation

Clone the repository:

```bash
git clone https://github.com/hector-sanchez/transactional-key-value-store.git
cd transactional-key-value-store
```

Install dependencies:

```bash
bundle install
```

## Usage

### Basic Operations

```ruby
require_relative 'key_value_store'

# Create a new store
kv = KeyValueStore.new

# Set values
kv.set("name", "Alice")
kv.set("age", 30)
kv.set("hobbies", ["reading", "swimming"])

# Get values
puts kv.get("name")    # => "Alice"
puts kv.get("age")     # => 30
puts kv.get("missing") # => nil

# Delete values
kv.delete("age")
puts kv.get("age")     # => nil
```

### Transaction Operations

```ruby
# Basic transaction
kv.set("balance", 100)

kv.begin
kv.set("balance", 150)
puts kv.get("balance")  # => 150 (within transaction)

kv.rollback
puts kv.get("balance")  # => 100 (rolled back)

# Commit transaction
kv.begin
kv.set("balance", 200)
kv.commit
puts kv.get("balance")  # => 200 (committed)
```

### Nested Transactions

```ruby
kv.set("x", 10)

kv.begin                # Transaction 1
kv.set("x", 20)

kv.begin                # Transaction 2 (nested)
kv.set("x", 30)
puts kv.get("x")        # => 30

kv.rollback             # Rollback Transaction 2
puts kv.get("x")        # => 20 (back to Transaction 1 value)

kv.commit               # Commit Transaction 1
puts kv.get("x")        # => 20 (committed)
```

## API Reference

### Public Methods

#### `initialize`
Creates a new KeyValueStore instance.

```ruby
store = KeyValueStore.new
```

#### `get(key)`
Retrieves the value associated with a key.

- **Parameters**: `key` - The key to look up
- **Returns**: The value associated with the key, or `nil` if not found
- **Behavior**: Looks in the current transaction first, then falls back to committed store

#### `set(key, value)`
Sets a key-value pair.

- **Parameters**: 
  - `key` - The key to set
  - `value` - The value to associate with the key (any Ruby object)
- **Behavior**: Sets the value in the current transaction if active, otherwise in the main store

#### `delete(key)`
Removes a key from the store.

- **Parameters**: `key` - The key to remove
- **Behavior**: Marks for deletion in current transaction if active, otherwise removes from main store

#### `begin`
Starts a new transaction.

- **Returns**: `true`
- **Behavior**: Creates a new transaction layer; supports nesting

#### `commit`
Commits the current transaction.

- **Returns**: `true` if successful, `false` if not in a transaction
- **Behavior**: Applies changes to the parent transaction or main store

#### `rollback`
Rolls back the current transaction.

- **Returns**: `true` if successful, `false` if not in a transaction
- **Behavior**: Discards all changes in the current transaction

## Testing

The project includes comprehensive RSpec tests covering all functionality.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run tests with detailed output
bundle exec rspec --format documentation
```

### Test Coverage

The test suite includes:

- ✅ Basic CRUD operations
- ✅ Transaction isolation and nesting
- ✅ Complex transaction scenarios
- ✅ Edge cases and error conditions
- ✅ Various data types as values
- ✅ Nested transaction commit/rollback behavior

Example test output:
```
KeyValueStore
  #get
    ✓ returns the value when key exists
    ✓ returns nil when key does not exist
    ✓ returns value from transaction layer
  #set
    ✓ sets a key-value pair
    ✓ accepts various value types
  #transaction operations
    ✓ handles nested transactions
    ✓ commits and rollbacks work correctly

29 examples, 0 failures
```

## Examples

### Complex Transaction Scenario

```ruby
kv = KeyValueStore.new

# Set initial values
kv.set("account_a", 100)
kv.set("account_b", 50)

# Transfer money with transactions
kv.begin
kv.set("account_a", kv.get("account_a") - 25)  # Withdraw from A
kv.set("account_b", kv.get("account_b") + 25)  # Deposit to B

# Check balances before commit
puts "A: #{kv.get('account_a')}, B: #{kv.get('account_b')}"  # A: 75, B: 75

kv.commit  # Make the transfer permanent

puts "Final - A: #{kv.get('account_a')}, B: #{kv.get('account_b')}"  # A: 75, B: 75
```

### Working with Different Data Types

```ruby
kv = KeyValueStore.new

# Store various Ruby objects
kv.set("string", "Hello World")
kv.set("number", 42)
kv.set("float", 3.14)
kv.set("array", [1, 2, 3])
kv.set("hash", { name: "Alice", age: 30 })
kv.set("boolean", true)
kv.set("nil_value", nil)

# All values are preserved with their original types
puts kv.get("hash")[:name]  # => "Alice"
puts kv.get("array").first  # => 1
```

## Implementation Details

- **Storage**: Uses Ruby Hash for both main store and transaction layers
- **Transactions**: Implemented as a stack of hash layers
- **Lookup Strategy**: Searches from most recent transaction backward to committed store
- **Deletion**: Uses `nil` markers in transaction layers, actual deletion on commit
- **Thread Safety**: Not thread-safe (single-threaded use)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`bundle exec rspec`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).