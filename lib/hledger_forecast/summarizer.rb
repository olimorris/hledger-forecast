module HledgerForecast
  # Summarise a forecast YAML file and output it to the CLI
  # TODO: Rename this to Summarizer and the main method becomes summarize
  class Summarizer
    @table = nil
    @generator = nil

    def self.summarize(forecast)
      # Read the forecast file and set the options

    end

    def self.init_table
      table = Terminal::Table.new

      table.add_row([{ value: 'FORECAST SUMMARY'.bold, colspan: 3, alignment: :center }])
      table.add_separator

      @table = table
    end

    def self.sum_transactions(forecast_data, period)
      category_total = Hash.new(0)
      forecast_data[period]&.each do |entry|
        entry['transactions'].each do |transaction|
          category_total[transaction['category']] += @generator.calculate_amount(transaction['amount'])
        end
      end

      category_total
    end

    def self.sum_custom_transactions(forecast_data)
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

    def self.format_amount(amount)
      # TODO: Use the formatter class
      formatted_amount = @generator.format_amount(amount)
      amount.to_f < 0 ? formatted_amount.green : formatted_amount.red
    end

    def self.add_rows_to_table(row_data, period_total, custom: false)
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

    def self.add_categories_to_table(categories, forecast_data)
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

    def self.sort_transactions(category_total)
      negatives = category_total.select { |_, amount| amount < 0 }.sort_by { |_, amount| amount }
      positives = category_total.select { |_, amount| amount > 0 }.sort_by { |_, amount| -amount }

      negatives.concat(positives).to_h
    end

    def self.format_total(text, total)
      @table.add_row [{ value: text.bold, colspan: 2, alignment: :left },
                      { value: format_amount(total).bold, alignment: :right }]
    end

    def self.generate(forecast)
      forecast_data = YAML.safe_load(forecast)

      init_table
      init_generator(forecast_data)

      category_totals = {}
      %w[monthly quarterly half-yearly yearly once custom].each do |period|
        category_totals[period] = sum_transactions(forecast_data, period)
      end

      add_categories_to_table(category_totals, forecast_data)

      @table.add_separator
      format_total("TOTAL", category_totals.values.map(&:values).flatten.sum)

      puts @table
    end
  end
end
