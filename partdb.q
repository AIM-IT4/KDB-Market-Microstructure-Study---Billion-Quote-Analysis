// ============================================================================
// PARTDB.Q - Partitioned Database for Billion+ Records
// Memory-efficient on-disk storage and retrieval
// ============================================================================

// Configuration
.partdb.config:(enlist`)!(enlist::);
.partdb.config[`hdbPath]:`$"./hdb";       // Default HDB location
.partdb.config[`symPath]:`$"./hdb/sym";   // Symbol enumeration file

// ---- DATABASE INITIALIZATION ----

// Initialize HDB directory structure
initHdb:{[path]
    .partdb.config[`hdbPath]:hsym `$path;
    .partdb.config[`symPath]:hsym `$path,"/sym";
    
    // Create directory if not exists
    system "mkdir -p ",path;
    
    // Initialize empty sym file if not exists
    if[not .partdb.config[`symPath] ~ key .partdb.config`symPath;
        .partdb.config[`symPath] set `symbol$()
    ];
    
    -1 "HDB initialized at: ",path;
};

// ---- PARTITIONING FUNCTIONS ----

// Save data as daily partition
savePartition:{[date;tableName;data]
    hdbPath:.partdb.config`hdbPath;
    
    // Enumerate symbols
    enumData:.Q.en[hdbPath;data];
    
    // Create partition path: hdb/2026.01.15/quote/
    partPath:` sv hdbPath,(`$string date),(`$tableName),`;
    
    // Save as splayed table
    partPath set enumData;
    
    -1 "Saved ",string[count data]," rows to ",string partPath;
};

// Save quotes with automatic date partitioning
saveQuotes:{[quotes]
    // Group by date
    byDate:quotes group quotes`date;
    
    // Save each date partition
    {[date;data]
        savePartition[date;`quote;data]
    } .' flip (key byDate;value byDate);
    
    // Reload HDB
    loadHdb[];
};

// ---- LOADING FUNCTIONS ----

// Load HDB
loadHdb:{[]
    hdbPath:.partdb.config`hdbPath;
    
    // Check if valid HDB
    if[not hdbPath ~ key hdbPath;
        -1 "HDB not found at: ",string hdbPath;
        :0b
    ];
    
    // Load
    system "l ",1 _ string hdbPath;
    
    -1 "HDB loaded. Tables: ",", " sv string tables[];
    1b
};

// ---- QUERY FUNCTIONS ----

// Query quotes for date range
queryDateRange:{[startDate;endDate]
    select from quote where date within (startDate;endDate)
};

// Query specific symbols
querySymbols:{[startDate;endDate;syms]
    select from quote where 
        date within (startDate;endDate),
        sym in syms
};

// Query with time filter (intraday)
queryIntraday:{[date;startTime;endTime;syms]
    select from quote where 
        date = date,
        time.time within (startTime;endTime),
        sym in syms
};

// Memory-efficient aggregation (uses map-reduce pattern)
aggregateByDate:{[aggFunc;startDate;endDate]
    dates:startDate + til 1 + endDate - startDate;
    
    // Process each date partition separately
    results:{[f;d]
        data:select from quote where date = d;
        if[0 = count data; :()];
        f data
    }[aggFunc] each dates;
    
    // Combine results
    raze results
};

// ---- PERFORMANCE UTILITIES ----

// Count records per partition
partitionCounts:{[]
    hdbPath:.partdb.config`hdbPath;
    dates:`date$"D"$string key hdbPath;
    dates:dates where not null dates;
    
    {[hdb;d]
        path:` sv hdb,(`$string d),`quote`;
        cnt:count get path;
        ([]date:enlist d;rows:enlist cnt)
    }[hdbPath] each dates
};

// Estimate memory for query
estimateMemory:{[startDate;endDate;syms]
    // Rough estimate: 100 bytes per row
    bytesPerRow:100;
    
    // Count matching rows (approximate)
    totalRows:count select from quote where 
        date within (startDate;endDate),
        sym in syms;
    
    memoryMb:(totalRows * bytesPerRow) % 1e6;
    
    -1 "Estimated rows: ",string totalRows;
    -1 "Estimated memory: ",string[memoryMb]," MB";
    
    memoryMb
};

// ---- MAINTENANCE FUNCTIONS ----

// Delete old partitions
deletePartition:{[date]
    hdbPath:.partdb.config`hdbPath;
    partPath:` sv hdbPath,`$string date;
    
    if[partPath ~ key partPath;
        // Remove directory
        system "rm -rf ",1 _ string partPath;
        -1 "Deleted partition: ",string date
    ];
};

// Compact sym file (remove unused symbols)
compactSymFile:{[]
    hdbPath:.partdb.config`hdbPath;
    // This is a complex operation, placeholder
    -1 "Sym file compaction not yet implemented";
};

// ---- BULK OPERATIONS ----

// Generate and save large dataset
generateAndSave:{[numQuotesPerDay;startDate;numDays]
    dates:startDate + til numDays;
    
    -1 "Generating ",string[numDays]," days of data...";
    -1 "Quotes per day: ",string numQuotesPerDay;
    
    {[n;d]
        -1 "Processing: ",string d;
        startTime:.z.p;
        
        // Generate quotes for this day
        quotes:genQuotes[n;d];
        
        // Save to partition
        savePartition[d;`quote;quotes];
        
        elapsed:(.z.p - startTime) % 1e9;
        -1 "  Generated and saved in ",string[elapsed]," seconds";
    }[numQuotesPerDay] each dates;
    
    // Reload HDB
    loadHdb[];
    
    -1 "\nGeneration complete. Total partitions: ",string count dates;
};

// ---- QUERY OPTIMIZATION ----

// Attribute-based query hints
// Add parted attribute for sym column
addPartedAttr:{[date]
    hdbPath:.partdb.config`hdbPath;
    symPath:` sv hdbPath,(`$string date),`quote,`sym;
    
    // Apply parted attribute
    @[symPath;`;`p#];
    
    -1 "Added parted attribute to sym column for ",string date;
};

// Add sorted attribute for time column
addSortedAttr:{[date]
    hdbPath:.partdb.config`hdbPath;
    timePath:` sv hdbPath,(`$string date),`quote,`time;
    
    // Apply sorted attribute
    @[timePath;`;`s#];
    
    -1 "Added sorted attribute to time column for ",string date;
};

-1 "Partitioned database module loaded.";
-1 "Initialize with: initHdb[\"/path/to/hdb\"]";
-1 "Generate data with: generateAndSave[quotesPerDay;startDate;numDays]";
