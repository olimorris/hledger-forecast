require_relative '../lib/hledger_forecast'
RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions that have a START DATE' do
    transactions = File.read('spec/stubs/transactions.journal')
    forecast = File.read('spec/stubs/start_date/forecast_startdate.yml')

    generated_journal = HledgerForecast::Generator.generate(transactions, forecast, '2023-03-01', '2023-08-30')

    expected_output = File.read('spec/stubs/start_date/output_startdate.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
