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

      return puts "Files cannot be compared" unless csv1.length == csv2.length && csv1[0].length == csv2[0].length

      # Add bolded headers
      @table.add_row csv1[0].map(&:bold)
      @table.add_separator

      generate_diff(csv1, csv2).drop(1).each do |row|
        @table.add_row [row[0].bold] + row[1..-1]
      end

      puts @table
    end

    def header?(row_idx)
      row_idx == 0
    end

    def generate_diff(csv1, csv2)
      csv1.each_with_index.map do |row, i|
        row.each_with_index.map do |cell, j|
          if header?(i) || j == 0 # Checking for the first column here
            csv2[i][j]
          else
            difference = parse_money(cell) - parse_money(csv2[i][j])
            format_difference(difference)
          end
        end
      end
    end

    def parse_money(value)
      Money.new(value.delete("£").to_f * 100).to_f
    end

    def format_difference(amount)
      formatted_amount = Formatter.format_money(amount, { currency: 'GBP' })

      return formatted_amount if amount == 0

      amount > 0 ? formatted_amount.green : formatted_amount.red
    end
  end
end
