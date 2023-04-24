require_relative '../lib/hledger_forecast'

RSpec.describe 'command' do
  it 'uses the CLI to generate an output' do
    # Delete the file if it exists
    generated_journal = './test_output.journal'
    File.delete(generated_journal) if File.exist?(generated_journal)

    system("./bin/hledger-forecast generate -t ./spec/stubs/transactions.journal -f ./spec/stubs/monthly/forecast_monthly.yml -o ./test_output.journal -s 2023-03-01 -e 2023-05-30 --force")

    expected_output = File.read('spec/stubs/monthly/output_monthly.journal')

    expect(File.read(generated_journal)).to eq(expected_output)
  end
end
