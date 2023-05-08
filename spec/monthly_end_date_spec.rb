require_relative '../lib/hledger_forecast'

config = <<~YAML
settings:
  currency: GBP

monthly:
  - from: "2023-03-01"
    account: "Assets:Bank"
    transactions:
      - description: Mortgage
        to: "2023-06-01"
        category: "Expenses:Mortgage"
        amount: 2000.00
      - description: Mortgage top up
        to: "2023-06-01"
        category: "Expenses:Mortgage Top Up"
        amount: 200.00
      - description: Food
        category: "Expenses:Food"
        amount: 100.00
      - description: Party time
        category: "Expenses:Going Out"
        amount: 50.00
YAML

output = <<~JOURNAL
~ monthly from 2023-03-01  * Food, Party time
    Expenses:Food               £100.00  ;  Food
    Expenses:Going Out          £50.00   ;  Party time
    Assets:Bank

~ monthly from 2023-03-01 to 2023-06-01  * Mortgage
    Expenses:Mortgage           £2,000.00;  Mortgage
    Assets:Bank

~ monthly from 2023-03-01 to 2023-06-01  * Mortgage top up
    Expenses:Mortgage Top Up    £200.00  ;  Mortgage top up
    Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions that have an end date' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
