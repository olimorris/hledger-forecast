require_relative '../lib/hledger_forecast'

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

    expected_output = File.read('spec/stubs/track/output_track.journal')
    expect(generated_journal).to eq(expected_output)
  end

  it 'writes a NON-FOUND entry for dates that are close to the current period' do
    require 'tempfile'

    current_month = Date.new(Date.today.year, Date.today.month, 1)
    previous_month = current_month.prev_month.prev_month

    forecast_config = <<~YAML
      once:
        - account: "Assets:Bank"
          start: "#{current_month}"
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
      #  TRACKED TRANSACTION
      ~ from #{current_month}  TRACKED - New kitchen
          Expenses:House    £5,000.00
          Assets:Bank

    JOURNAL

    expect(generated_journal).to eq(expected_output)
  end

  it 'treats a future tracked transaction as a regular transaction' do
    forecast = File.read('spec/stubs/track/track_normal.yml')

    options = {}
    options[:transaction_file] = 'spec/stubs/track/transactions_not_found.journal'

    generated = HledgerForecast::Generator
    generated.tracked = {} # Clear tracked transactions

    generated_journal = generated.generate(forecast, options)

    expected_output = File.read('spec/stubs/track/output_track_normal.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
