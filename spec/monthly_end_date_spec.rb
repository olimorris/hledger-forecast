require_relative '../lib/hledger_forecast'

config = <<~YAML
  settings:
    currency: GBP

  monthly:
    - from: "2023-03-01"
      to: "2023-06-01"
      account: "Assets:Bank"
      transactions:
        - description: Mortgage
          category: "Expenses:Mortgage"
          amount: 2000.00
        - description: Food
          category: "Expenses:Food"
          amount: 100.00
YAML

output = <<~JOURNAL
  ~ monthly from 2023-03-01 to 2023-06-01  * Mortgage, Food
      Expenses:Mortgage    £2,000.00;  Mortgage
      Expenses:Food        £100.00  ;  Food
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions that have an end date, at the top level' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
