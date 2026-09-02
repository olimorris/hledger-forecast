require_relative "../lib/hledger_forecast"

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
  describe "#summarize with roll_up" do
    let(:result) { described_class.summarize(config, {roll_up: "monthly"}) }
    let(:output) { result[:output] }

    it "includes the expected summary keys" do
      expect(output.first).to(include(:account, :from, :to, :type, :frequency))
    end

    it "returns the raw amount on each row" do
      expect(output.first[:amount]).to(eq(2000.55))
    end

    it "calculates rolled_up_amount for custom transactions" do
      expect(output.last[:rolled_up_amount]).to(eq((50.0 * 73.0) / 12.0))
    end

    it "returns a row for each non-excluded transaction" do
      expect(output.length).to(eq(5))
    end

    it "uses the calculated TO date from the CSV formula" do
      expect(output.first[:to]).to(eq(Date.parse("2025-02-28")))
    end
  end

  describe "#summarize without roll_up" do
    let(:output) { described_class.summarize(config)[:output] }

    it "returns a row for each non-excluded transaction" do
      expect(output.length).to(eq(5))
    end

    it "includes annualised_amount" do
      expect(output.first).to(have_key(:annualised_amount))
    end
  end
end

FILTER_CONFIG = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude
  monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,100,,
  monthly,,Assets:Bank,01/03/2023,01/01/2025,Mortgage,Expenses:Mortgage,2000,,
  yearly,,Assets:Bank,01/04/2023,01/06/2028,Insurance,Expenses:Insurance,500,,
  once,,Assets:Bank,05/03/2023,,Laptop refund,Expenses:Shopping,-3000,,
  once,,Assets:Bank,05/03/2029,,New car,Expenses:Car,10000,,
CSV

RSpec.describe HledgerForecast::Summarizer do
  def descriptions(options)
    described_class.summarize(FILTER_CONFIG, options)[:output].map { |r| r[:description] }
  end

  describe "#summarize with exclude_once" do
    it "removes one-off transactions" do
      expect(descriptions({exclude_once: true})).to(eq(["Food", "Mortgage", "Insurance"]))
    end

    it "keeps them by default" do
      expect(descriptions({})).to(include("Laptop refund", "New car"))
    end
  end

  describe "#summarize with from" do
    it "keeps transactions that are still running" do
      expect(descriptions({from: Date.new(2027, 9, 1)})).to(eq(["Food", "Insurance", "New car"]))
    end

    it "drops a one-off that has already happened" do
      expect(descriptions({from: Date.new(2023, 4, 1)})).not_to(include("Laptop refund"))
    end

    it "drops a transaction that ends before the date" do
      expect(descriptions({from: Date.new(2028, 7, 1)})).to(eq(["Food", "New car"]))
    end

    it "combines with exclude_once" do
      expect(descriptions({from: Date.new(2027, 9, 1), exclude_once: true})).to(eq(["Food", "Insurance"]))
    end
  end
end
