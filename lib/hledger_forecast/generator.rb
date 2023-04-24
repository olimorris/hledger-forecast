module HledgerForecast
  class Generator
    class << self
      attr_accessor :settings
    end

    self.settings = {}

    def self.configure_settings(forecast_data)
      @settings[:currency] = Money::Currency.new(forecast_data.fetch('settings', {}).fetch('currency', 'USD'))
      @settings[:show_symbol] = forecast_data.fetch('settings', {}).fetch('show_symbol', true)
      @settings[:sign_before_symbol] = forecast_data.fetch('settings', {}).fetch('sign_before_symbol', true)
      @settings[:thousands_separator] = forecast_data.fetch('settings', {}).fetch('thousands_separator', true)
    end

    def self.format_amount(amount)
      Money.from_cents(amount.to_f * 100, @settings[:currency]).format(
        symbol: @settings[:show_symbol],
        sign_before_symbol: @settings[:sign_before_symbol],
        thousands_separator: @settings[:thousands_separator] ? ',' : nil
      )
    end

    def self.generate(yaml_content)
      forecast_data = YAML.safe_load(yaml_content)

      configure_settings(forecast_data)

      output = ""

      forecast_data.each do |period, forecasts|
        if period == 'custom'
          output += custom_transaction(forecasts)
        else
          interval = convert_period_to_interval(period)
          next unless interval

          forecasts.each do |forecast|
            account = forecast['account']
            start_date = Date.parse(forecast['start'])
            end_date = forecast['end'] ? Date.parse(forecast['end']) : nil
            transactions = forecast['transactions']

            output += regular_transaction(interval, start_date, end_date, transactions, account)
            output += time_bound_transaction(interval, start_date, transactions, account)
          end
        end
      end

      output
    end

    def self.regular_transaction(interval, start_date, end_date, transactions, account)
      transactions = transactions.select { |transaction| transaction['end'].nil? }
      return "" if transactions.empty?

      output = if end_date
                 "#{interval} from #{start_date} to #{end_date}\n"
               else
                 "#{interval} from #{start_date}\n"
               end

      transactions.each do |transaction|
        amount = format_amount(transaction['amount'])
        category = transaction['category']
        description = transaction['description']

        output += "    #{category}            #{amount};  #{description}\n"
      end

      output += "    #{account}\n\n"
      output
    end

    def self.time_bound_transaction(interval, start_date, transactions, account)
      output = ""

      transactions.each do |transaction|
        end_date = transaction['end'] ? Date.parse(transaction['end']) : nil
        next unless end_date

        amount = format_amount(transaction['amount'])
        category = transaction['category']
        description = transaction['description']

        output += "#{interval} from #{start_date} to #{end_date}\n"
        output += "    #{category}            #{amount};  #{description}\n"
        output += "    #{account}\n\n"
      end

      output
    end

    def self.custom_transaction(forecasts)
      output = ""

      forecasts.each do |forecast|
        account = forecast['account']
        start_date = Date.parse(forecast['start'])
        frequency = forecast['frequency']
        transactions = forecast['transactions']

        output += "~ #{frequency} from #{start_date}\n"

        transactions.each do |transaction|
          amount = format_amount(transaction['amount'])
          category = transaction['category']
          description = transaction['description']

          output += "    #{category}            #{amount};  #{description}\n"
        end

        output += "    #{account}\n\n"
      end

      output
    end

    def self.convert_period_to_interval(period)
      map = {
        'once' => '~',
        'monthly' => '~ every month',
        'quarterly' => '~ every 3 months',
        'half-yearly' => '~ every 6 months',
        'yearly' => '~ every year'
      }

      map[period]
    end
  end
end
