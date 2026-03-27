require_relative '../lib/hledger_forecast'

RSpec.describe HledgerForecast::Formatter do
  def make_settings(overrides = {})
    rows = []
    overrides.each do |key, value|
      rows << { type: 'settings', frequency: key.to_s, account: value.to_s }
    end
    csv_rows = rows.map { |r| "settings,#{r[:frequency]},#{r[:account]},,,,,,,," }.join("\n")
    full_csv = "type,frequency,account,from,to,description,category,amount,roll_up,summary_exclude\n#{csv_rows}\n"

    parsed = CSV.parse(full_csv, headers: true, header_converters: ->(h) { h.to_s.tr('-', '_').to_sym }, converters: :numeric)
    HledgerForecast::Settings.parse(parsed.select { |r| r[:type] == 'settings' })
  end

  describe '.format_money' do
    context 'GBP with defaults' do
      let(:settings) { make_settings(currency: 'GBP') }

      it 'formats a positive amount' do
        expect(described_class.format_money(1000, settings)).to eq('£1,000.00')
      end

      it 'formats a negative amount' do
        expect(described_class.format_money(-500, settings)).to eq('£-500.00')
      end
    end

    context 'with thousands_separator disabled' do
      let(:settings) { make_settings(currency: 'USD', thousands_separator: 'false') }

      it 'omits the thousands separator' do
        expect(described_class.format_money(1000, settings)).to eq('$1000.00')
      end
    end

    context 'with no settings (all defaults)' do
      let(:settings) { make_settings }

      it 'defaults to USD' do
        expect(described_class.format_money(100, settings)).to eq('$100.00')
      end
    end
  end
end
