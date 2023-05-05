require_relative '../lib/hledger_forecast'

config = <<~YAML
  settings:
    currency: GBP

  once:
    - from: "2023-07-01"
      account: "Assets:Bank"
      transactions:
        - description: New Kitchen
          category: "Expense:House"
          amount: 5,000.00
YAML

output = <<~JOURNAL
  ~ 2023-07-01  * New Kitchen
      Expense:House    £5,000.00;  New Kitchen
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct ONCE transactions' do
    generated_journal = HledgerForecast::Generator.generate(config)
    expect(generated_journal).to eq(output)
  end
end
