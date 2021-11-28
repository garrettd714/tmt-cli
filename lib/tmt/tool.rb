# frozen_string_literal: true

require_relative './db'

module Tmt
  # TMT Algorithm
  class Tool
    attr_reader :trade, :test_mark

    def initialize(trade, test_mark = nil)
      @trade = trade
      @test_mark = test_mark
    end

    def self.call(trade, &block)
      new(trade).analyze(&block)
    end

    def self.test(trade) # rubocop:disable Metrics/AbcSize
      range = 50..(trade.mark * 100).to_i
      price_range = range.to_a.reverse.reject do |n|
        n > 500 ? trade.futures? ? n % 25 != 0 : n % 5 != 0 : n % 5 != 0
      end

      price_range.each do |x|
        t = new(trade, (x / 100.0).to_d).analyze
        return t if t.close?
      end
      OpenStruct.new(close?: false, open?: true, result: 'keep_open', details: nil, mark: '--')
    end

    def analyze
      trade.mark = test_mark if test_mark.present?
      if trade.profit?
        if trade.lte45days?
          if trade.gain_gte50?
            analysis(:close, 1)
          else
            if trade.lte10days?
              analysis(:close, 2)
            elsif trade.gain_gte40? && trade.ar_gte1x?
              analysis(:close, 3)
            elsif trade.gain_gte30? && trade.ar_gte1_5x?
              analysis(:close, 4)
            elsif trade.gain_gte20? && trade.ar_gte2x?
              analysis(:close, 5)
            else
              analysis(:keep_open, 6)
            end
          end
        else # gt45days
          analysis(:keep_open, 0)
        end
      else # no profit
        analysis(:keep_open, 7)
      end
    end

    private

    def analysis(result, details_idx)
      OpenStruct.new(close?: result == :close, open?: result == :keep_open, result: result.to_s, details: details[details_idx], mark: trade.mark.to_s)
    end

    def details
      [
        "With over 45 days left to expiration, and still a bit of premium left on the options,\nwe can keep this trade open to collect more profit",
        "We’ve made more than 50% of our maximum potential profit. We can close this trade and\nfree up the capital to establish a position in a further expiration cycle",
        "With only 10 days left until expiration, we have to be careful as trades become more\nsensitive as you near expiration. Consider closing the position and take the profit the market gave you. Reallocate the capital to a new position",
        "You’ve made #{trade.max_profit_pct}% of your maximum potential profit, but have only held the position\nfor #{trade.days_held_pct}% of the time (That’s a moderate Accelerated Return of #{trade.accel_return}x). Great! Consider closing the position here",
        "Even though you’ve made less than 50% of your maximum potential profit, you’re making\na return 1.5x faster than expected. Close the position and establish a position in a further expiration cycle",
        "Although you’ve only made #{trade.max_profit_pct}% of your maximum potential profit,\nyou might consider closing this position since you’ve made more than 2X Accelerated Return and have a profit of #{format('%.2f', trade.points * trade.multiplier)}",
        "You’re starting to show a decent profit. But to take a profit of less than 50% of our Max Profit,\nwe require the Accelerated Return to be at least above 1x to close the position",
        "This position is perfectly fine. You’re down a small amount and we still have a bit of time\nleft for this trade to play out and possibly get back to a profit"
      ]
    end
  end
end
