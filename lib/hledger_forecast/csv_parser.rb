module HledgerForecast
  # Formats various items used throughout the application
  class CSVParser
    def self.parse(csv_data, cli_options = nil)
      new.parse(csv_data, cli_options)
    end

    def parse(csv_data, _cli_options)
      csv_data = CSV.parse(csv_data, headers: true)
      yaml_data = {}
      group_by_type(csv_data, yaml_data)
      yaml_data.to_yaml
    end

    private

    def group_by_type(csv_data, yaml_data)
      csv_data.group_by { |row| row['type'] }.each do |type, rows|
        if type == 'settings'
          handle_settings(rows, yaml_data)
        else
          yaml_data[type] ||= []
          group_by_account_and_from(rows, yaml_data[type], type)
        end
      end
    end

    def handle_settings(rows, yaml_data)
      yaml_data['settings'] ||= {}
      rows.each do |row|
        yaml_data['settings'][row['frequency']] = cast_to_proper_type(row['account'])
      end
    end

    def group_by_account_and_from(rows, yaml_rows, type)
      rows.group_by { |row| [row['account'], row['from']] }.each do |(account, from), transactions|
        yaml_rows << if type == 'custom'
                       build_custom_transaction(account, from, transactions)
                     else
                       build_transaction(account, from, transactions)
                     end
      end
    end

    def build_transaction(account, from, transactions)
      transaction = {
        'account' => account,
        'from' => Date.parse(from).strftime('%Y-%m-%d'),
        'transactions' => []
      }

      transactions.each do |row|
        transaction['transactions'] << build_transaction_data(row)
      end

      transaction
    end

    def build_custom_transaction(account, from, transactions)
      transaction = build_transaction(account, from, transactions)
      transaction['frequency'] = transactions.first['frequency']
      transaction['roll-up'] = transactions.first['roll-up'].to_i if transactions.first['roll-up']
      transaction
    end

    def build_transaction_data(row)
      transaction_data = {
        'amount' => row['amount'].start_with?("=") ? row['amount'].to_s : row['amount'].to_f,
        'category' => row['category'],
        'description' => row['description']
      }

      if row['to']
        transaction_data['to'] = if row['to'].start_with?("=")
                                   row['to']
                                 else
                                   Date.parse(row['to']).strftime('%Y-%m-%d')
                                 end
      end

      transaction_data['summary_exclude'] = true if row['summary_exclude'] && row['summary_exclude'].downcase == "true"
      transaction_data['track'] = true if row['track'] && row['track'].downcase == "true"

      transaction_data
    end

    def cast_to_proper_type(str)
      case str.downcase
      when 'true', 'false'
        str.downcase == 'true'
      else
        str
      end
    end
  end
end
