# frozen_string_literal: true

require_relative '../db'

module Tmt
  module Tmp
    class AddMoreTradeFields112021 < ActiveRecord::Migration[6.0]
      def up
        add_column :trades, :account, :integer, null: false, default: 0
        add_column :trades, :strategy, :integer, null: false, default: 0
        add_column :trades, :spread_width, :decimal
        add_column :trades, :total_credit, :decimal
        add_column :trades, :source, :integer, null: false, default: 0
        add_column :trades, :put_bid_ask, :string
        add_column :trades, :call_bid_ask, :string
      end
    end
  end
end
