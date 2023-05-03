module HledgerForecast
  # Generates periodic transactions from a YAML file
  class Generator
    class << self
      attr_accessor :options, :tracked
    end

    self.options = {}
    self.tracked = {}

    def self.set_options(forecast_data)
      @options[:max_amount] = get_max_field_size(forecast_data, 'amount')
      @options[:max_category] = get_max_field_size(forecast_data, 'category')

      @options[:currency] = Money::Currency.new(forecast_data.fetch('settings', {}).fetch('currency', 'USD'))
      @options[:show_symbol] = forecast_data.fetch('settings', {}).fetch('show_symbol', true)
      # @options[:sign_before_symbol] = forecast_data.fetch('settings', {}).fetch('sign_before_symbol', false)
      @options[:thousands_separator] = forecast_data.fetch('settings', {}).fetch('thousands_separator', true)
    end

    def self.generate(yaml_file, _options = nil)
      forecast_data = YAML.safe_load(yaml_file)

      set_options(forecast_data)

      output = ""

      # Generate regular transactions
      forecast_data.each do |period, forecasts|
        if period == 'custom'
          output += custom_transaction(forecasts)
        else
          frequency = convert_period_to_frequency(period)
          next unless frequency

          forecasts.each do |forecast|
            account = forecast['account']
            start_date = Date.parse(forecast['from'])
            end_date = forecast['to'] ? Date.parse(forecast['to']) : nil
            transactions = forecast['transactions']

            output += regular_transaction(frequency, start_date, end_date, transactions, account)
            output += ending_transaction(frequency, start_date, transactions, account)
          end
        end
      end

      # Generate tracked transactions
      if _options && !_options[:no_track] && !@tracked.empty?
        if _options[:transaction_file]
          output += output_tracked_transaction(Tracker.track(@tracked,
                                                             _options[:transaction_file]))
        else
        puts "\nWarning: ".yellow.bold + "You need to specify a transaction file with the `--t` flag for smart transactions to work\n"
        end
      end

      output
    end

    def self.regular_transaction(frequency, start_date, end_date, transactions, account)
      transactions = transactions.select { |transaction| transaction['to'].nil? }
      return "" if transactions.empty?

      output = ""

      transactions.each do |transaction|
        if track_transaction?(transaction, start_date)
          track_transaction(start_date, end_date, account, transaction)
          next
        end

        output += output_amount(transaction['category'], format_amount(transaction['amount']),
                                transaction['description'])
      end

      return "" unless output != ""

      output = if end_date
                 "#{frequency} #{start_date} to #{end_date}  * #{extract_descriptions(transactions,
                                                                                      start_date)}\n" << output
               else
                 "#{frequency} #{start_date}  * #{extract_descriptions(transactions, start_date)}\n" << output
               end

      output += "    #{account}\n\n"
      output
    end

    def self.ending_transaction(frequency, start_date, transactions, account)
      output = ""

      transactions.each do |transaction|
        end_date = transaction['to'] ? Date.parse(transaction['to']) : nil
        next unless end_date

        if track_transaction?(transaction, start_date)
          track_transaction(start_date, end_date, account, transaction)
          next
        end

        output += "#{frequency} #{start_date} to #{end_date}  * #{transaction['description']}\n"
        output += output_amount(transaction['category'], format_amount(transaction['amount']),
                                transaction['description'])
        output += "    #{account}\n\n"
      end

      output
    end

    def self.custom_transaction(forecasts)
      output = ""

      forecasts.each do |forecast|
        account = forecast['account']
        start_date = Date.parse(forecast['from'])
        end_date = forecast['to'] ? Date.parse(forecast['to']) : nil
        frequency = forecast['frequency']
        transactions = forecast['transactions']

        output += "~ #{frequency} from #{start_date}  * #{extract_descriptions(transactions, start_date)}\n"

        transactions.each do |transaction|
          end_date = transaction['to'] ? Date.parse(transaction['to']) : end_date

          if track_transaction?(transaction, start_date)
            track_transaction(start_date, end_date, account, transaction)
            next
          end

          output += output_amount(transaction['category'], format_amount(transaction['amount']),
                                  transaction['description'])
        end

        output += "    #{account}\n\n"
      end

      output
    end

    def self.output_amount(category, amount, description)
      "    #{category.ljust(@options[:max_category])}    #{amount.ljust(@options[:max_amount])};  #{description}\n"
    end

    def self.output_tracked_transaction(transactions)
      output = ""

      transactions.each do |_key, transaction|
        output += "~ #{transaction['start']}  * [TRACKED] #{transaction['transaction']['description']}\n"
        output += "    #{transaction['transaction']['category'].ljust(@options[:max_category])}    #{transaction['transaction']['amount'].ljust(@options[:max_amount])};  #{transaction['transaction']['description']}\n"
        output += "    #{transaction['account']}\n\n"
      end

      output
    end

    def self.extract_descriptions(transactions, start_date)
      descriptions = []

      transactions.each do |transaction|
        next if track_transaction?(transaction, start_date)

        description = transaction['description']
        descriptions << description
      end

      descriptions.join(', ')
    end

    def self.track_transaction?(transaction, start_date)
      transaction['track'] && start_date < Date.today
    end

    def self.track_transaction(start_date, end_date, account, transaction)
      amount = transaction['amount']
      transaction['amount'] = format_amount(amount)
      transaction['inverse_amount'] = format_amount(amount * -1)

      @tracked[@tracked.length] =
        { 'account' => account, 'start' => start_date, 'end' => end_date, 'transaction' => transaction }
    end

    def self.convert_period_to_frequency(period)
      map = {
        'once' => '~',
        'monthly' => '~ monthly from',
        'quarterly' => '~ every 3 months from',
        'half-yearly' => '~ every 6 months from',
        'yearly' => '~ yearly from'
      }

      map[period]
    end

    def self.format_amount(amount)
      Money.from_cents(amount.to_f * 100, @options[:currency]).format(
        symbol: @options[:show_symbol],
        sign_before_symbol: @options[:sign_before_symbol],
        thousands_separator: @options[:thousands_separator] ? ',' : nil
      )
    end

    def self.get_max_field_size(forecast_data, field)
      max_size = 0

      forecast_data.each do |period, forecasts|
        next if period == 'settings'

        forecasts.each do |forecast|
          transactions = forecast['transactions']
          transactions.each do |transaction|
            field_value = if transaction[field].is_a?(Integer) || transaction[field].is_a?(Float)
                            ((transaction[field] + 2) * 100).to_s
                          else
                            transaction[field].to_s
                          end
            max_size = [max_size, field_value.length].max
          end
        end
      end

      max_size
    end
  end
end
