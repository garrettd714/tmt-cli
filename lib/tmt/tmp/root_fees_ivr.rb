# frozen_string_literal: true

require_relative '../db'

class RootFeesIvr < ActiveRecord::Migration[6.0]
  def up
    add_column :trades, :root_symbol, :string
    add_column :trades, :ivr, :decimal
    add_column :trades, :fees, :decimal
  end
end
