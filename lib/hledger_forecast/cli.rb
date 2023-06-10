module HledgerForecast
  # The Command Line Interface for the application
  # Takes user arguments and translates them into actions
  class Cli
    def self.run(command, options)
      case command
      when 'generate'
        generate(options)
      when 'summarize'
        summarize(options)
      else
        puts "Unknown command: #{command}"
        exit(1)
      end
    end

    def self.parse_commands(args = ARGV, _stdin = $stdin)
      command = nil
      options = {}

      global = OptionParser.new do |opts|
        opts.banner = "Usage: hledger-forecast [command] [options]"
        opts.separator ""
        opts.separator "Commands:"
        opts.separator "  generate    Generate the forecast file"
        opts.separator "  summarize   Summarize the forecast file and output to the terminal"
        opts.separator ""
        opts.separator "Options:"

        opts.on_tail("-h", "--help", "Show this help message") do
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Show the installed version") do
          puts VERSION
          exit
        end
      end

      begin
        global.order!(args)
        command = args.shift || 'generate'
      rescue OptionParser::InvalidOption => e
        puts e
        puts global
        exit(1)
      end

      case command
      when 'generate'
        options = parse_generate_options(args)
      when 'summarize'
        options = parse_summarize_options(args)
      else
        puts "Unknown command: #{command}"
        puts global
        exit(1)
      end

      return command, options
    end

    def self.parse_generate_options(args)
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: hledger-forecast generate [options]"
        opts.separator ""

        opts.on("-f", "--forecast FILE",
                "The path to the FORECAST csv/yml file to generate from") do |file|
          options[:forecast_file] = file

          options[:file_type] = if File.extname(file) == '.csv'
                                  "csv"
                                else
                                  "yml"
                                end

          options[:output_file] ||= file.sub(options[:file_type], 'journal')
        end

        opts.on("-o", "--output-file FILE",
                "The path to the OUTPUT file to create") do |file|
          options[:output_file] = file
        end

        opts.on("-t", "--transaction FILE",
                "The path to the TRANSACTION journal file") do |file|
          options[:transaction_file] = file
        end

        opts.on("-v", "--verbose",
                "Don't group transactions by type in the output file") do
          options[:verbose] = true
        end

        opts.on("--force",
                "Force an overwrite of the output file") do
          options[:force] = true
        end

        opts.on("--no-track",
                "Don't track any transactions") do
          options[:no_track] = true
        end

        opts.on_tail("-h", "--help", "Show this help message") do
          puts opts
          exit
        end
      end.parse!(args)

      options[:forecast_file] = "forecast.csv" unless options[:forecast_file]
      options[:file_type] = "csv" unless options[:file_type]
      options[:output_file] = "forecast.journal" unless options[:output_file]

      options
    end

    def self.parse_summarize_options(args)
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: hledger-forecast summarize [options]"
        opts.separator ""

        opts.on("-f", "--forecast FILE",
                "The path to the FORECAST csv/yml file to summarize") do |file|
          options[:file_type] = if File.extname(file) == '.csv'
                                  "csv"
                                else
                                  "yml"
                                end
          options[:forecast_file] = file
        end

        opts.on("-r", "--roll-up PERIOD",
                "The period to roll-up your forecasts into. One of:",
                "[yearly], [half-yearly], [quarterly], [monthly], [weekly], [daily]") do |rollup|
          options[:roll_up] = rollup
        end

        opts.on("-v", "--verbose",
                "Show additional information in the summary") do |_|
          options[:verbose] = true
        end

        # opts.on("--from DATE",
        #         "Include transactions that start FROM a given DATE [yyyy-mm-dd]") do |from|
        #   options[:from] = from
        # end
        #
        # opts.on("--to DATE",
        #         "Include transactions that run TO a given DATE [yyyy-mm-dd]") do |to|
        #   options[:to] = to
        # end

        # opts.on("-s", "--scenario \"NAMES\"",
        #         "Include transactions from given scenarios, e.g.:",
        #         "\"base, rennovation, car purchase\"") do |_scenario|
        #   # Loop through scenarios, seperated by a comma
        #   options[:scenario] = {}
        # end

        opts.on_tail("-h", "--help", "Show this help message") do
          puts opts
          exit
        end
      end.parse!(args)

      options
    end

    def self.generate(options)
      forecast = File.read(options[:forecast_file])

      begin
        forecast = HledgerForecast::CSVParser.parse(forecast) if options[:file_type] == "csv"
        transactions = Generator.generate(forecast, options)
      rescue StandardError => e
        puts "An error occurred while generating transactions: #{e.message}"
        exit(1)
      end

      output_file = options[:output_file]

      if File.exist?(output_file) && !options[:force]
        print "\nFile '#{output_file}' already exists. Overwrite? (y/n): "
        overwrite = gets.chomp.downcase

        if overwrite == 'y'
          File.write(output_file, transactions)
          puts "\nSuccess: ".bold.green + "File '#{output_file}' has been overwritten."
        else
          puts "\nInfo: ".bold.blue + "Operation aborted. File '#{output_file}' was not overwritten."
        end
      else
        File.write(output_file, transactions)
        puts "\nSuccess: ".bold.green + "File '#{output_file}' has been created"
      end
    end

    def self.summarize(options)
      config = File.read(options[:forecast_file])
      config = HledgerForecast::CSVParser.parse(config) if options[:file_type] == "csv"

      summarizer = Summarizer.summarize(config, options)

      puts SummarizerFormatter.format(summarizer[:output], summarizer[:settings])
    end
  end
end
