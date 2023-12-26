module HledgerForecast
  class Utilities
    def self.convert_amount(amount)
      case amount
      when /^-?\d+\.\d+$/ # Detects floating-point numbers (including negatives)
        amount.to_f
      when /^-?\d+$/ # Detects integers (including negatives)
        amount.to_i
      else
        amount
      end
    end
  end
end
