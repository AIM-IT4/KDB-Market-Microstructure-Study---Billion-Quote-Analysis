/ ============================================================================
/ MM_BEHAVIOR.Q - Market Maker Behavior Analysis
/ ============================================================================

/ Quote frequency by market maker
mmQuoteFrequency:{[q] select quoteCount:count i, quotesPerSecond:count[i] % (1e-9 * max[time] - min time), firstQuote:min time, lastQuote:max time by mmid from q}

/ Quote frequency by market maker and symbol
mmQuoteFreqBySym:{[q] select quoteCount:count i, avgSpread:avg ask-bid, avgSize:avg 0.5*bidSize+askSize by mmid, sym from q}

/ Market maker market share
mmMarketShare:{[q] total:count q; shares:select quoteCount:count i by mmid from q; update marketShare:100 * quoteCount % total from shares}

/ Inventory pressure via size imbalance
inventoryPressure:{[q] update sizeImbalance:(bidSize - askSize) % (bidSize + askSize) from q}

/ MM inventory pressure stats
mmInventoryPressure:{[q] q2:inventoryPressure q; select avgImbalance:avg sizeImbalance, imbalanceStd:dev sizeImbalance, pctBidHeavy:avg sizeImbalance > 0.1, pctAskHeavy:avg sizeImbalance < -0.1 by mmid from q2}

/ Quote-to-trade ratio
quoteToTradeRatio:{[quotes;trades] qCount:select qCount:count i by sym from quotes; tCount:select tCount:count i by sym from trades; qtr:qCount lj tCount; update qtr:qCount % tCount from qtr}

/ MM quote-to-trade ratio
mmQuoteToTradeRatio:{[quotes;trades] qCount:select qCount:count i by mmid, sym from quotes; tCount:select tCount:count i by mmid, sym from trades; qtr:qCount lj tCount; update qtr:qCount % tCount from qtr}

/ Quote duration
quoteDuration:{[q] update quoteDurationMs:1e-6 * deltas `long$time by mmid, sym from q}

/ Phantom quote detection
phantomQuoteDetection:{[q;thresholdMs] qd:quoteDuration q; select totalQuotes:count i, phantomQuotes:sum quoteDurationMs < thresholdMs, phantomPct:100 * avg quoteDurationMs < thresholdMs by mmid from qd}

-1 "Market maker behavior analysis loaded.";
