module HledgerForecast
  class Options
    def self.parse_command_line_options(args = ARGV, _stdin = $stdin)
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: Hledger-Forecast [options]"
        opts.separator ""

        opts.on("-f", "--forecast FILE",
                "The FORECAST yaml file to generate from") do |file|
          options[:forecast_file] = file
        end

        opts.on("-t", "--transaction FILE",
                "The base TRANSACTIONS file to extend from") do |file|
          options[:transactions_file] = file if file && !file.empty?
        end

        opts.on("-o", "--output-file FILE",
                "The OUTPUT file to create") do |file|
          options[:output_file] = file
        end

        opts.on("-s", "--start-date DATE",
                "The date to start generating from (yyyy-mm-dd)") do |a|
          options[:start_date] = a
        end

        opts.on("-e", "--end-date DATE",
                "The date to start generating to (yyyy-mm-dd)") do |a|
          options[:end_date] = a
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("--version", "Show version") do
          puts VERSION
          exit
        end

        opts.parse!(args)
      end

      options[:forecast_file] = "forecast.yml" unless options[:forecast_file]
      options[:output_file] = "forecast.journal" unless options[:output_file]

      today = Date.today

      unless options[:start_date]
        options[:default_dates] = true
        options[:start_date] =
          Date.new(today.year, today.month, 1).next_month.to_s
      end
      unless options[:end_date]
        options[:default_dates] = true
        options[:end_date] = Date.new(today.year + 3, 12, 31).to_s
      end

      return options
    end
  end
end
