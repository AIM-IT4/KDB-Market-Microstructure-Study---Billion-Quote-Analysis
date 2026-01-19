// ============================================================================
// MAIN.Q - Market Microstructure Study Entry Point
// Orchestrates all modules and provides high-level API
// ============================================================================

-1 "Loading Market Microstructure Study Framework...";
-1 "=" sv 60#"=";

// Load all modules
\l schema.q
\l spread_analytics.q
\l mm_behavior.q
\l microstructure_advanced.q
\l reports.q

// Note: datagen.q loads schema.q internally, load separately if needed
// Note: partdb.q loads datagen.q internally, load separately if needed

// ---- FRAMEWORK NAMESPACE ----
.mms:(enlist`)!(enlist::);
.mms.version:"1.0.0";
.mms.author:"Market Microstructure Study Project";

// ---- QUICK START API ----

// Generate sample data and run basic analysis
.mms.quickStart:{[]
    -1 "\n=== QUICK START ===\n";
    
    // Load data generator
    \l datagen.q
    
    // Generate 100K quotes
    -1 "Generating 100,000 sample quotes...";
    startTime:.z.p;
    quotes::genQuotes[100000;.z.d];
    elapsed:(.z.p - startTime) % 1e9;
    -1 "Generated in ",string[elapsed]," seconds\n";
    
    // Generate trades (1 per 50 quotes)
    -1 "Generating sample trades...";
    trades::genTrades[quotes;50];
    -1 "Generated ",string[count trades]," trades\n";
    
    // Run basic analysis
    -1 "=== SPREAD ANALYSIS ===";
    show spreadStatsBySym quotes;
    
    -1 "\n=== TOP MARKET MAKERS ===";
    show mmMarketShare quotes;
    
    -1 "\n=== LIQUIDITY SCORE (AAPL) ===";
    qAAPL:select from quotes where sym=`AAPL;
    tAAPL:select from trades where sym=`AAPL;
    show liquidityScore[qAAPL;tAAPL];
    
    -1 "\nQuick start complete. Data stored in global tables: quotes, trades";
};

// Run comprehensive analysis
.mms.fullAnalysis:{[quotes;trades]
    -1 "\n=== FULL MICROSTRUCTURE ANALYSIS ===\n";
    
    // Daily summary
    dailySummaryReport[quotes;trades];
    
    // Market maker behavior
    mmBehaviorReport[quotes;trades];
    
    // Advanced metrics for each symbol
    -1 "\n=== ADVANCED METRICS BY SYMBOL ===";
    syms:distinct quotes`sym;
    {[q;t;s]
        -1 "\n--- ",string[s]," ---";
        qSym:select from q where sym=s;
        tSym:select from t where sym=s;
        
        // Kyle's Lambda
        if[count tSym;
            kl:kyleLambda[tSym];
            -1 "Kyle's Lambda: ",string kl`lambda
        ];
        
        // Roll spread
        if[count tSym;
            rs:rollSpread tSym`price;
            -1 "Roll Spread: $",string rs
        ];
        
        // Liquidity score
        show liquidityScore[qSym;tSym];
    }[quotes;trades] each 5#syms;  // First 5 symbols
    
    -1 "\nFull analysis complete.";
};

