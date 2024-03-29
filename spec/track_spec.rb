require_relative '../lib/hledger_forecast'

current_month = Date.new(Date.today.year, Date.today.month, 1)
previous_month = current_month.prev_month
next_month = current_month.next_month

base_config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  once,,Assets:Bank,05/03/2023,,Tax owed,Expenses:Tax,3000,,,true
  once,,Assets:Bank,05/03/2023,,Food expenses,Expenses:Food,100,,,
  once,,Assets:Bank,05/03/2023,01/08/2023,Salary,Income:Salary,-1500,,,true
  settings,currency,GBP,,,,,,,,
CSV

base_output = <<~JOURNAL
  ~ 2023-03-05  * Food expenses
      Expenses:Food    £100.00   ;  Food expenses
      Assets:Bank

  ~ #{next_month}  * [TRACKED] Tax owed
      Expenses:Tax     £3,000.00;  Tax owed
      Assets:Bank

  ~ #{next_month}  * [TRACKED] Salary
      Income:Salary    £-1,500.00;  Salary
      Assets:Bank

JOURNAL

RSpec.describe 'Tracking transactions -' do
  it 'writes a NON-FOUND entry into a journal' do
    options = {}
    options[:transaction_file] = 'spec/stubs/transactions_not_found.journal'

    generated_journal = HledgerForecast::Generator.generate(base_config, options)

    expect(generated_journal).to eq(base_output)
  end

  it 'writes a NON-FOUND entry for dates that are close to the current period' do
    require 'tempfile'

    forecast_config = <<~CSV
      type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
      once,,Assets:Bank,"#{previous_month}",,New kitchen,Expenses:House,5000,,,true
      settings,currency,GBP,,,,,,,,
    CSV

    journal = <<~JOURNAL
      #{previous_month} * Opening balance
          Assets:Bank                             £1,000.00
          Equity:Opening balance

      #{previous_month} * Mortgage payment
          Expenses:Mortgage                 £1,500.00
          Assets:Bank

      #{current_month - 10} * Groceries
          Expenses:Groceries                £1,500.00
          Assets:Bank

    JOURNAL

    temp_file = Tempfile.new('journal')
    temp_file.write(journal)
    temp_file.close

    options = {}
    options[:transaction_file] = temp_file.path

    generated_journal = HledgerForecast::Generator.generate(forecast_config, options)

    expected_output = <<~JOURNAL

      ~ #{next_month}  * [TRACKED] New kitchen
          Expenses:House    £5,000.00;  New kitchen
          Assets:Bank

    JOURNAL

    expect(generated_journal).to eq(expected_output)
  end

  it 'treats a future tracked transaction as a regular transaction' do
    forecast_config = <<~CSV
      type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
      monthly,,Assets:Bank,"#{next_month}",,Food expenses,Expenses:Food,100,,,true
      settings,currency,GBP,,,,,,,,
    CSV

    options = {}
    options[:transaction_file] = 'spec/stubs/transactions_not_found.journal'

    generated_journal = HledgerForecast::Generator.generate(forecast_config, options)

    output = <<~JOURNAL
      ~ monthly from #{next_month}  * Food expenses
          Expenses:Food    £100.00 ;  Food expenses
          Assets:Bank

    JOURNAL

    expect(generated_journal).to eq(output)
  end
end
