<p align="center">
<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/5edb77e3-0ec6-4158-9b16-3978c1259879" alt="hledger-forecast" />
</p>

<h1 align="center">hledger-forecast</h1>

<p align="center">
<a href="https://github.com/olimorris/hledger-forecast/stargazers"><img src="https://img.shields.io/github/stars/olimorris/hledger-forecast?style=for-the-badge"></a>
<a href="https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/olimorris/hledger-forecast/ci.yml?branch=main&label=tests&style=for-the-badge"></a>
<a href="https://github.com/olimorris/hledger-forecast/releases"><img src="https://img.shields.io/github/v/release/olimorris/hledger-forecast?style=for-the-badge"</a>
</p>

**"Improved", you say?** Using a _CSV_ file, forecasts can be quickly generated into a _journal_ file ready to be fed into [hledger](https://github.com/simonmichael/hledger). **A 16 line [CSV file](https://github.com/olimorris/hledger-forecast/blob/main/example.csv) can generate a 46 line hledger [forecast file](https://github.com/olimorris/hledger-forecast/blob/main/example.journal)!**

## :sparkles: Features

- :rocket: Simple CSV file drives the whole forecast
- :mag: Supports maths in your amounts _and_ dates
- :label: Apply tags to your transactions​
- :bar_chart: Summarize forecasts as daily/weekly/monthly/yearly income and expenditure reports
- :twisted_rightwards_arrows: Compare and highlight the difference between two hledger CSV outputs
- :computer: Straightforward CLI

## :brain: The problem statement

Forecasting is essential to how I plan and budget with hledger. It enables me to know my financial position in 1 month, 10 months or even 100 months from now.

But forecasting in hledger is verbose and unintelligent. Consider this scenario: you purchase a new $3,000 laptop on a 0% finance deal and spread it over 20 months. In hledger, this would be accounted for with:

```ledger
~ monthly from 2026-01-01 to 2027-08-31  * New Laptop
    Expenses:General Expenses           $150.00
    Assets:Checking
```

Except, you'd need to work out what 20 months from `2026-01-01` is and do $3000 \div 20$.

In `hledger-forecast`, you add a single line to your CSV:

```csv
monthly,,Assets:Checking,01/01/2026,+20,New Laptop,Expenses:General Expenses,=3000/20,,,
```

The tool calculates the amount and the end date for you.

Now the natural next question: _what does that $150/month do to your monthly surplus_? With `hledger-forecast`, that's one command:

    hledger-forecast summarize -f forecast.csv -r monthly

You get an [income statement](https://en.wikipedia.org/wiki/Income_statement) in your terminal  - income, expenses, totals, and savings rate.

## :camera_flash: Screenshots

**A CSV forecast and the hledger journal it generates**

<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/430503b5-f447-4972-b122-b48f8628aff9" alt="hledger-Forecast" />

**The output from the `summarize` command**

<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/f5017ea2-9606-46ec-8b38-8840dc175e7b" alt="Summarize command" />

## :package: Installation

Assuming you have Ruby and [RubyGems](http://rubygems.org/pages/download) installed:

    gem install hledger-forecast

## :rocket: Usage

    hledger-forecast

    Usage: hledger-forecast [command] [options]

    Commands:
      generate    Generate a forecast from a CSV file
      summarize   Summarize the forecast file and output to the terminal
      compare     Compare and highlight the differences between two CSV files

    Options:
        -h, --help                       Show this help message
        -v, --version                    Show version

### Generate

Reads your CSV file and creates a journal file ready to use with hledger. See [example.journal](https://github.com/olimorris/hledger-forecast/blob/main/example.journal) for an example of the output.

    hledger-forecast generate -f my_forecast.csv -o forecast.journal

    Usage: hledger-forecast generate [options]

      -f, --forecast FILE              The path to the FORECAST CSV file to generate from
      -o, --output-file FILE           The path to the OUTPUT file to create
      -t, --tags TAGS                  Only include transactions with given tags (comma-separated)
      -v, --verbose                    Don't group transactions by type in the output file
          --force                      Force an overwrite of the output file
      -h, --help                       Show this help message

Running with no options assumes a `forecast.csv` file exists in the current directory.

### Using with hledger

Include the generated journal file and use hledger's `--forecast` flag:

    hledger -f bank_transactions.journal -f forecast.journal --forecast bal assets -e 2027-02

This will generate a forecast up to the end of Feb 2027, showing asset balances with your bank transactions overlaid. Forecasting in hledger has some nuance, so please refer to the [hledger docs](https://hledger.org/dev/hledger.html) or open a [discussion](https://github.com/olimorris/hledger-forecast/discussions/new?category=q-a) if you get stuck.

> **Tip:** If you use `hledger-ui`, the `--verbose` flag is worth using. It keeps each transaction as its own entry in the journal, making descriptions much easier to read in the UI.

### Summarize

As your forecast grows, it's useful to see the totals at a glance. Think of this as your income statement, rolled up to whatever period makes sense.

    hledger-forecast summarize -f my_forecast.csv

    Usage: hledger-forecast summarize [options]

      -f, --forecast FILE              The path to the FORECAST CSV file to summarize
      -r, --roll-up PERIOD             The period to roll-up your forecasts into. One of:
                                       [yearly], [half-yearly], [quarterly], [monthly], [weekly], [daily]
      -t, --tags TAGS                  Only include transactions with given tags (comma-separated)
      -v, --verbose                    Show additional information in the summary
      -h, --help                       Show this help message

### Compare

A core part of managing personal finances is comparing what you _expected_ to happen with what _actually_ happened. The `compare` command makes this easy:

    hledger-forecast compare path/to/expected.csv path/to/actual.csv

To generate CSV output from hledger, append `-O csv > output.csv` to any hledger command.

For wide output, pipe through a pager like [most](https://en.wikipedia.org/wiki/Most_(Unix)):

    hledger-forecast compare file1.csv file2.csv | most

> **Note:** The two CSV files must have the same structure.

## :gear: Creating your forecast

### Columns

The CSV file should have a header row with these columns:

| Column | Type | Required | Description |
|---|---|---|---|
| `type` | string | yes | One of: `monthly`, `quarterly`, `half-yearly`, `yearly`, `once`, `custom` |
| `frequency` | string | `custom` only | Repeating frequency, using hledger's [periodic rule syntax](https://hledger.org/dev/hledger.html#periodic-transactions) |
| `account` | string | yes | The account the transaction applies to, e.g. `Assets:Bank` |
| `from` | date | yes | Start date, e.g. `01/03/2023` |
| `to` | date | no | End date, e.g. `01/01/2025`. Supports `+` prefix for calculated values, e.g. `+12` for 12 months |
| `description` | string | yes | A description of the transaction |
| `category` | string | yes | The category account, e.g. `Expenses:Food` |
| `amount` | number | yes | The transaction amount. Supports `=` prefix for calculated values |
| `roll-up` | number | no | Multiplier for the summarizer — use this for `custom` types to annualise them |
| `summary_exclude` | boolean | no | Set to `TRUE` to exclude from the summarizer |
| `tag` | string | no | Pipe-separated tags, e.g. `fixed|essential`. Outputs as native hledger tags |

### Example

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,tag
monthly,,Assets:Bank,01/03/2023,,Salary,Income:Salary,-3500,,,fixed|essential
monthly,,Assets:Bank,01/03/2023,01/01/2025,Mortgage,Expenses:Mortgage,2000,,,fixed|essential
monthly,,Assets:Bank,01/03/2023,,Bills,Expenses:Bills,175,,,fixed|essential
monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,500,,,living|essential
monthly,,Assets:Bank,01/03/2023,,New Kitchen,Expenses:House,=5000/24,,,living
monthly,,Assets:Bank,01/03/2023,+12,Holiday,Expenses:Holiday,125,,,living
monthly,,Assets:Bank,01/03/2023,01/03/2025,Rainy day fund,Assets:Savings,300,,,saving
monthly,,Assets:Pension,01/01/2024,,Pension draw down,Income:Pension,-500,,,fixed|essential
quarterly,,Assets:Bank,01/04/2023,,Quarterly bonus,Income:Bonus,-1000,,,fixed
half-yearly,,Assets:Bank,01/04/2023,,Top up holiday funds,Expenses:Holiday,500,,,living
yearly,,Assets:Bank,01/04/2023,,Annual bonus,Income:Bonus,-2000,,,fixed
once,,Assets:Bank,05/03/2023,,Refund for that damn laptop,Expenses:Shopping,-3000,TRUE,
custom,every 2 weeks,Assets:Bank,01/03/2023,,Hair and beauty,Expenses:Personal Care,80,26,,living
custom,every 5 weeks,Assets:Bank,01/03/2023,,Misc expenses,Expenses:General Expenses,30,10.4,,living
settings,currency,USD,,,,,,,,
```

### Calculated amounts

Prefix any `amount` with `=` and write it as a standard formula — the app will evaluate it for you. Great for spreading a lump sum across months:

```csv
monthly,,Assets:Bank,01/03/2023,,New Kitchen,Expenses:House,=5000/24,,
```

> Calculations are evaluated to two decimal places.

### Calculated dates

The `to` column supports calculated values. Use `+` followed by a number to mean "N months from the `from` date":

```csv
monthly,,Assets:Bank,01/03/2026,+12,Holiday,Expenses:Holiday,125,,
```

That sets the end date to 12 months after `01/03/2026`. The `=` prefix also supports formulas — useful for longer periods:

```csv
monthly,,Assets:Bank,01/03/2026,=12*5,Mortgage,Expenses:Mortgage,2000,,
```

That sets the end date to 5 years (60 months) after `01/03/2026`.

### Tags

Add a `tag` column to your CSV to tag transactions. Tags are output as native [hledger tags](https://hledger.org/tags-tutorial.html), making them queryable in hledger itself. Multiple tags are separated by pipes (`|`):

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,tag
monthly,,Assets:Bank,01/03/2023,,Salary,Income:Salary,-3500,,,fixed|essential
monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,500,,,living|essential
monthly,,Assets:Bank,01/03/2023,,Netflix,Expenses:Subscriptions,15,,,living
```

This generates journal entries with proper hledger tags on each posting:

```
~ monthly from 2023-03-01  * Salary, Food, Netflix
    Income:Salary             £-3,500.00;  fixed:, essential:
    Expenses:Food             £500.00   ;  living:, essential:
    Expenses:Subscriptions    £15.00    ;  living:
    Assets:Bank
```

**Filtering by tags** - both `generate` and `summarize` accept a `--tags` flag to include only transactions matching any of the given tags:

```bash
# Generate a journal with only your fixed costs
hledger-forecast generate -f forecast.csv -o fixed.journal --tags=fixed

# Summarize only essential spending
hledger-forecast summarize -f forecast.csv --tags=essential

# Multiple tags use OR logic — matches any
hledger-forecast summarize -f forecast.csv --tags=fixed,living

# Can also exclude tags with a `-` prefix
hledger-forecast summarize -f forecast.csv --tags=fixed,-essential
```

**Querying in hledger** - because the tags are native hledger format, you can query them directly:

```bash
hledger bal tag:fixed -f forecast.journal
hledger bal tag:essential not:tag:living -f forecast.journal
```

### Settings

Settings rows live in the same CSV file. The defaults are:

```csv
settings,currency,USD,,,,,,,,
settings,show_symbol,true,,,,,,,,
settings,thousands_separator,true,,,,,,,,
```

Override any of them by adding a `settings` row. Multiple settings rows are fine — they won't clobber each other.

## :pencil2: Contributing

I'm open to pull requests that fix bugs. For new functionality, please open a discussion first so we can figure out whether it's the right direction before any code is written.
