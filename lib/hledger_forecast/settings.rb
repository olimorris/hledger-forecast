module HledgerForecast
  # Set the options from a user's confgi
  class Settings
    def self.config(forecast, cli_options)
      settings = {}

      settings[:max_amount] = get_max_field_size(forecast, 'amount') + 1 # +1 for the negatives
      settings[:max_category] = get_max_field_size(forecast, 'category')

      settings[:currency] = Money::Currency.new(forecast.fetch('settings', {}).fetch('currency', 'USD'))
      settings[:show_symbol] = forecast.fetch('settings', {}).fetch('show_symbol', true)
      # settings[:sign_before_symbol] = forecast.fetch('settings', {}).fetch('sign_before_symbol', false)
      settings[:thousands_separator] = forecast.fetch('settings', {}).fetch('thousands_separator', true)

      settings.merge!(cli_options) if cli_options

      settings
    end

    def self.get_max_field_size(block, field)
      max_size = 0

      block.each do |period, items|
        next if %w[settings].include?(period)

        items.each do |item|
          item['transactions'].each do |t|
            field_value = if t[field].is_a?(Integer) || t[field].is_a?(Float)
                            ((t[field] + 3) * 100).to_s
                          else
                            t[field].to_s
                          end
            max_size = [max_size, field_value.length].max
          end
        end
      end

      max_size
    end
  end
end
