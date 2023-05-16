module HledgerForecast
  # Summarise a forecast yaml file and output it to the CLI
  class Summarizer
    def self.summarize(config, cli_options)
      new.summarize(config, cli_options)
    end

    def summarize(config, cli_options = nil)
      @forecast = YAML.safe_load(config)
      @settings = Settings.config(@forecast, cli_options)
      @table = Terminal::Table.new

      generate(@forecast)
    end

    private

    def generate(forecast)
      init_table

      output = {}
      forecast.each do |period, blocks|
        next if %w[settings].include?(period)

        blocks.each do |block|
          output[output.length] = process_block(period, block)
        end
      end

      output = filter_out(flatten_and_merge(output))
      output = calculate_rolled_up_amount(output)

      add_rows_to_table(output)
      add_total_row_to_table(output, :rolled_up_amount)

      @table
    end

    def init_table
      title = 'FORECAST SUMMARY'
      title += " (#{@settings[:roll_up].upcase} ROLL UP)" if @settings[:roll_up]

      @table.add_row([{ value: title.bold, colspan: 3, alignment: :center }])
      @table.add_separator
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

    def format_amount(amount)
      formatted_amount = Formatter.format_money(amount, @settings)
      amount.to_f < 0 ? formatted_amount.green : formatted_amount.red
    end

    def add_rows_to_table(data)
      sum_hash = Hash.new { |h, k| h[k] = { sum: 0, descriptions: [] } }

      data.each do |item|
        sum_hash[item[:category]][:sum] += item[:rolled_up_amount]
        sum_hash[item[:category]][:descriptions] << item[:description]
      end

      # Convert arrays of descriptions to single strings
      sum_hash.each do |_category, values|
        values[:descriptions] = values[:descriptions].join(", ")
      end

      # Sort the array
      sorted_sums = sort_data(sum_hash, :sum)

      sorted_sums.each do |hash|
        @table.add_row [{ value: hash[:category], colspan: 2, alignment: :left },
                        { value: format_amount(hash[:sum]), alignment: :right }]
      end
    end

    def sort_data(data, sort_by)
      # Convert the hash to an array of hashes
      array = data.map do |category, values|
        { category: category, sum: values[sort_by], descriptions: values[:descriptions] }
      end

      # Sort the array
      array.sort_by do |hash|
        value = hash[:sum]
        [value >= 0 ? 1 : 0, value >= 0 ? -value : value]
      end
    end

    def add_total_row_to_table(data, row_to_sum)
      total = data.reduce(0) do |sum, item|
        sum + item[row_to_sum]
      end

      @table.add_row [{ value: "TOTAL".bold, colspan: 2, alignment: :left },
                      { value: format_amount(total).bold, alignment: :right }]
    end

    def add_categories_to_table(categories, forecast_data)
      first_period = true
      categories.each do |period, total|
        category_total = total.reject { |_, amount| amount == 0 }
        next if category_total.empty?

        sorted_category_total = sort_transactions(category_total)

        @table.add_separator unless first_period
        @table.add_row([{ value: period.capitalize.bold, colspan: 3, alignment: :center }])

        period_total = 0
        period_total += if period == 'custom'
                          add_rows_to_table(sum_custom_transactions(forecast_data), period_total, custom: true)
                        else
                          add_rows_to_table(sorted_category_total, period_total)
                        end

        format_total("#{period.capitalize} TOTAL", period_total)
        first_period = false
      end
    end

    def sort_transactions(category_total)
      negatives = category_total.select { |_, amount| amount < 0 }.sort_by { |_, amount| amount }
      positives = category_total.select { |_, amount| amount > 0 }.sort_by { |_, amount| -amount }

      negatives.concat(positives).to_h
    end

    def format_total(text, total)
      @table.add_row [{ value: text.bold, colspan: 2, alignment: :left },
                      { value: format_amount(total).bold, alignment: :right }]
    end
  end
end
