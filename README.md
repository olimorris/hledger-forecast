# Hledger-Forecast

[![Tests](https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml/badge.svg)](https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml)

> **Warning**: This is still in the early stages of development and the API is likely to change

Uses a YAML file to generate monthly, quarterly, yearly and one-off transactions for better forecasting in [Hledger](https://github.com/simonmichael/hledger).

See the [rationale](#brain-rationale) section for why this gem may be useful to you.

## :sparkles: Features

- :book: Uses a simple YAML config file to generate periodic transactions
- :date: Specify start and end dates for forecasts
- :heavy_dollar_sign: Full currency support (uses the [RubyMoney](https://github.com/RubyMoney/money) gem)
- :computer: Simple and easy to use CLI

## :package: Installation

Assuming you have Ruby and [Rubygems](http://rubygems.org/pages/download) installed on your system, simply run:

    gem install --user hledger-forecast

## :rocket: Usage

Simply run:

    hledger-forecast

Running `hledger-forecast -h` shows the available options:

    Usage: Hledger-Forecast [options]

        -f, --forecast FILE              The FORECAST yaml file to generate from
        -t, --transaction FILE           The base TRANSACTIONS file to extend from
        -o, --output-file FILE           The OUTPUT file to create
        -s, --start-date DATE            The date to start generating from (yyyy-mm-dd)
        -e, --end-date DATE              The date to start generating to (yyyy-mm-dd)
        -h, --help                       Show this message
            --version                    Show version

To then include in Hledger:

    hledger -f transactions.journal -f forecast.journal

where `transactions.journal` might be your bank transactions (your "actuals") and `forecast.journal` is the file generated with the `-o` option from above (your "forecast").

### A simple config file

> **Note**: An example can be found in the `example.yml` file

Firstly, create a `yml` file which will contain the transactions you'd like to forecast:

```yaml
# forecast.yml
monthly:
  - account: "[Assets:Bank]"
    start: "2023-03-01"
    transactions:
      - amount: 2000
        category: "[Expenses:Mortgage]"
        description: Mortgage
      - amount: 500
        category: "[Expenses:Food]"
        description: Food
```

Let's examine what's going on in this config file:

- Firstly, we're telling the app to create two monthly transactions and repeat them, forever, starting from March 2023. In this case, forever will be the `end_date` specified when running the app
- If you ran the app with `hledger-forecast -s 2023-04-01` then no transactions would be generated for March as the start date is greater than the periodic start date
- Notice we're also using [virtual postings](https://hledger.org/1.29/hledger.html#virtual-postings) (designated by the brackets) to be explicit to Hledger. This also makes it easy to filter them out with the `-R` or `--real` option in Hledger
- We also have not specified a currency; the default (`USD`) will be used

### Extending the config file

#### Periods

If you'd like to add quarterly, yearly or one-off transactions, use the following keys:

- `quarterly`
- `yearly`
- `once`

The structure of the config file remains exactly the same.

> **Note**: A quarterly transaction will repeat for every 3 months from the start date

#### Currency

To specify a currency:

```yaml
# forecast.yml
settings:
  currency: GBP
```

#### Additional settings

Additional settings in the config file:

```yaml
# forecast.yml
settings:
  show_symbol: true             # Show the currency symbol?
  sign_before_symbol: true      # Show the negative sign before the symbol?
  thousands_separator: true     # Separate thousands with a comma?
```

## :brain: Rationale

Firstly, I've come to realise from reading countless blog and Reddit posts on [plain text accounting](https://plaintextaccounting.org), that everyone does it __completely__ differently!

My days working in financial modelling have meant that a big macro-enabled spreadsheet was my go-to tool. Growing tired with the manual approach of importing transactions, heavily manipulating them, watching Excel become increasingly slower lead me to PTA. It's been a wonderful discovery.

One of the aspects of my previous approach to personal finance that I liked was the monthly recap of my performance and the looking ahead to the future. Am I still on track to hit my year-end savings goal? Am I still on track to hit my savings goal for 12, 24 months time? It was at this point in my shift to PTA that I hit a wall.

While Hledger provides support for [forecasting](https://hledger.org/1.29/hledger.html#forecasting) using periodic transactions, these are computed virtually at runtime. If I notice a big difference in my forecasted year-end balance compared to what I'm expecting, I want to investigate and start reconcilling. Computed transactions make this difficult and tiresome.

With this gem, my aim was to make it easy for users to change a config file, re-run a CLI command and be able to open a text file and see the changes. No guesswork. No surprises.
