# tmt-cli

> TMT-CLI is a options trade tracking cli tool for my own personal use
>
> **<span style="color:red">THIS REPO FOR REFERENCE PURPOSES ONLY!</span>**

## Purpose
A simple Ruby cli (command-line-interface) to track my option trades, show insights and optionally, update the prices on-demand.

## Disclaimer
Any/All results are for entertainment purposes only. **Not financial advice**.

> Utilizes an unofficial, reverse-engineered API for Tastyworks. There is no implied warranty for any actions and results which arise from using it.

## Features
* Trade CRUD with easy cli commands
* Positions table of active trades. ITM and breakeven indicators
* Paper trade, does not require trade to be placed with broker, with indicator and margin estimates
* Account summaries, all-time, year-to-date, annual/year w/ optional ticker detail
* Ticker summaries, all-time, year-to-date, annual/year
* Summary of summaries, inclusive/exclusive of accounts, income by acct, income by yr/month, strategy stats (wip)
* Support for on-demand mark & ticker price updates:
    * Stocks & ETFs support with either:   
        * RapidApi (with paid subscription)
        * Tastyworks (unofficially with brokerage account)

    * Futures mark update support with:
        * Tastyworks (unofficially with brokerage account)
* Adjustment support with modified trade stats in Positions and indicator
* [_experimental_] Trade management tool and insights (wip)
* Fully supported selling options strategies:
    * Short Strangle
    * Short Put/CSP-Cash-secured Put
    * Short Call/Covered Call
* In progress strategies:
    * Vertical/Put|Call Credit Spread


## Tastyworks

Using a/the "unofficial" (Python) Tastyworks ([data streamer](https://github.com/boyan-soubachov/tastyworks_api)) for on-demand pricing/quotes updates. An "unofficial" Ruby API client, _for other future needs_, is present in CLI and does not rely on the Python package

_more info on data streamer portion @ [tastyworks_api](https://github.com/boyan-soubachov/tastyworks_api)_


## Misc
* [tty gem](https://ttytoolkit.org/) - Ruby terminal app framework
* [sqlite](https://www.sqlite.org/index.html) - Database
* [ActiveRecord](https://github.com/rails/rails/tree/main/activerecord) - ORM


## Copyright

Copyright © 2021 Garrett Davis. See [MIT License](LICENSE.txt) for further details.
