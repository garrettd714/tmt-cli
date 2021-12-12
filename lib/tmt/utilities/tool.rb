# frozen_string_literal: true

require_relative '../db'

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
      range = trade.futures? ? 50..(trade.mark * 100).to_i : 5..(trade.mark * 100).to_i
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
            elsif trade.gain_gte40? && trade.ar_gte1x? && !trade.adjustment?
              analysis(:close, 3)
            # elsif trade.gain_gte40? && trade.ar_gte2x? && trade.adjustment? && () # trade p/l % gte -100
              # your adjustment trade
            elsif trade.gain_gte30? && trade.ar_gte1_5x? && !trade.adjustment?
              analysis(:close, 4)
            elsif trade.gain_gte20? && trade.ar_gte2x? && !trade.adjustment?
              analysis(:close, 5)
            else
              analysis(:keep_open, 6) if !trade.adjustment?
              new_analysis(:keep_open, :adjust_profit, :lte45days)
            end
          end
        else # gt45days & profit
          if !trade.futures? && trade.gain_gte50?
            new_analysis(:close, :profit, :gain_gte50)
          else
            new_analysis(:keep_open, :profit, :gt45days)
          end
        end
      else # no profit
        if trade.lte45days?
          new_analysis(:keep_open, :loss, :lte45days)
        else # gt45days & loss
          new_analysis(:keep_open, :loss, :gt45days)
        end
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

    def new_analysis(result, key1, key2)
      OpenStruct.new(close?: result == :close, open?: result == :keep_open, result: result.to_s, details: new_details[result][key1][key2], mark: trade.mark.to_s)
    end

    def new_details
      {
        keep_open: {
          profit: {
            gt45days: "With over 45 days left to expiration, and still a bit of premium left on the options,\nkeep this trade open to collect more profit",
            lte45days: "Starting to show a decent profit. But to take a profit of less than 50% of Max Profit,\nrequire the Accelerated Return to be at least above 1x to close the position"
          },
          loss: {
            gt45days: "This position is perfectly fine. You’re down but, still have plenty of time left for\nthis trade to play out and possibly get back to a profit",
            lte45days: "This position is down but, stay patient, stick to mechanics"
          },
          adjust_profit: {
            lte45days: "Starting to show a decent profit. But to take a profit of less than 50% of Max Profit,\nrequire the Accelerated Return to be at least above 2x to close the position and be down\nless than 100% on the trade"
          },
          adjust_loss: {}
        },
        close: {
          profit: {
            gain_gte50: "We’ve made more than 50% of our maximum potential profit. We can close this trade and\nfree up the capital to establish a position in a further expiration cycle"
          },
          loss: {},
          adjust_profit: {},
          adjust_loss: {}
        }
      }
    end
  end
end
