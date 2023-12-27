require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  once,,Assets:Bank,01/07/2023,,New Kitchen,Expenses:House,5000,,,
  settings,currency,GBP,,,,,,,,
CSV

output = <<~JOURNAL
  ~ 2023-07-01  * New Kitchen
      Expenses:House    £5,000.00;  New Kitchen
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct ONCE transactions' do
    generated_journal = HledgerForecast::Generator.generate(config)
    expect(generated_journal).to eq(output)
  end
end
