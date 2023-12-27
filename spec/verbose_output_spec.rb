require_relative '../lib/hledger_forecast'

output = <<~JOURNAL
  ~ monthly from 2023-03-01  * Mortgage
      Expenses:Mortgage    £2,000.55   ;  Mortgage
      Assets:Bank

  ~ monthly from 2023-03-01  * Food
      Expenses:Food        £100.00     ;  Food
      Assets:Bank

  ~ monthly from 2023-03-01  * Savings
      Assets:Bank          £-1,000.00  ;  Savings
      Assets:Savings

JOURNAL

RSpec.describe 'verbose command' do
  it 'does not group similar type transactions together in the output' do
    generated_journal = './test_output.journal'
    File.delete(generated_journal) if File.exist?(generated_journal)

    system("./bin/hledger-forecast generate -f ./spec/stubs/forecast.csv -o ./test_output.journal --verbose --force")

    expect(File.read(generated_journal)).to eq(output)
  end
end
