module HledgerForecast
  # Generate forecasts for hledger from a yaml config file
  class Generator
    def self.generate(config, cli_options = nil)
      new.generate(config, cli_options)
    end

    def generate(config, cli_options = nil)
      forecast = CSV.parse(config, headers: true)
      @settings = Settings.config(forecast, cli_options)

      processed = []
      forecast.each do |row|
        next if row['type'] == "settings"

        processed.push(process_forecast(row))
      end

      if @settings[:verbose]
        transformed = processed
      else
        processed = processed.group_by do |row|
          [row[:type], row[:frequency], row[:from], row[:to], row[:account]]
        end

        transformed = processed.map do |(type, frequency, from, to, account), transactions|
          {
            type: type,
            frequency: frequency,
            from: from,
            to: to,
            account: account,
            transactions: transactions
          }
        end
      end

      Formatter.output_to_ledger(
        Transactions::Default.generate(transformed, @settings)
        # Transactions::Trackers.generate(transformed, @settings)
      )
    end

    private

    def process_forecast(row)
      amount = Utilities.convert_amount(row['amount'])

      {
        type: row['type'],
        frequency: row['frequency'] || nil,
        account: row['account'],
        from: Date.parse(row['from']),
        to: row['to'] ? Calculator.new.evaluate_date(Date.parse(row['from']), row['to']) : nil,
        description: row['description'],
        category: row['category'],
        amount: Formatter.format_money(Calculator.new.evaluate(amount), @settings)
        # track: Transactions::Trackers.track?(row, block, @settings) ? true : false
      }
    end

    def transform_data(data)
      transformed_data = []

      data.each do |group_key, transactions|
        next if group_key == "settings"

        split_keys = group_key.split("@@")

        group_info = {
          type: split_keys[0],
          from: split_keys[1],
          to: split_keys[2],
          account: split_keys[3],
          transactions: transactions
        }

        transformed_data << group_info
      end

      transformed_data
    end
  end
end
