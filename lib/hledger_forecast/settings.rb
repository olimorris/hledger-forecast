module HledgerForecast
  class Settings
    DEFAULTS = {
      currency:            'USD',
      show_symbol:         true,
      sign_before_symbol:  false,
      thousands_separator: ','
    }.freeze

    attr_reader :currency, :show_symbol, :sign_before_symbol, :thousands_separator,
                :verbose, :roll_up

    def self.parse(settings_rows, cli_options = nil)
      new(settings_rows, cli_options)
    end

    def verbose? = @verbose

    private

    def initialize(settings_rows, cli_options)
      overrides = settings_rows.each_with_object({}) { |row, h| h[row[:frequency]] = row[:account] }
      opts      = cli_options || {}

      @currency            = opts[:currency]            || overrides['currency']            || DEFAULTS[:currency]
      @show_symbol         = opts[:show_symbol]         || overrides['show_symbol']         || DEFAULTS[:show_symbol]
      @sign_before_symbol  = opts[:sign_before_symbol]  || overrides['sign_before_symbol']  || DEFAULTS[:sign_before_symbol]
      @thousands_separator = opts[:thousands_separator] || overrides['thousands_separator'] || DEFAULTS[:thousands_separator]
      @verbose             = opts[:verbose] || false
      @roll_up             = opts[:roll_up]
    end
  end
end
