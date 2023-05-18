module HledgerForecast
  # Output the summarised forecast to the CLI
  class SummarizerFormatter
    def self.format(output, settings)
      new.format(output, settings)
    end

    def format(output, settings)
      @table = Terminal::Table.new
      @settings = settings

      init_table

      add_rows_to_table(output)
      add_total_row_to_table(output, :rolled_up_amount)

      @table
    end

    private

    def init_table
      title = 'FORECAST SUMMARY'
      title += " (#{@settings[:roll_up].upcase} ROLL UP)" if @settings[:roll_up]

      @table.add_row([{ value: title.bold, colspan: 3, alignment: :center }])
      @table.add_separator
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

    def format_amount(amount)
      formatted_amount = Formatter.format_money(amount, @settings)
      amount.to_f < 0 ? formatted_amount.green : formatted_amount.red
    end

    def format_total(text, total)
      @table.add_row [{ value: text.bold, colspan: 2, alignment: :left },
                      { value: format_amount(total).bold, alignment: :right }]
    end
  end
end
