require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions' do
    transactions = File.read('./spec/stubs/transactions.journal')
    forecast = File.read('./spec/stubs/monthly/forecast_monthly.yml')

    generated_journal = HledgerForecast::Generator.create_journal_entries(transactions, forecast, '2023-03-01', '2023-05-30')

    expected_output = File.read('./spec/stubs/monthly/output_monthly.journal')
    expect(generated_journal).to eq(expected_output)
  end

  it 'generates a forecast with correct MONTHLY transactions that have an end date' do
    transactions = File.read('./spec/stubs/transactions.journal')
    forecast = File.read('./spec/stubs/monthly/forecast_monthly_enddate.yml')

    generated_journal = HledgerForecast::Generator.create_journal_entries(transactions, forecast, '2023-03-01', '2023-08-30')

    expected_output = File.read('./spec/stubs/monthly/output_monthly_enddate.journal')
    expect(generated_journal).to eq(expected_output)
  end

  it 'generates a forecast with correct MONTHLY transactions that have an end date, at the top level' do
    transactions = File.read('./spec/stubs/transactions.journal')
    forecast = File.read('./spec/stubs/monthly/forecast_monthly_enddate_top.yml')

    generated_journal = HledgerForecast::Generator.create_journal_entries(transactions, forecast, '2023-03-01', '2023-08-30')

    expected_output = File.read('./spec/stubs/monthly/output_monthly_enddate_top.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