// Performance benchmark
.mms.benchmark:{[n]
    -1 "\n=== PERFORMANCE BENCHMARK ===\n";
    
    // Load data generator
    \l datagen.q
    
    -1 "Testing with ",string[n]," quotes...\n";
    
    // Data generation
    -1 "1. Data Generation:";
    t1:.z.p;
    quotes:genQuotes[n;.z.d];
    e1:(.z.p - t1) % 1e9;
    -1 "   Time: ",string[e1]," seconds";
    -1 "   Rate: ",string[`long$n % e1]," quotes/second\n";
    
    // Trade generation
    -1 "2. Trade Generation:";
    t2:.z.p;
    trades:genTrades[quotes;50];
    e2:(.z.p - t2) % 1e9;
    -1 "   Time: ",string[e2]," seconds";
    -1 "   Trades: ",string count trades;
    -1 "";
    
    // Spread calculation
    -1 "3. Spread Calculation (by symbol):";
    t3:.z.p;
    stats:spreadStatsBySym quotes;
    e3:(.z.p - t3) % 1e9;
    -1 "   Time: ",string[e3]," seconds\n";
    
    // Kyle's Lambda
    -1 "4. Kyle's Lambda Calculation:";
    t4:.z.p;
    kls:kyleLambdaBySym trades;
    e4:(.z.p - t4) % 1e9;
    -1 "   Time: ",string[e4]," seconds\n";
    
    // Summary
    total:e1+e2+e3+e4;
    -1 "TOTAL TIME: ",string[total]," seconds";
    -1 "THROUGHPUT: ",string[`long$n % total]," quotes/second\n";
    
    // Memory usage
    -1 "MEMORY:";
    -1 "   Quotes table: ",string[(-22!quotes) % 1e6]," MB";
    -1 "   Trades table: ",string[(-22!trades) % 1e6]," MB";
    
    ([]metric:`dataGen`tradeGen`spreadCalc`kyleLambda`total;
       seconds:e1,e2,e3,e4,total)
};

// ---- BILLION RECORD WORKFLOW ----

.mms.billionQuoteWorkflow:{[]
    -1 "\n=== BILLION QUOTE WORKFLOW ===\n";
    -1 "This workflow demonstrates handling 1B+ quotes using partitioned storage.\n";
    
    // Load partdb
    \l datagen.q
    \l partdb.q
    
    -1 "Step 1: Initialize HDB";
    initHdb["./hdb"];
    
    -1 "\nStep 2: Generate data (adjust based on your RAM)";
    -1 "  For testing: generateAndSave[1000000;.z.d;5]  // 5M quotes";
    -1 "  For full: generateAndSave[200000000;2026.01.01;5]  // 1B quotes";
    
    -1 "\nStep 3: After data generation, query examples:";
    -1 "  queryDateRange[2026.01.01;2026.01.05]";
    -1 "  querySymbols[2026.01.01;2026.01.05;`AAPL`MSFT]";
    
    -1 "\nStep 4: Run aggregated analysis";
    -1 "  spreadStats:aggregateByDate[spreadStatsBySym;2026.01.01;2026.01.05]";
    
    -1 "\nWorkflow guide complete. Use functions above to process billion+ records.";
};

// ---- HELP ----

.mms.help:{[]
    -1 "\n=== MARKET MICROSTRUCTURE STUDY - HELP ===\n";
    
    -1 "QUICK START:";
    -1 "  .mms.quickStart[]     - Generate sample data and run basic analysis";
    -1 "  .mms.benchmark[n]     - Performance test with n quotes";
    -1 "";
    
    -1 "DATA GENERATION:";
    -1 "  genQuotes[n;date]     - Generate n quotes for given date";
    -1 "  genTrades[quotes;r]   - Generate trades (1 per r quotes)";
    -1 "";
    
    -1 "SPREAD ANALYTICS:";
    -1 "  quotedSpread[q]       - Raw dollar spread";
    -1 "  spreadBps[q]          - Spread in basis points";
    -1 "  twas[q]               - Time-weighted average spread";
    -1 "  spreadStatsBySym[q]   - Aggregated stats by symbol";
    -1 "";
    
    -1 "MARKET MAKER ANALYSIS:";
    -1 "  mmQuoteFrequency[q]   - Quote count/rate by MM";
    -1 "  mmMarketShare[q]      - Market share by MM";
    -1 "  mmInventoryPressure[q]- Size imbalance analysis";
    -1 "";
    
    -1 "ADVANCED METRICS:";
    -1 "  kyleLambda[trades]    - Price impact coefficient";
    -1 "  rollSpread[prices]    - Roll implied spread";
    -1 "  amihud[trades]        - Amihud illiquidity";
    -1 "  liquidityScore[q;t]   - Composite liquidity score";
    -1 "";
    
    -1 "REPORTS:";
    -1 "  dailySummaryReport[q;t]  - Print daily summary";
    -1 "  exportAllReports[q;t;d]  - Export all CSVs to directory";
    -1 "";
    
    -1 "LARGE SCALE:";
    -1 "  .mms.billionQuoteWorkflow[] - Guide for billion+ records";
    -1 "";
};

// ---- STARTUP MESSAGE ----

-1 "=" sv 60#"=";
-1 "";
-1 "  MARKET MICROSTRUCTURE STUDY FRAMEWORK v",string .mms.version;
-1 "";
-1 "  Commands:";
-1 "    .mms.quickStart[]  - Run sample analysis";
-1 "    .mms.benchmark[n]  - Performance test";
-1 "    .mms.help[]        - Full help";
-1 "";
-1 "=" sv 60#"=";
