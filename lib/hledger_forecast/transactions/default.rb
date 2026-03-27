module HledgerForecast
  module Transactions
    # Generate hledger periodic transactions from TransactionGroups.
    # Example output:
    # ~ monthly from 2023-05-01  * Food expenses
    #    Expenses:Groceries    $250.00 ;  Food expenses
    #    Assets:Checking
    class Default
      def self.render(groups, settings)
        new(groups, settings).render
      end

      def render
        groups.map { |group| render_group(group) }.join.gsub(/\n{2,}/, "\n\n")
      end

      private

      attr_reader :groups, :settings

      def initialize(groups, settings)
        @groups = groups
        @settings = settings
        precompute_padding
      end

      def precompute_padding
        all_transactions = groups.flat_map(&:transactions)
        formatted_amounts = all_transactions.map { |t| Formatter.format_money(t.amount, settings) }

        @max_amount = formatted_amounts.map(&:length).max || 0
        @max_category = all_transactions.map { |t| t.category.to_s.length }.max || 0
      end

      def render_group(group)
        render_header(group) + render_postings(group) + "    #{group.account}\n\n"
      end

      def render_header(group)
        to_part = " to #{group.to}" if group.to
        descriptions = group.transactions.map(&:description).join(", ")
        "#{periodic_rule_for(group.type, group.frequency)} #{group.from}#{to_part}  * #{descriptions}\n"
      end

      def render_postings(group)
        group
          .transactions
          .map do |t|
            amount = Formatter.format_money(t.amount, settings)
            category = t.category.to_s.ljust(@max_category)

            if t.tags.any?
              tags_str = t.tags.map { |tag| "#{tag}:" }.join(", ")
              "    #{category}    #{amount.ljust(@max_amount)};  #{tags_str}\n"
            else
              "    #{category}    #{amount}\n"
            end
          end
          .join
      end

      def periodic_rule_for(type, frequency)
        {
          "once" => "~",
          "monthly" => "~ monthly from",
          "quarterly" => "~ every 3 months from",
          "half-yearly" => "~ every 6 months from",
          "yearly" => "~ yearly from",
          "custom" => "~ #{frequency} from"
        }.fetch(type)
      end
    end
  end
end
