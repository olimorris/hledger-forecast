module HledgerForecast
  # Summarise a forecast YAML file and output it to the CLI
  # TODO: Rename this to Summarizer and the main method becomes summarize
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

      category_totals = {}
      %w[monthly quarterly half-yearly yearly once custom].each do |period|
        category_totals[period] = sum_transactions(forecast, period)
      end

      add_categories_to_table(category_totals, forecast)

      @table.add_separator
      format_total("TOTAL", category_totals.values.map(&:values).flatten.sum)

      @table
    end

    def init_table
      @table.add_row([{ value: 'FORECAST SUMMARY'.bold, colspan: 3, alignment: :center }])
      @table.add_separator
    end

    def sum_transactions(forecast, period)
      category_total = Hash.new(0)
      forecast[period]&.each do |entry|
        entry['transactions'].each do |transaction|
          category_total[transaction['category']] += Calculator.new.evaluate(transaction['amount'])
        end
      end

      category_total
    end

    def sum_custom_transactions(forecast_data)
      category_total = Hash.new(0)
      custom_periods = []

      forecast_data['custom']&.each do |entry|
        period_data = {}
        period_data[:frequency] = entry['frequency']
        period_data[:category] = entry['transactions'].first['category']
        period_data[:amount] = entry['transactions'].first['amount']

        entry['transactions'].each do |transaction|
          category_total[transaction['category']] += transaction['amount']
        end

        custom_periods << period_data
      end

      { totals: category_total, periods: custom_periods }
    end

    def format_amount(amount)
      formatted_amount = Formatter.format_money(amount, @settings)
      amount.to_f < 0 ? formatted_amount.green : formatted_amount.red
    end

    def add_rows_to_table(row_data, period_total, custom: false)
      if custom
        row_data[:periods].each do |period|
          @table.add_row [{ value: period[:category], alignment: :left },
                          { value: period[:frequency], alignment: :right },
                          { value: format_amount(period[:amount]), alignment: :right }]

          period_total += period[:amount]
        end
      else
        row_data.each do |category, amount|
          @table.add_row [{ value: category, colspan: 2, alignment: :left },
                          { value: format_amount(amount), alignment: :right }]

          period_total += amount
        end
      end

      period_total
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
