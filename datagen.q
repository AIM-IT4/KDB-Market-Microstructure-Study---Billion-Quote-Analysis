// ============================================================================
// DATAGEN.Q - Realistic Quote Data Generator
// Simulates billion+ quotes with market microstructure properties
// ============================================================================

\l schema.q
initRefData[];

// Configuration namespace
.datagen.config:(enlist`)!(enlist::);
.datagen.config[`defaultSyms]:`AAPL`MSFT`GOOGL`AMZN`META`NVDA`TSLA`JPM`BAC`GS;
.datagen.config[`defaultMMs]:`CITADEL`VIRTU`JANE`TOWER`JUMP`SIG`IMC`OPTIVER;
.datagen.config[`exchanges]:`NYSE`NASDAQ`ARCA`BATS`IEX`EDGX;

// Base prices for each symbol (realistic starting points)
.datagen.basePrices:(`AAPL`MSFT`GOOGL`AMZN`META`NVDA`TSLA`JPM`BAC`GS)!
    (185.5;410.25;175.80;185.30;520.40;875.60;248.90;195.75;35.40;480.25);

// Volatility profiles (annualized %)
.datagen.vols:(`AAPL`MSFT`GOOGL`AMZN`META`NVDA`TSLA`JPM`BAC`GS)!
    (0.25;0.22;0.28;0.30;0.35;0.45;0.55;0.20;0.25;0.28);

// Intraday volume curve (U-shaped pattern)
// Returns multiplier for each minute of trading day (9:30-16:00 = 390 mins)
.datagen.intradayPattern:{[]
    x:til 390;
    // U-shape: high at open, low midday, high at close
    u:1 + 0.5*exp[neg (x-195) xexp 2 % 15000];
    u:u % avg u;  // normalize
    u
};

// Generate Poisson-modulated arrival times within a trading day
.datagen.genArrivalTimes:{[n;date]
    // Trading hours: 9:30 AM to 4:00 PM = 6.5 hours
    startTime:`time$09:30:00;
    endTime:`time$16:00:00;
    tradingMs:(endTime-startTime) % `long$1;
    
    // Generate uniform random times, then model clustering
    baseTimes:n?tradingMs;
    
    // Add some clustering (bursts of activity)
    clusterCenters:50?tradingMs;
    clustered:{[centers;t] 
        nearest:centers[first where centers > t];
        if[null nearest; nearest:last centers];
        t + `long$0.3 * (nearest - t) * rand 1.0
    }[clusterCenters;] each baseTimes;
    
    // Sort and convert to timestamps
    date + startTime + asc `time$clustered
};

// Generate correlated price series with mean reversion
.datagen.genPriceSeries:{[n;sym]
    basePrice:.datagen.basePrices[sym];
    vol:.datagen.vols[sym];
    
    // Daily vol scaled to per-quote (assuming ~1M quotes/day)
    perQuoteVol:vol % sqrt 252 * 1000000;
    
    // Mean-reverting price dynamics
    meanReversion:0.001;  // Speed of mean reversion
    
    // Generate returns with mean reversion
    returns:{[mr;vol;prevRet]
        shock:vol * (rand 1.0) - 0.5;
        neg[mr * prevRet] + shock
    }[meanReversion;perQuoteVol]\[n;0f];
    
    // Convert to prices
    prices:basePrice * prds 1+returns;
    prices
};

// Generate realistic bid-ask spreads
.datagen.genSpreads:{[n;sym]
    basePrice:.datagen.basePrices[sym];
    
    // Base spread in basis points (varies by stock liquidity)
    // More volatile stocks have wider spreads
    baseSpreadBps:10 * .datagen.vols[sym];
    
    // Spread variations (wider during volatility, tighter during calm)
    spreadMultiplier:1 + 0.5 * abs (n?1.0) - 0.5;
    
    // Convert to dollar spread
    spreads:basePrice * baseSpreadBps * spreadMultiplier % 10000;
    
    // Ensure minimum tick size (0.01)
    0.01 | spreads
};

// Generate quote sizes (power law distribution)
.datagen.genSizes:{[n]
    // Power law: most quotes are small, some are very large
    baseSizes:100 * 1 + floor (n?10.0) xexp 2;
    baseSizes
};

// Main quote generation function
genQuotes:{[n;date]
    syms:.datagen.config`defaultSyms;
    mms:.datagen.config`defaultMMs;
    exs:.datagen.config`exchanges;
    
    nPerSym:n div count syms;
    
    result:raze {[nPerSym;date;mms;exs;sym]
        // Generate arrival times
        times:.datagen.genArrivalTimes[nPerSym;date];
        
        // Generate mid prices
        midPrices:.datagen.genPriceSeries[nPerSym;sym];
        
        // Generate spreads
        spreads:.datagen.genSpreads[nPerSym;sym];
        
        // Calculate bid/ask
        halfSpreads:spreads % 2;
        bids:midPrices - halfSpreads;
        asks:midPrices + halfSpreads;
        
        // Round to tick size
        bids:0.01 * floor bids % 0.01;
        asks:0.01 * ceiling asks % 0.01;
        
        // Ensure spread is at least 1 tick
        asks:asks | bids + 0.01;
        
        // Generate sizes
        bidSizes:.datagen.genSizes[nPerSym];
        askSizes:.datagen.genSizes[nPerSym];
        
        // Assign market makers and exchanges
        mmids:nPerSym?mms;
        exchanges:nPerSym?exs;
        
        ([]
            time:times;
            date:nPerSym#date;
            sym:nPerSym#sym;
            bid:bids;
            ask:asks;
            bidSize:bidSizes;
            askSize:askSizes;
            exchange:exchanges;
            mmid:mmids;
            condition:nPerSym#`A  // Active quotes
        )
    }[nPerSym;date;mms;exs] each syms;
    
    // Sort by time globally
    `time xasc result
};

// Generate trades from quotes (for effective spread analysis)
genTrades:{[quotes;tradeRatio]
    // Generate 1 trade per tradeRatio quotes
    n:count[quotes] div tradeRatio;
    idx:(count quotes)?n;
    q:quotes idx;
    
    // Randomly select buy or sell
    sides:n?`B`S;
    
    // Trade at bid (sell) or ask (buy) with some slippage
    prices:?[sides=`B; q`ask; q`bid];
    slippage:0.01 * (n?1.0) - 0.5;  // +/- half cent
    prices+:slippage;
    
    // Trade sizes are subset of quote sizes
    sizes:floor 0.5 * ?[sides=`B; q`askSize; q`bidSize];
    
    ([]
        time:q`time;
        date:q`date;
        sym:q`sym;
        price:prices;
        size:sizes;
        side:sides;
        aggressor:sides;  // Same as side for simplicity
        mmid:q`mmid
    )
};

// Performance testing utility
.datagen.benchmark:{[n]
    -1 "Generating ",string[n]," quotes...";
    startTime:.z.p;
    quotes:genQuotes[n;.z.d];
    elapsed:(.z.p - startTime) % 1e9;
    -1 "Generated ",string[count quotes]," quotes in ",string[elapsed]," seconds";
    -1 "Rate: ",string[floor (count quotes) % elapsed]," quotes/second";
    -1 "Sample:";
    show 5#quotes;
    quotes
};

-1 "Data generator loaded. Use genQuotes[n;date] to generate n quotes.";
-1 "Example: quotes:genQuotes[1000000;.z.d]";
