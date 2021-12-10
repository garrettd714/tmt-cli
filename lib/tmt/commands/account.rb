# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require 'tty-table'

module Tmt
  module Commands
    class Account < Tmt::Command
      attr_reader :acct_enum, :options

      def initialize(acct_enum, options)
        @acct_enum = acct_enum
        @options = options
        @detail = options['detail']
      end

      def execute(input: $stdin, output: $stdout)
        summary = TTY::Table.new(
          [
            'count   ',
            # 'annualz %',
            # '   p/l %',
            '   p/l $',
            'realized',
            'held avg',
            '   rolls',
            '    fees'
          ],
          [
            [
              scope.where.not(adjustment: true).length,
              # year ? format('%.2f', annualized_ror) : '--',
              # format('%.2f', pl_pct_fraction * 100),
              format('%.2f', format('%.2f', scope.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) - total_fees)),
              format('%.2f', format('%.2f', scope.closed.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) - total_fees)),
              format('%.2f', scope.closed.map(&:days_held).reduce(:+) / scope.closed.length),
              scope.where(adjustment: true).length,
              format('%.2f', total_fees)
            ]
          ]
        )

        table = TTY::Table.new(
          [
            'ticker  ',
            '   count',
            '   p/l $',
            'held avg',
            '   rolls',
            '    fees'
          ],
          scope.where.not(adjustment: true).group(:ticker).count.sort_by { |k, v| [-v, k] }.map do |tick, count|
            trades = scope.where(ticker: tick)
            # next if tick == 'GDX'
            [
              tick,
              count,
              format('%.2f', trades.map { |t| t.points * t.multiplier * t.contracts }.reduce(:+) - (trades.closed.map(&:fees).reduce(:+) || 0.0)),
              format('%.2f', (trades.closed.map(&:days_held).reduce(:+) || 0.0) / (trades.closed.length || 0)),
              trades.where(adjustment: true).length,
              format('%.2f', (trades.closed.map(&:fees).compact.reduce(:+) || 0.0))
            ]
          rescue StandardError => e
            output.puts pastel.red("Data issue with ticker, #{tick}")
            raise e
          end
        ) if @detail

        output.puts "\n#{acct_enum.humanize}#{year ? ' '+year.to_s : nil} SUMMARY\n" + summary.render(
          :unicode,
          alignments: %i[left right right right right right right right],
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if row_index.zero?
              pastel.white.on_blue(val)
            elsif row_index.positive? && [1, 2].include?(col_index)
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            # elsif row_index.positive? && [1].include?(col_index) && @stock
            #   (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            else
              val
            end
          end
        } if summary

        output.puts "\n" + table.render(
          :unicode,
          alignments: %i[left right right right right right right right],
          padding: [0, 1, 0, 1]
        ) { |renderer|
          renderer.border.separator = :each_row
          renderer.filter = ->(val, row_index, col_index) do
            if row_index.zero?
              pastel.white.on_blue(val)
            elsif row_index.positive? && [2].include?(col_index)
              (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            # elsif row_index.positive? && [1].include?(col_index)
            #   (val.to_f.positive? ? pastel.green(val) : pastel.red(val))
            else
              val
            end
          end
        } if table
      rescue StandardError => e
        e.set_backtrace(e.backtrace.first(2))
        raise e
      end

      private

      def scope
        @scope ||= begin
          s = year.present? ? Trade.year(year) : Trade
          s.where(account: acct_enum.to_sym)
        end
      end

      def year
        options['ytd'] ? Time.now.year : options['year'] ? options['year'] : nil
      end

      def total_fees
        scope.closed.map(&:fees).compact.reduce(:+)
      end
    end
  end
end
