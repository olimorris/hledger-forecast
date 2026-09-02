module HledgerForecast
  # Renders the summary as CSV, mirroring the forecast file's columns and
  # appending the amounts the summarizer calculated
  class SummarizerExporter
    HEADERS = %i[type frequency account from to description category amount annualised_amount].freeze
    MONEY_FIELDS = %i[amount annualised_amount rolled_up_amount].freeze

    def self.export(output, settings)
      new.export(output, settings)
    end

    def export(output, settings)
      headers = settings.roll_up ? HEADERS + [:rolled_up_amount] : HEADERS

      CSV.generate do |csv|
        csv << headers
        output.each { |row| csv << headers.map { |h| format_value(h, row[h]) } }
      end
    end

    private

    def format_value(key, value)
      return nil if value.nil?
      return value.iso8601 if value.is_a?(Date)
      return value.to_f.round(2) if MONEY_FIELDS.include?(key)

      value
    end
  end
end
