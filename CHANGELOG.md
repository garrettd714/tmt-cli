## Changelog

### v0.4.0 [2021-12-12]
```diff
+ History normalize option
```
> Normalizes the underlying trades to the number of contracts passed
to the option. e.g. `tmt -hi /es --ytd -n=1`

### v0.3.1 [2021-12-12]
```diff
- Config command
```
> Moved utilities (tool, margin calc) to new directory, updated refs

### v0.3.0 [2021-12-12]
```diff
+ Account command
+ Summary command
+ Settings service
- Decoupled RapidApi support from commands
```
> * Lots of minor changes to commands
> * RapidApi superceded by Tastyworks implementation

### v0.2.0 [2021-11-29]
```diff
+ Data streaming support from Tastyworks
+   * TastyStream command
+   * TastyDxFeed command
+   * TastyRefresh command
```
> See [README](README.md) for details

### v0.1.0 [2021-11-28]
```diff
+ Initial release
+   * Positions command
+   * History command
+   * Open command
+   * Details command
+   * Close command
+   * Version command
```
