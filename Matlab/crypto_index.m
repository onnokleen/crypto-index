% Build a crypto index

clear; close all
if ~exist('../bld','dir'); mkdir('../bld'); end
if ~exist('../bld/figures','dir'); mkdir('../bld/figures'); end

df = readtable('df_index.csv');
df = df(df.date>='2016-11-01',:);
df.symbol = categorical(df.symbol);

% Re-sort by (1st) date, (2nd) market cap
df = sortrows(df,{'date','market_cap'},{'ascend','descend'});

% Get available dates
date = unique(df.date);



%% Build index

% Calculate market cap and share for different specification
df.cum20_market_cap = NaN(size(df,1),1);
df.share20_market_cap = NaN(size(df,1),1);
df.idx20c = NaN(size(df,1),1);
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

% Working plots
% figure('Name','Dominance Index')
% plot(df.date(df.symbol=='BTC'),df.share_market_cap(df.symbol=='BTC'))
% hold on
% plot(df.date(df.symbol=='BTC'),df.share20_market_cap(df.symbol=='BTC'))

% figure('Name','Lykke20 vs Lykke20+')
% plot(df.date(df.symbol=='BTC'),df.idx20(df.symbol=='BTC'))
% hold on
% plot(df.date(df.symbol=='BTC'&df.date>='2017-07-16'),df.idx(df.symbol=='BTC'&df.date>='2017-07-16'))



%% Final plots

fnt_size = 8;% Font size
linewdth = 1.2;% linewidth


% Plot index evolution
f1 = figure('Name','LCI20 and Bitcoin Dominance');
[ax,h1,h2] = plotyy(date,df.idx20(df.symbol=='BTC'), ...
    date,df.share_market_cap(df.symbol=='BTC'));

% Formatting commands
axis 'tight'
lgnd = legend({'LCI20','Bitcoin Share'},'location','SouthWest','box','off');
% Change linewidth, color and style of time series
set(h1,'linewidth', linewdth,'color','k')
set(h2,'linewidth', linewdth,'color','r','LineStyle','--')
% Format x axes
set(ax(1),'xcolor','k','ycolor','k','fontsize',fnt_size,'tickdir','out')
set(ax(2),'xcolor','k', 'ycolor','k','fontsize',fnt_size, ...
    'tickdir','out','xticklabel',[],'xtick',[])
linkaxes(ax,'x');
% Format y axes
y1sr_lim  = [0, 3000];% Lower and upper bound of y1 axis
y2sr_lim  = [0.4, 1];% Lower and upper bound of y2 axis
ylim(ax(1),y1sr_lim)
set(ax(1),'ytick',y1sr_lim(1):500:y1sr_lim(2),'box','off')
ylim(ax(2),y2sr_lim)
set(ax(2),'ytick',y2sr_lim(1):0.2:y2sr_lim(2),'box','off')
% Manually include top rule
hold on
h3 = line(date,y1sr_lim(2)*ones(1,length(date)));
set(h3,'linewidth',0.5,'color','k')

% Resize figure and export to eps
set(gcf, 'PaperPosition', [0.25 2.5 16.0 8.0]);
print('-depsc','../bld/figures/lci20.eps')


% Plot index vs Bitcoin price
f2 = figure('Name','LCI20 vs Bitcoin');
[ax,h1,h2] = plotyy(date, df.idx20(df.symbol=='BTC'), ...
    date,df.price(df.symbol=='BTC'));

% Formatting commands
axis 'tight'
lgnd = legend({'LCI20','Bitcoin Price'},'location','NorthWest','box','off');
% Change linewidth, color and style of time series
set(h1,'linewidth', linewdth,'color','k')
set(h2,'linewidth', linewdth,'color','b','LineStyle','--')
% Format x axes
set(ax(1),'xcolor','k','ycolor','k','fontsize',fnt_size,'tickdir','out')
set(ax(2),'xcolor','k', 'ycolor','k','fontsize',fnt_size, ...
    'tickdir','out','xticklabel',[],'xtick',[])
