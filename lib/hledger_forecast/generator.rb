module HledgerForecast
  # Generates journal entries based on a YAML forecast file.
  # on forecast data and optional existing transactions.
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

    def self.write_transactions(output, date, account, transaction)
      output.concat("#{date} * #{transaction['description']}\n")
      output.concat("    #{transaction['category']}                #{transaction['amount']}\n")
      output.concat("    #{account}\n\n")
    end

    def self.format_transaction(transaction)
      formatted_transaction = transaction.clone

      formatted_transaction['amount'] =
        Money.from_cents(formatted_transaction['amount'].to_f * 100, @settings[:currency]).format(
          symbol: @settings[:show_symbol],
          sign_before_symbol: @settings[:sign_before_symbol],
          thousands_separator: @settings[:thousands_separator] ? ',' : nil
        )

      formatted_transaction
    end

    def self.process_custom(output, forecast_data, date)
      forecast_data['custom']&.each do |forecast|
        start_date = Date.parse(forecast['start'])
        end_date = forecast['end'] ? Date.parse(forecast['end']) : nil
        account = forecast['account']
        period = forecast['recurrence']['period']
        quantity = forecast['recurrence']['quantity']

        next if end_date && date > end_date

        date_matches = case period
                       when 'days'
                         (date - start_date).to_i % quantity == 0
                       when 'weeks'
                         (date - start_date).to_i % (quantity * 7) == 0
                       when 'months'
                         ((date.year * 12 + date.month) - (start_date.year * 12 + start_date.month)) % quantity == 0 && date.day == start_date.day
                       end

        if date_matches
          forecast['transactions'].each do |transaction|
            end_date = transaction['end'] ? Date.parse(transaction['end']) : nil

            next unless end_date.nil? || date <= end_date

            write_transactions(output, date, account, format_transaction(transaction))
          end
        end
      end
    end

    def self.process_forecast(output_file, forecast_data, type, date)
      forecast_data[type]&.each do |forecast|
        start_date = Date.parse(forecast['start'])
        end_date = forecast['end'] ? Date.parse(forecast['end']) : nil
        account = forecast['account']

        next if end_date && date > end_date

        date_matches = case type
                       when 'monthly'
                         date.day == start_date.day
                       when 'quarterly'
                         date.day == start_date.day && date.month % 3 == start_date.month % 3
                       when 'half-yearly'
                         date.day == start_date.day && (date.month - start_date.month) % 6 == 0
                       when 'yearly'
                         date.day == start_date.day && date.month == start_date.month
                       when 'once'
                         date == start_date
                       end

        if date_matches
          forecast['transactions'].each do |transaction|
            transaction_start_date = transaction['start'] ? Date.parse(transaction['start']) : nil
            transaction_end_date = transaction['end'] ? Date.parse(transaction['end']) : nil

            if (transaction_start_date && date < transaction_start_date) || (transaction_end_date && date > transaction_end_date)
              next
            end

            write_transactions(output_file, date, account, format_transaction(transaction))
          end
        end
      end
    end

    def self.create_journal_entries(transactions, forecast, start_date, end_date)
      start_date = Date.parse(start_date)
      end_date = Date.parse(end_date)
      forecast_data = YAML.safe_load(forecast)

      configure_settings(forecast_data)

      output = ''
      output.concat(transactions) if transactions

      date = start_date

      while date <= end_date
        process_forecast(output, forecast_data, 'monthly', date)
        process_forecast(output, forecast_data, 'quarterly', date)
        process_forecast(output, forecast_data, 'half-yearly', date)
        process_forecast(output, forecast_data, 'yearly', date)
        process_forecast(output, forecast_data, 'once', date)
        process_custom(output, forecast_data, date)

        date = date.next_day
      end

      output
    end
  end
end
