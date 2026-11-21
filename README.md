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

### Resolving external properties

For reports that declare `externalPropertyFileReferences`, resolve the references before querying or validating the combined runs. Inline properties are located by GUID or `sarif:` URI. The method returns a new log and appends external arrays in reference order.

```crystal
log = Sarif.from_file("report.sarif")
resolved = log.resolve_external_properties
```

For separate property files, provide a loader that returns a `Sarif::ExternalProperties` object. `base_uri` gives relative references the location of the root report. The loader controls which files are read.

```crystal
parts = {
  "file:///reports/results.sarif-external-properties" =>
    Sarif::ExternalProperties.from_json(File.read("/reports/results.sarif-external-properties")),
}

resolved = log.resolve_external_properties(base_uri: "file:///reports/report.sarif") do |uri|
  parts.fetch(uri)
end
validation = Sarif::Validator.new.validate(resolved)
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

## Examples

Runnable examples live in [`examples/`](./examples):

```bash
crystal run examples/build.cr               # Builder DSL: run + rule + result
crystal run examples/parse_and_validate.cr  # parse / parse! / Validator
crystal run examples/round_trip.cr          # build -> JSON -> parse -> validate
```

## Contributing

1. Fork it (<https://github.com/hahwul/sarif.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
