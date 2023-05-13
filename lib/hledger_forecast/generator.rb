module HledgerForecast
  # Generate periodic transactions from a YAML file, compatible with hledger
  class Generator
    class << self
      attr_accessor :options
    end

    self.options = {}

    def self.generate(forecast, options = nil)
      forecast = YAML.safe_load(forecast)
      config_options(forecast)

      @options.merge!(options) if options

      output_block = {}
      forecast.each do |period, blocks|
        next if %w[settings].include?(period)

        blocks.each do |block|
          output_block[output_block.length] = process_block(period, block)
        end
      end

      format_to_ledger(
        compile_transaction(output_block),
        compile_modifier(output_block),
        compile_tracked_transaction(output_block)
      )
    end

    def self.config_options(forecast)
      @options[:max_amount] = get_max_field_size(forecast, 'amount') + 1 # +1 for the negatives
      @options[:max_category] = get_max_field_size(forecast, 'category')

      @options[:currency] = Money::Currency.new(forecast.fetch('settings', {}).fetch('currency', 'USD'))
      @options[:show_symbol] = forecast.fetch('settings', {}).fetch('show_symbol', true)
      # @options[:sign_before_symbol] = forecast.fetch('settings', {}).fetch('sign_before_symbol', false)
      @options[:thousands_separator] = forecast.fetch('settings', {}).fetch('thousands_separator', true)
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

    def self.compile_transaction(data)
      output = []

      data.each_value do |blocks|
        blocks.each do |block|
          block[:transactions].each do |to, transactions|
            to = header_to_date(block[:to], to)
            frequency = get_periodic_rules(block[:type], block[:frequency])

            block[:descriptions] = transactions.map do |t|
              next if t[:track]

              t[:description]
            end.compact.join(', ')

            transaction_lines = transactions.map do |t|
              next if t[:track]

              t[:amount] = t[:amount].to_s.ljust(@options[:max_amount])
              t[:category] = t[:category].ljust(@options[:max_category])

              "    #{t[:category]}    #{t[:amount]};  #{t[:description]}\n"
            end

            header = "#{frequency} #{block[:from]}#{to}  * #{block[:descriptions]}\n"
            footer = "    #{block[:account]}\n\n"

            output << { header:, transactions: transaction_lines, footer: }
          end
        end
      end

      output
    end

    def self.compile_modifier(data)
      return nil unless modifiers?(data)

      output = []

      extract_modifiers(data).each do |modifier|
        account = modifier[:account].ljust(@options[:max_category])
        category = modifier[:category].ljust(@options[:max_category])
        amount = modifier[:amount].to_s.ljust(@options[:max_amount])
        to = modifier[:to] ? "..#{modifier[:to]}" : nil

        header = "= #{modifier[:category]} date:#{modifier[:from]}#{to}\n"
        transactions = "    #{category}    *#{amount};  #{modifier[:description]}\n"
        footer = "    #{account}    *#{modifier[:amount] * -1}\n\n"

        output << { header:, transactions: [transactions], footer: }
      end

      output
    end

    def self.compile_tracked_transaction(data)
      return nil unless tracked_transactions?(data)

      output = []

      # TODO: Reduce the number of loops in this
      data.each do |_key, blocks|
        blocks.each do |block|
          block[:transactions].each do |_date, transaction|
            transaction.each do |t|
              next unless t[:track]

              category = t[:category].ljust(@options[:max_category])
              amount = t[:amount].to_s.ljust(@options[:max_amount])

              header = "~ #{Date.new(Date.today.year, Date.today.month,
                                     1).next_month}  * [TRACKED] #{t[:description]}\n"
              transactions = "    #{category}    #{amount};  #{t[:description]}\n"
              footer = "    #{block[:account]}\n\n"

              output << { header:, transactions: [transactions], footer: }
            end
          end
        end
      end

      output
    end

    def self.header_to_date(block, transaction)
      return " to #{transaction}" if transaction
      return " to #{block}" if block

      return nil
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

    def self.get_periodic_rules(type, frequency)
      map = {
        'once' => '~',
        'monthly' => '~ monthly from',
        'quarterly' => '~ every 3 months from',
        'half-yearly' => '~ every 6 months from',
        'yearly' => '~ yearly from',
        'custom' => "~ #{frequency} from"
      }

      map[type]
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

    def self.extract_modifiers(data)
      data.each_with_object([]) do |(_key, blocks), result|
        blocks.each do |block|
          block[:transactions].each_value do |transactions|
            transactions.each do |t|
              result.concat(t[:modifiers]) if t[:modifiers]
            end
          end
        end
      end
    end

    def self.modifiers?(data)
      data.any? do |_, blocks|
        blocks.any? do |block|
          block[:transactions].any? do |_, transactions|
            transactions.any? { |t| !t[:modifiers].empty? }
          end
        end
      end
    end

    def self.track?(transaction, data)
      transaction['track'] && Date.parse(data['from']) <= Date.today && Tracker.track(transaction, data, @options)
    end

    def self.tracked_transactions?(data)
      data.any? do |_, blocks|
        blocks.any? do |block|
          block[:transactions].any? do |_, transactions|
            transactions.any? { |t| t[:track] }
          end
        end
      end
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
