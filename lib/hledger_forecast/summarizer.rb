module HledgerForecast
  class Summarizer
    def self.summarize(csv_string, cli_options = nil)
      new.summarize(csv_string, cli_options)
    end

    def summarize(csv_string, cli_options = nil)
      forecast = Forecast.parse(csv_string, cli_options)
      transactions = forecast.transactions.reject(&:summary_exclude?)

      output = transactions.map { |t| build_summary_row(t) }
      output = apply_roll_up(output, forecast.settings.roll_up) if forecast.settings.roll_up

      {output: output, settings: forecast.settings}
    end

    private

    def build_summary_row(transaction)
      annualised = begin
        transaction.annualised_amount
      rescue KeyError => e
        puts("\nError: ".bold.red + e.message)
        exit
      end

      {
        account: transaction.account,
        from: transaction.from,
        to: transaction.to,
        type: transaction.type,
        frequency: transaction.frequency,
        category: transaction.category,
        description: transaction.description,
        amount: transaction.amount,
        annualised_amount: annualised.to_f,
        exclude: transaction.summary_exclude
      }
    end

    def apply_roll_up(output, roll_up_period)
      divisor = ANNUAL_MULTIPLIERS.fetch(roll_up_period)
      output.each { |row| row[:rolled_up_amount] = row[:annualised_amount] / divisor }
    end
  end
end
