# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require 'tty-table'

module Tmt
  module Commands
    # Summary (of summaries)
    class Summary < Tmt::Command
      attr_reader :options

      def initialize(options) # rubocop:disable Lint/MissingSuper
        @options = options
        @paper = options['paper']
      end

      def execute(input: $stdin, output: $stdout) # rubocop:disable all
        all_fees = scope_all.closed.map(&:fees).compact.reduce(:+)
        acct_sum = TTY::Table.new(
          [
            'account ',
            'count  ',
            '   p/l $',
            'realized',
            'held avg',
            '   rolls',
            '    fees'
          ],
          acct_symbols.map do |acct_symbol|
            trades = scope(acct_symbol)
            total_fees = trades.closed.map(&:fees).compact.reduce(:+)
            [
              acct_symbol.to_s.titleize,
              trades.where.not(adjustment: true).length,
              format('%.2f', format('%.2f', trades.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) - total_fees)),
              format('%.2f', format('%.2f', trades.closed.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) - total_fees)),
              format('%.2f', trades.closed.map(&:days_held).reduce(:+) / trades.closed.size.to_f),
              trades.where(adjustment: true).length,
              format('%.2f', total_fees)
            ]
          end + [
            [
              'Total',
              scope_all.where.not(adjustment: true).length,
              format('%.2f', format('%.2f', scope_all.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) - all_fees)),
              format('%.2f', format('%.2f', scope_all.closed.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) - all_fees)),
              format('%.2f', scope_all.closed.map(&:days_held).reduce(:+) / scope_all.closed.length),
              scope_all.where(adjustment: true).length,
              format('%.2f', all_fees)
            ]
          ]
        )

        header_array = ['month     ']
        header_array << year.to_s if year.present?
        header_array += (2021..Date.today.year).to_a.map(&:to_s) unless year.present?
        header2_array = %w[strategy count w/l_% held_avg]

        table = TTY::Table.new(
          (header_array + header2_array),
          (1..12).map do |m|
            a = [Date::ABBR_MONTHNAMES[m]]
            header_array.drop(1).each do |y|
              a << format('%.2f', (period_scope(y, m).closed.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) || 0) - period_fees(y, m))
            end
            strategy = strategies[m]
            a << strategy
            strategy = strategy.nil? ? 'unknown' : strategy

            strat_scope = scope_all.where(strategy: strategy)
            # count
            a << strat_scope.closed.where(adjustment: false).size
            # w/l %
            begin
              a << format('%.2f', (strat_scope.closed.where.not(adjustment: true).map(&:profitable_trade?).tap { |arr| arr.delete(false) }.size / strat_scope.closed.where.not(adjustment: true).size.to_f) * 100) if strat_scope.closed.where.not(adjustment: true).size.positive?
              a << 0 if strat_scope.closed.where.not(adjustment: true).size.zero?
            rescue ZeroDivisionError
              a << 0
            end
            # held_avg
            a << format('%.2f', (strat_scope.closed.map(&:days_held).reduce(:+) / strat_scope.closed.size.to_f)) if strat_scope.closed.size.positive?
            a << 0 if strat_scope.closed.size.zero?
            a
          end
        )

        output.puts "\n#{year ? year.to_s+' ' : nil}Options Account Summary"
        output.puts acct_sum.render(
          :unicode,
          alignments: %i[left left right right right right right],
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if row_index.zero? || (col_index.zero? && row_index != 4)
              pastel.white.on_blue(val)
            elsif row_index.positive? && [2, 3].include?(col_index)
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            elsif col_index.zero? && row_index == 4
              pastel.bold.white.on_blue(val)
            else
              val
            end
          end
        }

        output.puts "\n#{year ? year.to_s+' ' : nil}By Month Realized P/L $ / Strategies Summary"
        output.puts table.render(
          :unicode,
          alignments: header_array.length > 2 ? %i[left right right left right right right] : %i[left right left right right right],
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if col_index.zero?
              pastel.white.on_blue(val)
            elsif row_index.zero? && col_index < (header_array.size)
              pastel.white.on_blue(val)
            elsif row_index.zero? && col_index >= (header_array.size)
              pastel.black.on_bright_black(val)
            elsif row_index.positive? && col_index < (header_array.size + 1)
              return pastel.black.on_bright_black(val.titleize) if val.match?(/[A-Za-z?]/) || val.strip.empty?

              return pastel.dim(val) if BigDecimal(val) == BigDecimal(0)

              val.to_f.positive? ? pastel.green(val) : pastel.red(val)
            elsif col_index >= (header_array.size + 1)
              return pastel.dim(val) if BigDecimal(val) == BigDecimal(0)

              val
            else
              val
            end
          end
        }
      end

      private

      def year
        @year ||= options['ytd'] ? Time.now.year : options['year'] ? options['year'] : nil
      end

      def acct_symbols
        return Trade.accounts.except('paper').symbolize_keys.keys unless @paper

        Trade.accounts.symbolize_keys.keys
      end

      def scope(acct_symbol)
        s = year.present? ? Trade.year(year) : Trade
        s.where(account: acct_symbol)
      end

      def scope_all
        @scope_all ||= year.present? ? Trade.year(year) : Trade.all
      end

      def period_scope(yr, month)
        Trade.year(yr).close_month(month)
      end

      def period_fees(yr, month)
        period_scope(yr, month).closed.map(&:fees).compact.reduce(:+) || 0
      end

      # {1: strangle, 2: iron_condor, ...} starts at 1 to match months
      def strategies
        Trade.strategies.keys.excluding('uncategorized').to_enum.with_index(1).to_h.invert
      end
    end
  end
end
