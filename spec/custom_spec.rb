require_relative '../lib/hledger_forecast'

config = <<~YAML
  custom:
    - frequency: "every 2 weeks"
      from: "2023-05-01"
      account: "[Assets:Bank]"
      transactions:
        - amount: 80
          category: "[Expenses:Personal Care]"
          description: Hair and beauty
    - frequency: "every 5 days"
      from: "2023-05-01"
      account: "[Assets:Checking]"
      transactions:
        - amount: 50
          category: "[Expenses:Groceries]"
          description: Gotta feed that stomach

  settings:
    currency: GBP
YAML

output = <<~JOURNAL
  ~ every 2 weeks from 2023-05-01  * Hair and beauty
      [Expenses:Personal Care]    £80.00;  Hair and beauty
      [Assets:Bank]

  ~ every 5 days from 2023-05-01  * Gotta feed that stomach
      [Expenses:Groceries]        £50.00;  Gotta feed that stomach
      [Assets:Checking]

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct CUSTOM transactions' do
    generated_journal = HledgerForecast::Generator.generate(config)
    expect(generated_journal).to eq(output)
  end
end
