/ ============================================================================
/ MICROSTRUCTURE_ADVANCED.Q - Advanced Microstructure Metrics
/ Kyle's Lambda, Roll Spread, Amihud Illiquidity
/ ============================================================================

/ Kyle's Lambda - Price Impact Coefficient
/ λ = Cov(ΔP, SignedVolume) / Var(SignedVolume)
kyleLambda:{[trades] dp:deltas trades`price; signedVol:trades[`size] * ?[trades[`side]=`B;1;-1]; lambda:(cov[dp;signedVol]) % var signedVol; `lambda`tstat`nobs!(lambda; lambda % dev[dp] * sqrt count dp; count trades)}

/ Kyle's Lambda by symbol
kyleLambdaBySym:{[trades] select kyleLambda:(kyleLambda ([]price:price;size:size;side:side))`lambda by sym from trades}

/ Roll Spread: S = 2 * sqrt(-Cov(Δp_t, Δp_{t-1}))
rollSpread:{[prices] dp:deltas prices; cov_lag:cov[dp;prev dp]; $[cov_lag >= 0;0n;2 * sqrt neg cov_lag]}

/ Roll spread by symbol
rollSpreadBySym:{[trades] select rollSpread:rollSpread price by sym from trades}

/ Amihud illiquidity
amihud:{[trades] daily:select openPrice:first price, closePrice:last price, volume:sum size by date, sym from trades; update ret:abs (closePrice - openPrice) % openPrice from daily; update illiq:ret % volume from daily}

/ Average Amihud by symbol
avgAmihudBySym:{[trades] a:amihud trades; select avgIlliq:avg illiq, stdIlliq:dev illiq by sym from a}

/ Information share (variance by exchange)
informationShare:{[quotes] q2:update midPrice:0.5*bid+ask from quotes; q3:update priceChange:deltas midPrice by sym from q2; varByEx:select priceVar:var priceChange by exchange from q3; totalVar:sum varByEx`priceVar; update infoShare:100 * priceVar % totalVar from varByEx}

/ VPIN simplified
vpin:{[trades;bucketSize] t2:update cumVol:sums size by sym from trades; t3:update bucket:cumVol div bucketSize from t2; t4:update isBuy:side=`B from t3; imbalance:select buyVol:sum size where isBuy, sellVol:sum size where not isBuy, totalVol:sum size by sym, bucket from t4; update vpin:abs[buyVol - sellVol] % totalVol from imbalance}

/ Realized volatility 5-min
realizedVol5min:{[quotes] samples:select mid:last 0.5*bid+ask by sym, 5 xbar time.minute from quotes; s2:update ret:deltas log mid by sym from samples; select realizedVol:sqrt[252*78] * dev ret by sym from s2}

/ Composite liquidity score
liquidityScore:{[quotes;trades] avgSpreadBps:avg 10000 * (quotes[`ask]-quotes[`bid]) % 0.5*quotes[`ask]+quotes`bid; spreadScore:0|100 - avgSpreadBps; avgDepth:avg 0.5 * quotes[`bidSize] + quotes`askSize; depthScore:100&avgDepth % 1000; impactScore:$[count trades;0|100 - 10000 * abs (kyleLambda trades)`lambda;50]; score:0.4*spreadScore + 0.3*depthScore + 0.3*impactScore; `spreadScore`depthScore`impactScore`totalScore!(spreadScore;depthScore;impactScore;score)}

-1 "Advanced microstructure metrics loaded.";
-1 "Key functions: kyleLambda, rollSpread, amihud, vpin, liquidityScore";
