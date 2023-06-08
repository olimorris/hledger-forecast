module HledgerForecast
  # Formats various items used throughout the application
  class CSV2YAML
    def self.convert(csv_data, cli_options = nil)
      new.convert(csv_data, cli_options)
    end

    def convert(csv_data, _cli_options)
      csv_data = CSV.parse(csv_data, headers: true)
      yaml_data = {}

      csv_data.each do |row|
        frequency = row['frequency']
        yaml_data[frequency] ||= []

        transaction = {
          'account' => row['account'],
          'from' => Date.parse(row['from']),
          'transactions' => []
        }

        transaction_data = {
          'amount' => row['amount'].to_i,
          'category' => row['category'],
          'description' => row['description']
        }

        transaction_data['to'] = Date.parse(row['to']) if row['to']

        if yaml_data[frequency].any? do |existing_trans|
             existing_trans['account'] == transaction['account'] && existing_trans['from'] == transaction['from']
           end
          yaml_data[frequency].find do |existing_trans|
            existing_trans['account'] == transaction['account'] && existing_trans['from'] == transaction['from']
          end['transactions'] << transaction_data
        else
          transaction['transactions'] << transaction_data
          yaml_data[frequency] << transaction
        end
      end

      yaml_data.to_yaml.gsub!(/^---\n/, '')
    end
  end
end
