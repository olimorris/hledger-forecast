require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  half-yearly,,Assets:Bank,01/04/2023,,Holiday,Expenses:Holiday,500,,,
  settings,currency,GBP,,,,,,,,
CSV

output = <<~JOURNAL
  ~ every 6 months from 2023-04-01  * Holiday
      Expenses:Holiday    £500.00 ;  Holiday
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct HALF-YEARLY transactions' do
    generated_journal = HledgerForecast::Generator.generate(config)

    expect(generated_journal).to eq(output)
  end
end
