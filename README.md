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

Forecasting in hledger is essential to how I plan and budget. As my forecast grew in complexity, so did my journal file. The monthly ritual of hunting down specific amounts and tweaking dates became a pain in the proverbial. `hledger-forecast` helps to remedy that! One clean CSV file that can handle Excel-like formulae and a summarizer to give you an I&E-like statement.

## :sparkles: Features

- :rocket: Simple CSV file drives the whole forecast
- :mag: Supports maths in your amounts _and_ dates
- :bar_chart: Summarize forecasts as daily/weekly/monthly/yearly income and expenditure reports
- :twisted_rightwards_arrows: Compare and highlight the difference between two hledger CSV outputs
- :computer: Straightforward CLI

## :camera_flash: Screenshots

**A CSV forecast and the hledger journal it generates**

<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/430503b5-f447-4972-b122-b48f8628aff9" alt="hledger-Forecast" />

**The output from the `summarize` command**

<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/f5017ea2-9606-46ec-8b38-8840dc175e7b" alt="Summarize command" />

## :package: Installation

Assuming you have Ruby and [Rubygems](http://rubygems.org/pages/download) installed:

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

As your forecast grows, it's useful to see the totals at a glance. Think of this as your personal profit and loss statement — rolled up to whatever period makes sense.

    hledger-forecast summarize -f my_forecast.csv

    Usage: hledger-forecast summarize [options]

      -f, --forecast FILE              The path to the FORECAST CSV file to summarize
      -r, --roll-up PERIOD             The period to roll-up your forecasts into. One of:
                                       [yearly], [half-yearly], [quarterly], [monthly], [weekly], [daily]
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
| `to` | date | no | End date, e.g. `01/01/2025` |
| `description` | string | yes | A description of the transaction |
| `category` | string | yes | The category account, e.g. `Expenses:Food` |
| `amount` | number | yes | The transaction amount. Supports `=` prefix for calculated values |
| `roll-up` | number | no | Multiplier for the summarizer — use this for `custom` types to annualise them |
| `summary_exclude` | boolean | no | Set to `TRUE` to exclude from the summarizer |

### Example

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude
monthly,,Assets:Bank,01/03/2023,,Salary,Income:Salary,-3500,,
monthly,,Assets:Bank,01/03/2023,01/01/2025,Mortgage,Expenses:Mortgage,2000,,
monthly,,Assets:Bank,01/03/2023,,Bills,Expenses:Bills,175,,
monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,500,,
monthly,,Assets:Bank,01/03/2023,,New Kitchen,Expenses:House,=5000/24,,
monthly,,Assets:Bank,01/03/2023,=12,Holiday,Expenses:Holiday,125,,
monthly,,Assets:Bank,01/03/2023,01/03/2025,Rainy day fund,Assets:Savings,300,,
monthly,,Assets:Pension,01/01/2024,,Pension draw down,Income:Pension,-500,,
quarterly,,Assets:Bank,01/04/2023,,Quarterly bonus,Income:Bonus,-1000,,
half-yearly,,Assets:Bank,01/04/2023,,Top up holiday funds,Expenses:Holiday,500,,
yearly,,Assets:Bank,01/04/2023,,Annual bonus,Income:Bonus,-2000,,
once,,Assets:Bank,05/03/2023,,Refund for that damn laptop,Expenses:Shopping,-3000,TRUE,
custom,every 2 weeks,Assets:Bank,01/03/2023,,Hair and beauty,Expenses:Personal Care,80,26,
custom,every 5 weeks,Assets:Bank,01/03/2023,,Misc expenses,Expenses:General Expenses,30,10.4,
settings,currency,USD,,,,,,,,
```

### Calculated amounts

Prefix any `amount` with `=` and write it as a standard formula — the app will evaluate it for you. Great for spreading a lump sum across months:

```csv
monthly,,Assets:Bank,01/03/2023,,New Kitchen,Expenses:House,=5000/24,,
```

> Calculations are evaluated to two decimal places.

### Calculated dates

The `to` column also supports calculated values. Use `=` followed by a number to mean "N months from the `from` date":

```csv
monthly,,Assets:Bank,01/03/2023,=12,Holiday,Expenses:Holiday,125,,
```

That sets the end date to 12 months after `01/03/2023`.

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
