require_relative '../lib/hledger_forecast'

# once,Assets:Bank,2023-03-05,,Refund for that damn laptop,Expenses:Shopping,-3000,true,true
input = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  monthly,,Assets:Bank,2023-03-01,,Salary,Income:Salary,-3500,,,
  monthly,,Assets:Bank,2023-03-01,01/01/2025,Mortgage,Expenses:Mortgage,2000,,,
  monthly,,Assets:Bank,2023-03-01,,Bills,Expenses:Bills,175,,,
  monthly,,Assets:Bank,2023-03-01,,Food,Expenses:Food,500,,,
  monthly,,Assets:Bank,2023-03-01,,New Kitchen,Expenses:House,=5000/24,,,
  monthly,,Assets:Bank,2023-03-01,=12,Holiday,Expenses:Holiday,125,,,
  monthly,,Assets:Bank,2023-03-01,2025-01-01,Rainy day fund,Assets:Savings,300,,,
  monthly,,Assets:Pension,2024-01-01,,Pension draw down,Income:Pension,-500,,,
  quarterly,,Assets:Bank,2023-04-01,,Quarterly bonus,Income:Bonus,-1000,,,
  half-yearly,,Assets:Bank,2023-04-01,,Top up holiday funds,Expenses:Holiday,500,,,
  yearly,,Assets:Bank,2023-04-01,,Annual bonus,Income:Bonus,-2000,,,
  once,,Assets:Bank,2023-03-05,,Refund for that damn laptop,Expenses:Shopping,-3000,,true,true
  custom,every 2 weeks,Assets:Bank,2023-03-01,,Hair and beauty,Expenses:Personal Care,80,26,,
CSV

output = <<~YAML
    ---
    monthly:
    - account: Assets:Bank
      from: '2023-03-01'
      transactions:
      - amount: -3500.0
        category: Income:Salary
        description: Salary
      - amount: 2000.0
        category: Expenses:Mortgage
        description: Mortgage
        to: '2025-01-01'
      - amount: 175.0
        category: Expenses:Bills
        description: Bills
      - amount: 500.0
        category: Expenses:Food
        description: Food
      - amount: "=5000/24"
        category: Expenses:House
        description: New Kitchen
      - amount: 125.0
        category: Expenses:Holiday
        description: Holiday
        to: "=12"
      - amount: 300.0
        category: Assets:Savings
        description: Rainy day fund
        to: '2025-01-01'
    - account: Assets:Pension
      from: '2024-01-01'
      transactions:
      - amount: -500.0
        category: Income:Pension
        description: Pension draw down
    quarterly:
    - account: Assets:Bank
      from: '2023-04-01'
      transactions:
      - amount: -1000.0
        category: Income:Bonus
        description: Quarterly bonus
    half-yearly:
    - account: Assets:Bank
      from: '2023-04-01'
      transactions:
      - amount: 500.0
        category: Expenses:Holiday
        description: Top up holiday funds
    yearly:
    - account: Assets:Bank
      from: '2023-04-01'
      transactions:
      - amount: -2000.0
        category: Income:Bonus
        description: Annual bonus
    once:
    - account: Assets:Bank
      from: '2023-03-05'
      transactions:
      - amount: -3000.0
        category: Expenses:Shopping
        description: Refund for that damn laptop
        summary_exclude: true
        track: true
    custom:
    - account: Assets:Bank
      from: '2023-03-01'
      transactions:
      - amount: 80.0
        category: Expenses:Personal Care
        description: Hair and beauty
      frequency: every 2 weeks
      roll-up: 26
YAML

RSpec.describe 'CSV to YAML' do
  it 'converts a CSV file to the YAML file format needed for the plugin' do
    computed_yaml = HledgerForecast::CSV2YAML.convert(input)

    expect(computed_yaml).to eq(output)
  end
end
