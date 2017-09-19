library(dplyr)
library(readr)
library(lubridate)
df_btc <- jsonlite::fromJSON("http://coincap.io/history/BTC")
as.POSIXct(test$market_cap[, 1]/1000, origin = "1970-01-01 00:00.000", tz = "UTC")
Sys.setlocale("LC_TIME", "en_US.UTF-8")



lapply(test, FUN = function(x) cbind(as.POSIXct(x[, 1]/1000, origin = "1970-01-01 00:00.000", tz = "UTC"), x[,2]))

test <- jsonlite::fromJSON("http://coincap.io/history/BTC")
lapply(seq_along(test), 
       function(i) {
         pikachu <- data_frame(date = as.POSIXct(test[[i]][, 1]/1000, origin = "1970-01-01 00:00.000", tz = "UTC"), 
                          test[[i]][,2])
         colnames(pikachu) <- c("date", names(test)[[i]])
         pikachu
       })

df_iota <- read_csv("cryptocurrencypricehistory/iota_price.csv",
                    col_type = 
                      cols(
                        #Date = col_character(), 
                        Date = col_date(format = "%b %d, %Y"),
                        Open = col_double(),
                        High = col_double(),
                        Low = col_double(),
                        Close = col_double(),
                        Volume = col_character(),
                        `Market Cap` = col_character())) %>%
  mutate(Volume = as.numeric(gsub(",", "", Volume)),
         `Market Cap` = as.numeric(gsub(",", "", `Market Cap`)),
         currency = "iota")
colnames(df_iota) <- c("date", "open", "high", "low", "close", "volume", "market_cap", "currency")

df_bitcoin <- read_csv("cryptocurrencypricehistory/bitcoin_price.csv",
                       col_type = 
                         cols(
                           #Date = col_character(), 
                           Date = col_date(format = "%b %d, %Y"),
                           Open = col_double(),
                           High = col_double(),
                           Low = col_double(),
                           Close = col_double(),
                           Volume = col_character(),
                           `Market Cap` = col_character())) %>%
  mutate(Volume = as.numeric(gsub(",", "", Volume)),
         `Market Cap` = as.numeric(gsub(",", "", `Market Cap`)),
         currency = "bitcoin")
colnames(df_bitcoin) <- c("date", "open", "high", "low", "close", "volume", "market_cap", "currency")

df_daily <- 
  full_join(df_bitcoin, df_iota, by = c("date", "open", "high", "low", "close", "volume", "market_cap", "currency")) %>%
  arrange(date)

summary(df_daily)