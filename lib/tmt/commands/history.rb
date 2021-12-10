# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require_relative '../tool'
require 'tty-table'
require 'tty-spinner'
require 'pastel'

module Tmt
  module Commands
    # class comment
    class History < Tmt::Command
      attr_reader :ticker, :options

      def initialize(ticker, options)
        @ticker = ticker
        @options = options
        @future = futures?
        @stock = stock?
      end

      def execute(input: $stdin, output: $stdout)
        # futures summary
        summary = TTY::Table.new(
          [
            'count   ',
            'annualz %',
            '   points',
            '   p/l %',
            '   p/l $',
            'held avg',
            '   rolls',
            '    fees'
          ],
          [
            [
              scope.where.not(adjustment: true).length,
              year ? format('%.2f', annualized_ror) : '--',
              format('%.2f', scope.map(&:points).reduce(:+)),
              format('%.2f', pl_pct_fraction * 100),
              format('%.2f', scope.map(&:points).reduce(:+) * 50 - total_fees),
              format('%.2f', scope.closed.map(&:days_held).reduce(:+) / scope.closed.length),
              scope.where(adjustment: true).length,
              format('%.2f', total_fees)
            ]
          ]
        ) if @future
        # futures table
        table = TTY::Table.new(
          [
            'id',
            'ticker  ',
            'size',
            ' price',
            '  mark',
            '  p/dd %',
            '  p/l $',
            "expiration #{down_arrow}",
            'ar / roll',
            'held',
            'opened',
            'closed'
          ],
          scope.order(opened: :desc).all.map do |t|
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
              t.days_held,
              t.opened.strftime('%m/%d/%y'),
              t.closed_at&.strftime('%m/%d/%y')
            ]
          end
        ) if @future

        # stock/etf summary
        summary = TTY::Table.new(
          [
            'count   ',
            '   p/l $',
            'held avg',
            '   rolls',
            '    fees'
          ],
          [
            [
              scope.where.not(adjustment: true).length,
              format('%.2f', scope.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) - total_fees),
              format('%.2f', scope.closed.map(&:days_held).reduce(:+) / scope.closed.length),
              scope.where(adjustment: true).length,
              format('%.2f', total_fees)
            ]
          ]
        ) if @stock

        # stock/etf table
        table = TTY::Table.new(
          [
            'id',
            'size',
            ' price',
            '  mark',
            '  p/l %',
            '  p/l $',
            "expiration #{down_arrow}",
            'ar',
            'held',
            'opened',
            'closed',
            'strategy'
          ],
          scope.order(opened: :desc).all.map do |t|
            [
              t.adjustment? ? "#{t.id}#{"\u00AA".encode('utf-8')}" : t.id,
              t.size,
              format('%.2f', t.price),
              format('%.2f', t.mark),
              format('%.2f', t.max_profit_pct),
              # t.adjustment? ? format('%.2f', (t.total_credit - t.mark) * t.multiplier * t.contracts) : format('%.2f', t.points * t.multiplier * t.contracts),
              format('%.2f', t.points * t.multiplier * t.contracts),
              t.expiration.strftime('%m/%d/%y'),
              t.accel_return.positive? ? "#{format('%.2f', t.accel_return)}x" : '--',
              t.days_held,
              t.opened.strftime('%m/%d/%y'),
              t.closed_at&.strftime('%m/%d/%y'),
              t.strategy.humanize
            ]
          end
        ) if @stock

        output.puts "\n#{ticker.upcase}#{year ? ' '+year.to_s : nil} SUMMARY\n" + summary.render(
          :unicode,
          alignments: %i[left right right right right right right right],
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if row_index.zero?
              pastel.white.on_blue(val)
            elsif row_index.positive? && [1, 3, 4].include?(col_index) && @future
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            elsif row_index.positive? && [1].include?(col_index) && @stock
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            else
              val
            end
          end
        } if summary
        output.puts "\nHISTORY\n" + table.render(
          :unicode,
          alignments: %i[left left center center right right right right right right center right],
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if row_index.zero?
              pastel.white.on_blue(val)
            elsif row_index.positive? && [5, 6].include?(col_index) && @future
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            elsif row_index.positive? && [4, 5].include?(col_index) && @stock
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            # elsif col_index == 10 && row_index.positive?
            #   val.match?(/open/i) ? pastel.green(val) : pastel.red(val)
            else
              val
            end
          end
        } if table
      end

      private

      def futures?
        ticker.match?(%r{/})
      end

      def stock?
        !futures?
      end

      def scope
        @scope ||= begin
          s = year.present? ? Trade.year(year) : Trade
          return s.futures.where('lower(ticker) LIKE ?', "#{ticker.downcase}%") if @future

          s.stocks.where('lower(ticker) = ?', ticker.downcase) if @stock
        end
      end

      def total_fees
        scope.closed.map(&:fees).compact.reduce(:+) || 0.00
      end

      def down_arrow
        arrow = "\u25BC"
        arrow.encode('utf-8')
      end

      def year
        options['ytd'] ? Time.now.year : options['year'] ? options['year'] : nil
      end

      def pl_pct_fraction
        (scope.map(&:points).reduce(:+) * 50 - total_fees) / ENV.fetch('ivl_size', 15000)
      end

      def trading_days_year
        start = year != 2021 ? Date.new(year, 01, 01) : Date.new(2021,11,03)
        Date.today.mjd - start.mjd
      end

      # (((1 + {pl_pct_fraction}) ^ (365/{trading_days_year})) - 1) * 100 => 17.45(%)
      def annualized_ror
        (((1 + pl_pct_fraction)**(365 / trading_days_year)) - 1) * 100
      end
    end
  end
end
