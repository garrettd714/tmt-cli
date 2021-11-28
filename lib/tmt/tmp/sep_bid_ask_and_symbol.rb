# frozen_string_literal: true

require_relative '../db'

module Tmt
  module Tmp
    class SepBidAskAndSymbol < ActiveRecord::Migration[6.0]
      def up
        add_column :trades, :put_bid, :decimal
        add_column :trades, :put_ask, :decimal
        add_column :trades, :call_bid, :decimal
        add_column :trades, :call_ask, :decimal
        add_column :trades, :symbols, :string
        add_column :trades, :tasty_updated_at, :datetime
      end
    end
  end
end
