library(data.table)
library(dplyr)
library(readr)
library(purrr)
library(lubridate)
library(ggplot2)
library(ggthemes)
library(foreach)
Sys.setlocale("LC_TIME", "en_US.UTF-8")

download_coincap_one_currency <- function(symbol) {
  raw_json <- jsonlite::fromJSON(paste0("http://coincap.io/history/", symbol))
  
  if (is.null(raw_json) == TRUE) {
    return(NULL)
  }
  
  df_symbol <-
    lapply(seq_along(raw_json), 
           function(i) {
             pikachu <- data_frame(date = as.POSIXct(raw_json[[i]][, 1]/1000, origin = "1970-01-01 00:00.000", tz = "UTC"), 
                                   raw_json[[i]][,2])
             colnames(pikachu) <- c("date", names(raw_json)[[i]])
             pikachu
           }) %>%
    Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by = "date"), .)
  cbind(data_frame(symbol = symbol), df_symbol)
}

# test5 <- jsonlite::fromJSON("https://api.coinmarketcap.com/v1/ticker/?limit=0")

get_coincap_series <- function (symbols) {
  bind_rows(lapply(symbols, FUN = download_coincap_one_currency))
}

# currencies <- c("BTC", "IOT", "ETH", "BCH", "XRP", "LTC", "DASH", "XEM", "XMR", "ETC", "NEO", "OMG", "LSK", "QTUM", "STRAT",
#                 "USDT", "ZEC", "WAVES", "ARK", "EOS", "STEEM", "MAID", "EOS", "BAT", "BTS", "REP", "PAY", "DCR", "KMD", "VERI", "HSR", "PIVX", "NXS")

df_daily <- get_coincap_series(markets$MarketCurrency)

df_daily %>%
  mutate(date = date(date),
         market_cap = ifelse(is.na(market_cap) == TRUE, NA, market_cap)) %>%
  filter(date >= "2017-06-01", date < date(Sys.time())) %>%
  ggplot() +
  geom_line(aes(x = date, y = log(market_cap), colour = symbol, linetype = symbol)) +
  theme_few()


df_daily %>%
  mutate(date = date(date),
         market_cap = ifelse(is.na(market_cap) == TRUE, NA, market_cap)) %>%
  filter(date >= "2017-06-01", symbol == "ETH") %>% #,
  #symbol %in% c("BTC", "IOT", "ETH", "BCH", "XRP", "LTC", "DASH", "XEM", "XMR", "ETC", "NEO", "OMG", "LSK", "QTUM", "STRAT")) %>%
  ggplot() +
  geom_line(aes(x = date, y = market_cap, colour = symbol, linetype = symbol)) +
  theme_few()

# eth and btc should be in time series, otherwise weird index figures at those days without btc/eth

btc_dates <-
  df_daily %>%
  filter(symbol == "BTC") %>%
  select(date)
btc_dates <- btc_dates$date

eth_dates <-
  df_daily %>%
  filter(symbol == "ETH") %>%
  select(date)
eth_dates <- eth_dates$date

df_index <-
  df_daily %>%
  mutate(date = date(date),
         market_cap = ifelse(market_cap == 0, NA, market_cap)) %>%
  filter(date >= "2016-01-01",
         date < date(Sys.time())) %>%
  filter(date %in% date(btc_dates)) %>%
  filter(date %in% date(eth_dates)) %>%
  filter(is.na(market_cap) == FALSE) %>%
  group_by(date) %>%
  mutate(cum_market_cap = sum(market_cap)) %>%
  ungroup() %>%
  mutate(share_market_cap = market_cap / cum_market_cap)

df_n_currencies <-
  df_index %>%
  group_by(date) %>%
  summarise(n_currencies = n()) %>%
  ungroup()

df_index <-
  full_join(df_index, df_n_currencies, by = "date") %>%
  filter(n_currencies >= 21, market_cap > 0) %>%
  mutate(weekday = wday(date)) %>%
  arrange(date)

write_csv(df_index, "../Data/df_index.csv")

