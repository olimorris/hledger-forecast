# Hledger-Forecast

[![Tests](https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml/badge.svg)](https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml)

<p align="center">
<img src="https://user-images.githubusercontent.com/9512444/234382872-b81ac84d-2bcc-4488-a041-364f72627087.png" alt="Hledger-Forecast" />
</p>

A wrapper which builds on [Hledger's](https://github.com/simonmichael/hledger) [forecasting](https://hledger.org/dev/hledger.html#forecasting) capability. Uses a `YAML` config file to generate periodic transactions whilst allowing for future inflation and the smart tracking of future transactions.

See the [rationale](#brain-rationale) section for why this gem may be useful to you.

## :sparkles: Features

- :book: Uses simple YAML files to generate periodic transactions which are used for forecasting in Hledger
- :date: Can smartly track forecasted transactions against actuals
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

The `hledger-forecast generate` command will begin the generation of your forecast _from_ a `yaml` file _to_ a Hledger periodic transaction journal file.

The available options are:

    Usage: hledger-forecast generate [options]

      -f, --forecast FILE              The FORECAST yaml file to generate from
      -o, --output-file FILE           The OUTPUT file to create
          --force                      Force an overwrite of the output file
      -h, --help                       Show this help message

Simply running the command with no options will assume a `forecast.yml` file exists.

#### Using with Hledger

To work with Hledger, include the forecast file and use the `--forecast` flag. An example:

    hledger -f transactions.journal -f forecast.journal bal assets -e 2024-02 --forecast

The command will generate a forecast up to the end of Feb 2024, showing the balance for any asset accounts, referencing the transactions and forecast journal files.

### Summarize command

As your config file grows, it can be helpful to sum up the total amounts and output them in the CLI. This can be achieved by:

    hledger-forecast summarize -f my_forecast.yml

where `my_forecast.yml` is the config file to sum up.

The available options are:

    Usage: hledger-forecast summarize [options]

        -f, --forecast FILE              The FORECAST yaml file to summarize
        -h, --help                       Show this help message

## :gear: Configuration

### The YAML file

> **Note**: See the [example.yml](https://github.com/olimorris/hledger-forecast/blob/main/example.yml) file for an example of a complex config file

Firstly, create a `yaml` file which will contain the transactions you'd like to forecast:

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
- Notice we're also using [virtual postings](https://hledger.org/1.29/hledger.html#virtual-postings) (designated by the brackets). This makes it easy to filter them out with the `-R` or `--real` option in Hledger
- We also have not specified a currency; the default (`USD`) will be used

### Periods

Besides monthly recurring transactions, the app also supports the following periods:

- `quarterly` - For transactions every _3 months_ from the given start date
- `half-yearly` - For transactions every _6 months_ from the given start date
- `yearly` - Generate transactions _once a year_ from the given start date
- `once` - Generate _one-time_ transactions on a specified date
- `custom` - Generate transactions every _n days/weeks/months_

These will output periodic transactions such as `~ every 3 months` or `~ every year`.

#### Custom period

A custom period allows you to specify a custom periodic rule as per Hledger's [periodic rule syntax](https://hledger.org/dev/hledger.html#periodic-transactions):

```yaml
custom:
  - frequency: "every 2 weeks"
    account: "[Assets:Bank]"
    start: "2023-03-01"
    transactions:
      - amount: 80
        category: "[Expenses:Personal Care]"
        description: Hair and beauty
```

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

In the example below, only the single transaction will be constrained by the end date:

```yaml
monthly:
  - account: "[Assets:Bank]"
    start: "2023-03-01"
    transactions:
      - amount: 2000
        category: "[Expenses:Mortgage]"
        description: Mortgage
        end: "2025-01-01"
```

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
