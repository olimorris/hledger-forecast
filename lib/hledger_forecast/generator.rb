module HledgerForecast
  # Generate periodic transactions from a YAML file, compatible with hledger
  class Generator
    class << self
      attr_accessor :options
    end

    self.options = {}

    def self.generate(forecast, options = nil)
      forecast = YAML.safe_load(forecast)
      config_options(forecast, options)

      output_block = {}
      forecast.each do |period, blocks|
        next if %w[settings].include?(period)

        blocks.each do |block|
          output_block[output_block.length] = process_block(period, block)
        end
      end

      format_to_ledger(
        HledgerForecast::Transactions::Default.generate(output_block, @options),
        HledgerForecast::Transactions::Trackers.generate(output_block, @options),
        HledgerForecast::Transactions::Modifiers.generate(output_block, @options)
      )
    end

    def self.config_options(forecast, options)
      @options[:max_amount] = get_max_field_size(forecast, 'amount') + 1 # +1 for the negatives
      @options[:max_category] = get_max_field_size(forecast, 'category')

      @options[:currency] = Money::Currency.new(forecast.fetch('settings', {}).fetch('currency', 'USD'))
      @options[:show_symbol] = forecast.fetch('settings', {}).fetch('show_symbol', true)
      # @options[:sign_before_symbol] = forecast.fetch('settings', {}).fetch('sign_before_symbol', false)
      @options[:thousands_separator] = forecast.fetch('settings', {}).fetch('thousands_separator', true)

      @options.merge!(options) if options
    end

    def self.process_block(period, block)
      output = []

      output << {
        account: block['account'],
        from: Date.parse(block['from']),
        to: block['to'] ? Date.parse(block['to']) : nil,
        type: period,
        frequency: block['frequency'],
        transactions: []
      }

      block['transactions'].each do |t|
        output.last[:transactions] << {
          category: t['category'],
          amount: Formatter.format(get_amount(t['amount']), @options),
          description: t['description'],
          to: t['to'] ? get_date(Date.parse(block['from']), t['to']) : nil,
          modifiers: t['modifiers'] ? get_modifiers(t, block) : [],
          track: track?(t, block) ? true : false
        }
      end

      output.map do |item|
        transactions = item[:transactions].group_by { |t| t[:to] }
        item.merge(transactions:)
      end
    end

    # TODO: Move this to the formatter class
    def self.format_to_ledger(*compiled_data)
      compiled_data.compact.map do |data|
        data.map do |item|
          next unless item[:transactions].any?

          item[:header] + item[:transactions].join + item[:footer]
        end.join
      end.join("\n")
    end

    def self.get_amount(amount)
      return amount unless amount.is_a?(String)

      @calculator = Dentaku::Calculator.new if @calculator.nil?

      @calculator.evaluate(amount.slice(1..-1))
    end

    def self.get_date(from, to)
      return to unless to[0] == "="

      @calculator = Dentaku::Calculator.new if @calculator.nil?

      # Subtract a day from the final date
      (from >> @calculator.evaluate(to.slice(1..-1))) - 1
    end

    def self.get_modifiers(transaction, block)
      modifiers = []

      transaction['modifiers'].each do |modifier|
        description = transaction['description']
        description += " - #{modifier['description']}" unless modifier['description'].empty?

        modifiers << {
          account: block['account'],
          amount: modifier['amount'],
          category: transaction['category'],
          description:,
          from: Date.parse(modifier['from'] || block['from']),
          to: modifier['to'] ? Date.parse(modifier['to']) : nil
        }
      end

      modifiers
    end

    def self.track?(transaction, data)
      transaction['track'] && Date.parse(data['from']) <= Date.today && Tracker.track(transaction, data, @options)
    end


    def self.get_max_field_size(forecast, field)
      max_size = 0

      forecast.each do |period, items|
        next if period == 'settings'

        items.each do |item|
          transactions = item['transactions']
          transactions.each do |t|
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
