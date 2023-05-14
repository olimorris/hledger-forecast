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
      def self.generate(data, options)
        new(data, options).generate
      end

      def generate
        return nil unless tracked?(data)

        data.each_value do |blocks|
          blocks.each do |block|
            process_tracked(block)
          end
        end

        output
      end

      def self.track?(transaction, data, options)
        now = Date.today
        transaction['track'] && Date.parse(data['from']) <= now && !exists?(transaction, data['account'],
                                                                            data['from'], now, options)
      end

      def self.exists?(transaction, account, from, to, options)
        # Format the money
        amount = Formatter.format_money(transaction['amount'], options)
        inverse_amount = Formatter.format_money(transaction['amount'] * -1, options)

        category = transaction['category'].gsub('[', '\\[').gsub(']', '\\]').gsub('(', '\\(').gsub(')', '\\)')

        # We run two commands and check to see if category +/- amount or account +/- amount exists
        command1 = %(hledger print -f #{options[:transaction_file]} "date:#{from}..#{to}" | tr -s '[:space:]' ' ' | grep -q -Eo "#{category} (#{amount}|#{inverse_amount})")
        command2 = %(hledger print -f #{options[:transaction_file]} "date:#{from}..#{to}" | tr -s '[:space:]' ' ' | grep -q -Eo "#{account} (#{amount}|#{inverse_amount})")

        system(command1) || system(command2)
      end

      private

      attr_reader :data, :options, :output

      def initialize(data, options)
        @data = data
        @options = options
        @output = []
      end

      def tracked?(data)
        data.any? do |_, blocks|
          blocks.any? do |block|
            block[:transactions].any? do |_, transactions|
              transactions.any? { |t| t[:track] }
            end
          end
        end
      end

      def process_tracked(block)
        block[:transactions].each do |_to, transactions|
          transactions.each do |t|
            next unless t[:track]

            category = t[:category].ljust(options[:max_category])
            amount = t[:amount].to_s.ljust(options[:max_amount])

            header = "~ #{Date.new(Date.today.year, Date.today.month,
                                   1).next_month}  * [TRACKED] #{t[:description]}\n"
            transactions = "    #{category}    #{amount};  #{t[:description]}\n"
            footer = "    #{block[:account]}\n\n"

            output << { header:, transactions: [transactions], footer: }
          end
        end
      end
    end
  end
end
