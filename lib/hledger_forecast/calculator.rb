module HledgerForecast
  module Calculator
    @calc = Dentaku::Calculator.new

    def self.evaluate(amount)
      return amount.to_f unless amount.is_a?(String)

      @calc.evaluate(amount.slice(1..-1))
    end

    def self.evaluate_date(from, to)
      return (from >> to) - 1 if to.is_a?(Numeric)
      return Date.parse(to) unless to.start_with?("=") || to.start_with?("+")

      (from >> @calc.evaluate(to.slice(1..-1))) - 1
    end
  end
end
