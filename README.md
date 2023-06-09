<p align="center">
<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/5edb77e3-0ec6-4158-9b16-3978c1259879" alt="hledger-forecast" />
</p>

<h1 align="center">hledger-forecast</h1>

<p align="center">
<a href="https://github.com/olimorris/hledger-forecast/stargazers"><img src="https://img.shields.io/github/stars/olimorris/hledger-forecast?color=c678dd&logoColor=e06c75&style=for-the-badge"></a>
<a href="https://github.com/olimorris/hledger-forecast/issues"><img src="https://img.shields.io/github/issues/olimorris/hledger-forecast?color=%23d19a66&style=for-the-badge"></a>
<a href="https://github.com/olimorris/hledger-forecast/blob/main/LICENSE"><img src="https://img.shields.io/github/license/olimorris/hledger-forecast?color=%2361afef&style=for-the-badge"></a>
<a href="https://github.com/olimorris/hledger-forecast/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/olimorris/hledger-forecast/ci.yml?branch=main&label=tests&style=for-the-badge"></a>
</p>

**"Improved", you say?** Using a _csv_ (or _yml_) file, forecasts can be quickly generated into a _journal_ file ready to be fed into [hledger](https://github.com/simonmichael/hledger). Forecasts can be easily constrained between dates, inflated by modifiers, tracked until they appear in your bank statements and summarized into your own daily/weekly/monthly/yearly personal forecast income and expenditure statement.

## :sparkles: Features

- :muscle: Uses a simple csv (or yml) file to generate forecasts which can be used with hledger
- :date: Can smartly track forecasts against your bank statement
- :moneybag: Can automatically apply modifiers such as inflation/deflation to forecasts
- :abacus: Enables the use of maths in your forecasts (for amounts and dates)
- :chart_with_upwards_trend: Display your forecasts as income and expenditure reports (e.g. daily, weekly, monthly)
- :computer: Simple and easy to use CLI

## :camera_flash: Screenshots

**Config file and journal output**

<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/c3c3222e-f797-4643-bebd-9c94134bee92" alt="Hledger-Forecast" />

**Output from the `summarize` command**

<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/f5017ea2-9606-46ec-8b38-8840dc175e7b" alt="Summarize command" />


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

The `hledger-forecast generate` command will generate a forecast _from_ a `csv` or `yml` file _to_ a journal file. You can see the output of this command in the [example.journal](https://github.com/olimorris/hledger-forecast/blob/main/example.journal) file.

The available options are:

    Usage: hledger-forecast generate [options]

      -f, --forecast FILE              The path to the FORECAST csv/yml file to generate from
      -o, --output-file FILE           The path to the OUTPUT file to create
      -t, --transaction FILE           The path to the TRANSACTION journal file
          --force                      Force an overwrite of the output file
          --no-track                   Don't track any transactions
      -h, --help                       Show this help message

> **Note**: For the tracking of transactions you need to include the `-t` flag

Running the command with no options will assume a `forecast.yml` file exists.

### Using with hledger

To work with hledger, include the forecast file and use the `--forecast` flag:

    hledger -f bank_transactions.journal -f forecast.journal --forecast bal assets -e 2024-02

The command will generate a forecast up to the end of Feb 2024, showing the balance for any asset accounts, overlaying some bank transactions with the forecast journal file. Forecasting in hledger can be complicated so be sure to refer to the [documentation](https://hledger.org/dev/hledger.html) or start a [discussion](https://github.com/olimorris/hledger-forecast/discussions/new?category=q-a).

### Summarize command

As your configuration file grows, it can be helpful to sum up the total amounts and output them to the CLI.
Furthermore, being able to see your monthly profit and loss statement _if_ you were to purchase that new item may
influence your buying decision. In hledger-forecast, this can be achieved by:

    hledger-forecast summarize -f my_forecast.csv

The available options are:

    Usage: hledger-forecast summarize [options]

    -f, --forecast FILE              The path to the FORECAST csv/yml file to summarize
    -r, --roll-up PERIOD             The period to roll-up your forecasts into. One of:
                                     [yearly], [half-yearly], [quarterly], [monthly], [weekly], [daily]
    -v, --verbose                    Show additional information in the summary
    -h, --help                       Show this help message

## :gear: Creating your forecast

This app makes it easy to generate a comprehensive _journal_ file with very few lines of code. In the [example](https://github.com/olimorris/hledger-forecast/blob/main/example.csv) file in the repository, a 14 line CSV file generates a 43 line forecast file. This makes it much easier to stay on top of your forecasting from month to month.

### Columns

The `csv` file _should_ contain a header row with the following columns:

- `type` - (string) - The type of forecast entry. One of `monthly`, `quarterly`, `half-yearly`, `yearly`, `once` or `custom`
- `frequency` - (string) - The frequency that the type repeats with (only if `custom`). As per hledger's [periodic rule syntax](https://hledger.org/dev/hledger.html#periodic-transactions)
- `account` - (string) - The account the transaction applies to e.g. _Expenses:Food_
- `from` - (date) - The date the transaction should start from e.g. _2023-06-01_
- `to` - (date) _(optional)_ - The date the transaction should end on e.g. _2023-12-31_
- `description` - (string) - A description of the transaction
- `category` - (string) - The classification or category of the transaction
- `amount` - (integer/float) - The amount of the transaction
- `roll-up` - (integer/float) _(optional)_ - For use with the summarizer, the value you need to multiply the amount by to get it into a yearly amount
- `summary_exclude` - (boolean) _(optional)_ - Exclude the transaction from the summarizer?
- `track` - (boolean) _(optional)_ - Track the transaction against your confirmed transactions?

### An example CSV forecast

Putting it together, we end up with a CSV file like:

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
monthly,,Assets:Bank,01/03/2023,,Salary,Income:Salary,-3500,,,
monthly,,Assets:Bank,01/03/2023,01/01/2025,Mortgage,Expenses:Mortgage,2000,,,
monthly,,Assets:Bank,01/03/2023,,Bills,Expenses:Bills,175,,,
monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,500,,,
monthly,,Assets:Bank,01/03/2023,,New Kitchen,Expenses:House,=5000/24,,,
monthly,,Assets:Bank,01/03/2023,=12,Holiday,Expenses:Holiday,125,,,
monthly,,Assets:Bank,01/03/2023,01/03/2025,Rainy day fund,Assets:Savings,300,,,
monthly,,Assets:Pension,01/01/2024,,Pension draw down,Income:Pension,-500,,,
quarterly,,Assets:Bank,01/04/2023,,Quarterly bonus,Income:Bonus,-1000,,,
half-yearly,,Assets:Bank,01/04/2023,,Top up holiday funds,Expenses:Holiday,500,,,
yearly,,Assets:Bank,01/04/2023,,Annual bonus,Income:Bonus,-2000,,,
once,,Assets:Bank,05/03/2023,,Refund for that damn laptop,Expenses:Shopping,-3000,,TRUE,TRUE
custom,every 2 weeks,Assets:Bank,01/03/2023,,Hair and beauty,Expenses:Personal Care,80,26,,
settings,currency,USD,,,,,,,,
```

### Additional features

From the example above, there are a few additional features that may be useful.

#### Calculated amounts

> **Note**: Calculations will be determined up to two decimal places

It may be helpful to let the app calculate the forecasted amount in your transactions on your behalf. This can be especially useful if you're spreading a payment out over a number of months:

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
monthly,,Assets:Bank,01/03/2023,,New Kitchen,Expenses:House,=5000/24,,,
```

Simply start the `amount` column with a `=` sign and use standard Excel based math formatting.

#### Calculated dates

It may also be helpful for `to` dates to be calculated:

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
monthly,,Assets:Bank,01/03/2023,=12,Holiday,Expenses:Holiday,125,,,
```

### Settings

There are also additional settings that can be applied in the forecast. The defaults are:

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
settings,currency,USD,,,,,,,,
settings,show_symbol,true,,,,,,,,
settings,thousands_separator,true,,,,,,,,
```

### An example yml forecast

Taking the example above and applying it to a yml file:

```yml
monthly:
  - account: "Assets:Bank"
    from: "2023-03-01"
    transactions:
      - amount: -3500
        category: "Income:Salary"
        description: Salary
      - amount: 2000
        category: "Expenses:Mortgage"
        description: Mortgage
        to: "2025-01-01"
      - amount: 175
        category: "Expenses:Bills"
        description: Bills
      - amount: 500
        category: "Expenses:Food"
        description: Food
      - amount: "=5000/24"
        category: "Expenses:House"
        description: New Kitchen
      - amount: 125
        category: "Expenses:Holiday"
        description: Holiday
        to: "=12"
  - account: "Assets:Bank"
    from: "2023-03-01"
    to: "2025-01-01"
    transactions:
      - amount: 300
        category: "Assets:Savings"
        description: "Rainy day fund"
  - account: "Assets:Pension"
    from: "2024-01-01"
    transactions:
      - amount: -500
        category: "Income:Pension"
        description: Pension draw down

quarterly:
  - account: "Assets:Bank"
    from: "2023-04-01"
    transactions:
      - amount: -1000.00
        category: "Income:Bonus"
        description: Quarterly bonus

half-yearly:
  - account: "Assets:Bank"
    from: "2023-04-01"
    transactions:
      - amount: 500
        category: "Expenses:Holiday"
        description: Top up holiday funds

yearly:
  - account: "Assets:Bank"
    from: "2023-04-01"
    transactions:
      - amount: -2000.00
        category: "Income:Bonus"
        description: Annual Bonus

once:
  - account: "Assets:Bank"
    from: "2023-03-05"
    transactions:
      - amount: -3000
        category: "Expenses:Shopping"
        description: Refund for that damn laptop
        summary_exclude: true
        track: true

custom:
  - frequency: "every 2 weeks"
    account: "Assets:Bank"
    from: "2023-03-01"
    roll-up: 26
    transactions:
      - amount: 80
        category: "Expenses:Personal Care"
        description: Hair and beauty

settings:
  currency: USD
```

#### Modifiers

> **Note**: For modifiers to be included in your hledger reporting, use the `--auto` flag

Currently, a yml forecast allows a user to include forecasted % uplifts or downshifts:

```yml
monthly:
  - account: "Assets:Bank"
    from: "2023-03-01"
    transactions:
      - amount: 500
        category: "Expenses:Food"
        description: Food
        modifiers:
          - amount: 0.02
            description: "Inflation"
            from: "2024-01-01"
            to: "2024-12-31"
          - amount: 0.05
            description: "Inflation"
            from: "2025-01-01"
            to: "2025-12-31"
```

This will generate an [auto-posting](https://hledger.org/dev/hledger.html#auto-postings) in your forecast which will uplift any transaction with an `Expenses:Food` category. In the first year the uplift with be 2% and in the following year, 5%.

#### Additional yml features

Dates in a yml file can be constrained by the `to` date in two ways:

```yml
monthly:
  - account: "Assets:Bank"
    from: "2023-03-01"
    to: "2025-01-01"
    transactions:
      # details omitted for brevity
```

or:

```yml
monthly:
  - account: "Assets:Bank"
    from: "2023-03-01"
    transactions:
      - amount: 2000
        category: "Expenses:Mortgage"
        description: Mortgage
        to: "2025-01-01"
```

### Tracking

> **Note**: Marking a transaction for tracking will ensure that it is only written into the forecast if it isn't found within a specified transaction file

Sometimes it can be useful to track and monitor forecasted transactions to ensure that they are accounted for in any financial projections. If they are present, then these should be discarded from your forecast as this will create a double count against your actuals. However, if they can't be found then they should be carried forward into a future period to ensure accurate recording.

To mark transactions as available for tracking you may use the `track` option in your config file:

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
once,,Assets:Bank,2023-03-05,,Refund for that damn laptop,Expenses:Shopping,-3000,,,TRUE
```

Or:

```yml
once:
  - account: "Assets:Bank"
    from: "2023-03-05"
    transactions:
      - amount: -3000
        category: "Expenses:Shopping"
        description: Refund for that damn laptop
        track: true
```

> **Note**: This feature has been designed to work with `once` transaction types only

To use this feature, ensure you pass a filepath to the `-t` flag, such as:

    hledger-forecast generate -t [journal_file_to_search] -f [path_to_yaml_file] -o [path_to_output_journal]

The app will use a hledger query to determine if the combination of category and amount is present in the periods between the `from` key and the current date in the journal file you've specified. If not, then the app will include it as a forecast transaction in the output file.

## :pencil2: Contributing

I am open to any pull requests that fix bugs but would ask that any new functionality is discussed before it could be accepted.

