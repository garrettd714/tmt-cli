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
        args = { "#{porc}_bid" => bid, "#{porc}_ask" => ask } if ticker && !@price
        args = { "ticker_price" => mid } if @price
        # output.puts "Trade id: #{trade.id}, #{porc.capitalize}, #{bid}, #{ask}
        trade.update!(**args.transform_keys(&:to_sym), tasty_updated_at: Time.now)

        output.puts pastel.green("#{ticker}\t#{porc}\tsuccess")
      rescue StandardError => e
        output.puts pastel.red("#{ticker}\t#{porc}\tfailed\t#{e.message}")
      end

      # .ATVI211217P62.5 => ATVI, ./ESZ21GC4440 => /ES, ATVI => ATVI
      def ticker
        @ticker ||= id.match?(%r{\./E}i) ? '/ES' : id.match?(/\A\./) ? id.match(%r{\.([/A-Z]+{1,4})})[1] : (@price = true; id)
      end

      # .ATVI211217P62.5 => put|call, ATVI => ticker price
      def porc
        @porc ||= id.match?(/\d(C|P).+$/) ? id.match(/\d(C|P).+$/)[1] == 'P' ? 'put' : 'call' : 'ticker'
      end

      private

      def trade
        @trade ||= begin
          return Trade.active.where('lower(ticker) = ?', ticker.downcase).last unless ticker == '/ES'

          Trade.active.where('lower(ticker) LIKE ?', "#{ticker.downcase}%").last
        end
      end

      def mid
        ((bid + ask) / 2).round(2)
      end
    end
  end
end
