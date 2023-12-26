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
      when 'compare'
        compare(options)
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
        opts.separator "  generate    Generate a forecast from a file"
        opts.separator "  summarize   Summarize the forecast file and output to the terminal"
        opts.separator "  compare     Compare and highlight the differences between two CSV files"
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

      if args.empty?
        puts global
        exit(1)
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
      when 'compare'
        options = parse_compare_options(args)
      else
        puts "Unknown command: #{command}"
        puts global
        exit(1)
      end

      return command, options
    end

    def self.parse_generate_options(args)
      options = {}

      global = OptionParser.new do |opts|
        opts.banner = "Usage: hledger-forecast generate [options]"
        opts.separator ""

        opts.on("-f", "--forecast FILE",
                "The path to the FORECAST csv file to generate from") do |file|
          options[:forecast_file] = file
          options[:output_file] ||= file.sub(options[:forecast_file], 'journal')
        end

        opts.on("-o", "--output-file FILE",
                "The path to the OUTPUT file to create") do |file|
          options[:output_file] = file
        end

        opts.on("-t", "--transaction FILE",
                "The path to the TRANSACTION journal file") do |file|
          options[:transaction_file] = file
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
      end

      begin
        global.parse!(args)
      rescue OptionParser::InvalidOption => e
        puts e
        puts global
        exit(1)
      end

      if options.empty?
        puts global
        exit(1)
      end

      options[:forecast_file] ||= "forecast.csv"
      options[:file_type] ||= "csv"
      options[:output_file] ||= "forecast.journal"

      options
    end

    def self.parse_summarize_options(args)
      options = {}

      global = OptionParser.new do |opts|
        opts.banner = "Usage: hledger-forecast summarize [options]"
        opts.separator ""

        opts.on("-f", "--forecast FILE",
                "The path to the FORECAST csv file to summarize") do |file|
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
      end

      begin
        global.parse!(args)
      rescue OptionParser::InvalidOption => e
        puts e
        puts global
        exit(1)
      end

      if options.empty?
        puts global
        exit(1)
      end

      options
    end

    def self.parse_compare_options(args)
      options = {}

      global = OptionParser.new do |opts|
        opts.banner = "Usage: hledger-forecast compare [path/to/file1.csv] [path/to/file2.csv]"
        opts.separator ""
      end

      begin
        global.parse!(args)
      rescue OptionParser::InvalidOption => e
        puts e
        puts global
        exit(1)
      end

      if args[0].nil? || args[1].nil?
        puts global
        exit(1)
      end

      options[:file1] = args[0]
      options[:file2] = args[1]

      options
    end

    def self.generate(options)
      forecast = File.read(options[:forecast_file])

      begin
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

    def self.compare(options)
      if !File.exist?(options[:file1]) || !File.exist?(options[:file2])
        return puts "\nError: ".bold.red + "One or more of the files could not be found to compare"
      end

      puts Comparator.compare(options[:file1], options[:file2])
    end
  end
end
