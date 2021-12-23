## Known Bugs 🪲

### Streamer:
✅ Hangs before refreshing, mostly after-hours [2021-12-01] 🔺    
> fixed: v0.5.0(?)    

### History command:
⬜️ Error when first active trade in underlying [2021-12-12] 🔻    
> `tmt -hi gdx --ytd`    
> Workaround: Just use detail command until first trade is closed    
> Exit: return an error message, not a stack trace    

### Summary command:
🛑 Realized amount excludes realized debit from any active "rolls"  [2021-12-12] 🔻    
> Not sure I'll fix this hopefully infrequent occurrence    
> e.g. If I roll for a credit. The amount debited (realized) to buy back the leg, is not reflected in the realized amount. Should be a minimal discrepancy while the trade is open but, should be noted nevertheless

### Close command:
⬜️ Should NOT be able to close a trade that is already closed [2021-12-22] 🔺    
> Will fix    

⬜️ Using ticker symbol may close wrong trade [2021-12-22] 🔺    
> `tmt -c /es 5.25 8.48`    
> Will fix. Workaround: use trade id for now    

### Update command:
⬜️ `--note=` option is not adding line break [2021-12-22] 🔻    
> Will fix  
