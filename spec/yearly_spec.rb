require_relative '../lib/hledger_forecast'

config = <<~YAML
  settings:
    currency: GBP

  yearly:
    - account: "Assets:Bank"
      from: "2023-04-01"
      transactions:
        - description: Bonus
          category: "Income:Bonus"
          amount: -3,000.00
YAML

output = <<~JOURNAL
  ~ yearly from 2023-04-01  * Bonus
      Income:Bonus    £-3,000.00;  Bonus
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct YEARLY transactions' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
