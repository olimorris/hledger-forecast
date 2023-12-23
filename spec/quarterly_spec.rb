require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  quarterly,,Assets:Bank,01/04/2023,,Bonus,Income:Bonus,-1000,,,
  settings,currency,GBP,,,,,,,,
CSV

output = <<~JOURNAL
  ~ every 3 months from 2023-04-01  * Bonus
      Income:Bonus    £-1,000.00;  Bonus
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct QUARTERLY transactions' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
