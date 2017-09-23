% Build a crypto index

clear; close all


df = readtable('df_index.csv');
df.symbol = categorical(df.symbol);

% Re-sort by (1st) date, (2nd) market cap
df = sortrows(df,{'date','market_cap'},{'ascend','descend'});

% Get available dates
date = unique(df.date);


df.cum20_market_cap = NaN(size(df,1),1);
df.share20_market_cap = NaN(size(df,1),1);

df.idx20c = NaN(size(df,1),1);

% Calculate market cap and share for different specification
for t = 1:length(date)
    day   = df(df.date==date(t),:);
    day20 = day(1:20,:);
    df.cum20_market_cap(df.date==date(t)) = ... 
        ones(size(day,1),1) .* sum(day20.market_cap);
    df.share20_market_cap(df.date==date(t)) = ...
        [day20.market_cap; zeros(size(day,1)-20,1)] ./ ...
        df.cum20_market_cap(df.date==date(t));
end


% Calculate weighted prices
df.wprice   = df.price .* df.share_market_cap;
df.wprice20 = df.price .* df.share20_market_cap;

% Calculate indices
df.idx   = NaN(size(df,1),1);
df.idx20 = NaN(size(df,1),1);

for t = 1:length(date)
    day   = df(df.date==date(t),:);
    df.idx(df.date==date(t)) = sum(day.wprice);
    df.idx20(df.date==date(t)) = sum(day.wprice20);
end


figure('Name','Dominance Index')
plot(df.date(df.symbol=='BTC'),df.share_market_cap(df.symbol=='BTC'))
hold on
plot(df.date(df.symbol=='BTC'),df.share20_market_cap(df.symbol=='BTC'))

figure('Name','Lykke20 vs Lykke20+')
plot(df.date(df.symbol=='BTC'),df.idx20(df.symbol=='BTC'))
hold on
plot(df.date(df.symbol=='BTC'&df.date>='2017-07-16'),df.idx(df.symbol=='BTC'&df.date>='2017-07-16'))


%t = 1;


% a = ans(ans.date='2017-09-19')
% a = ans(ans.date=='2017-09-19')
% a = ans(ans.date=='2017-09-19',:)
% a(1:20,:)
% sum(ans.market_cap)




%symbol = categories(df.symbol);
%for i = 1:length(symbol)
%    T.symbol{i} = df(df.symbol==symbol{i},:);
%end

%unstackvars = {'price';'market_cap'};
%price = unstack(df,'price','symbol','GroupingVariables','date');
%market_cap = unstack(df,'price','symbol','GroupingVariables','date');

%plot(df.date(df.symbol=='BTC'),df.share_market_cap(df.symbol=='BTC'))


% Echtzeitindex (Gewicht basiert auf derzeitiger Marktkapitalisierung
% -> Frage der Rechenleistung)
% vs. Gewicht basiert auf Marktkapitalisierung des Vortages

% Answer: Hohe Vola bei Marktkapitalisierung führt zu hoher Vola bei
% Gewichten. Wenn aber Marktkapitalisierung von Tag zu Tag einigermaßen
% "smooth" ist, kann einfach die Marktkapitalisierung des Vortages genommen
% werden. Beispielsweise könnte die Marktkap. um 12 Uhr MEZ bestimmt werden


