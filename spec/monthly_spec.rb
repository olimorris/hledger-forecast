require_relative '../lib/hledger_forecast'

config = <<~YAML
  monthly:
    - account: "Assets:Bank"
      from: "2023-03-01"
      transactions:
        - amount: 2000.55
          category: "Expenses:Mortgage"
          description: Mortgage
        - amount: 100
          category: "Expenses:Food"
          description: Food
    - account: "Assets:Savings"
      from: "2023-03-01"
      transactions:
        - amount: -1000
          category: "Assets:Bank"
          description: Savings

  settings:
    currency: GBP
YAML

output = <<~JOURNAL
~ monthly from 2023-03-01  * Mortgage, Food
    Expenses:Mortgage    £2,000.55;  Mortgage
    Expenses:Food        £100.00  ;  Food
    Assets:Bank

~ monthly from 2023-03-01  * Savings
    Assets:Bank          £-1,000.00;  Savings
    Assets:Savings

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
