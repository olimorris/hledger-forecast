module HledgerForecast
  # Generate periodic transactions from a YAML file, compatible with hledger
  class Generator
    def self.generate(forecast, options = nil)
      new.generate(forecast, options)
    end

    def generate(forecast, options = nil)
      forecast = YAML.safe_load(forecast)
      config_options(forecast, options)

      output_block = {}
      forecast.each do |period, blocks|
        next if %w[settings].include?(period)

        blocks.each do |block|
          output_block[output_block.length] = process_block(period, block)
        end
      end

      Formatter.output_to_ledger(
        Transactions::Default.generate(output_block, @options),
        Transactions::Trackers.generate(output_block, @options),
        Transactions::Modifiers.generate(output_block, @options)
      )
    end

    private

    def config_options(forecast, options)
      @options = {}

      @options[:max_amount] = get_max_field_size(forecast, 'amount') + 1 # +1 for the negatives
      @options[:max_category] = get_max_field_size(forecast, 'category')

      @options[:currency] = Money::Currency.new(forecast.fetch('settings', {}).fetch('currency', 'USD'))
      @options[:show_symbol] = forecast.fetch('settings', {}).fetch('show_symbol', true)
      @options[:thousands_separator] = forecast.fetch('settings', {}).fetch('thousands_separator', true)

      @options.merge!(options) if options
    end

    def process_block(period, block)
      output = []

      output << {
        account: block['account'],
        from: Date.parse(block['from']),
        to: block['to'] ? Date.parse(block['to']) : nil,
        type: period,
        frequency: block['frequency'],
        transactions: []
      }

      output = process_transactions(block, output)

      output.map do |item|
        transactions = item[:transactions].group_by { |t| t[:to] }
        item.merge(transactions: transactions)
      end
    end

    def process_transactions(block, output)
      block['transactions'].each do |t|
        output.last[:transactions] << {
          category: t['category'],
          amount: Formatter.format_money(get_amount(t['amount']), @options),
          description: t['description'],
          to: t['to'] ? get_date(Date.parse(block['from']), t['to']) : nil,
          modifiers: t['modifiers'] ? Transactions::Modifiers.get_modifiers(t, block) : [],
          track: Transactions::Trackers.track?(t, block, @options) ? true : false
        }
      end

      output
    end

    def get_amount(amount)
      return amount unless amount.is_a?(String)

      @calculator = Dentaku::Calculator.new if @calculator.nil?

      @calculator.evaluate(amount.slice(1..-1))
    end

    def get_date(from, to)
      return to unless to[0] == "="

      @calculator = Dentaku::Calculator.new if @calculator.nil?

      # Subtract a day from the final date
      (from >> @calculator.evaluate(to.slice(1..-1))) - 1
    end

    def get_max_field_size(block, field)
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
