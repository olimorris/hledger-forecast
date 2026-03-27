require_relative "../lib/hledger_forecast"

RSpec.describe HledgerForecast::Settings do
  def settings_rows_from(csv)
    CSV
      .parse(csv, headers: true, header_converters: -> (h) { h.to_s.tr("-", "_").to_sym }, converters: :numeric)
      .select { |r| r[:type] == "settings" }
  end

  describe "defaults when no settings rows are present" do
    let(:rows) {
      settings_rows_from("type,frequency,account,from,to,description,category,amount,roll_up,summary_exclude\n")
    }

    it "defaults to USD" do
      expect(described_class.parse(rows).currency).to(eq("USD"))
    end

    it "shows the currency symbol" do
      expect(described_class.parse(rows).show_symbol).to(eq(true))
    end

    it "uses a thousands separator" do
      expect(described_class.parse(rows).thousands_separator).to(eq(","))
    end

    it "is not verbose" do
      expect(described_class.parse(rows).verbose?).to(eq(false))
    end
  end

  describe "single settings row" do
    let(:rows) do
      settings_rows_from(
        <<~CSV
          type,frequency,account,from,to,description,category,amount,roll_up,summary_exclude
          settings,currency,GBP,,,,,,,,
        CSV
      )
    end

    it "applies the currency" do
      expect(described_class.parse(rows).currency).to(eq("GBP"))
    end

    it "retains other defaults" do
      settings = described_class.parse(rows)
      expect(settings.show_symbol).to(eq(true))
      expect(settings.thousands_separator).to(eq(","))
    end
  end

  describe "multiple settings rows do not clobber each other" do
    let(:rows) do
      settings_rows_from(
        <<~CSV
          type,frequency,account,from,to,description,category,amount,roll_up,summary_exclude
          settings,currency,GBP,,,,,,,,
          settings,show_symbol,false,,,,,,,,
          settings,thousands_separator,false,,,,,,,,
        CSV
      )
    end

    it "preserves all three settings independently" do
      settings = described_class.parse(rows)
      expect(settings.currency).to(eq("GBP"))
      expect(settings.show_symbol).to(eq("false"))
      expect(settings.thousands_separator).to(eq("false"))
    end
  end

  describe "cli_options take precedence over csv settings" do
    let(:rows) do
      settings_rows_from(
        <<~CSV
          type,frequency,account,from,to,description,category,amount,roll_up,summary_exclude
          settings,currency,GBP,,,,,,,,
        CSV
      )
    end

    it "overrides currency from cli" do
      expect(described_class.parse(rows, {currency: "EUR"}).currency).to(eq("EUR"))
    end
  end

  describe "cli-only options" do
    let(:rows) {
      settings_rows_from("type,frequency,account,from,to,description,category,amount,roll_up,summary_exclude\n")
    }

    it "stores verbose from cli_options" do
      expect(described_class.parse(rows, {verbose: true}).verbose?).to(eq(true))
    end

    it "stores roll_up from cli_options" do
      expect(described_class.parse(rows, {roll_up: "monthly"}).roll_up).to(eq("monthly"))
    end
  end
end
