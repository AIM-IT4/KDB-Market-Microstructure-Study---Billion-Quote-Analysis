/ ============================================================================
/ SPREAD_ANALYTICS.Q - Bid-Ask Spread Analysis Engine
/ Core microstructure metrics for liquidity measurement
/ ============================================================================

/ ---- BASIC SPREAD METRICS ----

/ Quoted spread (raw dollar spread)
quotedSpread:{[q] q[`ask] - q[`bid]}

/ Mid-price calculation
midPrice:{[q] 0.5 * q[`ask] + q[`bid]}

/ Relative spread (percentage of mid-price)
relativeSpread:{[q] (q[`ask] - q[`bid]) % 0.5 * q[`ask] + q[`bid]}

/ Relative spread in basis points
spreadBps:{[q] 10000 * relativeSpread q}

/ ---- TIME-WEIGHTED METRICS ----

/ Time-weighted average spread (TWAS)
twas:{[q] spreads:quotedSpread q; durations:1e-9 * deltas `long$q`time; durations[0]:0f; totalDuration:sum durations; $[totalDuration=0;avg spreads;(sum spreads * durations) % totalDuration]}

/ Time-weighted relative spread
twrs:{[q] rspreads:relativeSpread q; durations:1e-9 * deltas `long$q`time; durations[0]:0f; totalDuration:sum durations; $[totalDuration=0;avg rspreads;(sum rspreads * durations) % totalDuration]}

/ ---- EFFECTIVE SPREAD ----

/ Effective spread from trade and quote data
/ effectiveSpread = 2 * |trade_price - midprice|
effectiveSpread:{[trades;quotes] qj:aj[`sym`time;trades;select time,sym,mid:0.5*bid+ask from quotes]; 2 * abs qj[`price] - qj`mid}

/ Effective half-spread (one-way cost)
effectiveHalfSpread:{[trades;quotes] 0.5 * effectiveSpread[trades;quotes]}

/ ---- REALIZED SPREAD ----

/ Realized spread: 2 * D * (trade_price - midprice_{t+delta})
realizedSpread:{[trades;quotes;deltaMs] direction:?[trades[`side]=`B;1;-1]; qAtTrade:aj[`sym`time;trades;select time,sym,mid:0.5*bid+ask from quotes]; futureTime:trades[`time] + `long$deltaMs * 1000000; futureRef:update time:futureTime from select time,sym from trades; qAtFuture:aj[`sym`time;futureRef;select time,sym,midFuture:0.5*bid+ask from quotes]; 2 * direction * (qAtTrade[`price] - qAtFuture`midFuture)}

/ ---- AGGREGATED ANALYTICS ----

/ Spread statistics by symbol
spreadStatsBySym:{[q] select avgSpread:avg quotedSpread q, minSpread:min quotedSpread q, maxSpread:max quotedSpread q, avgSpreadBps:avg spreadBps q, quoteCount:count i by sym from q}

/ Intraday spread profile (by minute)
intradaySpreadProfile:{[q] select avgSpread:avg quotedSpread q, avgSpreadBps:avg spreadBps q, quoteCount:count i by sym, minute:1 xbar time.minute from q}

/ ---- SPREAD DECOMPOSITION ----

/ Adverse selection component
adverseSelection:{[trades;quotes;deltaMs] es:effectiveSpread[trades;quotes]; rs:realizedSpread[trades;quotes;deltaMs]; es - rs}

/ ---- UTILITY FUNCTIONS ----

/ Filter quotes to regular trading hours
marketHoursOnly:{[q] select from q where time.time within (`time$09:30:00;`time$16:00:00)}

/ Quote quality metrics
quoteQuality:{[q] select avgSpread:avg ask-bid, pctTight:avg (ask-bid) < 0.02, pctWide:avg (ask-bid) > 0.10, avgBidSize:avg bidSize, avgAskSize:avg askSize, sizeImbalance:avg (bidSize-askSize)%bidSize+askSize by sym from q}

-1 "Spread analytics loaded.";
-1 "Key functions: quotedSpread, spreadBps, twas, effectiveSpread, spreadStatsBySym";
