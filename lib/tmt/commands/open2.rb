# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require 'tty-prompt'

module Tmt
  module Commands
    # Open Trade
    class Open2 < Tmt::Command
      attr_reader :trade

      def initialize(trade, options) # rubocop:disable Lint/MissingSuper
        @trade = trade
        @options = options
      end

      def execute(_input: $stdin, _output: $stdout) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        responses = prompt.collect do
          key(:put).ask('Put strike:', convert: :float)
          key(:call).ask('Call strike:', convert: :float)
          if Trade.last.defined_risk?
            key(:spread_width).ask('Spread width:', convert: :float)
          end
          if key(:adjustment).yes?('Is this an adjustment?')
            key(:total_credit).ask('Total credits received:', convert: :float)
          end
          key(:init_margin_req).ask('Initial margin requirement:', convert: :float)
          key(:put_delta).ask('Put delta:', value: '-0.15', convert: :float)
          key(:call_delta).ask('Call delta:', value: '0.15', convert: :float)
          key(:ticker_price).ask('Current price of underlying:', convert: :float)
          key(:pop).ask('Probability of Profit (POP):', value: '86', convert: :int)
          key(:p50).ask('Probability of 50% Profit (P50):', value: '94', convert: :int)
          key(:source).select('Source:', Trade.sources.symbolize_keys, required: true)
          key(:note).ask('Add note:')
        end
        %i[ticker_price init_margin_req].each { |f| responses[f] = format('%.2f', responses[f]) }
        responses[:note] = "#{responses[:note]}\n"
        trade.update!(**responses)
      rescue TTY::Reader::InputInterrupt
        puts pastel.red('Cancelled input. Additional data not saved')
      end
    end
  end
end
