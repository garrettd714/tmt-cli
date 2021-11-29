# tmt-cli

> TMT-CLI is a options trade tracking cli tool
>
> **NOT SUITABLE FOR USE!**

## Purpose
A simple cli (command-line-interface) with database to track option trades, show insights and optionally, update the prices on-demand.

## Disclaimer
Results are for entertainment purposes only. **Not financial advice**.

> ** This is an unofficial, reverse-engineered API for Tastyworks. There is no implied warranty for any actions and results which arise from using it.

## Features
* Trade CRUD with easy cli commands
    * `tmt -o` [O]pen trade
    * `tmt -d aapl` (Active) Trade [D]etails
    * `tmt -u aapl --args=` [U]pdate trade
    * `tmt -c aapl {fill} {fees}` [C]lose trade
* Positions table of active trades. ITM and breakeven indicators
* Paper trade, does not require trade to be placed, with indicator
* Support for on-demand mark & ticker price updates:
    * Stocks & ETFs support with either:
        * RapidApi (with paid subscription)
        * Tastyworks** (with brokerage account)

    * Futures support with:
        * Tastyworks** (with brokerage account)
* Adjustment support with modified trade stats in Positions and indicator
* [_experimental_] Trade management tool and insights
* Fully supported selling options strategies:
    * Short Strangle
    * Short Put/CSP-Cash-secured Put
    * Short Call/Covered Call


## Installation


    $ gem install tmt

For "unofficial" Tastyworks** streamer support (optional):


    $ pip install tastyworks
_more info @ [tastyworks_api](https://github.com/boyan-soubachov/tastyworks_api)_

...

TODO: Write additional installation instructions here

...

## Usage

TODO: Write usage instructions here

## Copyright

Copyright (c) 2021 Garrett Davis. See [MIT License](LICENSE.txt) for further details.