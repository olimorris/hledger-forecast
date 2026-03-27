module HledgerForecast
  class Generator
    def self.generate(csv_string, cli_options = nil)
      forecast = Forecast.parse(csv_string, cli_options)
      Transactions::Default.render(build_groups(forecast), forecast.settings)
    end

    private_class_method def self.build_groups(forecast)
      if forecast.settings.verbose?
        forecast.transactions.map do |t|
          TransactionGroup.new(type: t.type, frequency: t.frequency, account: t.account, from: t.from, to: t.to, transactions: [t])
        end
      else
        forecast.transactions
          .group_by { |t| [t.type, t.frequency, t.from, t.to, t.account] }
          .map do |(type, frequency, from, to, account), transactions|
            TransactionGroup.new(type: type, frequency: frequency, account: account, from: from, to: to, transactions: transactions)
          end
      end
    end
  end
end
