# frozen_string_literal: true

require 'thor'
require 'pastel'
require 'tty-font'

module Tmt
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    # help
    def help(*args)
      # system('clear')
      font = TTY::Font.new('3d')
      pastel = Pastel.new(enabled: !options['no-color'])
      puts pastel.blue(font.write('TMT-CLI'))
      super
    end

    # version
    desc 'version', 'tmt-cli version, -v'
    def version
      require_relative 'version'
      puts "v#{Tmt::VERSION}"
    end
    map %w[--version -v] => :version

    # summary
    desc 'summary', 'Options portfolio summary, -s [--ytd --year=2021 -y=2021]'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    method_option :ytd, type: :boolean, default: false,
                        desc: 'Only display Year-to-Date summary'
    method_option :year, aliases: '-y', type: :numeric,
                         desc: 'Display summary for given year'
    def summary(*)
      if options[:help]
        invoke :help, ['summary']
      else
        require_relative 'commands/summary'
        Tmt::Commands::Summary.new(options).execute
      end
    end
    map %w[--summary -s] => :summary

    # account
    desc 'account token', 'Account summary, -a token [--ytd --year=2021 -y=2021]'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    method_option :ytd, type: :boolean, default: false,
                        desc: 'Only display Year-to-Date history'
    method_option :year, aliases: '-y', type: :numeric,
                         desc: 'Display history for given year'
    method_option :detail, aliases: '-d', type: :boolean,
                         desc: 'Display table of ticker details'
    def account(token)
      if options[:help]
        invoke :help, ['account']
      else
        require_relative 'commands/account'
        Tmt::Commands::Account.new(token, options).execute
      end
    end
    map %w[--account -a] => :account

    # history
    desc 'history ticker', 'Display trade history for ticker, -hi ticker [--history ticker] [--ytd --year=2021 -y=2021 -n=1]'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    method_option :ytd, type: :boolean, default: false,
                        desc: 'Only display Year-to-Date history'
    method_option :year, aliases: '-y', type: :numeric,
                         desc: 'Display history for given year'
    method_option :normalize, aliases: '-n', type: :numeric,
                              desc: 'Normalize contracts to value'
    def history(ticker)
      if options[:help]
        invoke :help, ['history']
      else
        require_relative 'commands/history'
        Tmt::Commands::History.new(ticker, options).execute
      end
    end
    map %w[--history -hi] => :history

    # tasty_refresh
    desc 'tasty_refresh', 'Tasty streamer mark refresher hook (for streamer use only)'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'For tasty-refresh use only'
    def tasty_refresh(*)
      if options[:help]
        invoke :help, ['tasty_refresh']
      else
        require_relative 'commands/tasty_refresh'
        Tmt::Commands::TastyRefresh.new(options).execute
      end
    end

    # tasty_stream
    desc 'tasty_stream', 'Tasty streamer quote update hook (for streamer use only)'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'For tasty-refresh use only'
    method_option :bid, type: :numeric,
                        desc: 'bid from tastyworks'
    method_option :ask, type: :numeric,
                        desc: 'ask from tastyworks'
    def tasty_stream(id)
      if options[:help]
        invoke :help, ['tasty_stream']
      else
        require_relative 'commands/tasty_stream'
        Tmt::Commands::TastyStream.new(id, options).execute
      end
    end

    # tasty_dxfeed
    desc 'tasty_dxfeed', 'Tasty streamer dxfeed symbols hook (for streamer use only)'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'For tasty-refresh use only'
    def tasty_dxfeed(*)
      if options[:help]
        invoke :help, ['tasty_dxfeed']
      else
        require_relative 'commands/tasty_dxfeed'
        Tmt::Commands::TastyDxfeed.new(options).execute
      end
    end

    # close
    desc 'close id fill fees', 'Close the position, -c id fill fees [--close id fill fees]'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def close(id, fill, fees)
      if options[:help]
        invoke :help, ['close']
      else
        require_relative 'commands/close'
        Tmt::Commands::Close.new(id, fill, fees, options).execute
      end
    end
    map %w[--close -c] => :close

    # update
    desc 'update id', 'Update position, -u id [--edit id | -e id] [--mark= --ticker_price= --note=]'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Update a position'
    method_option :mark, type: :numeric,
                         desc: 'Update the trade mark manually'
    method_option :ticker_price, type: :numeric,
                                 desc: 'Update the ticker price manually'
    method_option :note, type: :string,
                               desc: 'Append a note'
    def update(id)
      if options[:help]
        invoke :help, ['update']
      else
        require_relative 'commands/update'
        Tmt::Commands::Update.new(id, options).execute
      end
    end
    map %w[--update -u --edit -e] => :update

    # details
    desc 'details id', 'Position detailed view, -d id [--show id | -s id]'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display the details of a position'
    method_option :refresh, aliases: '-r', type: :boolean,
                            desc: 'Refresh the details of a position'
    def details(id)
      # system('clear')
      if options[:help]
        invoke :help, ['details']
      else
        require_relative 'commands/details'
        Tmt::Commands::Details.new(id, options).execute
      end
    end
    map %w[--details -d --show] => :details

    # positions
    desc 'positions', 'List positions, -p [--list | -l]'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display table of open positions'
    method_option :refresh, aliases: '-r', type: :boolean,
                            desc: 'Refresh the details of the stock/etf positions'
    def positions(*)
      # system('clear')
      if options[:help]
        invoke :help, ['positions']
      else
        require_relative 'commands/positions'
        Tmt::Commands::Positions.new(options).execute
      end
    end
    map %w[--positions -p --list -l] => :positions

    # open
    desc 'open', 'Open a new trade, -o [--new | -n]'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def open(*)
      # system('clear')
      if options[:help]
        invoke :help, ['open']
      else
        require_relative 'commands/open'
        Tmt::Commands::Open.new(options).execute
      end
    end
    map %w[--open -o --new -n] => :open
  end
end
