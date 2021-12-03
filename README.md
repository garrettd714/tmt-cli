# tmt-cli

> TMT-CLI is a options trade tracking cli tool for my own personal use
>
> **<span style="color:red">REPO FOR REFERENCE PURPOSES ONLY!</span>**

## Purpose
A simple Ruby cli (command-line-interface) with database (sqlite3) to track option trades, show insights and optionally, update the prices on-demand.

## Disclaimer
All results are for entertainment purposes only. **Not financial advice**.

> Utilizes an unofficial, reverse-engineered API for Tastyworks. There is no implied warranty for any actions and results which arise from using it.

## Features
* Trade CRUD with easy cli commands
* Positions table of active trades. ITM and breakeven indicators
* Paper trade, does not require trade to be placed, with indicator
* Support for on-demand mark & ticker price updates:
    * Stocks & ETFs support with either:
        * RapidApi (with paid subscription)
        * Tastyworks (with brokerage account)

    * Futures support with:
        * Tastyworks (with brokerage account)
* Adjustment support with modified trade stats in Positions and indicator
* [_experimental_] Trade management tool and insights
* Fully supported selling options strategies:
    * Short Strangle
    * Short Put/CSP-Cash-secured Put
    * Short Call/Covered Call


## Tastyworks

Using a/the "unofficial" (Python) Tastyworks ([data streamer](https://github.com/boyan-soubachov/tastyworks_api)) for on-demand pricing/quotes updates. An "unofficial" Ruby API client, _for other future needs_, is present in CLI and does not rely on the Python package

_more info on data streamer portion @ [tastyworks_api](https://github.com/boyan-soubachov/tastyworks_api)_


## Copyright

Copyright © 2021 Garrett Davis. See [MIT License](LICENSE.txt) for further details.