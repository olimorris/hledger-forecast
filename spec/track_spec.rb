require_relative '../lib/hledger_forecast'

RSpec.describe 'Tracking transactions -' do
  it 'Determines which transactions should be tracked' do
    forecast = File.read('spec/stubs/track/track.yml')

    generated = HledgerForecast::Generator
    generated.generate(forecast)
    tracked = generated.tracked

    expect(tracked[0]['transaction']).to eq(
      { "amount" => "£3,000.00", "category" => "[Expenses:Tax]", "description" => "Tax owed",
        "track" => true }
    )
    expect(tracked[0]['account']).to eq("[Assets:Bank]")

    expect(tracked[1]['transaction']).to eq(
      { "amount" => "£-1,500.00", "category" => "[Income:Salary]", "description" => "Salary", "end" => "2023-08-01",
        "track" => true }
    )
    expect(tracked[1]['account']).to eq("[Assets:Bank]")
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
end
