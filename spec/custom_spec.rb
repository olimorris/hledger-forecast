require_relative '../lib/hledger_forecast'

base_config = <<~YAML
  custom:
    - account: "[Assets:Bank]"
      from: "2023-05-01"
      transactions:
        - amount: 80
          category: "[Expenses:Personal Care]"
          description: Hair and beauty
          frequency: "every 2 weeks"
        - amount: 50
          category: "[Expenses:Groceries]"
          description: Gotta feed that stomach
          frequency: "every 5 days"

  settings:
    currency: GBP
YAML

base_output = <<~JOURNAL
  ~ every 2 weeks from 2023-05-01  * Hair and beauty
      [Expenses:Personal Care]    £80.00;  Hair and beauty
      [Assets:Bank]

  ~ every 5 days from 2023-05-01  * Gotta feed that stomach
      [Expenses:Groceries]        £50.00;  Gotta feed that stomach
      [Assets:Bank]

JOURNAL

calculated_config = <<~YAML
  custom:
    - account: "[Assets:Bank]"
      from: "2023-05-01"
      transactions:
        - amount: 80
          category: "[Expenses:Personal Care]"
          description: Hair and beauty
          frequency: "every 2 weeks"
          to: "=6"

  settings:
    currency: GBP
YAML

calculated_output = <<~JOURNAL
  ~ every 2 weeks from 2023-05-01 to 2023-10-31  * Hair and beauty
      [Expenses:Personal Care]    £80.00;  Hair and beauty
      [Assets:Bank]

JOURNAL

RSpec.describe 'generate' do
  it 'generates a forecast with correct CUSTOM transactions' do
    generated_journal = HledgerForecast::Generator.generate(base_config)
    expect(generated_journal).to eq(base_output)
  end

  it 'generates a forecast with correct CUSTOM transactions and CALCULATED to dates' do
    generated_journal = HledgerForecast::Generator.generate(calculated_config)
    expect(generated_journal).to eq(calculated_output)
  end
end
