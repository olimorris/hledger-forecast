require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct ONCE transactions' do
    forecast = File.read('spec/stubs/once/forecast_once.yml')

    generated_journal = HledgerForecast::TransactionGenerator.generate(forecast)

    expected_output = File.read('spec/stubs/once/output_once.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
