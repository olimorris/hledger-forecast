module HledgerForecast
  # Calculate various
  class Calculator
    def initialize
      @calculator = Dentaku::Calculator.new
    end

    def evaluate(amount)
      return amount.to_f unless amount.is_a?(String)

      @calculator.evaluate(amount.slice(1..-1))
    end

    def evaluate_date(from, to)
      if to[0] != "="
        return to if to.is_a?(Date)

        return Date.parse(to)
      end

      # Subtract a day from the final date
      (from >> @calculator.evaluate(to.slice(1..-1))) - 1
    end
  end
end
