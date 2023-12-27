module HledgerForecast
  module Transactions
    # Generate hledger transactions based on the non-existance of a transaction
    # in your ledger. This is useful for ensuring that certain expenses are
    # accounted for, even if you forget to enter them.
    #
    # Example output:
    # ~ 2023-05-1  * [TRACKED] Food expenses
    #    Expenses:Groceries    $250.00 ;  Food expenses
    #    Assets:Checking
    class Trackers
      def self.generate(forecast, options)
        new(forecast, options).generate
      end

      def generate
        return if @options[:no_track]
        return nil unless tracked?(forecast)

        forecast.each do |row|
          process_tracked(row)
        end

        output
      end

      def self.track?(row, options)
        now = Date.today
        row['track'] && Date.parse(row['from']) <= now && !exists?(row, now, options)
      end

      def self.exists?(row, now, options)
        unless options[:transaction_file]
          puts "\nWarning: ".bold.yellow + "For tracked transactions, please specify a file with the `-t` flag"
          puts "ERROR: ".bold.red + "Tracked transactions ignored for now"
          return
        end

        # Format the money
        amount = Formatter.format_money(row['amount'], options)
        inverse_amount = Formatter.format_money(row['amount'] * -1, options)

        from = Date.parse(row['from'])
        category = row['category'].gsub('[', '\\[').gsub(']', '\\]').gsub('(', '\\(').gsub(')', '\\)')

        # We run two commands and check to see if category +/- amount or account +/- amount exists
        command1 = %(hledger print -f #{options[:transaction_file]} "date:#{from}..#{now}" | tr -s '[:space:]' ' ' | grep -q -Eo "#{category} (#{amount}|#{inverse_amount})")
        command2 = %(hledger print -f #{options[:transaction_file]} "date:#{from}..#{now}" | tr -s '[:space:]' ' ' | grep -q -Eo "#{row['account']} (#{amount}|#{inverse_amount})")

        system(command1) || system(command2)
      end

      private

      attr_reader :forecast, :options, :output

      def initialize(forecast, options)
        @forecast = forecast
        @options = options
        @output = []
      end

      def tracked?(forecast)
        forecast.any? do |row|
          return true if row[:track] == true
        end

        return false
      end

      def process_tracked(row)
        row[:transactions].each do |t|
          next if t[:track] == false

          category = t[:category].ljust(options[:max_category])
          amount = t[:amount].to_s.ljust(options[:max_amount])

          header = "~ #{Date.new(Date.today.year, Date.today.month,
                                 1).next_month}  * [TRACKED] #{t[:description]}\n"
          transactions = "    #{category}    #{amount};  #{t[:description]}\n"
          footer = "    #{row[:account]}\n\n"

          output << { header: header, transactions: [transactions], footer: footer }
        end
      end
    end
  end
end
