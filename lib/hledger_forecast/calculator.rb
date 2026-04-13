module HledgerForecast
  module Calculator
    @calc = Dentaku::Calculator.new

    def self.evaluate(amount)
      return amount.to_f unless amount.is_a?(String)

      result = @calc.evaluate(amount.slice(1..-1))
      raise ArgumentError, "invalid amount '#{amount}'" if result.nil?

      result
    end

    def self.evaluate_from_date(value)
      value = value.to_s
      return Date.parse(value) unless value.start_with?("=")

      date_str, offset_expr = value[1..].split("+", 2)
      date = Date.parse(date_str)
      return date unless offset_expr

      date >> @calc.evaluate(offset_expr).to_i
    end

    def self.evaluate_date(from, to)
      return (from >> to) - 1 if to.is_a?(Numeric)
      return Date.parse(to) unless to.start_with?("=") || to.start_with?("+")

      (from >> @calc.evaluate(to.slice(1..-1))) - 1
    end
  end
end
