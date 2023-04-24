require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct HALF-YEARLY transactions' do
    forecast = File.read('spec/stubs/half-yearly/forecast_half-yearly.yml')

    generated_journal = HledgerForecast::Generator.generate(forecast)

    expected_output = File.read('spec/stubs/half-yearly/output_half-yearly.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