# old
# 
# index_dates <- unique(df_index$date) 
# 
# cut_off <- 0.25
# 
# df_joint <- foreach (i = index_dates, .combine = "rbind") %do% {
#   print(i)
#   df_day <- 
#     df_index %>%
#     filter(date == i)
#   
#   # Filter 20 largest capitalization from coins
#   df_day <-
#     df_day %>%
#     filter(market_cap >= sort(df_day$market_cap, decreasing = TRUE)[20]) %>%
#     group_by(date) %>%
#     mutate(cum_market_cap = sum(market_cap)) %>%
#     ungroup() %>%
#     mutate(share_market_cap = market_cap / cum_market_cap)
#   
#   excess_market_share <-
#     df_day %>%
#     mutate(excess_share_market_cap = ifelse(share_market_cap > cut_off, share_market_cap - cut_off, 0)) %>%
#     summarise(excess_share = sum(excess_share_market_cap)) %>%
#     unlist()
#   
#   non_excess_market_share <-
#     df_day %>%
#     mutate(excess_share_market_cap = ifelse(share_market_cap <= cut_off, share_market_cap, 0)) %>%
#     summarise(excess_share = sum(excess_share_market_cap)) %>%
#     unlist()
#   # 
#   # df_weighting <-
#   #   df_day %>%
#   #   mutate(share_market_cap_trunc = ifelse(share_market_cap > cut_off, cut_off, 
#   #                                          share_market_cap  + share_market_cap / non_excess_market_share * excess_market_share))# %>%
#     #summarise(x = sum(share_market_cap_trunc))
#   # df_weighting
#   # df_weighting$share_market_cap_trunc %>% sum()
#   
#   
#   df_index_numbers <-
#     df_day %>%
#     mutate(share_market_cap_trunc = ifelse(share_market_cap > cut_off, cut_off, share_market_cap)) %>%
#     mutate(share_market_cap_trunc_standardized = share_market_cap_trunc / sum(.$share_market_cap_trunc)) %>%
#     mutate(index = market_cap * share_market_cap_trunc_standardized) %>%
#     group_by(date) %>%
#     summarise(index = sum(index))
#   
#   if (i == min(index_dates)) {
#     denominator <- unique(df_index_numbers$index)
#   }
#   
#   df_day <- 
#     df_index %>%
#     filter(date == i)
#   
#   # Filter 20 largest capitalization from coins
#   df_day <-
#     df_day %>%
#     mutate(id_included = ifelse(market_cap >= sort(df_day$market_cap, decreasing = TRUE)[20], 1, 0))
#   
#   full_join(df_day, df_index_numbers, by = "date")
# }
# 
# numeraire <-
#   df_joint %>%
#   filter(date == min(date)) %>%
#   select(index) %>%
#   unique() %>% 
#   unlist()
# 
# df_joint <- 
#   df_joint %>%
#   mutate(index = index / numeraire * 100)
# 
# df_joint %>%
#   ggplot() +
#   geom_line(aes(x = date, y = index)) +
#   ylim(0,600) +
#   theme_few() +
#   ggtitle("25")
# 
# 
# 
# 
# 
# # alt ----------------------------------------------------------------------------------------------------------------
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# df_joint %>%
#   filter(date %in% as.Date(c("2017-07-23", "2017-07-24", "2017-07-25"))) %>%
#   View()
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# df_daily %>%
#   mutate(date = date(date)) %>%
#   filter(date >= "2017-07-24",
#          symbol %in% c("BTC", "BCH")) %>%
#   ggplot() +
#   geom_line(aes(x = date, y = market_cap, colour = symbol, linetype = symbol)) +
#   theme_few()
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by = "date"), .)
# 
# download_coincap("BTC")
# 
# 
# download_coincap("IOT")
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# lapply(test, FUN = function(x) cbind(as.POSIXct(x[, 1]/1000, origin = "1970-01-01 00:00.000", tz = "UTC"), x[,2]))
# 
# test <- jsonlite::fromJSON("http://coincap.io/history/BTC")
# df_btc <-
#   lapply(seq_along(test), 
#        function(i) {
#          pikachu <- data_frame(date = as.POSIXct(test[[i]][, 1]/1000, origin = "1970-01-01 00:00.000", tz = "UTC"), 
#                           test[[i]][,2])
#          colnames(pikachu) <- c("date", names(test)[[i]])
#          pikachu
#        }) %>%
#   Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by = "date"), .)
# 
# df_iota <- 
#   read_csv("cryptocurrencypricehistory/iota_price.csv",
#            col_type = 
#              cols(
#                #Date = col_character(), 
#                Date = col_date(format = "%b %d, %Y"),
#                Open = col_double(),
#                High = col_double(),
#                Low = col_double(),
#                Close = col_double(),
#                Volume = col_character(),
#                `Market Cap` = col_character())) %>%
#   mutate(Volume = as.numeric(gsub(",", "", Volume)),
#          `Market Cap` = as.numeric(gsub(",", "", `Market Cap`)),
#          currency = "iota")
# colnames(df_iota) <- c("date", "open", "high", "low", "close", "volume", "market_cap", "currency")
# 
# df_bitcoin <- read_csv("cryptocurrencypricehistory/bitcoin_price.csv",
#                        col_type = 
#                          cols(
#                            #Date = col_character(), 
#                            Date = col_date(format = "%b %d, %Y"),
#                            Open = col_double(),
#                            High = col_double(),
#                            Low = col_double(),
#                            Close = col_double(),
#                            Volume = col_character(),
#                            `Market Cap` = col_character())) %>%
#   mutate(Volume = as.numeric(gsub(",", "", Volume)),
#          `Market Cap` = as.numeric(gsub(",", "", `Market Cap`)),
#          currency = "bitcoin")
# colnames(df_bitcoin) <- c("date", "open", "high", "low", "close", "volume", "market_cap", "currency")
# 
# df_daily <- 
#   full_join(df_bitcoin, df_iota, by = c("date", "open", "high", "low", "close", "volume", "market_cap", "currency")) %>%
#   arrange(date)
# 
# summary(df_daily)