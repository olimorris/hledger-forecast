require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct QUARTERLY transactions' do
    forecast = File.read('spec/stubs/quarterly/forecast_quarterly.yml')

    generated_journal = HledgerForecast::TransactionGenerator.generate(forecast)

    expected_output = File.read('spec/stubs/quarterly/output_quarterly.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
