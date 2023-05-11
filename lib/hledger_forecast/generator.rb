module HledgerForecast
  # Generates periodic transactions from a YAML file
  class Generator
    class << self
      attr_accessor :options, :modified, :tracked
    end

    self.options = {}
    self.modified = {}
    self.tracked = {}

    @calculator = Dentaku::Calculator.new

    def self.set_options(forecast_data)
      @options[:max_amount] = get_max_field_size(forecast_data, 'amount') + 1 # +1 for the negatives
      @options[:max_category] = get_max_field_size(forecast_data, 'category')

      @options[:currency] = Money::Currency.new(forecast_data.fetch('settings', {}).fetch('currency', 'USD'))
      @options[:show_symbol] = forecast_data.fetch('settings', {}).fetch('show_symbol', true)
      # @options[:sign_before_symbol] = forecast_data.fetch('settings', {}).fetch('sign_before_symbol', false)
      @options[:thousands_separator] = forecast_data.fetch('settings', {}).fetch('thousands_separator', true)
    end

    def self.generate(yaml_file, options = nil)
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
            from = Date.parse(forecast['from'])
            to = forecast['to'] ? Date.parse(forecast['to']) : nil
            transactions = forecast['transactions']

            output += regular_transaction(frequency, from, to, transactions, account)
            output += ending_transaction(frequency, from, transactions, account)
          end
        end
      end

      # Generate tracked transactions
      if options && !options[:no_track] && !@tracked.empty?
        if options[:transaction_file]
          output += output_tracked_transaction(Tracker.track(@tracked,
                                                             options[:transaction_file]))
        else
          puts "\nWarning: ".yellow.bold + "You need to specify a transaction file with the `--t` flag for smart transactions to work\n"
        end
      end

      output += output_modified_transaction(@modified) unless @modified.empty?

      output
    end

    def self.regular_transaction(frequency, from, to, transactions, account)
      transactions = transactions.select { |transaction| transaction['to'].nil? }
      return "" if transactions.empty?

      output = ""

      transactions.each do |transaction|
        if track_transaction?(transaction, from)
          track_transaction(from, to, account, transaction)
          next
        end

        modified_transaction(from, to, account, transaction)

        output += output_transaction(transaction['category'], format_amount(calculate_amount(transaction['amount'])),
                                     transaction['description'])
      end

      return "" unless output != ""

      output = if to
                 "#{frequency} #{from} to #{to}  * #{extract_descriptions(transactions,
                                                                          from)}\n" << output
               else
                 "#{frequency} #{from}  * #{extract_descriptions(transactions, from)}\n" << output
               end

      output += "    #{account}\n\n"
      output
    end

    def self.ending_transaction(frequency, from, transactions, account)
      output = ""

      transactions.each do |transaction|
        to = transaction['to'] ? calculate_date(from, transaction['to']) : nil
        next unless to

        if track_transaction?(transaction, from)
          track_transaction(from, to, account, transaction)
          next
        end

        modified_transaction(from, to, account, transaction)

        output += "#{frequency} #{from} to #{to}  * #{transaction['description']}\n"
        output += output_transaction(transaction['category'], format_amount(calculate_amount(transaction['amount'])),
                                     transaction['description'])
        output += "    #{account}\n\n"
      end

      output
    end

    def self.custom_transaction(forecasts)
      output = ""

      forecasts.each do |forecast|
        account = forecast['account']
        from = Date.parse(forecast['from'])
        to = forecast['to'] ? Date.parse(forecast['to']) : nil
        frequency = forecast['frequency']
        transactions = forecast['transactions']

        output += "~ #{frequency} from #{from}  * #{extract_descriptions(transactions, from)}\n"

        transactions.each do |transaction|
          to = transaction['to'] ? calculate_date(from, transaction['to']) : to

          if track_transaction?(transaction, from)
            track_transaction(from, to, account, transaction)
            next
          end

          modified_transaction(from, to, account, transaction)

          output += output_transaction(transaction['category'], format_amount(calculate_amount(transaction['amount'])),
                                       transaction['description'])
        end

        output += "    #{account}\n\n"
      end

      output
    end

    def self.output_transaction(category, amount, description)
      "    #{category.ljust(@options[:max_category])}    #{amount.ljust(@options[:max_amount])};  #{description}\n"
    end

    def self.output_modified_transaction(transactions)
      output = ""

      transactions.each do |_key, transaction|
        date = "date:#{transaction['from']}"
        date += "..#{transaction['to']}" if transaction['to']

        output += "= #{transaction['category']} #{date}\n"
        output += "    #{transaction['category'].ljust(@options[:max_category])}    *#{transaction['amount'].to_s.ljust(@options[:max_amount] - 1)};  #{transaction['description']}\n"
        output += "    #{transaction['account'].ljust(@options[:max_category])}    *#{transaction['amount'] * -1}\n\n"
      end

      output
    end

    def self.output_tracked_transaction(transactions)
      output = ""

      transactions.each do |_key, transaction|
        next if transaction['found']

        output += "~ #{transaction['from']}  * [TRACKED] #{transaction['transaction']['description']}\n"
        output += "    #{transaction['transaction']['category'].ljust(@options[:max_category])}    #{transaction['transaction']['amount'].ljust(@options[:max_amount])};  #{transaction['transaction']['description']}\n"
        output += "    #{transaction['account']}\n\n"
      end

      output
    end

    def self.extract_descriptions(transactions, from)
      descriptions = []

      transactions.each do |transaction|
        next if track_transaction?(transaction, from)

        description = transaction['description']
        descriptions << description
      end

      descriptions.join(', ')
    end

    def self.modified_transaction(from, to, account, transaction)
      return unless transaction['modifiers']

      transaction['modifiers'].each do |modifier|
        description = transaction['description']
        description += ' - ' + modifier['description'] unless modifier['description'].empty?

        @modified[@modified.length] = {
          'account' => account,
          'amount' => modifier['amount'],
          'category' => transaction['category'],
          'description' => description,
          'from' => modifier['from'] ? Date.parse(modifier['from']) : (from || nil),
          'to' => modifier['to'] ? Date.parse(modifier['to']) : (to || nil)
        }
      end
    end

    def self.track_transaction?(transaction, from)
      transaction['track'] && from <= Date.today
    end

    def self.track_transaction(from, to, account, transaction)
      amount = calculate_amount(transaction['amount'])
      transaction['amount'] = format_amount(amount)
      transaction['inverse_amount'] = format_amount(amount * -1)

      @tracked[@tracked.length] = {
        'account' => account,
        'from' => from,
        'to' => to,
        'transaction' => transaction
      }
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

    def self.calculate_amount(amount)
      return amount unless amount.is_a?(String)

      @calculator.evaluate(amount.slice(1..-1))
    end

    def self.calculate_date(from, to)
      return to unless to[0] == "="

      # Subtract a day from the final date
      (from >> @calculator.evaluate(to.slice(1..-1))) - 1
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
                            ((transaction[field] + 3) * 100).to_s
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
