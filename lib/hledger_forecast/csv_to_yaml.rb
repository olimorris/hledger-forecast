module HledgerForecast
  # Formats various items used throughout the application
  class CSV2YAML
    def self.convert(csv_data, cli_options = nil)
      new.convert(csv_data, cli_options)
    end

    def convert(csv_data, _cli_options)
      csv_data = CSV.parse(csv_data, headers: true)
      yaml_data = {}

      grouped_data = csv_data.group_by { |row| [row['account'], row['from']] }

      grouped_data.each do |(account, from), transactions|
        frequency = transactions.first['frequency']
        yaml_data[frequency] ||= []

        transaction = {
          'account' => account,
          'from' => Date.parse(from).strftime('%Y-%m-%d'),
          'transactions' => []
        }

        transactions.each do |row|
          transaction_data = {
            'amount' => row['amount'].to_i,
            'category' => row['category'],
            'description' => row['description']
          }

          transaction_data['to'] = Date.parse(row['to']).strftime('%Y-%m-%d') if row['to']

          transaction['transactions'] << transaction_data
        end

        yaml_data[frequency] << transaction
      end

      yaml_data.to_yaml.gsub!(/^---\n/, '')
    end
  end
end
