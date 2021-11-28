# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require 'pastel'

module Tmt
  module Commands
    # update records from streamer/tmt-refresh
    class TastyStream < Tmt::Command
      attr_reader :id, :options, :bid, :ask

      # @arg id dxfeed id
      def initialize(id, options) # rubocop:disable Lint/MissingSuper
        @id = id
        @bid = options[:bid]
        @ask = options[:ask]
        @options = options
      end

      def execute(_input: $stdin, output: $stdout)
        args = { "#{porc}_bid" => bid, "#{porc}_ask" => ask }
        # output.puts "Trade id: #{trade.id}, #{porc.capitalize}, #{bid}, #{ask}
        trade.update!(**args.transform_keys(&:to_sym), tasty_updated_at: Time.now)

        output.puts pastel.green("#{ticker} #{porc.capitalize} updated successfully")
      rescue StandardError => e
        output.puts pastel.red("#{ticker} #{porc.capitalize} update failed. #{e.message}")
      end

      # .ATVI211217P62.5 => ATVI, ./ESZ21GC4440 => /ES
      def ticker
        @ticker ||= id.match?(%r{\./E}i) ? '/ES' : id.match(%r{\.([/A-Z]+{1,4})})[1]
      end

      # .ATVI211217P62.5 => put|call
      def porc
        @porc ||= id.match(/(C|P).+$/)[1] == 'P' ? 'put' : 'call'
      end

      private

      def trade
        @trade ||= Trade.active.where('lower(ticker) = ?', ticker.downcase).last
      end
    end
  end
end
