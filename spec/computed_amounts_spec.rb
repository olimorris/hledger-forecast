require_relative '../lib/hledger_forecast'

config = <<~YAML
  settings:
    currency: GBP

  monthly:
    - account: "Liabilities:Amex"
      from: "2023-05-01"
      transactions:
        - amount: "=5000/24"
          category: "Expenses:House"
          description: New Kitchen
        - amount: "=25*4.3"
          category: "Expenses:Food"
          description: Monthly food shop
        - amount: "=(102.50+3.25)/2"
          category: "Expenses:Food"
          description: Random food
YAML

output = <<~JOURNAL
  ~ monthly from 2023-05-01  * New Kitchen, Monthly food shop, Random food
      Expenses:House    £208.33          ;  New Kitchen
      Expenses:Food     £107.50          ;  Monthly food shop
      Expenses:Food     £52.88           ;  Random food
      Liabilities:Amex

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct CALCULATED transactions' do
    expect(HledgerForecast::Generator.generate(config)).to eq(output)
  end
end
