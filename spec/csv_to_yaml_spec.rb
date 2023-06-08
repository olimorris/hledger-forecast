require_relative '../lib/hledger_forecast'

input = <<~CSV
  frequency,account,from,to,description,category,amount,summary_exclude,track
  monthly,Assets:Bank,2023-03-01,,Salary,Income:Salary,-3500,,
  monthly,Assets:Bank,2023-03-01,01/01/2025,Mortgage,Expenses:Mortgage,2000,,
  monthly,Assets:Bank,2023-03-01,,Bills,Expenses:Bills,175,,
  monthly,Assets:Bank,2023-03-01,,Food,Expenses:Food,500,,
  monthly,Assets:Bank,2023-03-01,2025-01-01,Rainy day fund,Assets:Savings,300,,
  monthly,Assets:Pension,2024-01-01,,Pension draw down,Income:Pension,-500,,
CSV

output = <<~YAML
  monthly:
  - account: Assets:Bank
    from: '2023-03-01'
    transactions:
    - amount: -3500
      category: Income:Salary
      description: Salary
    - amount: 2000
      category: Expenses:Mortgage
      description: Mortgage
      to: '2025-01-01'
    - amount: 175
      category: Expenses:Bills
      description: Bills
    - amount: 500
      category: Expenses:Food
      description: Food
    - amount: 300
      category: Assets:Savings
      description: Rainy day fund
      to: '2025-01-01'
  - account: Assets:Pension
    from: '2024-01-01'
    transactions:
    - amount: -500
      category: Income:Pension
      description: Pension draw down
YAML

RSpec.describe 'CSV to YAML' do
  it 'converts a CSV file to the YAML file format needed for the plugin' do
    computed_yaml = HledgerForecast::CSV2YAML.convert(input)

    expect(computed_yaml).to eq(output)
  end
end
