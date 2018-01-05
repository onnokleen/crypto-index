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

Sys.setlocale("LC_TIME", "en_US.UTF-8")

download_coincap_one_currency <- function(symbol) {
  raw_json <- jsonlite::fromJSON(paste0("http://coincap.io/history/", symbol))
  
  if (is.null(raw_json) == TRUE) {
    return(NULL)
  }
  
  df_symbol <-
    lapply(seq_along(raw_json), 
           function(i) {
             pikachu <- data_frame(date = as_date(as.POSIXct(raw_json[[i]][, 1]/1000, origin = "1970-01-01 00:00.000", tz = "UTC")), 
                                   raw_json[[i]][,2])
             colnames(pikachu) <- c("date", names(raw_json)[[i]])
             pikachu
           }) %>%
    Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by = "date"), .)
  cbind(data_frame(symbol = symbol), df_symbol)
}

get_coincap_series <- function (symbols) {
  bind_rows(lapply(symbols, FUN = download_coincap_one_currency))
}


markets <- filter(jsonlite::fromJSON("https://bittrex.com/api/v1.1/public/getmarkets")$result, 
                  IsActive == TRUE & BaseCurrency == "BTC")

df_daily_raw <- get_coincap_series(c("BTC", markets$MarketCurrency)) 

df_daily <- 
  df_daily_raw %>%
  filter(date <= (Sys.Date() - days(2)))
# %>%
#   bind_rows(left_join(data_frame(symbol = rep(c("BTC", markets$MarketCurrency), times = 3),
#                                  date = c(rep(Sys.Date()          , times = length(c("BTC", markets$MarketCurrency))), 
#                                           rep(Sys.Date() - days(1), times = length(c("BTC", markets$MarketCurrency))), 
#                                           rep(Sys.Date() - days(2), times = length(c("BTC", markets$MarketCurrency))))),
#                       select(filter(df_daily_raw, date == (Sys.Date() - days(3))), symbol, market_cap), by = "symbol" ))
  

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

write_csv(df_intraday, "../Data/first_intraday_starting_2017-12-17.csv.gz")

df_daily_index <- foreach (i = unique(df_daily$date), .combine = bind_rows) %do% {
  if (length(unique(filter(df_daily, date == i)$symbol)) < 20 | ("BTC" %in% unique(filter(df_daily, date == i)$symbol) == FALSE)) {
    NULL
  } else {
    df_shares <-
      df_daily %>%
      filter(date == i) %>%
      arrange(desc(market_cap)) %>%
      head(20) %>%
      mutate(overall_market_cap = sum(market_cap)) %>%
      mutate(share_market_cap = market_cap / overall_market_cap) %>%
      mutate(transformed_share = share_market_cap) %>%
      arrange(desc(market_cap))
    
    for (j in c(1:19)) {
      if (df_shares$transformed_share[j] >= 0.2) {
        diff <- df_shares$transformed_share[j] - 0.2
        df_shares$transformed_share[j] <- 0.2
        df_shares$transformed_share[(j+1):20] <- df_shares$transformed_share[(j+1):20] / sum(df_shares$transformed_share[(j+1):20]) * (1 - j * 0.2)
      }
    }
    df_index <- data_frame(date = i, coi = sum(df_shares$price * df_shares$transformed_share))
  }
}

initial_value <- df_daily_index$coi[1]

df_daily_index$coi <- df_daily_index$coi / initial_value * 100

df_btc <- 
  df_daily %>%
  filter(symbol == "BTC") %>%
  filter(date >= min(df_daily_index$date)) %>%
  arrange(date) %>%
  mutate(btc_price_div_10 = price / 10)

df_joint <-
  left_join(df_daily_index, df_btc) %>%
  gather(index, value, btc_price_div_10, coi)  

df_joint %>%
  filter(date <= "2017-01-01") %>%
  spread(index, value) %>%
  summarise(cor = cor(coi, btc_price_div_10))


ggplotly(df_joint %>%
           filter(date >= "2017-01-01") %>%
           ggplot() + 
           geom_line(aes(x = date, y = value, colour = index)) +
           #coord_cartesian(ylim = c(0, 170)) +
           theme(legend.position = "below")) 


df_joint <-
  df_intraday %>%
  left_join(select(filter(df_daily, date >= min(df_intraday$date)), symbol, date, market_cap)) %>%
  filter(date <= (Sys.Date() - days(2)))

df_intraday_index <- foreach (i = unique(df_joint$dt), .combine = bind_rows) %do% {
  print(i)
  if (length(unique(filter(df_daily, date == date(i))$symbol)) < 20 | ("BTC" %in% unique(filter(df_daily, date == date(i))$symbol) == FALSE)) {
    NULL
  } else {
    
    df_shares <-
      df_daily %>%
      filter(date == date(i)) %>%
      arrange(desc(market_cap)) %>%
      head(20) %>%
      mutate(overall_market_cap = sum(market_cap)) %>%
      mutate(share_market_cap = market_cap / overall_market_cap) %>%
      mutate(transformed_share = share_market_cap) %>%
      arrange(desc(market_cap))
    
    for (j in c(1:19)) {
      if (df_shares$transformed_share[j] >= 0.2) {
        diff <- df_shares$transformed_share[j] - 0.2
        df_shares$transformed_share[j] <- 0.2
        df_shares$transformed_share[(j+1):20] <- df_shares$transformed_share[(j+1):20] / sum(df_shares$transformed_share[(j+1):20]) * (1 - j * 0.2)
      }
    }
    
    df_shares <-
      df_joint %>%
      filter(dt == i) %>%
      #filter(symbol %in% symbols_included$symbol) %>%
      left_join(select(df_shares, symbol, date, transformed_share), by = c("symbol", "date")) %>%
      filter(is.na(btc) == FALSE)
      
    df_index <- data_frame(dt = i, coi = sum(df_shares$close_usd * df_shares$transformed_share, na.rm = TRUE))
  }
}

df_intraday_index$coi <- df_intraday_index$coi / initial_value * 100


ggplotly(df_intraday_index %>%
           ggplot() + 
           geom_line(aes(x = dt, y = coi)) +
           coord_cartesian(ylim = c(2000, 3000)) +
           theme(legend.position = "below")) 

