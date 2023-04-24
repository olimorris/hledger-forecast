require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct CUSTOM transactions' do
    forecast = File.read('spec/stubs/custom/forecast_custom.yml')

    generated_journal = HledgerForecast::Generator.generate(forecast)

    expected_output = File.read('spec/stubs/custom/output_custom.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
