library(data.table)
library(dplyr)
library(readr)
library(purrr)
library(lubridate)
library(ggplot2)
library(ggthemes)
library(foreach)
library(plotly)
library(tidyr)

setwd("/Users/Arbeit/Git/crypto-index/R")

Sys.setlocale("LC_TIME", "en_US.UTF-8")


get_coincap_series <- function (symbols) {
  bind_rows(lapply(symbols, FUN = download_coincap_one_currency))
}


markets <- filter(jsonlite::fromJSON("https://bittrex.com/api/v1.1/public/getmarkets")$result, 
                  IsActive == TRUE & BaseCurrency == "BTC")

get_bittrex <- function (market) {
  
  df_market <- cbind(market = market, 
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

df_btc <- get_bittrex("USDT-BTC") %>%
  mutate(close_usd = close)

intraday_data <- lapply(markets$MarketName, FUN = get_bittrex)

df_intraday <-
  intraday_data %>%
  #lapply(test, function(x) select(x, dt,  market, `C`, btc)) %>%
  bind_rows() %>%
  as_data_frame() %>%
  mutate(close_usd = close * btc) %>%
  bind_rows(df_btc) %>%
  #filter(market != "USDT-BTC") %>%
  mutate(symbol = ifelse(market == "USDT-BTC", "BTC", substr(market, 5, nchar(market)))) %>%
  mutate(date = date(dt)) 

write_csv(df_intraday, paste0("../Data/intraday_download_", date(Sys.time()), ".csv.gz"))
