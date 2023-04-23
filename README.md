# Hledger-Forecast

[![Tests](https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml/badge.svg)](https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml)

Uses a YAML file to generate periodic transactions for better forecasting in [Hledger](https://github.com/simonmichael/hledger).

See the [rationale](#brain-rationale) section for why this gem may be useful to you.

## :sparkles: Features

- :book: Uses simple YAML files to generate forecasts from periodic transactions
- :date: Generate forecasts between specified start and end dates
- :heavy_dollar_sign: Full currency support (uses the [RubyMoney](https://github.com/RubyMoney/money) gem)
- :computer: Simple and easy to use CLI
- :chart_with_upwards_trend: Summarize your forecasts by period and category and output to the CLI

## :package: Installation

Assuming you have Ruby and [Rubygems](http://rubygems.org/pages/download) installed on your system, simply run:

    gem install --user hledger-forecast

## :rocket: Usage

Run:

    hledger-forecast

The available options are:

    Usage: hledger-forecast [command] [options]

    Commands:
      generate    Generate the forecast file
      summarize   Summarize the forecast file and output to the terminal

    Options:
        -h, --help                       Show this help message
        -v, --version                    Show version

### Generate command

The `hledger-forecast generate` command will begin the generation of your forecast from a `yaml` file.

The available options are:

    Usage: hledger-forecast generate [options]

      -t, --transaction FILE           The base TRANSACTIONS file to extend from
      -f, --forecast FILE              The FORECAST yaml file to generate from
      -o, --output-file FILE           The OUTPUT file to create
      -s, --start-date DATE            The date to start generating from (yyyy-mm-dd)
      -e, --end-date DATE              The date to start generating to (yyyy-mm-dd)
          --force                      Force an overwrite of the output file
      -h, --help                       Show this help message

Simply running the command with no options will assume a `forecast.yml` file exists

Another example of a common command:

    hledger-forecast generate -f my_forecast.yml -s 2023-05-01 -e 2024-12-31

This will generate an output file (`my_forecast.journal`) from the forecast file between the two date ranges.

### Summarize command

As your config file grows, it can be helpful to sum up the total amounts and output them in the CLI. This can be achieved by:

    hledger-forecast summarize -f my_forecast.yml

where `my_forecast.yml` is the config file to sum up.

The available options are:

    Usage: hledger-forecast summarize [options]

        -f, --forecast FILE              The FORECAST yaml file to summarize
        -h, --help                       Show this help message

### Using with Hledger

To use the outputs in Hledger:

    hledger -f transactions.journal -f my_forecast.journal

where:

- `transactions.journal` might be your bank transactions (your "_actuals_")
- `my_forecast.journal` is the generated forecast file

## :gear: Configuration

### The YAML file

> **Note**: See the [example.yml](https://github.com/olimorris/hledger-forecast/blob/main/example.yml) file for an example of a complex config file

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

settings:
  currency: GBP
```

Let's examine what's going on in this config file:

- Firstly, we're telling the app to create two monthly transactions and repeat them, forever, starting from March 2023. In this case, forever will be the `end_date` specified when running the app
- If you ran the app with `hledger-forecast -s 2023-04-01` then no transactions would be generated for March as the start date is greater than the periodic start date
- Notice we're also using [virtual postings](https://hledger.org/1.29/hledger.html#virtual-postings) (designated by the brackets). This makes it easy to filter them out with the `-R` or `--real` option in Hledger
- We also have not specified a currency; the default (`USD`) will be used

### Periods

Besides monthly recurring transactions, the app also supports the following periods:

- `quarterly` - For transactions every _3 months_ from the given start date
- `half-yearly` - For transactions every _6 months_ from the given start date
- `yearly` - Generate transactions _once a year_ from the given start date
- `once` - Generate _one-time_ transactions on a specified date
- `custom` - Generate transactions every _n days/weeks/months_

#### Custom period

A custom period allows you to specify a given number of days, weeks or months for a transaction to repeat within. These can be included in the config file as follows:

```yaml
custom:
  - description: Fortnightly hair and beauty spend
    recurrence:
      period: weeks
      quantity: 2
    account: "[Assets:Bank]"
    start: "2023-03-01"
    transactions:
      - amount: 80
        category: "[Expenses:Personal Care]"
        description: Hair and beauty
```

Where `quantity` is an integer and `period` is one of:

- days
- weeks
- months

### Dates

The core of any solid forecast is predicting the correct periods that costs will fall into. When running the app from the CLI, you can specify specific dates to generate transactions over (see the [usage](#rocket-usage) section).

You can further control the dates at a period/top-level as well as at a transaction level:

#### Top level

In the example below, all transactions in the `monthly` block will be constrained by the end date:

```yaml
monthly:
  - account: "[Assets:Bank]"
    start: "2023-03-01"
    end: "2025-01-01"
    transactions:
      # details omitted for brevity
```

#### Transaction level

In the example below, only the single transaction will be constrained by the end date and controlled via an additional start date:

```yaml
monthly:
  - account: "[Assets:Bank]"
    start: "2023-03-01"
    transactions:
      - amount: 2000
        category: "[Expenses:Mortgage]"
        description: Mortgage
        start: "2023-05-01"
        end: "2025-01-01"
```

The addition of the `start` key means that while the block will start on 2023-03-01, the transaction for the mortgage won't start until `2023-05-01`.

### Additional settings

Additional settings in the config file to consider:

```yaml
settings:
  currency: GBP                 # Specify the currency to use
  show_symbol: true             # Show the currency symbol?
  sign_before_symbol: true      # Show the negative sign before the symbol?
  thousands_separator: true     # Separate thousands with a comma?
```

## :brain: Rationale

Firstly, I've come to realise from reading countless blog and Reddit posts on [plain text accounting](https://plaintextaccounting.org), that everyone does it __completely__ differently!

There is _great_ support in Hledger for [forecasting](https://hledger.org/1.29/hledger.html#forecasting) using periodic transactions.

With this gem, my aim was to make it easy for users to change their config file, regenerate the forecast and open a journal file and see the transactions. Or, use multiple forecast files for different scenarios and pass them in turn to Hledger to observe the impact.
