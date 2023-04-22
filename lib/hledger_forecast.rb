#!/usr/bin/env ruby

require 'colorize'
require 'date'
require 'highline'
require 'money'
require 'optparse'
require 'terminal-table'
require 'yaml'

Money.locale_backend = nil
Money.rounding_mode = BigDecimal::ROUND_HALF_UP

require_relative 'hledger_forecast/version'
require_relative 'hledger_forecast/generator'
require_relative 'hledger_forecast/summarize'
# require_relative 'hledger_forecast/checker'
require_relative 'hledger_forecast/cli'
