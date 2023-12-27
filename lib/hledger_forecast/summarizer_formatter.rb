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

      if @settings[:roll_up].nil?
        add_rows_to_table(output)
        add_total_row_to_table(output, :amount)
      else
        add_rolled_up_rows_to_table(output)
        add_total_row_to_table(output, :rolled_up_amount)
      end

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
      data = data.group_by { |item| item[:type] }

      data = sort(data)

      data.each_with_index do |(type, items), index|
        @table.add_row([{ value: type.capitalize.bold, colspan: 3, alignment: :center }])
        total = 0
        items.each do |item|
          total += item[:amount].to_f

          if @settings[:verbose]
            @table.add_row [{ value: item[:category], alignment: :left },
                            { value: item[:description], alignment: :left },
                            { value: format_amount(item[:amount]), alignment: :right }]
          else
            @table.add_row [{ value: item[:category], colspan: 2, alignment: :left },
                            { value: format_amount(item[:amount]), alignment: :right }]
          end
        end

        @table.add_row [{ value: "TOTAL".bold, colspan: 2, alignment: :left },
                        { value: format_amount(total).bold, alignment: :right }]

        @table.add_separator if index != data.size - 1
      end
    end

    def sort(data)
      data.each do |type, items|
        data[type] = items.sort_by do |item|
          value = item[:amount].to_f
          [value >= 0 ? 1 : 0, value >= 0 ? -value : value]
        end
      end
    end

    def add_rolled_up_rows_to_table(data)
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
      sorted_sums = sort_roll_up(sum_hash, :sum)

      if @settings[:verbose]
        sorted_sums.each do |hash|
          @table.add_row [{ value: hash[:category], colspan: 1, alignment: :left },
                          { value: hash[:descriptions], colspan: 1, alignment: :left },
                          { value: format_amount(hash[:sum]), alignment: :right }]
        end
      else
        sorted_sums.each do |hash|
          @table.add_row [{ value: hash[:category], colspan: 2, alignment: :left },
                          { value: format_amount(hash[:sum]), alignment: :right }]
        end
      end
    end

    def sort_roll_up(data, sort_by)
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
        sum + item[row_to_sum].to_f
      end

      income = data.reduce(0) do |sum, item|
        sum += item[row_to_sum].to_f if item[row_to_sum].to_f < 0
        sum
      end

      savings = (total / income * 100).to_f.round(2)

      @table.add_separator
      @table.add_row [{ value: "TOTAL".bold, colspan: 2, alignment: :left },
                      { value: format_amount(total).bold, alignment: :right }]
      @table.add_row [{ value: "as a % of income".italic, colspan: 2, alignment: :left },
                      { value: "#{savings}%".italic, alignment: :right }]
    end

    def format_amount(amount)
      formatted_amount = Formatter.format_money(amount, @settings)
      amount.to_f < 0 ? formatted_amount.green : formatted_amount.red
    end
  end
end
