# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require_relative '../tool'
require 'tty-table'

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
        tool = trade.open? ? Tool.call(trade) : OpenStruct.new(result: 'closed', details: 'n/a')
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
              trade.open? ? 'close_at' : 'closed_at', trade.open? ? format('%.2f', Tool.test(trade)&.mark.to_f) : trade.closed_at.localtime.strftime('%m/%d/%y %H:%M'),
              trade.put ? 'put' : '{put}', trade.put ? format('%.2f', trade.put) : '',
              'account', trade.account.titleize
            ],
            [
              'mark', format('%.2f', trade.reload.mark),
              'days_held', trade.days_held,
              trade.call ? 'call' : '{call}', trade.call ? format('%.2f', trade.call) : '',
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
              trade.call ? 'call bid/ask' : '{call bid/ask}', trade.call ? "#{trade.call_bid}/#{trade.call_ask}" : ''
            ],
            [
              'P/L $', format('%.2f', trade.points * trade.multiplier * trade.contracts),
              'AR_rate', trade.accel_return.positive? ? "#{format('%.2f', trade.accel_return)}x" : '--',
              'Pop/P50', "#{trade.pop}/#{trade.p50}",
              trade.defined_risk? ? 'spread_width' : '{spread width}', trade.defined_risk? ? trade.spread_width : nil
            ],
            [
              'expiration', trade.expiration.strftime('%m/%d/%y    '),
              trade.futures? ? 'roll_indicator' : '{roll}', trade.futures? && trade.roll_indicator.negative? ? trade.roll_indicator : nil,
              trade.closed? ? 'fees' : '{fees}', trade.closed? ? format('%.2f', trade.fees || 0.00) : nil,
              trade.adjustment? ? 'trade P/L %' : '{trade p/l %}', trade.adjustment? ? format('%.2f', trade_pl_pct) : nil
            ],
            [
              'trade_id', trade.id,
              '', nil,
              trade.adjustment? ? 'total_credit' : 'adjustment', trade.adjustment? ? trade.total_credit : 'No',
              trade.adjustment? || trade.closed? ? 'trade P/L $' : '{trade p/l $}', trade.adjustment? || trade.closed? ? format('%.2f', trade_pl_dollars) : nil
            ],
            [
              'opened_on', trade.opened.strftime('%m/%d/%y'),
              '', '           ',
              '', '           ',
              'updated_at', trade.updated_at.localtime.strftime('%m/%d %H:%M')
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
              v = val.match?(/\{.+\}/) ? pastel.dim(val) : val.titleize
              pastel.white.on_blue(v)
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
            elsif (col_index == 5 && [3, 5].include?(row_index)) || (col_index == 7 && [3, 4].include?(row_index))
              val.match?(%r{\A\s/}) ? pastel.dim(val) : val
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
        @trade ||= id.to_i.zero? ? Trade.where('lower(ticker) LIKE ?', "#{id.downcase}%").order(opened: :asc).last : Trade.find(id)
      end

      def trade_pl_pct
        return ((trade.total_credit - trade.mark) / trade.total_credit) * 100 if trade.adjustment? && trade.open?

        (trade_pl_dollars / (trade.total_credit * trade.multiplier)) * 100 if trade.adjustment? && trade.closed?

        # ((trade.price - trade.mark) / trade.price) * 100 if trade.closed? # ok
      end

      # order chain p/l if adjustment & NOT closed (no fees)
      # order chain p/l w/ total fees if closed
      # nothing if open & NOT adjustment (would be duplicate of positon p/l)
      def trade_pl_dollars
        return (trade.total_credit - trade.mark) * trade.multiplier * trade.contracts if trade.adjustment? && trade.open?

        return (((trade.total_credit - trade.mark) * trade.multiplier) - (trade.fees + trade.order_chain_fees)) if trade.adjustment? && trade.closed?

        trade.points * trade.multiplier * trade.contracts - trade.fees if trade.closed? # ok
      end
    end
  end
end
