require_relative '../lib/hledger_forecast'

base_config = <<~YAML
  monthly:
    - account: "Assets:Bank"
      from: "2023-01-01"
      transactions:
        - amount: 500
          category: "Expenses:Groceries"
          description: Food shopping
          modifiers:
            - amount: 0.02
              description: "Y1 inflation"
              from: "2024-01-01"
              to: "2024-12-31"
            - amount: 0.05
              description: "Y2 inflation"
              from: "2025-01-01"
              to: "2025-12-31"

  settings:
    currency: USD
YAML

base_journal = <<~JOURNAL
  ~ monthly from 2023-01-01  * Food shopping
      Expenses:Groceries    $500.00;  Food shopping
      Assets:Bank

  = Expenses:Groceries date:2024-01-01..2024-12-31
      Expenses:Groceries    *0.02;  Food shopping - Y1 inflation
      Assets:Bank           *-0.02

  = Expenses:Groceries date:2025-01-01..2025-12-31
      Expenses:Groceries    *0.05;  Food shopping - Y2 inflation
      Assets:Bank           *-0.05

JOURNAL

no_date_config = <<~YAML
  monthly:
    - account: "Assets:Bank"
      from: "2023-01-01"
      transactions:
        - amount: 500
          category: "Expenses:Groceries"
          description: Food shopping
          modifiers:
            - amount: 0.1
              description: "Inflation"

  settings:
    currency: USD
YAML

no_date_journal = <<~JOURNAL
  ~ monthly from 2023-01-01  * Food shopping
      Expenses:Groceries    $500.00;  Food shopping
      Assets:Bank

  = Expenses:Groceries date:2023-01-01
      Expenses:Groceries    *0.1 ;  Food shopping - Inflation
      Assets:Bank           *-0.1

JOURNAL

RSpec.describe 'Applying modifiers to transactions -' do
  it 'Auto-postings should be created correctly' do
    generated = HledgerForecast::Generator
    generated.modified = {} # Clear modified transactions

    generated_journal = generated.generate(base_config)
    generated.modified = {} # Clear modified transactions

    expect(generated_journal).to eq(base_journal)
  end

  it 'Auto-postings should be created correctly if no dates are set' do
    generated = HledgerForecast::Generator
    generated.modified = {} # Clear modified transactions

    generated_journal = generated.generate(no_date_config)
    generated.modified = {} # Clear modified transactions

    expect(generated_journal).to eq(no_date_journal)
  end
end
