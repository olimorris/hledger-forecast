module HledgerForecast
  # Generate forecasts for hledger from a yaml config file
  class Generator
    def self.generate(config, cli_options = nil)
      new.generate(config, cli_options)
    end

    def generate(config, cli_options = nil)
      forecast = YAML.safe_load(config)
      @settings = Settings.config(forecast, cli_options)

      output = {}
      forecast.each do |period, blocks|
        next if %w[settings].include?(period)

        blocks.each do |block|
          output[output.length] = process_block(period, block)
        end
      end

      Formatter.output_to_ledger(
        Transactions::Default.generate(output, @settings),
        Transactions::Trackers.generate(output, @settings),
        Transactions::Modifiers.generate(output, @settings)
      )
    end

    private

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
          amount: Formatter.format_money(Calculator.new.evaluate(t['amount']), @settings),
          description: t['description'],
          to: t['to'] ? Calculator.new.evaluate_date(Date.parse(block['from']), t['to']) : nil,
          modifiers: t['modifiers'] ? Transactions::Modifiers.get_modifiers(t, block) : [],
          track: Transactions::Trackers.track?(t, block, @settings) ? true : false
        }
      end

      output
    end
  end
end
