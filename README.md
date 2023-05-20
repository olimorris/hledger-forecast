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

**"Improved", you say?** Using a _yaml_ file, forecasts can be quickly generated into a _journal_ file ready to be fed into [hledger](https://github.com/simonmichael/hledger). Forecasts can be easily constrained between dates, inflated by modifiers, tracked until they appear in your bank statements and summarized into your own daily(/weekly/monthly etc) personal forecast income and expenditure statement.

I **strongly** recommend you read the [rationale](#rainbow-rationale) section to see if this app might be useful to you.

## :sparkles: Features

- :book: Uses a simple yaml file to generate forecasts which can be used with hledger
- :date: Can smartly track forecasts against your bank statement
- :moneybag: Can automatically apply modifiers such as inflation/deflation to forecasts
- :abacus: Enables the use of maths in your forecasts (for amounts and dates)
- :chart_with_upwards_trend: Display your forecasts as income and expenditure reports (e.g. daily, weekly, monthly)
- :computer: Simple and easy to use CLI

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

The `hledger-forecast generate` command will generate a forecast _from_ a `yaml` file _to_ a journal file. You can see the output of this command in the [example.journal](https://github.com/olimorris/hledger-forecast/blob/main/example.journal) file.

The available options are:

    Usage: hledger-forecast generate [options]

      -f, --forecast FILE              The path to the FORECAST yaml file to generate from
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

The command will generate a forecast up to the end of Feb 2024, showing the balance for any asset accounts, overlaying some bank transactions with the forecast journal file. Of course, refer to the [hledger](https://hledger.org/dev/hledger.html) documentation for more information on how to query your finances.

> **Note**: To apply any modifiers, use the `--auto` flag at the end of your command.

### Summarize command

As your `yaml` configuration file grows, it can be helpful to sum up the total amounts and output them to the CLI.
Furthermore, being able to see your monthly profit and loss statement _if_ you were to purchase that new item may
influence your buying decision. In hledger-forecast, this can be achieved by:

    hledger-forecast summarize -f my_forecast.yml

The available options are:

    Usage: hledger-forecast summarize [options]

    -f, --forecast FILE              The path to the FORECAST yaml file to summarize
    -r, --roll-up PERIOD             The period to roll-up your forecasts into. One of:
                                     [yearly], [half-yearly], [quarterly], [monthly], [weekly], [daily]
    -h, --help                       Show this help message

## :gear: Configuration

### The yaml file

> **Note**: See the [example.yml](https://github.com/olimorris/hledger-forecast/blob/main/example.yml) file for an example config and its corresponding [output](https://github.com/olimorris/hledger-forecast/blob/main/example.journal)

Firstly, create a `yaml` file which will contain the transactions you'd like to forecast:

```yaml
# forecast.yml
monthly:
  - account: "Assets:Bank"
    from: "2023-03-01"
    transactions:
      - amount: 2000
        category: "Expenses:Mortgage"
        description: Mortgage
      - amount: 500
        category: "Expenses:Food"
        description: Food

settings:
  currency: GBP
```

Let's examine what's going on in this config file:

- We're telling the app to create two monthly transactions and repeat them, forever, starting from March 2023
- We're telling the app to link them both to the `Assets:Bank` account
- We've added descriptions to make it easy to follow in our output file
- Finally, we're telling the app to use the `GBP` currency; the default (`USD`) will be used if this is not specified

### Periods

Besides monthly recurring transactions, the app also supports the following periods:

- `quarterly` - For transactions every _3 months_
- `half-yearly` - For transactions every _6 months_
- `yearly` - Generate transactions _once a year_
- `once` - Generate _one-time_ transactions on a specified date
- `custom` - Generate transactions every _n days/weeks/months_

These will write periodic transactions such as `~ every 3 months` or `~ every year` in the output journal file.

#### Custom period

When you need a bespoke time bound forecast, a custom period may be useful. Custom periods allow you to specify a periodic rule as per hledger's [periodic rule syntax](https://hledger.org/dev/hledger.html#periodic-transactions):

```yaml
custom:
  - frequency: "every 2 weeks"
    account: "Assets:Bank"
    from: "2023-03-01"
    transactions:
      - amount: 80
        category: "Expenses:Personal Care"
        description: Hair and beauty
```

### Dates

The core of any solid forecast is predicting the correct periods that costs will fall into. When running the app from the CLI, you can specify specific dates to generate transactions over (see the [usage](#rocket-usage) section).

You can further control the dates at a period/top-level as well as at a transaction level:

#### Top level

In the example below, all transactions in the `monthly` block will be constrained by the `to` date:

```yaml
monthly:
  - account: "Assets:Bank"
    from: "2023-03-01"
    to: "2025-01-01"
    transactions:
      # details omitted for brevity
```

#### Transaction level

In the example below, only the single transaction will be constrained by the `to` date:

```yaml
monthly:
  - account: "Assets:Bank"
    from: "2023-03-01"
    transactions:
      - amount: 2000
        category: "Expenses:Mortgage"
        description: Mortgage
        to: "2025-01-01"
```

It can also be useful to compute a `to` date by adding on a number of months to the `from` date. Extending the example above:

```yaml
- amount: 125
  category: "Expenses:Holiday"
  description: Holiday
  to: "=12"
```

This will take the `to` date to _2024-02-29_. This can be useful if you know a payment is due to end in _n_ months time and don't wish to use one of the many date calculators on the internet.

### Calculated amounts

> **Note**: Calculations will be determined up to two decimal places

It may be helpful to let the app calculate the forecasted amount in your transactions on your behalf. This can be especially useful if you're spreading a payment out over a number of months:

```yaml
monthly:
  - account: "Liabilities:Amex"
    from: "2023-05-01"
    transactions:
      - amount: "=5000/24"
        category: "Expenses:House"
        description: New Kitchen
```

Simply ensure that the amount starts with an `=` sign, is enclosed in quotation marks and uses standard mathematical notations. Of course, it may make sense to restrict this transaction with a `to` date in months, as per the [transaction level dates](#transaction-level) section.

### Tracking transactions

> **Note**: Marking a transaction for tracking will ensure that it is only written into the forecast if it isn't found within a specified transaction file

Sometimes it can be useful to track and monitor forecasted transactions to ensure that they are accounted for in any financial projections. If they are present, then these should be discarded from your forecast as this will create a double count against your actuals. However, if they can't be found then they should be carried forward into a future period to ensure accurate recording.

To mark transactions as available for tracking you may use the `track` option in your config file:

```yaml
once:
  - account: "Assets:Bank"
    from: "2023-03-05"
    transactions:
      - amount: -3000
        category: "Expenses:Shopping"
        description: Refund for that damn laptop
        track: true
```

> **Note**: This feature has been designed to work with one-off transactions only

To use this feature, ensure you pass a filepath to the `-t` flag, such as:

    hledger-forecast generate -t [journal_file_to_search] -f [path_to_yaml_file] -o [path_to_output_journal]

The app will use a hledger query to determine if the combination of category and amount is present in the periods between the `from` key and the current date in the journal file you've specified. If not, then the app will include it as a forecast transaction in the output file.

### Modifiers

> **Note**: For modifiers to be included in your hledger reporting, use the `--auto` flag

Within your forecasts, it can be useful to reflect future increases/decreases in certain categories. For example, next year, I expect the cost of groceries to increase by 2%:

```yaml
monthly:
  account: "Assets:Bank"
  from: "2023-03-05"
  transactions:
    - amount: 450
      category: "Expenses:Groceries"
      description: Food shopping
      modifiers:
        - amount: 0.02
          description: "Inflation"
          from: "2024-01-01"
          to: "2024-12-31"
```

This will generate an [auto-posting](https://hledger.org/dev/hledger.html#auto-postings) in your forecast which will
uplift any transaction with an `Expenses:Groceries` category.

Of course you may wish to apply 2% for next year and another 3% for the year after:

```yaml
# details above omitted for brevity
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

### Roll-ups

As part of the summarize command, it can be useful to sum-up all of the transactions in your `yaml` file and see what your income and expenditure is over a given period (e.g. "how much profit do I _actually_ make every year when all of my costs are taken into account?").

In order to do this, custom forecasts need to have the `roll-up` key defined. That is, given the custom period you've specified, what number do you need to multiply the amount by in order to "roll it up" into an annualised figure. Let's look at the example below:

```yaml
custom:
  - frequency: "every 2 weeks"
    account: "Assets:Bank"
    from: "2023-03-01"
    roll-up: 26
    transactions:
      - amount: 80
        category: "Expenses:Personal Care"
        description: Hair and beauty
```

Every 2 weeks a planned expense of £80 is made. So over the course of a year, we'd need to multiply that amount by 26 to get to an annualised figure. Of course for periods like `monthly` and `quarterly` it's easy for hledger-forecast to annual those amounts so no `roll-up` is required.

To see the monthly summary of your `yaml` file, the following command can be used:

    hledger-forecast summarize -f my_forecast.yml -r monthly

### Summary exclusions

It can also be useful to exclude certain items from your summary such as one-off items. This can be achieved by specifying `summary_exclude: true` next to a transaction:

```yaml
once:
  - account: "Assets:Bank"
    from: "2023-03-05"
    transactions:
      - amount: -3000
        category: "Expenses:Shopping"
        description: Refund for that damn laptop
        summary_exclude: true
        track: true
```

### Additional config settings

Additional settings in the config file to consider:

```yaml
settings:
  currency: GBP # Specify the currency to use
  show_symbol: true # Show the currency symbol?
  thousands_separator: true # Separate thousands with a comma?
```

## :camera_flash: Screenshots

**Yaml config file and output**

<img src="https://user-images.githubusercontent.com/9512444/234382872-b81ac84d-2bcc-4488-a041-364f72627087.png" alt="Hledger-Forecast" />

**Summarize command**

<img src="https://user-images.githubusercontent.com/9512444/234386807-1301c8d9-af77-4f58-a3c3-a345b5e890a2.png" alt="Summarize command" />

## :paintbrush: Rationale

I moved to hledger from my trusty Excel macro workbook. This thing had been with me for 5+ years. I used it to workout whether I could afford that new gadget and when I'd be in a position to buy a house. I used it to see if I was on track to have £X in my savings accounts by a given date as well as see how much money I could save on a monthly basis. That time I accidentally double counted my bonus or thought I'd accounted for my credit card bill? Painful! Set me back a few months in terms of my savings plans. In summary, I relied _heavily_ on having a detailed and accurate forecast.

I love hledger. Switching from Excel has been a breath of fresh air. There's only so many bank transactions a workbook can take before it starts groaning (yes, even on an M1 Mac). However there were a few forecasting features that I missed. The sort of features that in Excel terms mean I'd just copy a bunch of cells and paste them into columns which represented future dates or apply a neat little formula to divide a big number by 12 to get to a monthly repayment. Because I like to plan 3-5 years out at a time, I wanted to crudely account for future price and salary increases. Sure, I can add some auto-postings to the end of my journal file but I bet a lot of users didn't know about this or even know how to constrain them between two dates. I also made an assumption that a lot of users probably think of their finances in terms of their monthly costs (e.g. car payments, mortgage, food), half-yearly costs (e.g. service charge if you have an apartment in the UK) and yearly costs (e.g. holidays, gifts) etc. But likely never do the math to add them all together and workout how much money they have left over by the end of it all. Well I built that into this app and my daily profit figure hit me hard :rofl:. Give it a try!

So I thought I'd share this little Ruby gem in the hope that people find it useful. Perhaps for those who are moving from an Excel based approach to [plain text accounting](https://plaintextaccounting.org), or for those who want a little bit of improvement to the existing capabilities within hledger.
