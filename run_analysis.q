/ Quick test and run script
/ Sets up environment and runs analysis

/ Basic test
-1 ">>> KDB+ Engine Test:";
show 2+2;

/ Load schema first
-1 "\n>>> Loading schema.q...";
\l schema.q
-1 "Schema loaded successfully.";
initRefData[];

/ Load spread analytics
-1 "\n>>> Loading spread_analytics.q...";
\l spread_analytics.q
-1 "Spread analytics loaded.";

/ Load market maker behavior
-1 "\n>>> Loading mm_behavior.q...";
\l mm_behavior.q
-1 "MM behavior module loaded.";

/ Load advanced microstructure
-1 "\n>>> Loading microstructure_advanced.q...";
\l microstructure_advanced.q
-1 "Advanced microstructure loaded.";

/ Load reports
-1 "\n>>> Loading reports.q...";
\l reports.q
-1 "Reports module loaded.";

-1 "\n>>> All base modules loaded successfully!";
-1 ">>> Now generating sample data...\n";

/ Generate sample quotes manually
syms:`AAPL`MSFT`GOOGL`AMZN`META`NVDA`TSLA`JPM`BAC`GS;
mms:`CITADEL`VIRTU`JANE`TOWER`JUMP`SIG`IMC`OPTIVER;
exs:`NYSE`NASDAQ`ARCA`BATS`IEX`EDGX;

basePrices:(`AAPL`MSFT`GOOGL`AMZN`META`NVDA`TSLA`JPM`BAC`GS)!185.5 410.25 175.80 185.30 520.40 875.60 248.90 195.75 35.40 480.25;

n:10000000;
-1 "Generating ",string[n]," quotes (10 MILLION)...";

/ Generate random data
times:.z.d + asc n?`time$24:00:00;
symList:n?syms;
midPrices:basePrices[symList] * 1 + 0.01 * (n?1.0) - 0.5;
spreads:0.01 + 0.05 * n?1.0;
bids:midPrices - 0.5*spreads;
asks:midPrices + 0.5*spreads;
bidSizes:100 * 1 + n?50;
askSizes:100 * 1 + n?50;

quotes:flip `time`date`sym`bid`ask`bidSize`askSize`exchange`mmid`condition!(times;n#.z.d;symList;bids;asks;bidSizes;askSizes;n?exs;n?mms;n#`A);

-1 "Generated ",string[count quotes]," quotes.\n";

/ Generate trades
-1 "Generating sample trades...";
nTrades:n div 50;
tradeIdx:nTrades?n;
tq:quotes tradeIdx;
sides:nTrades?`B`S;
tqAsk:tq`ask;
tqBid:tq`bid;
prices:?[sides=`B;tqAsk;tqBid];
tqAskSize:tq`askSize;
tqBidSize:tq`bidSize;
sizes:`long$floor 0.5 * ?[sides=`B;tqAskSize;tqBidSize];

trades:flip `time`date`sym`price`size`side`aggressor`mmid!(tq`time;tq`date;tq`sym;prices;sizes;sides;sides;tq`mmid);

-1 "Generated ",string[count trades]," trades.\n";

/ Run analysis
-1 "============================================================";
-1 "     ANALYSIS RESULTS";
-1 "============================================================";

-1 "\n>>> SPREAD STATISTICS BY SYMBOL:";
spreadStats:select avgSpread:avg ask-bid, avgSpreadBps:avg 10000*(ask-bid)%0.5*ask+bid, minSpread:min ask-bid, maxSpread:max ask-bid, quoteCount:count i by sym from quotes;
show spreadStats;

-1 "\n>>> MARKET MAKER MARKET SHARE:";
mmShare:select quoteCount:count i, pct:100*count[i]%count quotes by mmid from quotes;
show `pct xdesc mmShare;

-1 "\n>>> EXCHANGE BREAKDOWN:";
exBreak:select quoteCount:count i, pct:100*count[i]%count quotes by exchange from quotes;
show `pct xdesc exBreak;

-1 "\n>>> MARKET MAKER INVENTORY PRESSURE:";
invPress:select avgImbalance:avg (bidSize-askSize)%(bidSize+askSize), imbalanceStd:dev (bidSize-askSize)%(bidSize+askSize) by mmid from quotes;
show invPress;

-1 "\n>>> KYLE'S LAMBDA (PRICE IMPACT) BY SYMBOL:";
kyleLambdaCalc:{[t] dp:deltas t`price; signedVol:t[`size] * ?[t[`side]=`B;1;-1]; (cov[dp;signedVol]) % var signedVol};
kls:select kyleLambda:kyleLambdaCalc flip `price`size`side!(price;size;side) by sym from trades;
show kls;

-1 "\n>>> LIQUIDITY SCORE SAMPLE (AAPL):";
qAAPL:select from quotes where sym=`AAPL;
tAAPL:select from trades where sym=`AAPL;
avgSpreadBps:avg 10000 * (qAAPL[`ask]-qAAPL[`bid]) % 0.5*qAAPL[`ask]+qAAPL`bid;
spreadScore:0|100 - avgSpreadBps;
avgDepth:avg 0.5 * qAAPL[`bidSize] + qAAPL`askSize;
depthScore:100&avgDepth % 1000;
lambda:$[count tAAPL;kyleLambdaCalc flip `price`size`side!(tAAPL`price;tAAPL`size;tAAPL`side);0];
impactScore:0|100 - 10000 * abs lambda;
totalScore:0.4*spreadScore + 0.3*depthScore + 0.3*impactScore;
show flip `metric`value!(`spreadScore`depthScore`impactScore`totalScore;spreadScore,depthScore,impactScore,totalScore);

/ Save results to CSV
-1 "\n>>> SAVING RESULTS TO CSV...";

/ Create output directory (ignore if exists)
@[system;"mkdir output";{}];

/ Save spread stats
`:output/spread_stats.csv 0: csv 0: 0!spreadStats;
-1 "Saved: output/spread_stats.csv";

/ Save MM market share
`:output/mm_market_share.csv 0: csv 0: 0!mmShare;
-1 "Saved: output/mm_market_share.csv";

/ Save exchange breakdown
`:output/exchange_breakdown.csv 0: csv 0: 0!exBreak;
-1 "Saved: output/exchange_breakdown.csv";

/ Save inventory pressure
`:output/mm_inventory_pressure.csv 0: csv 0: 0!invPress;
-1 "Saved: output/mm_inventory_pressure.csv";

/ Save Kyle's Lambda
`:output/kyle_lambda.csv 0: csv 0: 0!kls;
-1 "Saved: output/kyle_lambda.csv";

/ Save intraday profile
intradayProfile:select avgMid:avg 0.5*bid+ask, avgSpread:avg ask-bid, avgSpreadBps:avg 10000*(ask-bid)%0.5*ask+bid, quoteCount:count i by sym, 5 xbar time.minute from quotes;
`:output/intraday_profile.csv 0: csv 0: 0!intradayProfile;
-1 "Saved: output/intraday_profile.csv";

-1 "\n>>> ALL RESULTS SAVED SUCCESSFULLY!";
-1 ">>> Output files are in: ./output/";
-1 "============================================================";

/ Exit
\\
