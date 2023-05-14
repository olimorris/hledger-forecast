module HledgerForecast
  module Transactions
    # Generate regular hledger transactions which track specific forecasts
    # Example output:
    # ~ monthly from 2023-05-1  * [TRACKED] Food expenses
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
