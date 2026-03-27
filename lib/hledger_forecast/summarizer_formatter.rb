module HledgerForecast
  class SummarizerFormatter
    def self.format(output, settings)
      new.format(output, settings)
    end

    def format(output, settings)
      @table    = Terminal::Table.new
      @settings = settings

      init_table

      if @settings.roll_up.nil?
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
      title += " (#{@settings.roll_up.upcase} ROLL UP)" if @settings.roll_up

      @table.add_row([{ value: title.bold, colspan: 3, alignment: :center }])
      @table.add_separator
    end

    def add_rows_to_table(data)
      data.group_by { |item| item[:type] }.tap { |d| sort_items(d) }.each_with_index do |(type, items), index|
        @table.add_row([{ value: type.capitalize.bold, colspan: 3, alignment: :center }])

        total = 0
        items.each do |item|
          total += item[:amount].to_f

          if @settings.verbose
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

    def add_rolled_up_rows_to_table(data)
      aggregated = data.each_with_object(Hash.new { |h, k| h[k] = { sum: 0, descriptions: [] } }) do |item, h|
        h[item[:category]][:sum]          += item[:rolled_up_amount]
        h[item[:category]][:descriptions] << item[:description]
      end

      aggregated.each_value { |v| v[:descriptions] = v[:descriptions].join(', ') }

      sort_by_amount(aggregated.map { |cat, v| { category: cat, sum: v[:sum], descriptions: v[:descriptions] } }).each do |hash|
        if @settings.verbose
          @table.add_row [{ value: hash[:category], colspan: 1, alignment: :left },
                          { value: hash[:descriptions], colspan: 1, alignment: :left },
                          { value: format_amount(hash[:sum]), alignment: :right }]
        else
          @table.add_row [{ value: hash[:category], colspan: 2, alignment: :left },
                          { value: format_amount(hash[:sum]), alignment: :right }]
        end
      end
    end

    def add_total_row_to_table(data, row_to_sum)
      total   = data.sum { |item| item[row_to_sum].to_f }
      income  = data.sum { |item| (v = item[row_to_sum].to_f) < 0 ? v : 0 }
      savings = (total / income * 100).round(2)

      @table.add_separator
      @table.add_row [{ value: "TOTAL".bold, colspan: 2, alignment: :left },
                      { value: format_amount(total).bold, alignment: :right }]
      @table.add_row [{ value: "as a % of income".italic, colspan: 2, alignment: :left },
                      { value: "#{savings}%".italic, alignment: :right }]
    end

    def sort_items(grouped)
      grouped.transform_values! { |items| sort_by_amount(items, key: :amount) }
    end

    def sort_by_amount(collection, key: :sum)
      collection.sort_by do |item|
        value = item[key].to_f
        [value >= 0 ? 1 : 0, value >= 0 ? -value : value]
      end
    end

    def format_amount(amount)
      formatted = Formatter.format_money(amount, @settings)
      amount.to_f.negative? ? formatted.green : formatted.red
    end
  end
end
