require_relative "../lib/hledger_forecast"

RSpec.describe HledgerForecast::Calculator do
  describe ".evaluate" do
    it "returns a float for an integer" do
      expect(described_class.evaluate(250)).to(eq(250.0))
    end

    it "returns a float for a float" do
      expect(described_class.evaluate(99.5)).to(eq(99.5))
    end

    it "evaluates a division formula" do
      expect(described_class.evaluate("=5000/24")).to(be_within(0.01).of(208.33))
    end

    it "evaluates a multiplication formula" do
      expect(described_class.evaluate("=25*4.3")).to(be_within(0.01).of(107.5))
    end

    it "evaluates a compound expression" do
      expect(described_class.evaluate("=(102.50+3.25)/2")).to(be_within(0.01).of(52.875))
    end
  end

  describe ".evaluate_from_date" do
    it "parses a plain date string" do
      expect(described_class.evaluate_from_date("01/09/2022")).to(eq(Date.parse("2022-09-01")))
    end

    it "evaluates a date with a month offset" do
      expect(described_class.evaluate_from_date("=01/09/2022+6")).to(eq(Date.parse("2023-03-01")))
    end

    it "evaluates a date with a multiplied offset" do
      expect(described_class.evaluate_from_date("=01/09/2022+(5*12)")).to(eq(Date.parse("2027-09-01")))
    end

    it "evaluates a formula with no offset" do
      expect(described_class.evaluate_from_date("=01/09/2022")).to(eq(Date.parse("2022-09-01")))
    end
  end

  describe ".evaluate_date" do
    let(:from) { Date.parse("2023-03-01") }

    it "parses a plain date string" do
      expect(described_class.evaluate_date(from, "2023-06-01")).to(eq(Date.parse("2023-06-01")))
    end

    it "calculates N months forward and subtracts one day" do
      expect(described_class.evaluate_date(from, "=12")).to(eq(Date.parse("2024-02-29")))
    end

    it "handles a 6-month offset" do
      expect(described_class.evaluate_date(from, "=6")).to(eq(Date.parse("2023-08-31")))
    end

    it "handles a 24-month offset" do
      expect(described_class.evaluate_date(from, "=24")).to(eq(Date.parse("2025-02-28")))
    end

    it "handles dates with a +" do
      expect(described_class.evaluate_date(from, "+24")).to(eq(Date.parse("2025-02-28")))
    end

    it "handles a numeric offset (CSV numeric converter coerces +N to integer)" do
      expect(described_class.evaluate_date(from, 24)).to(eq(Date.parse("2025-02-28")))
    end
  end
end
