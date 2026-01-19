# KDB+ Market Microstructure Study

[![KDB+](https://img.shields.io/badge/KDB%2B-4.0-blue)](https://kx.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-grade KDB+/q framework for analyzing bid-ask spreads, market maker behavior, and microstructure dynamics on **billion+ quote datasets**.

## 🎯 Key Features

| Module | Description |
|--------|-------------|
| **Spread Analytics** | Quoted, effective, realized, time-weighted spreads |
| **Market Maker Analysis** | Quote frequency, inventory pressure, market share |
| **Price Impact** | Kyle's Lambda, Roll spread, Amihud illiquidity |
| **Scalable Storage** | Date-partitioned HDB for billion+ rows |
| **CSV Export** | Ready for Python/R visualization |

## 📊 Sample Output

```
>>> SPREAD STATISTICS BY SYMBOL:
sym  | avgSpread  avgSpreadBps quoteCount
-----| ----------------------------------
AAPL | 0.035      1.88         10,008     
MSFT | 0.035      0.85         10,072     
NVDA | 0.035      0.40         9,914      

>>> KYLE'S LAMBDA (PRICE IMPACT):
sym  | kyleLambda   
-----| -------------
AAPL | +0.0003      
NVDA | -0.0047      
```

## 🚀 Quick Start

```bash
# Clone the repo
git clone https://github.com/AIM-IT4/KDB-Market-Microstructure-Study---Billion-Quote-Analysis.git
cd KDB-Market-Microstructure-Study---Billion-Quote-Analysis

# Run analysis (requires KDB+ installed)
q run_analysis.q
```

## 📁 Project Structure

```
├── schema.q                  # Quote/trade table definitions
├── datagen.q                 # Realistic market data generator
├── spread_analytics.q        # Spread calculation engine
├── mm_behavior.q             # Market maker analysis
├── microstructure_advanced.q # Kyle's Lambda, Roll, Amihud, VPIN
├── partdb.q                  # Partitioned database for billions
├── reports.q                 # CSV export functions
├── main.q                    # Entry point with API
├── run_analysis.q            # Standalone analysis runner
└── output/                   # Generated CSV reports
```

## 🔬 Metrics Implemented

### Spread Analytics
- **Quoted Spread**: `ask - bid`
- **Relative Spread**: `(ask - bid) / mid` in basis points
- **TWAS**: Time-weighted average spread
- **Effective Spread**: `2 × |trade_price - mid|`
- **Realized Spread**: Market maker P&L proxy

### Advanced Microstructure
- **Kyle's Lambda**: Price impact coefficient (λ = Cov(ΔP, Vol) / Var(Vol))
- **Roll Spread**: Implied spread from trade autocorrelation
- **Amihud Illiquidity**: |return| / volume ratio
- **VPIN**: Volume-synchronized probability of informed trading

### Market Maker Analysis
- Quote frequency and time at NBBO
- Inventory pressure (bid/ask size imbalance)
- Quote-to-trade ratio (HFT indicator)
- Competitive dynamics and market share

## 📈 Billion Quote Workflow

```q
// Initialize partitioned database
\l partdb.q
initHdb["./hdb"]

// Generate 1 billion quotes (5 days × 200M/day)
generateAndSave[200000000;2026.01.01;5]

// Memory-efficient query
data:queryDateRange[2026.01.01;2026.01.05]

// Aggregated analysis
stats:aggregateByDate[spreadStatsBySym;2026.01.01;2026.01.05]
```

## 📋 Requirements

- KDB+ 4.0+ (64-bit recommended)
- 8GB+ RAM for 10M+ quote analysis
- SSD for partitioned database performance

## 📚 Academic References

- Kyle, A.S. (1985). "Continuous Auctions and Insider Trading"
- Roll, R. (1984). "A Simple Implicit Measure of the Effective Bid-Ask Spread"
- Amihud, Y. (2002). "Illiquidity and Stock Returns"

## 🎓 Interview Topics Covered

- Market microstructure theory
- High-frequency trading metrics
- KDB+ optimization (partitioning, attributes)
- Production-grade q programming

## 📄 License

MIT License - feel free to use for learning and projects.

## 👤 Author

Built for quantitative finance interviews and production analytics.
