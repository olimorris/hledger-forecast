require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions' do
    forecast = File.read('spec/stubs/monthly/forecast_monthly.yml')

    generated_journal = HledgerForecast::Generator.generate(forecast)

    expected_output = File.read('spec/stubs/monthly/output_monthly.journal')
    expect(generated_journal).to eq(expected_output)
  end

  it 'generates a forecast with correct MONTHLY transactions that have an end date' do
    forecast = File.read('spec/stubs/monthly/forecast_monthly_enddate.yml')

    generated_journal = HledgerForecast::Generator.generate(forecast)

    expected_output = File.read('spec/stubs/monthly/output_monthly_enddate.journal')
    expect(generated_journal).to eq(expected_output)
  end

  it 'generates a forecast with correct MONTHLY transactions that have an end date, at the top level' do
    forecast = File.read('spec/stubs/monthly/forecast_monthly_enddate_top.yml')

    generated_journal = HledgerForecast::Generator.generate(forecast)

    expected_output = File.read('spec/stubs/monthly/output_monthly_enddate_top.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
