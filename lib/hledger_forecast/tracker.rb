module HledgerForecast
  # Checks for the existence of a transaction in a journal file and tracks it
  class Tracker
    def self.track(transactions, transaction_file)
      to_date = Date.parse(latest_date(transaction_file))

      transactions.each_with_object({}) do |(key, transaction), updated_transactions|
        found = transaction_exists?(transaction_file, transaction['start'], to_date, transaction['account'],
                                    transaction['transaction'])
        updated_transactions[key] = transaction.merge('start' => to_date >> 1, 'found' => found)
      end
    end

    def self.latest_date(file)
      command = %(hledger print --file #{file} | grep '^[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}' | awk '{print $1}' | sort -r | head -n 1)

      date_output = `#{command}`
      date_output.strip
    end

    def self.transaction_exists?(file, from, to, account, transaction)
      category = escape_str(transaction['category'])
      amount = transaction['amount']
      inverse_amount = transaction['inverse_amount']

      # We run two commands and check to see if category +/- amount or account +/- amount exists
      command1 = %(hledger print -f #{file} "date:#{from}..#{to}" | tr -s '[:space:]' ' ' | grep -q -Eo "#{category} (#{amount}|#{inverse_amount})")
      command2 = %(hledger print -f #{file} "date:#{from}..#{to}" | tr -s '[:space:]' ' ' | grep -q -Eo "#{account} (#{amount}|#{inverse_amount})")

      system(command1) || system(command2)
    end

    def self.escape_str(str)
      str.gsub('[', '\\[').gsub(']', '\\]').gsub('(', '\\(').gsub(')', '\\)')
    end
  end
end
