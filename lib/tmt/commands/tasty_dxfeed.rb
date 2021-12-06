# frozen_string_literal: true

require_relative '../command'
require_relative '../db'

module Tmt
  module Commands
    # Dxfeed symbols for use with `tmt-refresh`
    #   returns comma delimeted string
    class TastyDxfeed < Tmt::Command
      def initialize(options) # rubocop:disable Lint/MissingSuper
        @options = options
      end

      # only return active futures symbols if after stock/etf trading hours (30..60 min cushion on either end)
      def execute(_input: $stdin, output: $stdout) # rubocop:disable Metrics/AbcSize
        return output.puts Trade.active.futures.map(&:symbols).flatten.compact.join(',') if after_hours?

        output.puts (Trade.active.map(&:symbols) + Trade.active.stocks.map(&:ticker)).flatten.compact.join(',')
      end

      private

      # returns false if
      #   - a weekend
      #   - not between 9-5 EST (9:30-4 EST reg trading hours)
      def after_hours?
        time = Time.now
        return true if [0, 6].include?(time.wday)

        return true unless (14..22).include?(time.utc.hour)

        false
      end
    end
  end
end
