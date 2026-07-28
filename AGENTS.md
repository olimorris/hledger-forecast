# hledger-forecast

This is a RubyGem that enables users to use a CSV file as a forecast. This then feeds into hledger, generating entries into a journal file.

## Code formatting

After editing any Ruby files, run:

```
rubyfmt spec lib -i
```

## Tests

Tests can be run with:

```
rspec
```

## Non-verbose grouping

In non-verbose mode, `Generator.build_groups` (lib/hledger_forecast/generator.rb) merges CSV rows into a single hledger periodic transaction only when they share `[type, frequency, from, to, account, category]`. Rows with different categories always produce separate `~` entries, even if they share account/date - hledger treats postings within one transaction as linked, so bundling unrelated line items under one transaction misrepresents them in reports (e.g. `hledger register` shows every posting's account against every row, not just the filtered one). When touching grouping logic, check the effect through `hledger reg`/`register`, not just the raw journal text output.

## version.rb

`lib/hledger_forecast/version.rb` is bumped by release automation (release-please), not manually. If it shows as changed after running tests/tooling and you didn't intend a release bump, `git checkout` it rather than committing the bump.
