library(httr)


r <- GET("https://beta-pro-api.coinmarketcap.com/v1/cryptocurrency/ohlcv/historical?symbol=BTC&interval=1d&time_start=2010-01-01", add_headers("X-CMC_PRO_API_KEY" = "1a376f70-92ce-4195-bf88-9975ecdeb711"))
r
content(r)
