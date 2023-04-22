module HledgerForecast
  # The Command Line Interface for the application
  # Takes user arguments and translates them into actions
  class Cli

    def self.run(subcommand, options)
      case subcommand
      when 'generate'
        generate(options)
      when 'summarize'
        summarize(options)
      else
        puts "Unknown command: #{subcommand}"
        exit(1)
      end
    end

    def self.parse_commands(args = ARGV, _stdin = $stdin)
      subcommand = nil
      options = {}

      global = OptionParser.new do |opts|
        opts.banner = "Usage: hledger-forecast [subcommand] [options]"
        opts.separator ""
        opts.separator "Subcommands:"
        opts.separator "  generate    Generate the forecast file"
        opts.separator "  summarize   Summarize the forecast file and output to the terminal"
        opts.separator ""
        opts.separator "Options:"

        opts.on_tail("-h", "--help", "Show this help message") do
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Show version") do
          puts VERSION
          exit
        end
      end

      begin
        global.order!(args)
        subcommand = args.shift || 'generate'
      rescue OptionParser::InvalidOption => e
        puts e
        puts global
        exit(1)
      end

      case subcommand
      when 'generate'
        options = parse_generate_options(args)
      when 'summarize'
        options = parse_summarize_options(args)
      else
        puts "Unknown subcommand: #{subcommand}"
        puts global
        exit(1)
      end

      return subcommand, options
    end

    def self.parse_generate_options(args)
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: Hledger-Forecast generate [options]"
        opts.separator ""

        opts.on("-t", "--transaction FILE",
                "The base TRANSACTIONS file to extend from") do |file|
          options[:transactions_file] = file if file && !file.empty?
        end

        opts.on("-f", "--forecast FILE",
                "The FORECAST yaml file to generate from") do |file|
          options[:forecast_file] = file
          options[:output_file] ||= file.sub(/\.yml$/, '.journal')
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

        opts.on("--force",
                "Force an overwrite of the output file") do |a|
          options[:force] = a
        end

        opts.on_tail("-h", "--help", "Show this help message") do
          puts opts
          exit
        end
      end.parse!(args)

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

      options
    end

    def self.parse_summarize_options(args)
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: Hledger-Forecast summarize [options]"
        opts.separator ""

        opts.on("-f", "--forecast FILE",
                "The FORECAST yaml file to summarize") do |file|
          options[:forecast_file] = file
        end

        opts.on_tail("-h", "--help", "Show this help message") do
          puts opts
          exit
        end
      end.parse!(args)

      options
    end

    def self.generate(options)
      end_date = options[:end_date]
      start_date = options[:start_date]
      forecast = File.read(options[:forecast_file])
      transactions = options[:transactions_file] ? File.read(options[:transactions_file]) : nil

      # Generate the forecast
      puts "[Using default dates: #{start_date} to #{end_date}]" if options[:default_dates]

      transactions = Generator.generate(transactions, forecast, start_date, end_date)

      output_file = options[:output_file]
      if File.exist?(output_file) && !options[:force]
        print "File '#{output_file}' already exists. Overwrite? (y/n): "
        overwrite = gets.chomp.downcase

        if overwrite == 'y'
          File.write(output_file, transactions)
          puts "File '#{output_file}' has been overwritten."
        else
          puts "Operation aborted. File '#{output_file}' was not overwritten."
        end
      else
        File.write(output_file, transactions)
        puts "File '#{output_file}' has been created."
      end
    end

    def self.summarize(options)
      forecast = File.read(options[:forecast_file])
      puts Summarize.generate(forecast)
    end

    # def self.run(args)
    #   end_date = args[:end_date]
    #   start_date = args[:start_date]
    #   forecast = File.read(args[:forecast_file])
    #   transactions = args[:transactions_file] ? File.read(args[:transactions_file]) : nil
    #
    #   # Output the summary
    #   return HledgerForecast::Summarize.generate(forecast) if args[:summarize]
    #
    #   # Generate the forecast
    #   unless args[:skip]
    #
    #     puts "[Using default dates: #{start_date} to #{end_date}]" if args[:default_dates]
    #
    #     transactions = Generator.generate(transactions, forecast, start_date, end_date)
    #
    #     output_file = args[:output_file]
    #     if File.exist?(output_file) && !args[:force]
    #       print "File '#{output_file}' already exists. Overwrite? (y/n): "
    #       overwrite = gets.chomp.downcase
    #
    #       if overwrite == 'y'
    #         File.write(output_file, transactions)
    #         puts "File '#{output_file}' has been overwritten."
    #       else
    #         puts "Operation aborted. File '#{output_file}' was not overwritten."
    #       end
    #     else
    #       File.write(output_file, transactions)
    #       puts "File '#{output_file}' has been created."
    #     end
    #   end
    #
    #   # Check for missing transactions
    #   return unless args[:check] && args[:transactions_file] && args[:forecast_file]
    #
    #   HledgerForecast::Checker.check(args)
    # end
  end
end
