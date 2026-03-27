require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude
  monthly,,Assets:Bank,01/03/2023,=24,Mortgage,Expenses:Mortgage,2000.55,,
  monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,100,,
  monthly,,Assets:Savings,01/03/2023,,Savings,Assets:Bank,-1000,,
  custom,every 2 weeks,[Assets:Bank],01/05/2023,,Hair and beauty,[Expenses:Personal Care],80,26,
  custom,every 2 weeks,[Assets:Checking],01/05/2023,,Extra Food,[Expenses:Groceries],50,73,
  settings,currency,GBP,,,,,,,,
CSV

RSpec.describe HledgerForecast::Summarizer do
  describe '#summarize with roll_up' do
    let(:result) { described_class.summarize(config, { roll_up: 'monthly' }) }
    let(:output) { result[:output] }

    it 'includes the expected summary keys' do
      expect(output.first).to include(:account, :from, :to, :type, :frequency)
    end

    it 'returns the raw amount on each row' do
      expect(output.first[:amount]).to eq(2000.55)
    end

    it 'calculates rolled_up_amount for custom transactions' do
      expect(output.last[:rolled_up_amount]).to eq((50.0 * 73.0) / 12.0)
    end

    it 'returns a row for each non-excluded transaction' do
      expect(output.length).to eq(5)
    end

    it 'uses the calculated TO date from the CSV formula' do
      expect(output.first[:to]).to eq(Date.parse("2025-02-28"))
    end
  end

  describe '#summarize without roll_up' do
    let(:output) { described_class.summarize(config)[:output] }

    it 'returns a row for each non-excluded transaction' do
      expect(output.length).to eq(5)
    end

    it 'includes annualised_amount' do
      expect(output.first).to have_key(:annualised_amount)
    end
  end
end
