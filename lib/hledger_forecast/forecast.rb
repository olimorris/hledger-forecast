module HledgerForecast
  class Forecast
    attr_reader :transactions, :settings

    def self.parse(csv_string, cli_options = nil)
      rows = CSV.parse(
        csv_string,
        headers: true,
        header_converters: -> (h) { h.to_s.tr("-", "_").to_sym },
        converters: :numeric
      )

      settings = Settings.parse(rows.select { |r| r[:type] == "settings" }, cli_options)
      transactions = rows.reject { |r| r[:type] == "settings" }.map { |r| Transaction.from_row(r) }

      new(transactions, settings, rows.headers.include?(:tag))
    end

    def has_tags_column? = @has_tags_column

    private

    def initialize(transactions, settings, has_tags_column)
      @transactions = transactions
      @settings = settings
      @has_tags_column = has_tags_column
    end
  end
end
