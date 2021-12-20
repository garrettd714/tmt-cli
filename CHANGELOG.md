## Changelog

### tbd [--]
```diff
+ Positions: total credit, p/l %, p/l $ for trade w/ indicator
+ Summary: --acct-only option
+ Positions: roll treatment w/ indicator based on note token
+ Details: Adjustment value to "rolled" based on note token
+ Streamer: Bugfix: Stop hang after symbols depleted
+ Containerize app w/ Docker & Compose on Alpine Linux
+   * with cron support for tmt-refresh
+   * bind mounts to persist the db and logs
```
> _Resulting Docker image not optimized for size (~326MB)_    
> Build*: `docker image build -t garrettd714/tmt-cli .`    
> Run app: `docker compose up -d`    
> Prompt: `docker container exec -it tmt-app-1 bash`   
> Stop app: `docker compose down`     
> _*Image only requires rebuild if Gemfile or Dockerfile are changed._

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
