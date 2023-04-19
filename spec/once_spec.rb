require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct ONCE transactions' do
    transactions = File.read('spec/stubs/transactions.journal')
    forecast = File.read('spec/stubs/once/forecast_once.yml')

    generated_journal = HledgerForecast::Generator.generate(transactions, forecast, '2023-03-01', '2024-04-30')

    expected_output = File.read('spec/stubs/once/output_once.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
