require_relative "../lib/hledger_forecast"

EXPORT_CONFIG = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude
  monthly,,Assets:Bank,01/03/2023,01/03/2025,Mortgage,Expenses:Mortgage,2000.555,,
  monthly,,Assets:Bank,01/03/2023,,"Food, drink",Expenses:Food,100,,
  custom,every 2 weeks,Assets:Bank,01/05/2023,,Hair,Expenses:Personal Care,80,26,
  settings,currency,GBP,,,,,,,,
CSV

RSpec.describe HledgerForecast::SummarizerExporter do
  def exported(options = {})
    summary = HledgerForecast::Summarizer.summarize(EXPORT_CONFIG, options)
    CSV.parse(described_class.export(summary[:output], summary[:settings]), headers: true)
  end

  it "writes a header row mirroring the forecast columns" do
    expect(exported.headers).to(
      eq(%w[type frequency account from to description category amount annualised_amount])
    )
  end

  it "writes a row per transaction" do
    expect(exported.length).to(eq(3))
  end

  it "formats dates as ISO 8601" do
    expect(exported[0]["from"]).to(eq("2023-03-01"))
    expect(exported[0]["to"]).to(eq("2025-03-01"))
  end

  it "leaves an open-ended TO date blank" do
    expect(exported[1]["to"]).to(be_nil)
  end

  it "rounds amounts to two decimal places" do
    expect(exported[0]["amount"]).to(eq("2000.56"))
  end

  it "writes amounts without currency formatting" do
    expect(exported[0]["annualised_amount"]).to(eq("24006.66"))
  end

  it "quotes fields containing a comma" do
    expect(exported[1]["description"]).to(eq("Food, drink"))
  end

  it "adds a rolled_up_amount column when rolling up" do
    rolled = exported({roll_up: "monthly"})

    expect(rolled.headers).to(include("rolled_up_amount"))
    expect(rolled[2]["rolled_up_amount"]).to(eq(((80.0 * 26) / 12).round(2).to_s))
  end

  it "omits the rolled_up_amount column without a roll-up" do
    expect(exported.headers).not_to(include("rolled_up_amount"))
  end

  it "only exports rows that survived the filters" do
    expect(exported({from: Date.new(2026, 1, 1)}).map { |r| r["description"] }).to(eq(["Food, drink", "Hair"]))
  end
end
