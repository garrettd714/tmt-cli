# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require_relative './open2'
require 'tty-prompt'

module Tmt
  module Commands
    # Open Trade
    class Open < Tmt::Command
      def initialize(options) # rubocop:disable Lint/MissingSuper
        @options = options
      end

      def execute(_input: $stdin, output: $stdout) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        responses = prompt.collect do
          if key(:ticker).ask('Ticker symbol:', default: '/ES', required: true).match?(/\/ES/)
            key(:root_symbol).ask('Root symbol (no slash):')
          end
          key(:strategy).select('Strategy:', Trade.strategies.symbolize_keys, required: true)
          key(:account).select('Trading account:', Trade.accounts.symbolize_keys, required: true)
          key(:opened).ask('Date opened trade:', default: Time.current.strftime("%Y-%m-%d"), required: true, convert: :date)
          key(:expiration).ask('Expiration date:', default: 'yyyy-mm-dd', required: true, convert: :date)
          key(:size).ask('Position size:', default: -1, required: true, convert: :int)
          key(:price).ask('Trade price:', default: 7.50, required: true, convert: :float)
          key(:mark).ask('Current mark price:', required: true, convert: :float)
        end
        %i[price mark].each { |f| responses[f] = format('%.2f', responses[f]) }
        responses[:ticker] = responses[:ticker].upcase
        trade = Trade.create!(**responses)

        Open2.new(trade, @options).execute if prompt.yes?('Would you like to continue?')
        output.puts pastel.green('Trade Opened!')
      rescue TTY::Reader::InputInterrupt
        puts pastel.red('Cancelled input. Data not saved')
      end
    end
  end
end
