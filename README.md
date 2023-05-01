# Hledger-Forecast

[![Tests](https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml/badge.svg)](https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml)

A wrapper which builds on [hledger's](https://github.com/simonmichael/hledger) [forecasting](https://hledger.org/dev/hledger.html#forecasting) capability. Uses a `YAML` config file to generate forecasts whilst adding functionality for future cost rises (e.g. inflation) and the automatic tracking of planned transactions.

See the [rationale](#brain-rationale) section for why this gem may be useful to you.

## :sparkles: Features

- :book: Uses simple YAML files to generate forecasts which can be used with hledger
- :date: Can smartly track forecasted transactions against actuals
- :moneybag: Can apply modifiers such as inflation/deflation to forecasts
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

The `hledger-forecast generate` command will begin the generation of your forecast _from_ a `yaml` file _to_ a hledger periodic transaction journal file.

The available options are:

    Usage: hledger-forecast generate [options]

      -f, --forecast FILE              The FORECAST yaml file to generate from
      -o, --output-file FILE           The OUTPUT file to create
      -t, --transaction FILE           The TRANSACTION file to search within if using tracking
          --force                      Force an overwrite of the output file
          --no-track                   Don't track any transactions
      -h, --help                       Show this help message

Simply running the command with no options will assume a `forecast.yml` file exists.

### Using with Hledger

To work with hledger, include the forecast file and use the `--forecast` flag:

    hledger -f transactions.journal -f forecast.journal bal assets -e 2024-02 --forecast

The command will generate a forecast up to the end of Feb 2024, showing the balance for any asset accounts, referencing the transactions and forecast journal files. Of course, refer to the [hledger](https://hledger.org/dev/hledger.html) documentation for more information on how to query your finances.

To apply any modifiers, use the `--auto` flag as well.

### Summarize command

As your `yaml` configuration file grows, it can be helpful to sum up the total amounts and output them to the CLI. This can be achieved by:

    hledger-forecast summarize -f my_forecast.yml

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

### Tracking transactions

> **Note**: Marking a transaction for tracking will ensure that it is only written into the forecast if it isn't found

Sometimes it can be useful to track and monitor forecasted transactions to ensure that they are accounted for in any financial projections. If they are present, then these should be discarded from your forecast as this will create a double count against your actuals. However, if they can't be found amongst your actuals then they should be carried forward into a future period to ensure accurate recording.

To mark transactions as available for tracking you may use the `track` option in your config file:

```yaml
once:
    account: "Assets:Bank"
    start: "2023-03-05"
    transactions:
      - amount: 3000
        category: "Expenses:Shopping"
        description: Refund for that damn laptop
        track: true
```

The app will use a hledger query to determine if the combination of category and amount is present in the period specified in the `start` key. If not, then the app will continue searching up to the latest period in the transactions file, including it as a forecast transaction in the output file.

### Applying modifiers

> **Note**: For modifiers to be included in your hledger reporting, use the `--auto` flag

Within your forecasts, it can be useful to reflect future increases/decreases in certain categories. For example, next year, I expect the cost of groceries to increase by 2%:

```yaml
monthly:
    account: "Assets:Bank"
    start: "2023-03-05"
    transactions:
      - amount: 450
        category: "Expenses:Groceries"
        description: Food shopping
        modifiers:
          - from: 2024-01-01
            to: 2024-12-13
            amount: 0.02
```

This will generate an [auto-posting](https://hledger.org/dev/hledger.html#auto-postings) in your forecast which will
uplift any transaction with an `Expenses:Groceries` category:

```
= Expenses:Groceries date:2024-01-01..2024-12-31
    (Expenses:Groceries)  *0.02
```

Of course you may wish to apply 2% for next year and another 3% for the year after:

```yaml
modifiers:
  - from: 2024-01-01
    to: 2024-12-13
    amount: 0.02
  - from: 2025-01-01
    to: 2025-12-13
    amount: 0.05
```


### Additional settings

Additional settings in the config file to consider:

```yaml
settings:
  currency: GBP                 # Specify the currency to use
  show_symbol: true             # Show the currency symbol?
  thousands_separator: true     # Separate thousands with a comma?
```

## :camera_flash: Screenshots

**Yaml config file and output**

<img src="https://user-images.githubusercontent.com/9512444/234382872-b81ac84d-2bcc-4488-a041-364f72627087.png" alt="Hledger-Forecast" />

**Summarize command**

<img src="https://user-images.githubusercontent.com/9512444/234386807-1301c8d9-af77-4f58-a3c3-a345b5e890a2.png" alt="Summarize command" />

## :paintbrush: Rationale

Firstly, I've come to realise from reading countless blog and Reddit posts on [plain text accounting](https://plaintextaccounting.org), that everyone does it __completely__ differently! There is _great_ support in hledger for [forecasting](https://hledger.org/1.29/hledger.html#forecasting) using periodic transactions. Infact, it's nearly perfect for my needs.

My only wishes were to be able to sum up monthly transactions much faster (so I can see my forecasted monthly I&E), apply future cost pressures more easily (such as inflation) and to be able to track and monitor specific transactions. Regarding the latter; I may be expecting a material amount of money to leave my account in May (perhaps for a holiday booking). But maybe, that booking ends up leaving in July instead. Whilst I would have accounted for that expense in my forecast, it will likely be for the period of May. So if that transaction doesn't appear in the "actuals" of my May bank statement (which I import into hledger), it won't be included in my forecast at all (as the latest transaction period will be greater than the forecast period). The impact is that my forecasted balance in any future month could be $X better off than reality.

Now I'll freely admit these are minor issues. So minor infact that they can probably be addressed by a dedicated 5 minutes every month. However I liked the idea of automating as much of my month end process as possible and saw this as an interesting challenge to try and solve.

Whilst I tried to work within the constraints of a `journal` file, moving to a structured `yaml` format made the implementation of these features much easier. I also wanted to stay as true as possible to how hledger recommends we forecast with periodic transactions.
