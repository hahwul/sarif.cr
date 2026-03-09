# sarif.cr

Crystal library for the [SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html) (Static Analysis Results Interchange Format) specification. Build, parse, and validate SARIF documents with type safety.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  sarif:
    github: hahwul/sarif.cr
```

Then run `shards install`.

## Usage

```crystal
require "sarif"
```

### Building SARIF

```crystal
log = Sarif::Builder.build do |b|
  b.run("MyLinter", "1.0.0") do |r|
    r.rule("LINT001", name: "UnusedVar",
           short_description: "Unused variable detected")
    r.result("Variable 'x' is never used",
             rule_id: "LINT001",
             level: Sarif::Level::Warning,
             uri: "src/main.cr",
             start_line: 10)
  end
end

puts log.to_pretty_json
```

### Parsing SARIF

```crystal
# From string
log = Sarif.parse(json_string)

# From string with validation
log = Sarif.parse!(json_string)

# From file
log = Sarif.from_file("report.sarif")
log = Sarif.from_file!("report.sarif") # with validation
```

### Validating SARIF

```crystal
validator = Sarif::Validator.new
result = validator.validate(log)

if result.valid?
  puts "Valid SARIF document"
else
  result.errors.each { |e| puts e.message }
end
```

## Contributing

1. Fork it (<https://github.com/hahwul/sarif.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
