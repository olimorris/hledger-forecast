require_relative '../lib/hledger_forecast'

RSpec.describe 'generate' do
  it 'generates a forecast with correct CUSTOM DAILY transactions' do
    transactions = File.read('spec/stubs/transactions.journal')
    forecast = File.read('spec/stubs/custom/forecast_custom_days.yml')

    generated_journal = HledgerForecast::Generator.create_journal_entries(transactions, forecast, '2023-03-01',
                                                                          '2023-03-10')

    expected_output = File.read('spec/stubs/custom/output_custom_days.journal')
    expect(generated_journal).to eq(expected_output)
  end

  it 'generates a forecast with correct CUSTOM WEEKlY transactions' do
    transactions = File.read('spec/stubs/transactions.journal')
    forecast = File.read('spec/stubs/custom/forecast_custom_weeks.yml')

    generated_journal = HledgerForecast::Generator.create_journal_entries(transactions, forecast, '2023-03-01',
                                                                          '2023-04-30')

    expected_output = File.read('spec/stubs/custom/output_custom_weeks.journal')
    expect(generated_journal).to eq(expected_output)
  end

  it 'generates a forecast with MULTIPLE correct CUSTOM WEEKlY transactions' do
    transactions = File.read('spec/stubs/transactions.journal')
    forecast = File.read('spec/stubs/custom/forecast_custom_weeks_twice.yml')

    generated_journal = HledgerForecast::Generator.create_journal_entries(transactions, forecast, '2023-03-01',
                                                                          '2023-03-30')

    expected_output = File.read('spec/stubs/custom/output_custom_weeks_twice.journal')
    expect(generated_journal).to eq(expected_output)
  end

  it 'generates a forecast with correct CUSTOM MONTHLY transactions' do
    transactions = File.read('spec/stubs/transactions.journal')
    forecast = File.read('spec/stubs/custom/forecast_custom_months.yml')

    generated_journal = HledgerForecast::Generator.create_journal_entries(transactions, forecast, '2023-03-01',
                                                                          '2024-02-28')

    expected_output = File.read('spec/stubs/custom/output_custom_months.journal')
    expect(generated_journal).to eq(expected_output)
  end
end
