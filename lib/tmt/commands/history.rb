# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require_relative '../settings'
require 'tty-table'
require 'yaml'

module Tmt
  module Commands
    # class comment
    class History < Tmt::Command
      attr_reader :ticker, :options, :normalized

      def initialize(ticker, options) # rubocop:disable Lint/MissingSuper
        @ticker = ticker
        @options = options
        @future = futures?
        @stock = stock?
        @normalized = options['normalize']
      end

      def execute(_input: $stdin, output: $stdout)
        # futures summary
        summary = TTY::Table.new(
          [
            'count   ',
            'annualz %',
            '   points',
            '   p/l %',
            '   p/l $',
            '  avg p%',
            '  avg ar',
            'held avg',
            '   rolls',
            '    fees'
          ],
          [
            [
              scope.where.not(adjustment: true).length,
              year ? (annualized_ror.positive? ? format('%.2f', annualized_ror) : '--') : '--',
              normalized.present? ? format('%.2f', scope.map(&:points).reduce(:+) * normalized) : format('%.2f', scope.map(&:points).reduce(:+)),
              normalized.present? ? format('%.2f', (scope.map(&:points).reduce(:+) * normalized * 50) / 15000.0 * 100) : format('%.2f', pl_pct_fraction * 100),
              normalized.present? ? format('%.2f', scope.map(&:points).reduce(:+) * 50 * normalized) : format('%.2f', scope.map { |t| t.points * t.contracts }.reduce(:+) * 50 - total_fees),
              format('%.2f', profits.sum(0.0) / profits.size * 100),
              "#{format('%.2f', (accel_returns.sum(0.0) / accel_returns.size))}x",
              format('%.2f', scope.closed.map(&:days_held).reduce(:+).to_f / scope.closed.length.to_f),
              scope.where(adjustment: true).length,
              normalized.present? ? '--' : format('%.2f', total_fees)
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
              normalized.present? ? normalized * -1 : t.size,
              format('%.2f', t.price),
              format('%.2f', t.mark),
              # show account drawdown when loss
              t.profit? ? format('%.2f', t.max_profit_pct) : normalized.present? ? format('%.2f', (t.points * 50 * normalized) / 15000.0 * 100) : format('%.2f', (t.points * 50 * t.contracts) / (Settings.ivl_size.to_f * t.contracts) * 100),
              format('%.2f', t.points * t.multiplier * (normalized || t.contracts)),
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
              format('%.2f', scope.map { |t| t.points * t.multiplier * (normalized || t.contracts) }.reduce(:+) - total_fees),
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
              normalized.present? ? normalized * -1 : t.size,
              format('%.2f', t.price),
              format('%.2f', t.mark),
              format('%.2f', t.max_profit_pct),
              format('%.2f', t.points * t.multiplier * (normalized || t.contracts)),
              t.expiration.strftime('%m/%d/%y'),
              t.accel_return.positive? ? "#{format('%.2f', t.accel_return)}x" : '--',
              t.days_held,
              t.opened.strftime('%m/%d/%y'),
              t.closed_at&.strftime('%m/%d/%y'),
              t.strategy.humanize
            ]
          end
        ) if @stock
        output.puts pastel.bold.red("\nTrade size normalized to -#{normalized}, actual results may vary. $15k account.") if normalized
        output.puts "\n#{ticker.upcase}#{year ? ' '+year.to_s : nil} SUMMARY\n" + summary.render(
          :unicode,
          alignments: %i[left right right right right right right right right right],
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
        } + "\n\n" if table
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
        # (scope.map(&:points).reduce(:+) * 50 - total_fees) / (scope.last.contracts * Settings.ivl_size)
        (scope.map { |t| t.points * t.contracts }.reduce(:+) * 50) / (scope.last.contracts * Settings.ivl_size)
      end

      def trading_days_year
        start = year != 2021 ? Date.new(year, 01, 01) : Date.new(2021,11,03)
        Date.today.mjd - start.mjd
      end

      # (((1 + {pl_pct_fraction}) ^ (365/{trading_days_year})) - 1) * 100 => 17.45(%)
      def annualized_ror
        (((1 + pl_pct_fraction)**(365 / trading_days_year)) - 1) * 100
      end

      def ivl_size
        # YAML.safe_load(File.read(File.join(File.dirname(__FILE__), '../../../settings.yml'))).fetch('ivl_size')
        Settings.ivl_size
      end

      def accel_returns
        @accel_returns ||= scope.closed.not_adjustment.map do |t|
          if t.days_held.zero?
            t.max_profit_pct_fraction / (0.9 / t.days_left)
          elsif t.accel_return.positive?
            t.accel_return
          else
            0.0
          end
        end
      end

      def profits
        @profits ||= scope.closed.map do |t|
          if t.profit?
            t.max_profit_pct_fraction
          # elsif t.adjustment?
          #   (t.mark - t.total_credit) / t.total_credit * -100
          end
        end.compact
      end
    end
  end
end
