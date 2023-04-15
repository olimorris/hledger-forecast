module HledgerForecast
  class CLI
    def self.run(args)
      end_date = args[:end_date]
      start_date = args[:start_date]
      forecast = File.read(args[:forecast_file])
      transactions = args[:transactions_file] ? File.read(args[:transactions_file]) : nil

      return HledgerForecast::Summarize.generate(forecast) if args[:summarize]

      puts "[Using default dates: #{start_date} to #{end_date}]" if args[:default_dates]

      transactions = Generator.create_journal_entries(transactions, forecast, start_date, end_date)

      output_file = args[:output_file]
      if File.exist?(output_file) && !args[:force]
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
  end
end
