require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  monthly,,Assets:Bank,01/03/2023,01/06/2023,Mortgage,Expenses:Mortgage,2000.00,,,
  monthly,,Assets:Bank,01/03/2023,01/06/2023,Mortgage top up,Expenses:Mortgage,200.00,,,
  monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,100.00,,,
  settings,currency,GBP,,,,,,,,
CSV

output = <<~JOURNAL
  ~ monthly from 2023-03-01 to 2023-06-01  * Mortgage, Mortgage top up
      Expenses:Mortgage    £2,000.00   ;  Mortgage
      Expenses:Mortgage    £200.00     ;  Mortgage top up
      Assets:Bank

  ~ monthly from 2023-03-01  * Food
      Expenses:Food        £100.00     ;  Food
      Assets:Bank

JOURNAL

computed_config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  monthly,,Assets:Bank,01/03/2023,=12,Mortgage,Expenses:Mortgage,2000.00,,,
  settings,currency,GBP,,,,,,,,
CSV

computed_output = <<~JOURNAL
  ~ monthly from 2023-03-01 to 2024-02-29  * Mortgage
      Expenses:Mortgage    £2,000.00   ;  Mortgage
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions that have an end date' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end

  it 'generates a forecast with correct MONTHLY transactions that have a COMPUTED end date' do
    expect(HledgerForecast::Generator.generate(computed_config)).to eq(computed_output)
  end
end
