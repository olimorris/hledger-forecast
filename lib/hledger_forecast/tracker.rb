module HledgerForecast
  # Checks for the existence of a transaction in a journal file and tracks it
  class Tracker
    def self.track(transaction, data, options)
      !exists?(transaction, data['account'], data['from'], Date.today, options)
    end

    def self.exists?(transaction, account, from, to, options)
      # Format the money
      amount = Formatter.format(transaction['amount'], options)
      inverse_amount = Formatter.format(transaction['amount'] * -1, options)

      # We run two commands and check to see if category +/- amount or account +/- amount exists
      command1 = %(hledger print -f #{options[:transaction_file]} "date:#{from}..#{to}" | tr -s '[:space:]' ' ' | grep -q -Eo "#{escape_str(transaction['category'])} (#{amount}|#{inverse_amount})")
      command2 = %(hledger print -f #{options[:transaction_file]} "date:#{from}..#{to}" | tr -s '[:space:]' ' ' | grep -q -Eo "#{account} (#{amount}|#{inverse_amount})")

      system(command1) || system(command2)
    end

    def self.escape_str(str)
      str.gsub('[', '\\[').gsub(']', '\\]').gsub('(', '\\(').gsub(')', '\\)')
    end
  end
end
