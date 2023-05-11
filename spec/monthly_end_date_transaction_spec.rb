require_relative '../lib/hledger_forecast'

base_config = <<~YAML
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

base_output = <<~JOURNAL
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

computed_config = <<~YAML
  settings:
    currency: GBP

  monthly:
    - from: "2023-03-01"
      account: "Assets:Bank"
      transactions:
        - description: Mortgage
          category: "Expenses:Mortgage"
          to: "=12"
          amount: 2000.00
YAML

computed_output = <<~JOURNAL
  ~ monthly from 2023-03-01 to 2024-02-29  * Mortgage
      Expenses:Mortgage    £2,000.00;  Mortgage
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct MONTHLY transactions that have an end date' do
    expect(HledgerForecast::Generator.generate(base_config)).to eq(base_output)
  end

  it 'generates a forecast with correct MONTHLY transactions that have a COMPUTED end date' do
    expect(HledgerForecast::Generator.generate(computed_config)).to eq(computed_output)
  end
end
