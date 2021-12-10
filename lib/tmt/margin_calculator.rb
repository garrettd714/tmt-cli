# frozen_string_literal: true

require_relative './db'

module Tmt
  # TMT Estimated Margin Calculator
  # https://support.tastyworks.com/support/solutions/folders/43000342979
  # @wip @experimental @unused
  class MarginCalculator
    attr_reader :trade

    def initialize(trade)
      @trade = trade
    end

    def self.call(trade, &block)
      new(trade).calculate(&block)
    end

    def calculate
      return trade.init_margin_req if trade.account == 'robinhood'

      case trade.strategy
      # https://support.tastyworks.com/support/solutions/articles/43000435282-short-straddle-strangle
      # EXAMPLE OF SELLING A STRADDLE OR STRANGLE IN A MARGIN ACCOUNT
      # With the underlying at $45,

      # Sell to open 1 Mar 47 call at $2.10
      # Sell to open 1 Mar 43 put at $1.20

      # Mar 47-strike Call Margin Requirement
      # [((.20 x 45) - 2) + 2.10] x 1 x 100 = $910 ← highest margin requirement
      # Or
      # [(.10 x 45) + 2.10] x 1 x 100  = $660

      # Mar 43-strike Put Margin Requirement
      # [((.20 x 45) - 2) + 1.20] x 1 x 100  = $820
      # Or
      # [(.10 x 43) + 1.20] x 1 x 100  = $550

      # Since the 47-strike call has the highest margin requirement ($910), this makes the total margin requirement $1,030
      # since the premium from the put side ($910 + $120) is added to the margin requirement.
      when 'strangle'
        calc_strangle
        # porc = trade.put_mid > trade.call_mid ? :put : :call
        # opp = porc == :put ? :call : :put
        # mid = trade.send("#{porc}_mid")
        # other_side_premium = trade.send("#{opp}_mid") * 100 * trade.contracts
        # (((0.2 * trade.ticker_price) - (porc == :put ? (trade.ticker_price - trade.put) : (trade.call - trade.ticker_price))) + mid) * trade.contracts * 100 + other_side_premium
      # https://tastyworks.freshdesk.com/support/solutions/articles/43000435177
      when 'short_put'
        ((0.19 * trade.ticker_price) - (trade.ticker_price - trade.put) + trade.price) * trade.contracts * 100 - (trade.total_credit * 100.0 * trade.contracts)
      else
        "no hit for #{trade.strategy}"
      end
    rescue StandardError => e
      binding.pry
      "error for trade #{trade.id} and #{trade.strategy}"
    end

    private

    # @todo/note would need premium(s) columns for a more accurate margin, although after testing it still doesn't quite match
    #   as I don't know what ticker price they are using for the calculations and how often its updated. I think it would only
    #   be good for initial margin calculations, not necessarily "my" ongoing margin requirements according to Tastyworks
    # @note can probably request margin requirements from TW via this app and forget the calcs
    def calc_strangle
      results = []
      otm = (trade.ticker_price - trade.put).positive? ? trade.ticker_price - trade.put : 0.0
      # [((.20 x put strike) - otm) + premium] x 1 x 100
      results << [:put, (((0.2 * trade.put) - otm) + trade.put_mid) * trade.contracts * trade.multiplier]
      # [(.10 x put strike) + premium] x 1 x 100
      results << [:put, ((0.1 * trade.put) + trade.put_mid) * trade.contracts * trade.multiplier]
      # [((.20 x call strike) - otm) + premium] x 1 x 100
      otm = (trade.call - trade.ticker_price).positive? ? trade.call - trade.ticker_price : 0.0
      results << [:call, (((0.2 * trade.call) - otm) + trade.call_mid) * trade.contracts * trade.multiplier]
      # [(.10 x call strike) + premium] x 1 x 100
      results << [:call, ((0.1 * trade.call) + trade.call_mid) * trade.contracts * trade.multiplier]
      # find max result
      max = results.max { |a, b| a[1] <=> b[1] }
      # determine credit to add from other side
      added_credits = max[0] == :put ? (trade.call_mid * 100.0) : (trade.put_mid * 100.0)
      (max[1] + added_credits).round(2)
    end
  end
end
