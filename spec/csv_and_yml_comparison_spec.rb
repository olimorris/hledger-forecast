require_relative '../lib/hledger_forecast'

RSpec.describe 'CSV and yml outputs' do
  it 'should return the same value when ran through hledger' do
    generated_journal = './test_output.journal'
    File.delete(generated_journal) if File.exist?(generated_journal)

    system("./bin/hledger-forecast generate -f ./spec/stubs/csv_and_yml/forecast.csv -o ./test_output.journal --force > /dev/null 2>&1")
    csv_output = `hledger -f ./test_output.journal --forecast bal -b=2023-01 -e=2023-06`

    system("./bin/hledger-forecast generate -f ./spec/stubs/csv_and_yml/forecast.yml -o ./test_output.journal --force > /dev/null 2>&1")
    yml_output = `hledger -f ./test_output.journal --forecast bal -b=2023-01 -e=2023-06`

    expect(csv_output).to eq(yml_output)
  end

  it 'check that it can fail!' do
    generated_journal = './test_output.journal'
    File.delete(generated_journal) if File.exist?(generated_journal)

    system("./bin/hledger-forecast generate -f ./spec/stubs/csv_and_yml/forecast.csv -o ./test_output.journal --force > /dev/null 2>&1")

    ### CHANGE DATE!!!!!!!!!!!!!!!!
    csv_output = `hledger -f ./test_output.journal --forecast bal -b=2023-01 -e=2023-03`

    system("./bin/hledger-forecast generate -f ./spec/stubs/csv_and_yml/forecast.yml -o ./test_output.journal --force > /dev/null 2>&1")
    yml_output = `hledger -f ./test_output.journal --forecast bal -b=2023-01 -e=2023-06`

    expect(csv_output).not_to eq(yml_output)
  end
end
