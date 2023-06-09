module HledgerForecast
  module Transactions
    # Generate default hledger transactions
    # Example output:
    # ~ monthly from 2023-05-1  * Food expenses
    #    Expenses:Groceries    $250.00 ;  Food expenses
    #    Assets:Checking
    class Default
      def self.generate(data, options)
        new(data, options).generate
      end

      def generate
        data.each_value do |blocks|
          blocks.each do |block|
            if block[:type] == "custom"
              process_custom_block(block)
            else
              process_block(block)
            end
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

      def process_custom_block(block)
        block[:transactions].each do |to, transactions|
          to = get_header(block[:to], to)

          transactions.each do |t|
            header = "~ #{t[:frequency]} from #{block[:from]}#{to}  * #{t[:description]}\n"
            footer = "    #{block[:account]}\n\n"
            output << { header: header, transactions: write_transactions([t]), footer: footer }
          end
        end
      end

      def process_block(block)
        block[:transactions].each do |to, transactions|
          to = get_header(block[:to], to)
          block[:descriptions] = get_descriptions(transactions)

          frequency = get_periodic_rules(block[:type], block[:frequency])

          header = "#{frequency} #{block[:from]}#{to}  * #{block[:descriptions]}\n"
          footer = "    #{block[:account]}\n\n"

          output << { header: header, transactions: write_transactions(transactions), footer: footer }
        end
      end

      def get_header(block, transaction)
        return " to #{transaction}" if transaction
        return " to #{block}" if block

        return nil
      end

      def get_descriptions(transactions)
        transactions.map do |t|
          # Skip transactions that have been marked as tracked
          next if t[:track]

          t[:description]
        end.compact.join(', ')
      end

      def get_periodic_rules(type, frequency)
        map = {
          'once' => '~',
          'monthly' => '~ monthly from',
          'quarterly' => '~ every 3 months from',
          'half-yearly' => '~ every 6 months from',
          'yearly' => '~ yearly from',
          'custom' => "~ #{frequency} from"
        }

        map[type]
      end

      def write_transactions(transactions)
        transactions.map do |t|
          # Skip transactions that have been marked as tracked
          next if t[:track]

          t[:amount] = t[:amount].to_s.ljust(options[:max_amount])
          t[:category] = t[:category].ljust(options[:max_category])

          "    #{t[:category]}    #{t[:amount]};  #{t[:description]}\n"
        end
      end
    end
  end
end
