# Jenerator

### JSON Document &#x21E8; Crystal type definitions

Jump-start your next JSON API client by generating types from a sample API response!

The results this outputs are meant as a starting off point, to eliminate having
to write a lot of the boilerplate involved in creating a new project to parse
the response from an API, without resorting to the runtime overhead of relying
on `JSON.parse`. You will probably want to review the generated code and make
some revisions, especially if your data sample includes arrays of objects (see
Known Issues).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     jenerator:
       github: dscottboggs/jenerator
   ```

2. Run `shards install`

## Usage

```crystal
require "jenerator"

sample = %[{"data": "just some text", "listOfData": ["one", 2, 3.0]}]
puts Jenerator.process sample
```

The above code sample would output this Crystal code:

```crystal
require "json"

class Document
  include JSON::Serializable
  @data : String
  @[JSON::Field(key: "listOfData")]
  @list_of_data : Array(String | Int64 | Float64)
end

```

There's also a compiled script which you can download as a static binary from
the ["releases"](https://github.com/dscottboggs/cached-file-server/releases)
page which will generate new Crystal source files for each `.json` file in a
directory.

# Known issues:

When generating code for an array of objects, a new class or struct is
generated for each object member of that array. The resulting type
eliminates redundant types from the union, but the types are still declared.

See [jenerator_spec.cr](./spec/jenerator_spec.cr) for an example.

## Contributing

1. Fork it (<https://github.com/dscottboggs/jenerator/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [D. Scott Boggs](https://github.com/dscottboggs) - creator and maintainer
