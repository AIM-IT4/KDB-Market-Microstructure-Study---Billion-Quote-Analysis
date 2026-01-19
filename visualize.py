"""
KDB+ Market Microstructure Study - Visualization Script
Generates plots from the analysis CSV outputs
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os

# Set style
plt.style.use('seaborn-v0_8-darkgrid')
plt.rcParams['figure.figsize'] = (10, 6)
plt.rcParams['font.size'] = 12

# Create plots directory
os.makedirs('plots', exist_ok=True)

# 1. Spread Statistics by Symbol
print("Generating spread statistics plot...")
spread_df = pd.read_csv('output/spread_stats.csv')

fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Bar chart of average spread in bps
colors = plt.cm.viridis(np.linspace(0.2, 0.8, len(spread_df)))
bars = axes[0].bar(spread_df['sym'], spread_df['avgSpreadBps'], color=colors, edgecolor='black')
axes[0].set_xlabel('Symbol', fontsize=12)
axes[0].set_ylabel('Average Spread (Basis Points)', fontsize=12)
axes[0].set_title('Bid-Ask Spread by Symbol (10M Quotes)', fontsize=14, fontweight='bold')
axes[0].tick_params(axis='x', rotation=45)

# Add value labels on bars
for bar, val in zip(bars, spread_df['avgSpreadBps']):
    axes[0].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1, 
                f'{val:.2f}', ha='center', va='bottom', fontsize=9)

# Quote count by symbol
axes[1].bar(spread_df['sym'], spread_df['quoteCount']/1e6, color=colors, edgecolor='black')
axes[1].set_xlabel('Symbol', fontsize=12)
axes[1].set_ylabel('Quote Count (Millions)', fontsize=12)
axes[1].set_title('Quote Distribution by Symbol', fontsize=14, fontweight='bold')
axes[1].tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('plots/spread_analysis.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: plots/spread_analysis.png")

# 2. Market Maker Market Share
print("Generating market maker analysis plot...")
mm_df = pd.read_csv('output/mm_market_share.csv')

fig, ax = plt.subplots(figsize=(10, 8))
colors = plt.cm.Set3(np.linspace(0, 1, len(mm_df)))
wedges, texts, autotexts = ax.pie(mm_df['pct'], labels=mm_df['mmid'], autopct='%1.1f%%',
                                   colors=colors, explode=[0.02]*len(mm_df),
                                   shadow=True, startangle=90)
ax.set_title('Market Maker Market Share\n(10M Quotes)', fontsize=14, fontweight='bold')
plt.setp(autotexts, size=10, weight='bold')

plt.tight_layout()
plt.savefig('plots/mm_market_share.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: plots/mm_market_share.png")

# 3. Exchange Breakdown
print("Generating exchange breakdown plot...")
ex_df = pd.read_csv('output/exchange_breakdown.csv')

fig, ax = plt.subplots(figsize=(10, 6))
colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']
bars = ax.barh(ex_df['exchange'], ex_df['pct'], color=colors, edgecolor='black')
ax.set_xlabel('Market Share (%)', fontsize=12)
ax.set_ylabel('Exchange', fontsize=12)
ax.set_title('Quote Distribution by Exchange', fontsize=14, fontweight='bold')

# Add value labels
for bar, val in zip(bars, ex_df['pct']):
    ax.text(val + 0.1, bar.get_y() + bar.get_height()/2, 
           f'{val:.2f}%', va='center', fontsize=10)

plt.tight_layout()
plt.savefig('plots/exchange_breakdown.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: plots/exchange_breakdown.png")

# 4. Kyle's Lambda (Price Impact)
print("Generating Kyle's Lambda plot...")
kyle_df = pd.read_csv('output/kyle_lambda.csv')

fig, ax = plt.subplots(figsize=(10, 6))
colors = ['#2ecc71' if x > 0 else '#e74c3c' for x in kyle_df['kyleLambda']]
bars = ax.bar(kyle_df['sym'], kyle_df['kyleLambda'] * 1e5, color=colors, edgecolor='black')
ax.axhline(y=0, color='black', linestyle='-', linewidth=0.5)
ax.set_xlabel('Symbol', fontsize=12)
ax.set_ylabel('Kyle\'s Lambda (×10⁻⁵)', fontsize=12)
ax.set_title('Price Impact Coefficient by Symbol\n(Higher = More Price Impact per Trade)', fontsize=14, fontweight='bold')
ax.tick_params(axis='x', rotation=45)

# Add interpretation annotation
ax.annotate('Positive λ: Prices move WITH order flow\n(Information in trades)',
           xy=(0.02, 0.98), xycoords='axes fraction', fontsize=9,
           verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.5))
ax.annotate('Negative λ: Prices mean-revert\n(Noise trading dominates)',
           xy=(0.02, 0.02), xycoords='axes fraction', fontsize=9,
           verticalalignment='bottom', bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.5))

plt.tight_layout()
plt.savefig('plots/kyle_lambda.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: plots/kyle_lambda.png")

# 5. Market Maker Inventory Pressure
print("Generating inventory pressure plot...")
inv_df = pd.read_csv('output/mm_inventory_pressure.csv')

fig, ax = plt.subplots(figsize=(10, 6))
colors = ['#3498db' if x > 0 else '#e67e22' for x in inv_df['avgImbalance']]
bars = ax.bar(inv_df['mmid'], inv_df['avgImbalance'] * 100, color=colors, edgecolor='black')
ax.axhline(y=0, color='black', linestyle='-', linewidth=0.5)
ax.set_xlabel('Market Maker', fontsize=12)
ax.set_ylabel('Average Size Imbalance (%)', fontsize=12)
ax.set_title('Market Maker Inventory Pressure\n(Positive = Long Bias, Negative = Short Bias)', fontsize=14, fontweight='bold')
ax.tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('plots/inventory_pressure.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: plots/inventory_pressure.png")

# 6. Intraday Profile (sample for top 3 symbols)
print("Generating intraday profile plot...")
intraday_df = pd.read_csv('output/intraday_profile.csv')

# Get top 3 symbols by volume
top_syms = ['AAPL', 'MSFT', 'NVDA']

fig, axes = plt.subplots(2, 1, figsize=(14, 10))

for sym in top_syms:
    sym_data = intraday_df[intraday_df['sym'] == sym].head(100)  # First 100 5-min buckets
    axes[0].plot(range(len(sym_data)), sym_data['avgSpreadBps'], label=sym, linewidth=2)

axes[0].set_xlabel('Time Bucket (5-min intervals)', fontsize=12)
axes[0].set_ylabel('Average Spread (bps)', fontsize=12)
axes[0].set_title('Intraday Spread Profile', fontsize=14, fontweight='bold')
axes[0].legend()
axes[0].grid(True, alpha=0.3)

for sym in top_syms:
    sym_data = intraday_df[intraday_df['sym'] == sym].head(100)
    axes[1].plot(range(len(sym_data)), sym_data['quoteCount'], label=sym, linewidth=2)

axes[1].set_xlabel('Time Bucket (5-min intervals)', fontsize=12)
axes[1].set_ylabel('Quote Count', fontsize=12)
axes[1].set_title('Intraday Quote Activity (U-Shaped Pattern Expected)', fontsize=14, fontweight='bold')
axes[1].legend()
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('plots/intraday_profile.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: plots/intraday_profile.png")

print("\n✅ All plots generated successfully!")
print("Plots saved in: ./plots/")
