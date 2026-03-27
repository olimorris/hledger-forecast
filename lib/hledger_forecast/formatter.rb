module HledgerForecast
  class Formatter
    def self.format_money(amount, settings)
      Money.from_cents(amount.to_f * 100, settings.currency).format(
        symbol: settings.show_symbol,
        sign_before_symbol: settings.sign_before_symbol,
        thousands_separator: resolve_separator(settings.thousands_separator)
      )
    end

    private_class_method def self.resolve_separator(value)
      case value
      when "false", false, nil
        nil
      when "true", true
        ","
      else
        value
      end
    end
  end
end
