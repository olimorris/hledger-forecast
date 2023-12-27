require_relative '../lib/hledger_forecast'

output = <<~JOURNAL
  ~ monthly from 2023-03-01  * Mortgage, Food
      Expenses:Mortgage    £2,000.55   ;  Mortgage
      Expenses:Food        £100.00     ;  Food
      Assets:Bank

  ~ monthly from 2023-03-01  * Savings
      Assets:Bank          £-1,000.00  ;  Savings
      Assets:Savings

JOURNAL

def strip_ansi_codes(str)
  str.gsub(/\e\[([;\d]+)?m/, "")
end

def capture_stdout
  old_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end

RSpec.describe 'command' do
  it 'uses the CLI to generate an output with a CSV config file' do
    generated_journal = './test_output.journal'
    File.delete(generated_journal) if File.exist?(generated_journal)

    system("./bin/hledger-forecast generate -f ./spec/stubs/forecast.csv -o ./test_output.journal --force")

    expect(File.read(generated_journal)).to eq(output)
  end

  it 'uses the CLI to compare two CSV files' do
    expected_output = strip_ansi_codes(<<~OUTPUT)
      +---------+---------+---------+
      | account | 2023-07 | 2023-08 |
      +---------+---------+---------+
      | total   | £10.00  | €-10.00 |
      +---------+---------+---------+

    OUTPUT

    actual_output = `./bin/hledger-forecast compare ./spec/stubs/output1.csv ./spec/stubs/output2.csv`

    expect(strip_ansi_codes(actual_output)).to eq(expected_output)
  end
end
