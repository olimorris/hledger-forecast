require_relative '../lib/hledger_forecast'

config = <<~YAML
  monthly:
    - account: "Assets:Bank"
      from: "2023-03-01"
      transactions:
        - amount: 2000.55
          category: "Expenses:Mortgage"
          description: Mortgage
          to: "=24"
        - amount: 100
          category: "Expenses:Food"
          description: Food
    - account: "Assets:Savings"
      from: "2023-03-01"
      transactions:
        - amount: -1000
          category: "Assets:Bank"
          description: Savings

  custom:
    - frequency: "every 2 weeks"
      from: "2023-05-01"
      account: "[Assets:Bank]"
      roll-up: 26
      transactions:
        - amount: 80
          category: "[Expenses:Personal Care]"
          description: Hair and beauty
    - frequency: "every 5 days"
      from: "2023-05-01"
      account: "[Assets:Checking]"
      roll-up: 73
      transactions:
        - amount: 50
          category: "[Expenses:Groceries]"
          description: Gotta feed that stomach

  settings:
    currency: GBP
YAML

RSpec.describe HledgerForecast::Summarizer do
  let(:summarizer) { described_class.new }

  describe '#generate with roll_up' do
    let(:forecast) { YAML.safe_load(config) }
    let(:cli_options) { { roll_up: 'monthly' } }

    before do
      summarizer.summarize(config, cli_options)
    end

    it 'generates the correct output' do
      output = summarizer.send(:generate, forecast)

      expect(output.first).to include(:account, :from, :to, :type, :frequency)
      expect(output.first[:amount]).to eq(2000.55)
      expect(output.last[:rolled_up_amount]).to eq(304) # ((50 * 73) / 12)
      expect(output.length).to eq(5)
    end

    it 'transaction TO date take precedence over block TO date' do
      output = summarizer.send(:generate, forecast)

      expect(output.first[:to]).to eq(Date.parse("2025-02-28"))
    end
  end

  describe '#generate' do
    let(:forecast) { YAML.safe_load(config) }
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
