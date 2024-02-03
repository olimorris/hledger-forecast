module HledgerForecast
  # Summarise a forecast yaml file and output it to the CLI
  class Summarizer
    def self.summarize(config, cli_options)
      new.summarize(config, cli_options)
    end

    def summarize(config, cli_options = nil)
      @forecast = CSV.parse(config, headers: true)
      @settings = Settings.config(@forecast, cli_options)

      { output: generate(@forecast), settings: @settings }
    end

    private

    def generate(forecast)
      output = []

      forecast.each do |row|
        next if row['type'] == 'settings'
        next if row['summary_exclude']

        row['amount'] = Calculator.new.evaluate(Utilities.convert_amount(row['amount']))

        begin
          annualised_amount = row['roll-up'] ? row['amount'] * row['roll-up'].to_f : row['amount'] * annualise(row['type'])
        rescue StandardError
          puts "\nError: ".bold.red + 'Could not create an annualised ammount. Have you set the roll-up for your custom type transactions?'
          exit
        end

        output << {
          account: row['account'],
          from: Date.parse(row['from']),
          to: row['to'] ? Calculator.new.evaluate_date(Date.parse(row['from']), row['to']) : nil,
          type: row['type'],
          frequency: row['frequency'],
          category: row['category'],
          description: row['description'],
          amount: row['amount'],
          annualised_amount: annualised_amount.to_f,
          exclude: row['summary_exclude']
        }
      end

      output = calculate_rolled_up_amount(output) unless @settings[:roll_up].nil?

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

    def calculate_rolled_up_amount(forecast)
      forecast.each do |row|
        row[:rolled_up_amount] = row[:annualised_amount] / annualise(@settings[:roll_up])
      end
    end
  end
end
