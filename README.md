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

**Before hledger**: As the complexity of my forecasts started to increase, so did the length of my journal file. When I undertook the monthly exercise of editing my forecast, it became more cumbersome to find specific amounts and descriptions.It also became a nuisance if I'd grouped certain items by date which needed to be changed.

With `hledger-forecast` forecasts can be constrained between dates, tracked until they appear in your bank statements and summarized into your own daily/weekly/monthly/yearly personal forecast income and expenditure statement.

## :sparkles: Features

- :rocket: Uses a simple CSV file to generate forecasts which can be used with hledger
- :calendar: Can smartly track forecasts against your bank statement
- :dollar: Can automatically apply modifiers such as inflation/deflation to forecasts
- :mag: Enables the use of maths in your forecasts (for amounts and dates)
- :bar_chart: Display your forecasts as income and expenditure reports (e.g. daily, weekly, monthly)
- :twisted_rightwards_arrows: Compare and display the difference between hledger outputs
- :computer: Simple and easy to use CLI

## :camera_flash: Screenshots

**A CSV forecast and the hledger journal it generates**

<img src="https://github.com/olimorris/hledger-forecast/assets/9512444/430503b5-f447-4972-b122-b48f8628aff9" alt="hledger-Forecast" />

**The ouput from the `summarize` command**

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
      generate    Generate a forecast from a file
      summarize   Summarize the forecast file and output to the terminal
      compare     Compare and highlight the differences between two CSV files

    Options:
        -h, --help                       Show this help message
        -v, --version                    Show version

### Generate command

The `hledger-forecast generate` command will generate a forecast _from_ a `CSV` file _to_ a journal file. You can see the output of this command in the [example.journal](https://github.com/olimorris/hledger-forecast/blob/main/example.journal) file.

The available options are:

    Usage: hledger-forecast generate [options]

      -f, --forecast FILE              The path to the FORECAST CSV file to generate from
      -o, --output-file FILE           The path to the OUTPUT file to create
      -t, --transaction FILE           The path to the TRANSACTION journal file
      -v, --verbose                    Don't group transactions by type in the output file
          --force                      Force an overwrite of the output file
          --no-track                   Don't track any transactions
      -h, --help                       Show this help message

> **Note**: For the tracking of transactions you need to include the `-t` flag

Running the command with no options will assume a `forecast.csv` file exists.

### Using with hledger

To work with hledger, include the forecast file and use the `--forecast` flag:

    hledger -f bank_transactions.journal -f forecast.journal --forecast bal assets -e 2024-02

The command will generate a forecast up to the end of Feb 2024, showing the balance for any asset accounts, overlaying some bank transactions with the forecast journal file. Forecasting in hledger can be complicated so be sure to refer to the [documentation](https://hledger.org/dev/hledger.html) or start a [discussion](https://github.com/olimorris/hledger-forecast/discussions/new?category=q-a).

If you use the `hledger-ui` tool, it may be helpful to use the `--verbose` flag. This ensures that transactions are not grouped together in the forecast journal file, making descriptions much easier to read.

### Summarize command

As your forecast file grows, it can be helpful to sum up the total amounts and output them to the CLI. Think of this command as your own _profit and loss_ summarizer, generating a statement over a period you specify.

    hledger-forecast summarize -f my_forecast.csv

The available options are:

    Usage: hledger-forecast summarize [options]

    -f, --forecast FILE              The path to the FORECAST CSV file to summarize
    -r, --roll-up PERIOD             The period to roll-up your forecasts into. One of:
                                     [yearly], [half-yearly], [quarterly], [monthly], [weekly], [daily]
    -v, --verbose                    Show additional information in the summary
    -h, --help                       Show this help message

### Compare command

A core part of managing your personal finances is the comparison of what you _expected_ to happen versus what _actually_ happened. This can be challenging to accomplish with hledger so to make this easier, the app has a useful `compare` command:

    hledger-forecast compare [path/to/file1.csv] [path/to/file2.csv]

To generate CSV output with hledger, append `-O csv > output.csv` to your desired command.

To make it easier to read horizontal output in the terminal, consider the use of a terminal pager like [most](https://en.wikipedia.org/wiki/Most_(Unix)) by appending `| most` to the compare command.

> **Note:** The two CSV files being compared must have the same structure

## :gear: Creating your forecast

The app makes it easy to generate a comprehensive _journal_ file with very few lines of code, making it much easier to stay on top of your forecasting from month to month.

### Columns

The _CSV_ file _should_ contain a header row with the following columns:

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

### Example forecast

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
custom,every 5 weeks,Assets:Bank,01/03/2023,,Misc expenses,Expenses:General Expenses,30,10.4,,
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

### Tracking

> **Note**: Marking a transaction for tracking will ensure that it is only written into the forecast if it isn't found within a specified transaction file

Sometimes it can be useful to track and monitor forecasted transactions to ensure that they are accounted for in any financial projections. If they are present, then these should be discarded from your forecast as this will create a double count against your actuals. However, if they can't be found then they should be carried forward into a future period to ensure accurate recording.

To mark transactions as available for tracking you may use the `track` option in your config file:

```csv
type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
once,,Assets:Bank,2023-03-05,,Refund for that damn laptop,Expenses:Shopping,-3000,,,TRUE
```

> **Note**: This feature has been designed to work with `once` transaction types only

To use this feature, ensure you pass a filepath to the `-t` flag, such as:

    hledger-forecast generate -t [journal_file_to_search] -f [path_to_yaml_file] -o [path_to_output_journal]

The app will use a hledger query to determine if the combination of category and amount is present in the periods between the `from` key and the current date in the journal file you've specified. If not, then the app will include it as a forecast transaction in the output file.

## :pencil2: Contributing

I am open to any pull requests that fix bugs but would ask that any new functionality is discussed before it could be accepted.
