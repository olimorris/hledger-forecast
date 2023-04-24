require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct YEARLY transactions' do
    forecast = File.read('spec/stubs/yearly/forecast_yearly.yml')

    generated_journal = HledgerForecast::Generator.generate(forecast)

    expected_output = File.read('spec/stubs/yearly/output_yearly.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
