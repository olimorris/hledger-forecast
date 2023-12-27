module HledgerForecast
  # Set the options from a user's config
  class Settings
    def self.config(forecast, cli_options)
      settings = {}
      settings[:max_amount] = 0
      settings[:max_category] = 0

      forecast.each do |row|
        if row['type'] != 'settings'
          category_length = row['category'].length
          settings[:max_category] = category_length if category_length > settings[:max_category]

          amount = if row['amount'].is_a?(Integer) || row['amount'].is_a?(Float)
                     ((row['amount'] + 3) * 100).to_s
                   else
                     row['amount'].to_s
                   end

          settings[:max_amount] = amount.length if amount.length > settings[:max_amount]
        end

        if row['type'] == 'settings'

          settings[:currency] = if row['frequency'] == "currency"
                                  row['account']
                                else
                                  "USD"
                                end

          settings[:show_symbol] = if row['frequency'] == "show_symbol"
                                     row['account']
                                   else
                                     true
                                   end

          settings[:sign_before_symbol] = if row['frequency'] == "sign_before_symbol"
                                            row['account']
                                          else
                                            false
                                          end

          settings[:thousands_separator] = if row['frequency'] == "thousands_separator"
                                             row['account']
                                           else
                                             ","
                                           end
        end

        settings.merge!(cli_options) if cli_options
      end

      settings
    end
  end
end
