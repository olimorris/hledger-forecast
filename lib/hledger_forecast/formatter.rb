module HledgerForecast
  # Formats various items used throughout the application
  class Formatter
    def self.format_money(amount, settings)
      Money.from_cents(amount.to_f * 100, (settings[:currency]) || 'USD').format(
        symbol: settings[:show_symbol] || true,
        sign_before_symbol: settings[:sign_before_symbol] || false,
        thousands_separator: settings[:thousands_separator] ? ',' : nil
      )
    end

    def self.output_to_ledger(*compiled_data)
      output = compiled_data.compact.map do |data|
        data.map do |item|
          next unless item[:transactions].any?

          item[:header] + item[:transactions].join + item[:footer]
        end.join
      end.join("\n")

      output.gsub(/\n{2,}/, "\n\n")
    end
  end
end
