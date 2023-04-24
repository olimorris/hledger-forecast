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
                "The FORECAST yaml file to generate from") do |file|
          options[:forecast_file] = file
          options[:output_file] ||= file.sub(/\.yml$/, '.journal')
        end

        opts.on("-o", "--output-file FILE",
                "The OUTPUT file to create") do |file|
          options[:output_file] = file
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
        options[:use_default_dates] = true
        options[:start_date] =
          Date.new(today.year, today.month, 1).next_month.to_s
      end
      unless options[:end_date]
        options[:use_default_dates] = true
        options[:end_date] = Date.new(today.year + 3, 12, 31).to_s
      end

      options
    end

    def self.parse_summarize_options(args)
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: hledger-forecast summarize [options]"
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
      forecast = File.read(options[:forecast_file])

      begin
        transactions = Generator.generate(forecast)
      rescue StandardError => e
        puts "An error occurred while generating transactions: #{e.message}"
        exit(1)
      end

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
  end
end
