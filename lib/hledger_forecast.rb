#!/usr/bin/env ruby

require 'colorize'
require 'date'
require 'dentaku'
require 'highline'
require 'money'
require 'optparse'
require 'terminal-table'
require 'yaml'

Money.locale_backend = nil
Money.rounding_mode = BigDecimal::ROUND_HALF_UP

require_relative 'hledger_forecast/calculator'
require_relative 'hledger_forecast/cli'
require_relative 'hledger_forecast/formatter'
require_relative 'hledger_forecast/generator'
require_relative 'hledger_forecast/settings'
require_relative 'hledger_forecast/summarizer'
require_relative 'hledger_forecast/version'

require_relative 'hledger_forecast/transactions/default'
require_relative 'hledger_forecast/transactions/modifiers'
require_relative 'hledger_forecast/transactions/trackers'
