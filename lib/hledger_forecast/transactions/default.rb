module HledgerForecast
  module Transactions
    # Generate default hledger transactions
    # Example output:
    # ~ monthly from 2023-05-1  * Food expenses
    #    Expenses:Groceries    $250.00 ;  Food expenses
    #    Assets:Checking
    class Default
      def self.generate(forecast, settings)
        new(forecast, settings).generate
      end

      def generate
        forecast.each do |row|
          next if row[:type] == "settings"

          process_transactions(row)
        end

        output
      end

      private

      attr_reader :forecast, :settings, :output

      def initialize(forecast, settings)
        @forecast = forecast
        @settings = settings
        @output = []
      end

      def process_transactions(row)
        to = build_to_header(row[:to])
        frequency = get_periodic_rules(row[:type], row[:frequency])

        if @settings[:verbose]
          description = row[:description]
          transactions = [row]
        else
          description = get_descriptions(row[:transactions])
          transactions = row[:transactions]
        end

        header = build_header(row, frequency, to, description)
        footer = build_footer(row)

        output << build_transaction(header, transactions, footer)
      end

      def build_header(row, frequency, to, descriptions)
        "#{frequency} #{row[:from]}#{to}  * #{descriptions}\n"
      end

      def build_footer(block)
        "    #{block[:account]}\n\n"
      end

      def build_transaction(header, transactions, footer)
        { header: header, transactions: write_transactions(transactions), footer: footer }
      end

      def build_to_header(to)
        return " to #{to}" if to
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

          t[:amount] = t[:amount].to_s.ljust(@settings[:max_amount] + 5)
          t[:category] = t[:category].to_s.ljust(@settings[:max_category])

          "    #{t[:category]}    #{t[:amount]};  #{t[:description]}\n"
        end.compact
      end
    end
  end
end
