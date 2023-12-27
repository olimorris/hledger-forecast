require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  monthly,,Assets:Bank,01/03/2023,,Bills,Expenses:Bills,175,,,
  monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,500,,,
  monthly,,Assets:Bank,01/03/2023,,Savings,Assets:Savings,-1000,,,
  settings,currency,GBP,,,,,,,,
CSV

output = <<~JOURNAL
  ~ monthly from 2023-03-01  * Bills, Food, Savings
      Expenses:Bills    £175.00   ;  Bills
      Expenses:Food     £500.00   ;  Food
      Assets:Savings    £-1,000.00;  Savings
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
