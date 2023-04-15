require_relative '../lib/hledger_forecast'

RSpec.describe 'command' do
  it 'uses the CLI to generate an output' do
    system("./bin/hledger-forecast -t ./spec/stubs/transactions.journal -f ./spec/stubs/monthly/forecast_monthly.yml -o ./test_output.journal -s 2023-03-01 -e 2023-05-30 --force")

    expected_output = File.read('spec/stubs/monthly/output_monthly.journal')
    generated_journal = File.read('./test_output.journal')

    expect(generated_journal).to eq(expected_output)
  end
end
