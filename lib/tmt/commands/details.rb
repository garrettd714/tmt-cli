# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require_relative '../tool'
require_relative '../refresh'
require 'tty-table'
require 'tty-spinner'
require 'pastel'

module Tmt
  module Commands
    # show trade details
    class Details < Tmt::Command
      attr_reader :id, :options

      def initialize(id, options) # rubocop:disable Lint/MissingSuper
        @id = id
        @options = options
      end

      def execute(_input: $stdin, output: $stdout) # rubocop:disable all
        error = nil
        if options[:refresh]
          spinner = TTY::Spinner.new('[:spinner] Refreshing data...')
          spinner.auto_spin
          begin
            Tmt::Refresh.call(trade)
          rescue StandardError => e
            error = e.message
          end
          spinner.stop('Done!')
        end
        tool = Tool.call(trade)
        table = TTY::Table.new(
          [
            [
              'ticker', trade.ticker,
              'action', tool&.result&.titleize&.upcase,
              'ticker price', format('%.2f', trade.ticker_price) + (trade.break_even? ? "/be" : trade.itm? ? "/itm" : ''),
              'strategy', trade.strategy.humanize
            ],
            [
              'price', format('%.2f', trade.price),
              'close_at', format('%.2f', Tool.test(trade)&.mark.to_f),
              trade.put ? 'put' : '', trade.put ? format('%.2f', trade.put) : '',
              'account', trade.account.titleize
            ],
            [
              'mark', format('%.2f', trade.reload.mark),
              'days_held', trade.days_held,
              trade.call ? 'call' : '', trade.call ? format('%.2f', trade.call) : '',
              'source', trade.source.humanize
            ],
            [
              'size', trade.size,
              'days_left', trade.days_left,
              "deltas #{"\u0394".encode('utf-8')}", "#{trade.put_delta}/#{trade.call_delta}",
              trade.put ? 'put bid/ask' : '', trade.put ? "#{trade.put_bid}/#{trade.put_ask}" : ''
            ],
            [
              'P/L %', format('%.2f', trade.max_profit_pct),
              'time_in_trade_%', format('%.2f', trade.days_held_pct),
              'margin req', format('%.2f', trade.init_margin_req),
              trade.call ? 'call bid/ask' : '', trade.call ? "#{trade.call_bid}/#{trade.call_ask}" : ''
            ],
            [
              'P/L $', format('%.2f', trade.points * trade.multiplier * trade.contracts),
              'AR_rate', trade.accel_return.positive? ? "#{format('%.2f', trade.accel_return)}x" : '--',
              'Pop/P50', "#{trade.pop}/#{trade.p50}",
              trade.defined_risk? ? 'spread_width' : '', trade.defined_risk? ? trade.spread_width : nil
            ],
            [
              'expiration', trade.expiration.strftime('%m/%d/%y    '),
              trade.futures? ? 'roll_indicator' : '', trade.futures? && trade.roll_indicator.negative? ? trade.roll_indicator : nil,
              '', nil,
              trade.adjustment? ? 'trade P/L %' : '', trade.adjustment? ? format('%.2f', ((trade.total_credit - trade.mark) / trade.total_credit) * 100) : nil
            ],
            [
              'trade_id', trade.id,
              'opened_on', trade.opened.strftime('%m/%d/%y    '),
              trade.adjustment? ? 'total_credit' : 'adjustment', trade.adjustment? ? trade.total_credit : 'No',
              trade.adjustment? ? 'trade P/L $' : '', trade.adjustment? ? format('%.2f', (trade.total_credit - trade.mark) * trade.multiplier * trade.contracts) : nil
            ],
            [
              'opened_on', trade.opened.strftime('%m/%d/%y'),
              'closed_at', trade.closed_at&.localtime&.strftime('%m/%d/%y %H:%M') || '--',
              'created_at', trade.created_at.localtime.strftime('%m/%d/%y %H:%M'),
              'updated_at', trade.updated_at.localtime.strftime('%m/%d/%y %H:%M')
            ]
          ]
        )

        output.puts "\nPOSITION DETAILS:\n" + (error.present? ? "#{pastel.red(error)}\n" : "") + table.render(
          :unicode,
          width: 200,
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if col_index.even?
              pastel.white.on_blue(val.titleize)
            elsif col_index == 1 && [4, 5].include?(row_index) || col_index == 3 && row_index == 5 || col_index == 7 && [6, 7].include?(row_index)
              val.to_f.zero? ? val : (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            elsif col_index == 1 && row_index == 0
              pastel.black.on_bright_cyan(val.upcase)
            elsif col_index == 3 && row_index == 0
              if val.match?(/open/i)
                pastel.black.on_bright_green(val.upcase)
              else
                pastel.black.on_bright_red(val.upcase)
              end
            elsif col_index == 5 && row_index == 0
              val.match?(/\/be/) ? pastel.white.on_red(val.gsub(/\/be/, "  #{"\u24B7".encode('utf-8')}")) : val.match?(/\/itm/) ? pastel.black.on_yellow(val.gsub(/\/itm/, "  #{"\u24D8".encode('utf-8')}")) : val
            else
              val
            end
          end
        } + "\nNOTE:\n#{trade.note}\n\nINSIGHTS:\n\"#{tool.details}\""
      rescue NoMethodError => e
        output.puts pastel.red(e.message)
      end

      private

      def trade
        @trade ||= id.to_i.zero? ? Trade.where('lower(ticker) = ?', id.downcase).last : Trade.find(id)
      end
    end
  end
end
