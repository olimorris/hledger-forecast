require_relative '../lib/hledger_forecast'

config = <<~YAML
  settings:
    currency: GBP

  quarterly:
    - from: "2023-04-01"
      account: "Assets:Bank"
      transactions:
        - description: Bonus
          category: "Income:Bonus"
          amount: -1,000.00
YAML

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
