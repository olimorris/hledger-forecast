module HledgerForecast
  # Summarise a forecast YAML file and output it to the CLI
  class Summarize
    def self.sum_transactions(forecast_data, period)
      category_totals = Hash.new(0)
      forecast_data[period]&.each do |entry|
        entry['transactions'].each do |transaction|
          category_totals[transaction['category']] += transaction['amount']
        end
      end

      category_totals
    end

    def self.print_category_totals(period, category_totals, generator)
      puts "#{period.capitalize}:"
      period_total = 0

      category_totals.each do |category, amount|
        formatted_amount = generator.format_transaction({ 'amount' => amount })['amount']
        formatted_amount = amount.to_i < 0 ? formatted_amount.green : formatted_amount.red
        puts "  #{category.ljust(40)}#{formatted_amount}"
        period_total += amount
      end

      formatted_period_total = generator.format_transaction({ 'amount' => period_total })['amount']
      formatted_period_total = period_total.to_i < 0 ? formatted_period_total.green : formatted_period_total.red
      puts "  TOTAL".ljust(42) + formatted_period_total
    end

    def self.sum_all_periods(forecast_data)
      periods = %w[monthly quarterly half-yearly yearly once]
      total = {}
      grand_total = 0

      (periods + ['custom']).each do |period|
        total[period] = sum_transactions(forecast_data, period)
        grand_total += total[period]
      end

      total['total'] = grand_total
      total
    end

    def self.sum_custom_transactions(forecast_data)
      category_totals = Hash.new(0)
      custom_periods = []

      forecast_data['custom']&.each do |entry|
        period_data = {}
        period_data[:quantity] = entry['recurrence']['quantity']
        period_data[:period] = entry['recurrence']['period']
        period_data[:description] = entry['transactions'].first['description']
        period_data[:category] = entry['transactions'].first['category']
        period_data[:amount] = entry['transactions'].first['amount']

        entry['transactions'].each do |transaction|
          category_totals[transaction['category']] += transaction['amount']
        end

        custom_periods << period_data
      end

      { totals: category_totals, periods: custom_periods }
    end

    def self.generate(forecast)
      forecast_data = YAML.safe_load(forecast)

      category_totals_by_period = {}
      %w[monthly quarterly half-yearly yearly once custom].each do |period|
        category_totals_by_period[period] = sum_transactions(forecast_data, period)
      end

      grand_total = category_totals_by_period.values.map(&:values).flatten.sum

      generator = HledgerForecast::Generator
      generator.configure_settings(forecast_data)

      table = Terminal::Table.new

      table.add_row([{ value: 'FORECAST SUMMARY', colspan: 3, alignment: :center }])
      table.add_separator

      first_period = true
      category_totals_by_period.each do |period, category_totals|
        non_zero_totals = category_totals.select { |_, amount| amount != 0 }
        next if non_zero_totals.empty?

        table.add_separator unless first_period
        table.add_row([{ value: period.capitalize, colspan: 3, alignment: :center }])

        period_total = 0

        if period == 'custom'
          custom_periods_data = sum_custom_transactions(forecast_data)
          custom_periods_data[:periods].each do |custom_period|
            formatted_amount = generator.format_transaction({ 'amount' => custom_period[:amount] })['amount']
            formatted_amount = custom_period[:amount].to_i < 0 ? formatted_amount.green : formatted_amount.red
            table.add_row [{ value: custom_period[:category], alignment: :left },
                           { value: "every #{custom_period[:quantity]} #{custom_period[:period]}", alignment: :right }, { value: formatted_amount, alignment: :right }]
            period_total += custom_period[:amount]
          end
        else
          non_zero_totals.each do |category, amount|
            formatted_amount = generator.format_transaction({ 'amount' => amount })['amount']
            formatted_amount = amount.to_i < 0 ? formatted_amount.green : formatted_amount.red

            table.add_row [{ value: category, colspan: 2, alignment: :left },
                           { value: formatted_amount, alignment: :right }]
            period_total += amount
          end
        end

        formatted_period_total = generator.format_transaction({ 'amount' => period_total })['amount']
        formatted_period_total = period_total.to_i < 0 ? formatted_period_total.green : formatted_period_total.red
        table.add_row [{ value: "#{period.capitalize} TOTAL", colspan: 2, alignment: :left },
                       { value: formatted_period_total, alignment: :right }]

        first_period = false
      end

      table.add_separator
      formatted_grand_total = generator.format_transaction({ 'amount' => grand_total })['amount']
      formatted_grand_total = grand_total.to_i < 0 ? formatted_grand_total.green : formatted_grand_total.red
      table.add_row [{ value: 'TOTAL', colspan: 2, alignment: :left },
                     { value: formatted_grand_total, alignment: :right }]

      puts table
    end
  end
end
