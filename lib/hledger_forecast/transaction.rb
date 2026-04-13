module HledgerForecast
  ANNUAL_MULTIPLIERS = {
    "monthly" => 12,
    "quarterly" => 4,
    "half-yearly" => 2,
    "yearly" => 1,
    "once" => 1,
    "daily" => 352,
    "weekly" => 52
  }.freeze

  Transaction = Struct.new(
    :type,
    :frequency,
    :account,
    :from,
    :to,
    :description,
    :category,
    :amount,
    :roll_up,
    :summary_exclude,
    :tags,
    keyword_init: true
  ) do
    def self.from_row(row)
      from = Calculator.evaluate_from_date(row[:from])
      new(
        type: row[:type],
        frequency: row[:frequency],
        account: row[:account],
        from: from,
        to: row[:to] ? Calculator.evaluate_date(from, row[:to]) : nil,
        description: row[:description],
        category: row[:category],
        amount: Calculator.evaluate(row[:amount]),
        roll_up: row[:roll_up],
        summary_exclude: row[:summary_exclude],
        tags: row[:tag].to_s.split("|").map(&:strip).reject(&:empty?)
      )
    end

    def matches_tags?(filter_tags)
      return true if filter_tags.nil? || filter_tags.empty?

      exclude_tags = filter_tags.select { |t| t.start_with?("-") }.map { |t| t[1..] }
      include_tags = filter_tags.reject { |t| t.start_with?("-") }

      return false if exclude_tags.any? && (tags & exclude_tags).any?
      return (tags & include_tags).any? if include_tags.any?

      true
    end

    def annualised_amount
      if roll_up
        amount * roll_up
      else
        amount *
          ANNUAL_MULTIPLIERS.fetch(type) {
            raise(KeyError, "Unknown type '#{type}'. Set a roll-up for custom transactions.")
          }
      end
    end

    def summary_exclude? = !!summary_exclude
  end

  TransactionGroup = Struct.new(:type, :frequency, :account, :from, :to, :transactions, keyword_init: true)
end
