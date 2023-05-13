module HledgerForecast
  # Formats various items used throughout the application
  class Formatter
    def self.format(amount, options)
      Money.from_cents(amount.to_f * 100, (options[:currency]) || 'USD').format(
        symbol: options[:show_symbol] || true,
        sign_before_symbol: options[:sign_before_symbol] || false,
        thousands_separator: options[:thousands_separator] ? ',' : nil
      )
    end
  end
end
