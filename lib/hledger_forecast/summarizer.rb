module HledgerForecast
  # Summarise a forecast yaml file and output it to the CLI
  class Summarizer
    def self.summarize(config, cli_options)
      new.summarize(config, cli_options)
    end

    def summarize(config, cli_options = nil)
      @forecast = YAML.safe_load(config)
      @settings = Settings.config(@forecast, cli_options)

      return { output: generate(@forecast), settings: @settings }
    end

    private

    def generate(forecast)
      output = {}
      forecast.each do |period, blocks|
        next if %w[settings].include?(period)

        blocks.each do |block|
          output[output.length] = process_block(period, block)
        end
      end

      output = filter_out(flatten_and_merge(output))
      calculate_rolled_up_amount(output)
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

      process_transactions(period, block, output)
    end

    def process_transactions(period, block, output)
      block['transactions'].each do |t|
        amount = Calculator.new.evaluate(t['amount'])

        output.last[:transactions] << {
          amount: amount,
          annualised_amount: amount * (block['roll-up'] || annualise(period)),
          rolled_up_amount: 0,
          category: t['category'],
          exclude: t['summary_exclude'],
          description: t['description'],
          to: t['to'] ? Calculator.new.evaluate_date(Date.parse(block['from']), t['to']) : nil
        }
      end

      output
    end

    def annualise(period)
      annualise = {
        'monthly' => 12,
        'quarterly' => 4,
        'half-yearly' => 2,
        'yearly' => 1,
        'once' => 1,
        'daily' => 352,
        'weekly' => 52
      }

      annualise[period]
    end

    def filter_out(data)
      data.reject { |item| item[:exclude] == true }
    end

    def flatten_and_merge(blocks)
      blocks.values.flatten.flat_map do |block|
        block[:transactions].map do |transaction|
          block.slice(:account, :from, :to, :type, :frequency).merge(transaction)
        end
      end
    end

    def calculate_rolled_up_amount(data)
      data.map do |item|
        item[:rolled_up_amount] = item[:annualised_amount] / annualise(@settings[:roll_up])
        item
      end
    end

    def group_by(data, group_by, sum_up)
      data.map do |key, value|
        { group_by => key, sum_up => value }
      end
    end

    def sort_transactions(category_total)
      negatives = category_total.select { |_, amount| amount < 0 }.sort_by { |_, amount| amount }
      positives = category_total.select { |_, amount| amount > 0 }.sort_by { |_, amount| -amount }

      negatives.concat(positives).to_h
    end
  end
end
