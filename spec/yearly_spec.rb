require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct YEARLY transactions' do
    transactions = File.read('spec/stubs/transactions.journal')
    forecast = File.read('spec/stubs/yearly/forecast_yearly.yml')

    generated_journal = HledgerForecast::Generator.create_journal_entries(transactions, forecast, '2023-03-01', '2024-04-30')

    expected_output = File.read('spec/stubs/yearly/output_yearly.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
