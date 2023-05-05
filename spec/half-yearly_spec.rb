require_relative '../lib/hledger_forecast'

config = <<~YAML
  settings:
    currency: GBP

  half-yearly:
    - from: "2023-04-01"
      account: "Assets:Bank"
      transactions:
        - description: Holiday
          category: "Expenses:Holiday"
          amount: 500
YAML

output = <<~JOURNAL
  ~ every 6 months from 2023-04-01  * Holiday
      Expenses:Holiday    £500.00;  Holiday
      Assets:Bank

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct HALF-YEARLY transactions' do
    generated_journal = HledgerForecast::Generator.generate(config)

    expect(generated_journal).to eq(output)
  end
end
