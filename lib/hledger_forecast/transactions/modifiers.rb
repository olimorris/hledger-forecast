module HledgerForecast
  module Transactions
    # Generate auto-posting hledger transactions
    # Example output:
    # = Expenses:Groceries date:2024-01-01..2025-12-31
    #    Expenses:Groceries    *0.1 ;  Groceries
    #    Assets:Checking       *-0.1
    class Modifiers
      def self.generate(data, options)
        new(data, options).generate
      end

      def generate
        return nil unless modifiers?

        process_modifier

        output
      end

      def self.get_modifiers(transaction, block)
        modifiers = []

        transaction['modifiers'].each do |modifier|
          description = transaction['description']
          description += " - #{modifier['description']}" unless modifier['description'].empty?

          modifiers << {
            account: block['account'],
            amount: modifier['amount'],
            category: transaction['category'],
            description:,
            from: Date.parse(modifier['from'] || block['from']),
            to: modifier['to'] ? Date.parse(modifier['to']) : nil
          }
        end

        modifiers
      end

      private

      attr_reader :data, :options, :output

      def initialize(data, options)
        @data = data
        @options = options
        @output = []
      end

      def modifiers?
        @data.any? do |_, blocks|
          blocks.any? do |block|
            block[:transactions].any? do |_, transactions|
              transactions.any? { |t| !t[:modifiers].empty? }
            end
          end
        end
      end

      def process_modifier
        get_transactions.each do |modifier|
          account = modifier[:account].ljust(@options[:max_category])
          category = modifier[:category].ljust(@options[:max_category])
          amount = modifier[:amount].to_s.ljust(@options[:max_amount] - 1)
          to = modifier[:to] ? "..#{modifier[:to]}" : nil

          header = "= #{modifier[:category]} date:#{modifier[:from]}#{to}\n"
          transactions = "    #{category}    *#{amount};  #{modifier[:description]}\n"
          footer = "    #{account}    *#{modifier[:amount] * -1}\n\n"

          output << { header:, transactions: [transactions], footer: }
        end
      end

      def get_transactions
        @data.each_with_object([]) do |(_key, blocks), result|
          blocks.each do |block|
            block[:transactions].each_value do |transactions|
              transactions.each do |t|
                result.concat(t[:modifiers]) if t[:modifiers]
              end
            end
          end
        end
      end
    end
  end
end
