require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct QUARTERLY transactions' do
    transactions = File.read('spec/stubs/transactions.journal')
    forecast = File.read('spec/stubs/quarterly/forecast_quarterly.yml')

    generated_journal = HledgerForecast::Generator.generate(transactions, forecast, '2023-03-01', '2023-10-30')

    expected_output = File.read('spec/stubs/quarterly/output_quarterly.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
