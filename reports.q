/ ============================================================================
/ REPORTS.Q - Reporting and CSV Export
/ ============================================================================

/ Configuration
.reports.outputDir:`$"./output"

/ Initialize reports directory
initReports:{[outputPath] .reports.outputDir:`$outputPath; system "mkdir ",outputPath," 2>nul"; -1 "Reports output directory: ",outputPath}

/ Export spread analysis to CSV
exportSpreadAnalysis:{[quotes;filepath] stats:select avgSpread:avg ask-bid, minSpread:min ask-bid, maxSpread:max ask-bid, avgSpreadBps:avg 10000*(ask-bid)%0.5*ask+bid, quoteCount:count i by sym, 15 xbar time.minute from quotes; hsym[`$filepath] 0: csv 0: 0!stats; -1 "Exported spread analysis to: ",filepath}

/ Export market maker activity
exportMmActivity:{[quotes;filepath] activity:select quoteCount:count i, avgSpread:avg ask-bid, avgBidSize:avg bidSize, avgAskSize:avg askSize by mmid, sym, exchange from quotes; hsym[`$filepath] 0: csv 0: 0!activity; -1 "Exported MM activity to: ",filepath}

/ Export intraday profile
exportIntradayProfile:{[quotes;filepath] profile:select midPrice:avg 0.5*bid+ask, spread:avg ask-bid, spreadBps:avg 10000*(ask-bid)%0.5*ask+bid, totalBidSize:sum bidSize, totalAskSize:sum askSize, quoteCount:count i by sym, 5 xbar time.minute from quotes; hsym[`$filepath] 0: csv 0: 0!profile; -1 "Exported intraday profile to: ",filepath}

/ Daily summary report
dailySummaryReport:{[quotes;trades]
    -1 "\n";
    -1 "=" sv 60#"=";
    -1 "     MARKET MICROSTRUCTURE DAILY SUMMARY";
    -1 "=" sv 60#"=";
    -1 "\nDATA OVERVIEW:";
    -1 "  Quotes: ",string count quotes;
    -1 "  Trades: ",string count trades;
    -1 "  Symbols: ",string count distinct quotes`sym;
    -1 "  Market Makers: ",string count distinct quotes`mmid;
    -1 "  Exchanges: ",string count distinct quotes`exchange;
    -1 "\nTIME RANGE:";
    -1 "  First quote: ",string min quotes`time;
    -1 "  Last quote: ",string max quotes`time;
    -1 "\nSPREAD STATISTICS:";
    show select avgSpread:avg ask-bid, avgSpreadBps:avg 10000*(ask-bid)%0.5*ask+bid, minSpread:min ask-bid, maxSpread:max ask-bid by sym from quotes;
    -1 "\nTOP MARKET MAKERS:";
    show 5#`quoteCount xdesc select quoteCount:count i by mmid from quotes;
    -1 "\nEXCHANGE BREAKDOWN:";
    show select quoteCount:count i, pct:100*count[i]%count quotes by exchange from quotes;
    -1 "\n" sv 60#"=";
 }

/ Export all reports
exportAllReports:{[quotes;trades;outputDir] initReports outputDir; -1 "Exporting all reports to: ",outputDir; exportSpreadAnalysis[quotes;outputDir,"/spread_analysis.csv"]; exportMmActivity[quotes;outputDir,"/mm_activity.csv"]; exportIntradayProfile[quotes;outputDir,"/intraday_profile.csv"]; -1 "\nAll reports exported."}

-1 "Reports module loaded.";
