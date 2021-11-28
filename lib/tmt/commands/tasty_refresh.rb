# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require 'pastel'

module Tmt
  module Commands
    # update the marks from streamer/tmt-refresh
    class TastyRefresh < Tmt::Command
      def initialize(options) # rubocop:disable Lint/MissingSuper
        @options = options
      end

      def execute(_input: $stdin, output: $stdout)
        now = Time.now
        Trade.active.where(tasty_updated_at: (now - 5.minutes)..now).each do |t|
          t.update(mark: t.put_mid + t.call_mid) if updateable?(t)
        end

        output.puts pastel.green('Mark prices refreshed successfully')
      rescue StandardError => e
        output.puts pastel.red("Mark prices update failed. #{e.message}")
      end

      private

      def updateable?(trade)
        res = true
        res = false if trade.put.present? && (trade.put_bid.nil? || trade.put_ask.nil?)
        res = false if trade.call.present? && (trade.call_bid.nil? || trade.call_ask.nil?)
        res
      end
    end
  end
end
