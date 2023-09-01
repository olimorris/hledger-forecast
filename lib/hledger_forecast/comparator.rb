module HledgerForecast
  # Compare the output of two CSV files
  class Comparator
    def initialize
      @table = Terminal::Table.new
    end

    def self.compare(file1, file2)
      new.compare(file1, file2)
    end

    def compare(file1, file2)
      compare_csvs(file1, file2)
    end

    private

    def compare_csvs(file1, file2)
      csv1 = CSV.read(file1)
      csv2 = CSV.read(file2)

      unless csv1.length == csv2.length && csv1[0].length == csv2[0].length
        return puts "\nError: ".bold.red + "The files have different formats and cannot be compared"
      end

      @table.add_row csv2[0].map(&:bold)
      @table.add_separator

      generate_diff(csv1, csv2).drop(1).each do |row|
        @table.add_row [row[0].bold] + row[1..]
      end

      puts @table
    end

    def header?(row_num)
      row_num == 0
    end

    def generate_diff(csv1, csv2)
      csv1.each_with_index.map do |row, i|
        row.each_with_index.map do |cell, j|
          if header?(i) || j == 0 # Checking for the first column here
            csv2[i][j]
          else
            difference = parse_money(csv2[i][j]) - parse_money(cell)
            format_difference(difference, detect_currency(cell))
          end
        end
      end
    end

    def detect_currency(str)
      return nil if str == "0"

      # Explicitly check for common currencies
      return "GBP" if str.include?("£")
      return "EUR" if str.include?("€")
      return "USD" if str.include?("$")

      Money::Currency.table.each_value do |currency|
        return currency[:iso_code] if str.include?(currency[:symbol])
      end

      nil
    end

    def parse_money(value)
      return 0.0 if value.strip == '0'

      value.gsub(/[^0-9.-]/, '').to_f
    end

    def format_difference(amount, currency)
      formatted_amount = if currency.nil?
                           format("%.2f", amount)
                         else
                           Formatter.format_money(amount, { currency: currency })
                         end

      return formatted_amount if amount == 0

      amount > 0 ? formatted_amount.green : formatted_amount.red
    end
  end
end
