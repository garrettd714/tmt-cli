# frozen_string_literal: true

require_relative './get_options'

module Tmt
  # refresh trade data
  class Refresh
    attr_reader :trade

    def initialize(trade)
      @trade = trade
    end

    def self.call(trade, &block)
      new(trade).refresh(&block)
    end

    def refresh
      trade.assign_attributes(ticker_price: ticker_price) if ticker_price.present?
      trade.assign_attributes(mark: mark, put_bid_ask: "#{put_bid}/#{put_ask}", call_bid_ask: "#{call_bid}/#{call_ask}") if exp_data.present?
      trade.save!
      raise StandardError, "Live option chain data not found for #{trade.ticker.upcase} on #{trade.expiration.strftime('%m/%d/%y')}. Enter trade 'mark' manually\n" unless exp_data.present?

      trade
    end

    private

    def ticker_price
      # stock's have current price, etfs only have bid/ask, it appears [11/22/21]
      data['stock']['currentPrice']&.round(2) || mid(data['stock']['bid'], data['stock']['ask'])
    end

    def mark
      mid(low, nat)
    end

    def nat
      put_ask + call_ask
    end

    def low
      put_bid + call_bid
    end

    def put_ask
      return 0.0 if trade.put.nil?

      exp_data['puts'].find { |opt| opt['strike'].to_d == trade.put }&.[]('ask') || 0.00
    end

    def call_ask
      return 0.0 if trade.call.nil?

      exp_data['calls'].find { |opt| opt['strike'].to_d == trade.call }&.[]('ask') || 0.00
    end

    def put_bid
      return 0.0 if trade.put.nil?

      exp_data['puts'].find { |opt| opt['strike'].to_d == trade.put }&.[]('bid') || 0.00
    end

    def call_bid
      return 0.0 if trade.call.nil?

      exp_data['calls'].find { |opt| opt['strike'].to_d == trade.call }&.[]('bid') || 0.00
    end

    def call_mid
      return 0.0 if trade.call.nil?

      strike = exp_data['calls'].find { |opt| opt['strike'].to_d == trade.call }
      mid(strike['bid'], strike['ask'])
    end

    def put_mid
      return 0.0 if trade.put.nil?

      strike = exp_data['puts'].find { |opt| opt['strike'].to_d == trade.put }
      mid(strike['bid'], strike['ask'])
    end

    def data
      @data ||= GetOptions.call(trade.ticker)
    end

    def exp_data
      @exp_data ||= data['options'].find { |exp| exp.keys.first == trade.expiration.to_s }&.[](trade.expiration.to_s)
    end

    def mid(bid, ask)
      ((bid + ask) / 2).round(2)
    end
  end
end
