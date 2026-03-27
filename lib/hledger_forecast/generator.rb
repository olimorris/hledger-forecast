module HledgerForecast
  class Generator
    def self.generate(csv_string, cli_options = nil)
      forecast = Forecast.parse(csv_string, cli_options)
      transactions = forecast.transactions

      if cli_options&.dig(:tags)
        raise "The --tags option requires a 'tag' column in the forecast CSV" unless forecast.has_tags_column?
        transactions = transactions.select { |t| t.matches_tags?(cli_options[:tags]) }
      end

      Transactions::Default.render(build_groups(transactions, forecast.settings), forecast.settings)
    end

    private_class_method def self.build_groups(transactions, settings)
      if settings.verbose?
        transactions.map do |t|
          TransactionGroup.new(
            type: t.type,
            frequency: t.frequency,
            account: t.account,
            from: t.from,
            to: t.to,
            transactions: [t]
          )
        end
      else
        transactions
          .group_by { |t| [t.type, t.frequency, t.from, t.to, t.account] }
          .map do |(type, frequency, from, to, account), txns|
            TransactionGroup.new(
              type: type,
              frequency: frequency,
              account: account,
              from: from,
              to: to,
              transactions: txns
            )
          end
      end
    end
  end
end
