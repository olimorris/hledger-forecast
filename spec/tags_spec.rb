require_relative "../lib/hledger_forecast"

config = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,tag
  monthly,,Assets:Bank,01/03/2023,,Salary,Income:Salary,-3500,,,fixed|essential
  monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,500,,,living|essential
  monthly,,Assets:Bank,01/03/2023,,Netflix,Expenses:Subscriptions,15,,,living
  settings,currency,GBP,,,,,,,,
CSV

config_without_tags = <<~CSV
  type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude,tag
  monthly,,Assets:Bank,01/03/2023,,Salary,Income:Salary,-3500,,,
  monthly,,Assets:Bank,01/03/2023,,Food,Expenses:Food,500,,,
  settings,currency,GBP,,,,,,,,
CSV

RSpec.describe "tags" do
  it "outputs hledger tags in posting comments" do
    expected = <<~JOURNAL
      ~ monthly from 2023-03-01  * Salary, Food, Netflix
          Income:Salary             £-3,500.00;  fixed:, essential:
          Expenses:Food             £500.00   ;  living:, essential:
          Expenses:Subscriptions    £15.00    ;  living:
          Assets:Bank

    JOURNAL

    expect(HledgerForecast::Generator.generate(config)).to(eq(expected))
  end

  it "omits comments when no tags are present" do
    expected = <<~JOURNAL
      ~ monthly from 2023-03-01  * Salary, Food
          Income:Salary    £-3,500.00
          Expenses:Food    £500.00
          Assets:Bank

    JOURNAL

    expect(HledgerForecast::Generator.generate(config_without_tags)).to(eq(expected))
  end

  it "filters transactions by a single tag" do
    expected = <<~JOURNAL
      ~ monthly from 2023-03-01  * Food, Netflix
          Expenses:Food             £500.00;  living:, essential:
          Expenses:Subscriptions    £15.00 ;  living:
          Assets:Bank

    JOURNAL

    expect(HledgerForecast::Generator.generate(config, {tags: ["living"]})).to(eq(expected))
  end

  it "filters transactions by multiple tags (OR logic)" do
    expected = <<~JOURNAL
      ~ monthly from 2023-03-01  * Salary, Food
          Income:Salary    £-3,500.00;  fixed:, essential:
          Expenses:Food    £500.00   ;  living:, essential:
          Assets:Bank

    JOURNAL

    expect(HledgerForecast::Generator.generate(config, {tags: ["fixed", "essential"]})).to(eq(expected))
  end

  it "filters summarizer output by tags" do
    result = HledgerForecast::Summarizer.summarize(config, {tags: ["living"]})
    descriptions = result[:output].map { |r| r[:description] }

    expect(descriptions).to(eq(["Food", "Netflix"]))
  end

  it "raises an error when --tags is used on a CSV without a tag column" do
    csv_without_tag_column = <<~CSV
      type,frequency,account,from,to,description,category,amount,roll-up,summary_exclude
      monthly,,Assets:Bank,01/03/2023,,Salary,Income:Salary,-3500,,
      settings,currency,GBP,,,,,,,,
    CSV

    expect {
      HledgerForecast::Generator.generate(csv_without_tag_column, {tags: ["fixed"]})
    }
      .to(raise_error(RuntimeError, /tag.*column/i))

    expect {
      HledgerForecast::Summarizer.summarize(csv_without_tag_column, {tags: ["fixed"]})
    }
      .to(raise_error(RuntimeError, /tag.*column/i))
  end
end
