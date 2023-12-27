require_relative '../lib/hledger_forecast'

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,track
  monthly,,Assets:Bank,01/03/2023,=24,Mortgage,Expenses:Mortgage,2000.55,,,
  monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,100,,,
  monthly,,Assets:Savings,01/03/2023,,Savings,Assets:Bank,-1000,,,
  custom,every 2 weeks,[Assets:Bank],01/05/2023,,Hair and beauty,[Expenses:Personal Care],80,26,,
  custom,every 2 weeks,[Assets:Checking],01/05/2023,,Extra Food,[Expenses:Groceries],50,73,,
  settings,currency,GBP,,,,,,,,
CSV

RSpec.describe HledgerForecast::Summarizer do
  let(:summarizer) { described_class.new }

  describe '#generate with roll_up' do
    let(:forecast) { CSV.parse(config, headers: true) }
    let(:cli_options) { { roll_up: 'monthly' } }

    before do
      summarizer.summarize(config, cli_options)
    end

    it 'generates the correct output' do
      output = summarizer.send(:generate, forecast)

      expect(output.first).to include(:account, :from, :to, :type, :frequency)
      expect(output.first[:amount]).to eq(2000.55)
      expect(output.last[:rolled_up_amount]).to eq((50.0 * 73.0) / 12.0) # ((50 * 73) / 12)
      expect(output.length).to eq(5)
    end

    it 'transaction TO date take precedence over block TO date' do
      output = summarizer.send(:generate, forecast)

      expect(output.first[:to]).to eq(Date.parse("2025-02-28"))
    end
  end

  describe '#generate' do
    let(:forecast) { CSV.parse(config, headers: true) }
    let(:cli_options) { nil }

    before do
      summarizer.summarize(config, cli_options)
    end

    it 'generates the correct output' do
      output = summarizer.send(:generate, forecast)

      # expect(output.first).to include(:account, :from, :to, :type, :frequency)
      expect(output.length).to eq(5)
    end
  end
end
