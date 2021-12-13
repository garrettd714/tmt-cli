# frozen_string_literal: true

class Trade < ApplicationRecord
  enum account: {
    paper: 0,
    sky_trades: 1,
    iv_league: 2,
    robinhood: 3
  }

  enum strategy: {
    uncategorized: 0,
    strangle: 1,
    # es_strangle: 2,
    iron_condor: 5,
    covered_call: 10,
    short_put: 15,
    short_call: 16,
    put_credit_spread: 20,
    call_credit_spread: 21,
    long_put: 25,
    long_call: 26
  }

  enum source: {
    me: 0,
    sky_trade: 5,
    ivl_adam: 10,
    benzinga: 15,
    reddit: 20,
    other: 50
  }

  scope :active, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }
  scope :futures, -> { where('ticker LIKE ?', '%/%') }
  scope :stocks, -> { where.not('ticker LIKE ?', '%/%') }
  scope :no_paper, -> { where.not(account: :paper) }
  # closed in year OR opened in year but not closed yet. sqlite3 query
  scope :year, ->(year) { where("cast(strftime('%Y', closed_at) as int) = ?", year).or(Trade.where("(closed_at IS NULL AND cast(strftime('%Y', opened) as int) = ?)", year)) }
  scope :close_month, ->(month) { where("cast(strftime('%m', closed_at) as int) = ?", month) }

  def symbols
    val = super
    return JSON.parse(val) if val.present?

    [].tap { |a| a << dxfeed_put_symbol; a << dxfeed_call_symbol }.compact
  end

  def defined_risk?
    %w[iron_condor put_credit_spread call_credit_spread].include?(strategy)
  end

  def profit?
    price > mark
  end

  def profitable_trade?
    return true if profit?

    # if loss, look at the next closed trade to see if it was an adjustment
    #   if adjustment was made, was the combinded result profitable?
    t2 = Trade.closed.where(ticker: ticker).where('id > ?', id).order(closed_at: :asc).first
    if t2&.adjustment?
      return false unless t2.profit?

      (t2.points + points).positive?
    else
      false
    end
  end

  def loss?
    price < mark
  end

  # For untested/roll up/roll down adjustments, change price and strike on trade and add note with "!ROLL!" for positions treament
  def rolled?
    note.match?(/¡ROLL!/)
  end

  def lte45days?
    days_left <= 45
  end

  def lte10days?
    days_left <= 10
  end

  def lte7days?
    days_left <= 7
  end

  def lte3days?
    days_left <= 3
  end

  def mark_lte1_5?
    mark <= 1.5
  end

  def mark_lte_5?
    mark <= 0.5
  end

  def gain_gte50?
    max_profit_pct >= 50
  end

  def gain_gte40?
    max_profit_pct >= 40
  end

  def gain_gte30?
    max_profit_pct >= 30
  end

  def gain_gte20?
    max_profit_pct >= 20
  end

  def ar_gte1x?
    accel_return >= 1
  end

  def ar_gte1_5x?
    accel_return >= 1.5
  end

  def ar_gte2x?
    accel_return >= 2
  end

  def accel_return
    (max_profit_pct / days_held_pct).round(2)
  end

  def max_profit_pct_fraction
    points / price.to_f
  end

  def max_profit_pct
    (max_profit_pct_fraction * 100).round(2)
  end

  def days_left
    closed? ? expiration.mjd - closed_at.to_date.mjd : expiration.mjd - Date.today.mjd
  end

  def days_held
    closed? ? closed_at.to_date.mjd - opened.mjd : Date.today.mjd - opened.mjd
  end

  def closed?
    closed_at.present?
  end

  def open?
    closed_at.nil?
  end

  def days_held_pct_fraction
    days_held / (days_held + days_left).to_f
  end

  def days_held_pct
    (days_held_pct_fraction * 100).round(2)
  end

  def points
    price - mark
  end

  def close!
    touch(:closed_at)
  end

  def contracts
    size * -1
  end

  def roll_indicator
    ((points * (multiplier / 50).to_f) / days_left).to_f.round(2)
  end

  def multiplier
    %r{/es}i.match?(ticker) ? 50 : 100
  end

  def futures?
    %r{/es}i.match?(ticker)
  end

  def stock?
    !futures?
  end

  def itm?
    put && ticker_price < put || call && ticker_price > call
  end

  def break_even?
    put && ((put - real_price) > ticker_price) || call && ((call + real_price) < ticker_price)
  end

  def real_price
    adjustment? ? total_credit : price
  end

  def dxfeed_put_symbol
    return ".#{ticker.upcase}#{expiration.strftime("%y%m%d")}P#{(put % 1).zero? ? put.to_i : put}" if put.present? && !futures?

    "./#{root_symbol.upcase}#{futures_month_code[expiration.strftime('%B')]}#{expiration.strftime('%y')}P#{(put % 1).zero? ? put.to_i : put}:XCME" if put.present? && root_symbol.present?
  end

  def dxfeed_call_symbol
    return ".#{ticker.upcase}#{expiration.strftime("%y%m%d")}C#{(call % 1).zero? ? call.to_i : call}" if call.present? && !futures?

    "./#{root_symbol.upcase}#{futures_month_code[expiration.strftime('%B')]}#{expiration.strftime('%y')}C#{(call % 1).zero? ? call.to_i : call}:XCME" if call.present? && root_symbol.present?
  end

  def put_mid
    (((put_bid || 0) + (put_ask || 0)) / 2).round(2)
  end

  def call_mid
    (((call_bid || 0) + (call_ask || 0)) / 2).round(2)
  end

  def futures_month_code
    {
      'January' => 'F',
      'February' => 'G',
      'March' => 'H',
      'April' => 'J',
      'May' => 'K',
      'June' => 'M',
      'July' => 'N',
      'August' => 'Q',
      'September' => 'U',
      'October' => 'V',
      'November' => 'X',
      'December' => ''
    }.freeze
  end

  def order_chain_fees
    return unless adjustment?

    prev_trade = Trade.where(ticker: ticker).where("id < #{id}").order(opened: :desc).first
    (prev_trade.adjustment? ? prev_trade.order_chain_fees + prev_trade.fees : prev_trade.fees) if prev_trade
  end
end

# [46] pry(main)> m = ".ATVI211217P62.5".match(%r{\.([\/A-Z]+{1,4})})[1]
# => "ATVI"
# [47] pry(main)> m = ".ATVI211217P62.5".match(%r{(C|P).+$})[1]
# => "P"

# ./{root}{yy}{mc}{C|P}{strike}:XCME => ./ESZ21P4485:XCME
# The month code is represented with a single letter as displayed below:
# F - January
# G - February
# H - March
# J - April
# K - May
# M - June
# N - July
# Q - August
# U - September
# V - October
# X - November
# Z - December
