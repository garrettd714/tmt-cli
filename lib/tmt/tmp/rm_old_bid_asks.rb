# frozen_string_literal: true

require_relative '../db'

class RmOldBidAsks < ActiveRecord::Migration[6.0]
  def up
    remove_column :trades, :put_bid_ask
    remove_column :trades, :call_bid_ask
  end
end
