# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require_relative '../tool'
# require_relative '../refresh'
require 'tty-table'
require 'tty-spinner'
require 'pastel'

module Tmt
  module Commands
    # List positions
    class Positions < Tmt::Command # rubocop:disable Metrics/ClassLength
      attr_reader :options

      def initialize(options) # rubocop:disable Lint/MissingSuper
        @options = options
      end

      def execute(_input: $stdin, output: $stdout) # rubocop:disable all
        errors = []
        if options[:refresh]
          spinner = TTY::Spinner.new('[:spinner] Refreshing data...')
          spinner.auto_spin
          scope = if Trade.active.stocks.count > 5
                    errors << "Due to API rate limiting any paper trades have not been refreshed\n"
                    Trade.active.stocks.no_paper
                  else
                    Trade.active.stocks
                  end
          scope.order(updated_at: :asc).each_with_index do |t, i|
            Tmt::Refresh.call(t) if i < 5 # configurable
            errors << "API limit reached, #{t.ticker.upcase} not refreshed. Enter trade 'mark' ['ticker_price'] manually\n" if i >= 5
          rescue StandardError => e
            errors << e.message
          end
          spinner.stop("Done!\n")
        end

        # futures table
        table = TTY::Table.new(
          [
            'id',
            'ticker  ',
            'size',
            ' price',
            '  mark',
            ' p/dd %',
            '  p/l $',
            "expiration #{up_arrow}",
            'ar / roll',
            'held/rem',
            'action',
            'close at'
          ],
          Trade.active.futures.order(expiration: :asc, opened: :asc).all.map do |t|
            [
              t.id,
              "#{t.ticker.split(/(?<=[S])/)[0]}#{pastel.dim(t.ticker.split(/(?<=[S])/)[1])} #{pastel.dim(t.root_symbol)}",
              t.size,
              format('%.2f', t.price),
              format('%.2f', t.mark),
              # t.adjustment? ? format('%.2f', (((t.total_credit - t.mark) / t.total_credit.to_f) * 100).round(2)) : format('%.2f', t.max_profit_pct),
              # show account drawdown when loss
              t.profit? ? format('%.2f', t.max_profit_pct) : format('%.2f', ((t.points * t.multiplier * t.contracts) / 15000.00) * 100),
              t.adjustment? ? format('%.2f', (t.total_credit - t.mark) * t.multiplier * t.contracts) : format('%.2f', t.points * t.multiplier * t.contracts),
              t.expiration.strftime('%m/%d/%y'),
              t.accel_return.positive? ? "#{format('%.2f', t.accel_return)}x" : t.roll_indicator,
              "#{t.days_held}/#{t.days_left}",
              Tool.call(t)&.result&.titleize&.upcase,
              format('%.2f', Tool.test(t)&.mark.to_f)
            ]
          end
        )
        # stocks table
        table2 = TTY::Table.new(
          [
            'id',
            'ticker   ',
            'size',
            ' price',
            '  mark',
            '  p/l %',
            '  p/l $',
            "expiration #{up_arrow}",
            'ar rate  ',
            'held/rem',
            'action',
            'close at'
          ],
          Trade.active.stocks.order(expiration: :asc, opened: :asc).all.map do |t|
            t.ticker = "#{t.ticker}#{"\u00AA".encode('utf-8')}" if t.adjustment?
            t.ticker = "#{t.ticker}#{"\u00B0".encode('utf-8')}" if t.paper?
            [
              t.id,
              t.break_even? ? "#{t.ticker}/be" : t.itm? ? "#{t.ticker}/itm" : t.ticker,
              t.size,
              format('%.2f', t.price),
              format('%.2f', t.mark),
              t.adjustment? ? format('%.2f', (((t.total_credit - t.mark) / t.total_credit.to_f) * 100).round(2)) : format('%.2f', t.max_profit_pct),
              t.adjustment? ? format('%.2f', (t.total_credit - t.mark) * t.multiplier * t.contracts) : format('%.2f', t.points * t.multiplier * t.contracts),
              # format('%.2f', t.max_profit_pct),
              # format('%.2f', t.points * t.multiplier * t.contracts),
              t.expiration.strftime('%m/%d/%y'),
              t.accel_return.positive? ? "#{format('%.2f', t.accel_return)}x" : '--',
              "#{t.days_held}/#{t.days_left}",
              Tool.call(t)&.result&.titleize&.upcase,
              format('%.2f', Tool.test(t)&.mark.to_f)
            ]
          end
        )
        output.puts "\nPOSITIONS\n" + (errors.present? ? "#{pastel.red(errors&.join)}" : "") + table.render(
          :unicode,
          alignments: %i[left left center center right right right right right right center right],
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if row_index.zero?
              pastel.white.on_blue(val)
            elsif row_index.positive? && [5, 6].include?(col_index)
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            elsif col_index == 10 && row_index.positive?
              val.match?(/open/i) ? pastel.green(val) : pastel.red(val)
            else
              val
            end
          end
        } + "\n\n" + table2.render(
          :unicode,
          alignments: %i[left left center center right right right right right right center right],
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if row_index.zero?
              pastel.white.on_blue(val)
            elsif row_index.positive? && col_index == 1
              val.match?(/\/be/) ? pastel.white.on_red(val.gsub(/\/be/, '')) : val.match?(/\/itm/) ? pastel.black.on_yellow(val.gsub(/\/itm/, '')) : val
            elsif row_index.positive? && [5, 6].include?(col_index)
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            elsif col_index == 10 && row_index.positive?
              val.match?(/open/i) ? pastel.green(val) : pastel.red(val)
            else
              val
            end
          end
        }
      end

      def up_arrow
        arrow = "\u25B2"
        arrow.encode('utf-8')
      end

      def pastel
        @pastel ||= Pastel.new
      end
    end
  end
end
