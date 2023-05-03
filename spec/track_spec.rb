require_relative '../lib/hledger_forecast'

current_month = Date.new(Date.today.year, Date.today.month, 1)
previous_month = current_month.prev_month
next_month = current_month.next_month

output = <<~JOURNAL
  ~ 2023-03-05  * Food expenses
      Expenses:Food    £100.00;  Food expenses
      Assets:Bank

  ~ #{next_month}  * [TRACKED] Tax owed
      Expenses:Tax     £3,000.00;  Tax owed
      Assets:Bank

  ~ #{next_month}  * [TRACKED] Salary
      Income:Salary    £-1,500.00;  Salary
      Assets:Bank

JOURNAL

RSpec.describe 'Tracking transactions -' do
  it 'Determines which transactions should be tracked' do
    forecast = File.read('spec/stubs/track/track.yml')

    generated = HledgerForecast::Generator
    generated.generate(forecast)
    tracked = generated.tracked

    expect(tracked[0]['transaction']).to eq(
      { "amount" => "£3,000.00", "category" => "Expenses:Tax", "description" => "Tax owed",
        "inverse_amount" => "£-3,000.00", "track" => true }
    )
    expect(tracked[0]['account']).to eq("Assets:Bank")

    expect(tracked[1]['transaction']).to eq(
      { "amount" => "£-1,500.00", "category" => "Income:Salary", "description" => "Salary", "end" => "2023-08-01",
        "inverse_amount" => "£1,500.00", "track" => true }
    )
    expect(tracked[1]['account']).to eq("Assets:Bank")
  end

  it 'marks a transaction as NOT FOUND if it doesnt exist' do
    forecast = File.read('spec/stubs/track/track.yml')

    generated = HledgerForecast::Generator
    generated.tracked = {} # Clear tracked transactions
    generated.generate(forecast)
    transactions_to_track = generated.tracked

    track = HledgerForecast::Tracker.track(transactions_to_track, 'spec/stubs/track/transactions_not_found.journal')

    expect(track[0]['found']).to eq(false)
    expect(track[1]['found']).to eq(false)
  end

  it 'marks a transaction as FOUND if it exists' do
    forecast = File.read('spec/stubs/track/track.yml')

    generated = HledgerForecast::Generator
    generated.tracked = {} # Clear tracked transactions
    generated.generate(forecast)
    transactions_to_track = generated.tracked

    track = HledgerForecast::Tracker.track(transactions_to_track, 'spec/stubs/track/transactions_found.journal')

    expect(track[0]['found']).to eq(true)
    expect(track[1]['found']).to eq(true)
  end

  it 'marks a transaction as FOUND if it exists, even if the category/amount are inversed' do
    forecast = File.read('spec/stubs/track/track.yml')

    generated = HledgerForecast::Generator
    generated.tracked = {} # Clear tracked transactions
    generated.generate(forecast)
    transactions_to_track = generated.tracked

    track = HledgerForecast::Tracker.track(transactions_to_track, 'spec/stubs/track/transactions_found_inverse.journal')

    expect(track[0]['found']).to eq(true)
  end

  it 'writes a NON-FOUND entry into a journal' do
    forecast = File.read('spec/stubs/track/track.yml')

    options = {}
    options[:transaction_file] = 'spec/stubs/track/transactions_not_found.journal'

    generated = HledgerForecast::Generator
    generated.tracked = {} # Clear tracked transactions

    generated_journal = generated.generate(forecast, options)

    expected_output = output
    expect(generated_journal).to eq(expected_output)
  end

  it 'writes a NON-FOUND entry for dates that are close to the current period' do
    require 'tempfile'

    forecast_config = <<~YAML
      once:
        - account: "Assets:Bank"
          start: "#{previous_month}"
          transactions:
            - amount: 5000
              category: "Expenses:House"
              description: New kitchen
              track: true

      settings:
        currency: GBP
    YAML

    journal = <<~JOURNAL
      #{previous_month} * Opening balance
          Assets:Bank                             £1,000.00
          Equity:Opening balance

      #{previous_month} * Mortgage payment
          Expenses:Mortgage                 £1,500.00
          Assets:Bank

      #{current_month - 10} * Groceries
          Expenses:Groceries                £1,500.00
          Assets:Bank

    JOURNAL

    temp_file = Tempfile.new('journal')
    temp_file.write(journal)
    temp_file.close

    options = {}
    options[:transaction_file] = temp_file.path

    generated = HledgerForecast::Generator
    generated.tracked = {} # Clear tracked transactions

    generated_journal = generated.generate(forecast_config, options)

    expected_output = <<~JOURNAL
      ~ #{next_month}  * [TRACKED] New kitchen
          Expenses:House    £5,000.00;  New kitchen
          Assets:Bank

    JOURNAL

    expect(generated_journal).to eq(expected_output)
  end

  it 'treats a future tracked transaction as a regular transaction' do
    forecast_config = <<~YAML
      monthly:
        - account: "Assets:Bank"
          start: "#{next_month}"
          transactions:
            - amount: 100
              category: "Expenses:Food"
              description: Food expenses
              track: true

      settings:
        currency: GBP
    YAML

    options = {}
    options[:transaction_file] = 'spec/stubs/track/transactions_not_found.journal'

    generated = HledgerForecast::Generator
    generated.tracked = {} # Clear tracked transactions

    generated_journal = generated.generate(forecast_config, options)

    output = <<~JOURNAL
      ~ monthly from #{next_month}  * Food expenses
          Expenses:Food    £100.00;  Food expenses
          Assets:Bank

    JOURNAL

    expect(generated_journal).to eq(output)
  end
end
