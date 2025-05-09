# Memoization

Easy Crystal memoization.

## Installation

Add to your `shard.yml`:

```yml
dependencies:
  memoization:
    github: davidrunger/memoization
```

## Usage

Just add `memoize` before the method that you would like to memoize.

```crystal
require "memoization"

class Example
  memoize def random_number : Float64
    Random.rand
  end

  memoize def hello_with_random_number(name_to_greet : String) : String
    "Hello, #{name_to_greet}! #{Random.rand}"
  end

  def call_private_method
    private_method
  end

  private memoize def private_method : String
    "private #{Random.rand}"
  end
end

example = Example.new

# Memoize a public method:
pp! example.random_number # => 0.7239151427874982
pp! example.random_number # => 0.7239151427874982

# Memoize a method that takes argument(s):
pp! example.hello_with_random_number("Jane") # => "Hello, Jane! 0.18170318331241622"
pp! example.hello_with_random_number("John") # => "Hello, John! 0.8370694373403952"
pp! example.hello_with_random_number("Jane") # => "Hello, Jane! 0.18170318331241622"

# Memoize a private method:
pp! example.call_private_method # => "private 0.5261598848669066"
pp! example.call_private_method # => "private 0.5261598848669066"
```

## Credit

This library is based on the [Lucky web framework's memoization code][lucky-memoization].

[lucky-memoization]: https://github.com/luckyframework/lucky/blob/v1.3.0/src/lucky/memoizable.cr
