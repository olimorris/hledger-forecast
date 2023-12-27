require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  monthly,,Liabilities:Amex,01/05/2023,,New kitchen,Expenses:House,=5000/24,,,
  monthly,,Liabilities:Amex,01/05/2023,,Monthly food shop,Expenses:Food,=25*4.3,,,
  monthly,,Liabilities:Amex,01/05/2023,,Random food,Expenses:Food,=(102.50+3.25)/2,,,
  settings,currency,GBP,,,,,,,,
CSV

output = <<~JOURNAL
  ~ monthly from 2023-05-01  * New kitchen, Monthly food shop, Random food
      Expenses:House    £208.33              ;  New kitchen
      Expenses:Food     £107.50              ;  Monthly food shop
      Expenses:Food     £52.88               ;  Random food
      Liabilities:Amex

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct CALCULATED transactions' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