linkaxes(ax,'x');
% Format y axes
y1sr_lim  = [0, 3000];% Lower and upper bound of y1 axis
y2sr_lim  = [0, 5500];% Lower and upper bound of y2 axis
ylim(ax(1),y1sr_lim)
set(ax(1),'ytick',y1sr_lim(1):500:y1sr_lim(2),'box','off')
ylim(ax(2),y2sr_lim)
set(ax(2),'ytick',y2sr_lim(1):500:y2sr_lim(2),'box','off')
% Manually include top rule
hold on
h3 = line(date,y1sr_lim(2)*ones(1,length(date)));
set(h3,'linewidth',0.5,'color','k')

% Resize figure and export to eps
set(gcf, 'PaperPosition', [0.25 2.5 16.0 8.0]);
print('-depsc','../bld/figures/lci20_vs_btc.eps')


% Plot index evolution during split
f3 = figure('Name','LCI20 during Split');
sdate = '2017-07-01';
edate = '2017-08-26';
bch_p = [NaN(size(date(date>=sdate&date<='2017-08-01'),1),1); ...
    df.price(df.symbol=='BCH'&df.date>=sdate&df.date<=edate)];
[ax,h1,h2] = plotyy(date(date>=sdate&date<=edate), ...
    df.idx20(df.symbol=='BTC'&df.date>=sdate&df.date<=edate), ...
    date(date>=sdate&date<=edate), ...
    [df.price(df.symbol=='BTC'&df.date>=sdate&df.date<=edate)'; bch_p']);

% Formatting commands
axis 'tight'
lgnd = legend({'LCI20','Bitcoin Price','Bitcoin Cash Price'},'location','NorthWest','box','off');
% Change linewidth, color and style of time series
set(h1,'linewidth', linewdth,'color','k')
set(h2(1),'linewidth', linewdth,'color','b','LineStyle','--')
set(h2(2),'linewidth', linewdth,'color','r','LineStyle','--')
% Format x axes
set(ax(1),'xcolor','k','ycolor','k','fontsize',fnt_size,'tickdir','out')
datetick(ax(1),'x','mmm dd','keepticks')
set(ax(2),'xcolor','k', 'ycolor','k','fontsize',fnt_size, ...
    'tickdir','out','xticklabel',[],'xtick',[])
linkaxes(ax,'x');
% Format y axes
y1sr_lim  = [0, 3000];% Lower and upper bound of y1 axis
y2sr_lim  = [0, 5500];% Lower and upper bound of y2 axis
ylim(ax(1),y1sr_lim)
set(ax(1),'ytick',y1sr_lim(1):500:y1sr_lim(2),'box','off')
ylim(ax(2),y2sr_lim)
set(ax(2),'ytick',y2sr_lim(1):500:y2sr_lim(2),'box','off')
% Manually include top rule
hold on
h3 = line(date(date>=sdate&date<=edate),y1sr_lim(2) * ...
    ones(1,length(date(date>=sdate&date<=edate))));
set(h3,'linewidth',0.5,'color','k')

% Resize figure and export to eps
set(gcf, 'PaperPosition', [0.25 2.5 16.0 8.0]);
print('-depsc','../bld/figures/lci20_bch_split.eps')


% Plot share of currencies
clist = {'BTC','ETH','BCH','XRP','LTC'};
dlist = {'2017-01-01','2017-02-01', ...
         '2017-03-01','2017-04-01','2017-05-01','2017-06-01', ...
         '2017-07-01','2017-08-01','2017-09-01'};

A = zeros(length(dlist),length(clist)+1);
for i = 1:length(dlist)
    for j = 1:length(clist)
        a_ij = df.share_market_cap(df.symbol==clist{j}&df.date==dlist{i});
        if isempty(a_ij)==0
            A(i,j) = a_ij;
        end
    end
end
A(:,length(clist)+1) = ones(length(dlist),1) - sum(A(:,1:length(clist)),2);

f4 = figure('Name','Share of Currencies');
bar(datetime(dlist,'InputFormat','yyyy-MM-dd'),A,'stacked')
lgnd = legend({'BTC','ETH','BCH','XRP','LTC','Other'},'location','EastOutside');
ax = gca;
ax.TickLength = [0 0];
ax.YTick = [0:0.25:1];
ax.XTickLabel = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep'};
ax.XTickLabelRotation = 0;
ax.FontSize = 8;

% Resize figure and export to eps
set(gcf, 'PaperPosition', [0.25 2.5 16.0 8.0]);
print('-depsc','../bld/figures/currency_shares.eps')
