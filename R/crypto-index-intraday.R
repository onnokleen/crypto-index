library(foreach)
library(dplyr)
library(lubridate)
library(readr)

jsonlite::fromJSON("https://bittrex.com/Api/v2.0/pub/market/GetTicks?marketName=USDT-BTC&tickInterval=oneMin")


jsonlite::fromJSON("https://bittrex.com/api/v1.1/public/getmarkethistory?market=BTC-DOGE&tickInterval=oneMin")

#markets <- filter(jsonlite::fromJSON("https://bittrex.com/api/v2.0/pub/markets/GetMarkets")$result, IsActive == TRUE & BaseCurrency == "BTC")

markets <- filter(jsonlite::fromJSON("https://bittrex.com/api/v1.1/public/getmarkets")$result, 
                  IsActive == TRUE & BaseCurrency == "BTC")

test_new <- foreach(market = markets$MarketName)  %do% {
  
  df_market <- cbind(market, 
                     jsonlite::fromJSON(paste0("https://bittrex.com/Api/v2.0/pub/market/GetTicks?marketName=", 
                                               market, 
                                               "&tickInterval=oneMin"))$result)
       
  df_btc <- 
    jsonlite::fromJSON(paste0("https://bittrex.com/Api/v2.0/pub/market/GetTicks?marketName=USDT-BTC&tickInterval=oneMin"))$result %>%
    rename(btc = `C`)
  
  left_join(df_market, select(df_btc, `T`, btc) , by = "T") %>%
    rename(open = `O`,
           high = `H`,
           low = `L`,
           close = `C`,
           volume = `V`,
           dt = `T`) %>%
    mutate(dt = as_datetime(dt))
    
}


df_intraday <-
  test_new %>%
  #lapply(test, function(x) select(x, dt,  market, `C`, btc)) %>%
  bind_rows() %>%
  as_data_frame() %>%
  mutate(close_usd = close * btc) %>%
  #filter(market != "USDT-BTC") %>%
  mutate(symbol = ifelse(market == "USDT-BTC", NA, substr(market, 5, nchar(market))))

write_csv(df_intraday, "../Data/first_intraday_starting_2017-11-26.csv.gz")


df_intraday_2 <- read_csv("../Data/first_intraday_starting_2017-11-25.csv.gz")

test3 <- jsonlite::fromJSON(paste0("http://coincap.io/coins"))

test2 <- jsonlite::fromJSON(paste0("http://coincap.io/history/BTC"))

df_daily <- get_coincap_series(unique(df_intraday$symbol[1:2]))

test4 <- foreach (symbol = unique(df_intraday$symbol)) %do% {
  test2 <- jsonlite::fromJSON(paste0("http://coincap.io/history/", symbol))
}

constituents <-
  df_daily %>%
  mutate(date = date(date))











