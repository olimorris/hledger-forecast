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
        formatted_amount = amount.to_i < 0 ? formatted_amount.red : formatted_amount.green
        puts "  #{category.ljust(40)}#{formatted_amount}"
        period_total += amount
      end

      formatted_period_total = generator.format_transaction({ 'amount' => period_total })['amount']
      formatted_period_total = period_total.to_i < 0 ? formatted_period_total.red : formatted_period_total.green
      puts "  TOTAL".ljust(42) + formatted_period_total
    end

    def self.sum_all_periods(forecast_data)
      periods = %w[monthly quarterly half-yearly yearly once]
      total = {}
      grand_total = 0

      periods.each do |period|
        total[period] = sum_transactions(forecast_data, period)
        grand_total += total[period]
      end

      total['total'] = grand_total
      total
    end

    def self.generate(forecast)
      forecast_data = YAML.safe_load(forecast)

      category_totals_by_period = {}
      %w[monthly quarterly half-yearly yearly once].each do |period|
        category_totals_by_period[period] = sum_transactions(forecast_data, period)
      end

      grand_total = category_totals_by_period.values.map(&:values).flatten.sum

      generator = HledgerForecast::Generator
      generator.configure_settings(forecast_data)

      puts
      category_totals_by_period.each do |period, category_totals|
        print_category_totals(period, category_totals, generator)
        puts
      end

      formatted_grand_total = generator.format_transaction({ 'amount' => grand_total })['amount']
      formatted_grand_total = grand_total.to_i < 0 ? formatted_grand_total.red : formatted_grand_total.green
      puts "TOTAL:".ljust(42) + formatted_grand_total
    end
  end
end
