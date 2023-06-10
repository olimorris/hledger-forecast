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
            process_block(block)
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

      def process_block(block)
        block[:transactions].each do |to, transactions|
          to = get_header(block[:to], to)

          if block[:type] == "custom"
            process_custom_transactions(block, to, transactions)
          else
            process_standard_transactions(block, to, transactions)
          end
        end
      end

      def process_custom_transactions(block, to, transactions)
        transactions.each do |t|
          frequency = get_periodic_rules(block[:type], t[:frequency])

          header = build_header(block, to, frequency, t[:description])
          footer = build_footer(block)
          output << build_transaction(header, [t], footer)
        end
      end

      def process_standard_transactions(block, to, transactions)
        if @options[:verbose]
          transactions.map do |t|
            # Skip transactions that have been marked as tracked
            next if t[:track]

            frequency = get_periodic_rules(block[:type], block[:frequency])
            header = build_header(block, to, frequency, t[:description])
            footer = build_footer(block)
            output << build_transaction(header, [t], footer)
          end
          return
        end

        block[:descriptions] = get_descriptions(transactions)
        frequency = get_periodic_rules(block[:type], block[:frequency])
        header = build_header(block, to, frequency, block[:descriptions])
        footer = build_footer(block)
        output << build_transaction(header, transactions, footer)
      end

      def build_header(block, to, frequency, description)
        "#{frequency} #{block[:from]}#{to}  * #{description}\n"
      end

      def build_footer(block)
        "    #{block[:account]}\n\n"
      end

      def build_transaction(header, transactions, footer)
        { header: header, transactions: write_transactions(transactions), footer: footer }
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
