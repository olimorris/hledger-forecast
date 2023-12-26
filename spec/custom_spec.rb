require_relative '../lib/hledger_forecast'

base_config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  custom,every 2 weeks,[Assets:Bank],01/05/2023,,Hair and beauty,[Expenses:Personal Care],80,,,
  custom,every 5 days,[Assets:Bank],01/05/2023,,Food,[Expenses:Groceries],50,,,
  settings,currency,GBP,,,,,,,,
CSV

base_output = <<~JOURNAL
  ~ every 2 weeks from 2023-05-01  * Hair and beauty
      [Expenses:Personal Care]    £80.00 ;  Hair and beauty
      [Assets:Bank]

  ~ every 5 days from 2023-05-01  * Food
      [Expenses:Groceries]        £50.00 ;  Food
      [Assets:Bank]

JOURNAL

calculated_config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  custom,every 2 weeks,[Assets:Bank],01/05/2023,=6,Hair and beauty,[Expenses:Personal Care],80,,,
  settings,currency,GBP,,,,,,,,
CSV

calculated_output = <<~JOURNAL
  ~ every 2 weeks from 2023-05-01 to 2023-10-31  * Hair and beauty
      [Expenses:Personal Care]    £80.00 ;  Hair and beauty
      [Assets:Bank]

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct CUSTOM transactions' do
    generated_journal = HledgerForecast::Generator.generate(base_config)
    expect(generated_journal).to eq(base_output)
  end

  it 'generates a forecast with correct CUSTOM transactions and CALCULATED to dates' do
    generated_journal = HledgerForecast::Generator.generate(calculated_config)
    expect(generated_journal).to eq(calculated_output)
  end
end
