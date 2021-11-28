# frozen_string_literal: true

require 'sqlite3'
require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: '/Users/garrett/Projects/tmt/tmt.db' # 'tmt.db'
)

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.level = 1
ActiveRecord::Migration.verbose = false

# Set up database tables and columns
ActiveRecord::Schema.define do
  create_table :trades, if_not_exists: true do |t|
    t.string :ticker, null: false
    t.integer :account, null: false, default: 0
    t.integer :strategy, null: false, default: 0
    t.date :opened, null: false
    t.date :expiration, null: false
    t.integer :size, null: false
    t.decimal :price, null: false # trade price/credit
    t.decimal :mark, null: false
    t.decimal :put
    t.decimal :call
    t.decimal :spread_width
    t.decimal :ticker_price
    t.decimal :ivr
    t.decimal :put_delta
    t.decimal :call_delta
    t.decimal :init_margin_req
    t.integer :pop
    t.integer :p50
    t.text :note
    t.boolean :adjustment, default: false, null: false
    t.decimal :total_credit
    t.integer :source, null: false, default: 0
    t.decimal :fees
    t.datetime :closed_at
    t.decimal :put_bid
    t.decimal :put_ask
    t.decimal :call_bid
    t.decimal :call_ask
    t.string :root_symbol
    t.string :symbols
    t.datetime :tasty_updated_at

    t.timestamps
  end

  # long_put_bid, long_put_ask, long_call_bid, long_call_ask

  # create_table :settings, if_not_exists: true do |s|
  #   s.integer :iv_league_cash # per contract collateral
  #   s.integer :sky_trades_cash # account size trading
  #   s.boolean :live, default: false, null: false
  #   s.string :rapidapi_host
  #   s.string :rapidapi_key

  #   s.timestamps
  # end
end

# Set up model classes
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

require_relative 'models/trade'
