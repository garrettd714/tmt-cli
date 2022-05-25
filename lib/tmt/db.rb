# frozen_string_literal: true

require 'sqlite3'
require 'active_record'
require 'yaml'
require_relative './settings'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: Tmt::Settings.db_path
)

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.level = 1
ActiveRecord::Migration.verbose = false

# Set up database tables and columns
ActiveRecord::Schema.define do
  create_table :trades, if_not_exists: true do |t|
    t.string :ticker, null: false, index: true
    t.integer :account, null: false, default: 0, index: true
    t.integer :strategy, null: false, default: 0, index: true
    t.date :opened, null: false, index: true
    t.date :expiration, null: false, index: true
    t.integer :size, null: false
    t.decimal :price, null: false # trade price/credit
    t.decimal :mark, null: false
    t.decimal :put
    t.decimal :call
    t.decimal :spread_width
    t.decimal :ticker_price # move to underlying?
    t.decimal :ivr
    t.decimal :put_delta
    t.decimal :call_delta
    t.decimal :init_margin_req
    t.integer :pop
    t.integer :p50
    t.text :note
    t.boolean :adjustment, default: false, null: false, index: true
    t.decimal :total_credit
    t.integer :source, null: false, default: 0, index: true
    t.decimal :fees
    t.datetime :closed_at, index: true
    t.decimal :put_bid
    t.decimal :put_ask
    t.decimal :call_bid
    t.decimal :call_ask
    t.string :root_symbol
    t.string :symbols
    t.datetime :tasty_updated_at, index: true

    t.timestamps
  end

  create_table :stock_trades, if_not_exists: true do |s|
    s.string :ticker, null: false, index: true
    s.date :opened, null: false, index: true
    s.integer :account, null: false, default: 0, index: true
    s.integer :source, null: false, default: 0, index: true
    s.decimal :shares, null: false
    s.decimal :cost_per_share, null: false
    s.decimal :spy_initial
    s.decimal :sold_per_share
    s.decimal :fees
    s.datetime :closed_at, index: true
    s.text :note
    s.text :metadata
    s.datetime :tasty_updated_at, index: true

    s.timestamps
  end

  create_table :underlyings, if_not_exists: true do |u|
    u.string :ticker, null: false, index: { unique: true }
    u.decimal :bid
    u.decimal :ask
    u.decimal :price_eoy_2020
    u.decimal :price_eoy_2021
    u.decimal :price_eoy_2022
    u.decimal :price_eoy_2023
    u.boolean :active, default: true, null: false, index: true

    u.timestamps
  end
end

# Set up model classes
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

require_relative 'models/trade'
require_relative 'models/stock_trade'
require_relative 'models/underlying'
