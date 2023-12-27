require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  yearly,,Assets:Bank,01/04/2023,,Bonus,Income:Bonus,-3000,,,
  settings,currency,GBP,,,,,,,,
CSV

output = <<~JOURNAL
  ~ yearly from 2023-04-01  * Bonus
      Income:Bonus    £-3,000.00;  Bonus
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct YEARLY transactions' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
