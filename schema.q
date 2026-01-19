/ ============================================================================
/ SCHEMA.Q - Market Microstructure Study
/ Database schema definitions for billion+ quote analysis
/ ============================================================================

/ Quote table schema - optimized for massive datasets
/ Using flip for proper table creation
quote:flip `time`date`sym`bid`ask`bidSize`askSize`exchange`mmid`condition!
    (`timestamp$();`date$();`symbol$();`float$();`float$();`long$();`long$();`symbol$();`symbol$();`symbol$())

/ Trade table for effective spread calculation
trade:flip `time`date`sym`price`size`side`aggressor`mmid!
    (`timestamp$();`date$();`symbol$();`float$();`long$();`symbol$();`symbol$();`symbol$())

/ Market maker reference data
mmref:([mmid:`symbol$()] name:`symbol$(); mmtype:`symbol$(); tier:`int$())

/ Symbol reference data
symref:([sym:`symbol$()] name:`symbol$(); tickSize:`float$(); lotSize:`long$(); avgDailyVolume:`long$())

/ Initialize reference data
initRefData:{[]
    / Sample market makers
    `mmref upsert flip `mmid`name`mmtype`tier!(
        `CITADEL`VIRTU`JANE`TOWER`JUMP`SIG`IMC`OPTIVER`SUSQUE`GTS;
        `$("Citadel";"Virtu";"JaneStreet";"Tower";"Jump";"Susquehanna";"IMC";"Optiver";"Susq2";"GTS");
        `HFT`HFT`HFT`HFT`HFT`INST`HFT`HFT`INST`HFT;
        1 1 1 1 1 2 1 1 2 2
    );
    
    / Sample symbols
    `symref upsert flip `sym`name`tickSize`lotSize`avgDailyVolume!(
        `AAPL`MSFT`GOOGL`AMZN`META`NVDA`TSLA`JPM`BAC`GS;
        `$("Apple";"Microsoft";"Alphabet";"Amazon";"Meta";"NVIDIA";"Tesla";"JPMorgan";"BankAmerica";"Goldman");
        10#0.01;
        10#100;
        100000000 80000000 50000000 60000000 40000000 70000000 120000000 30000000 50000000 20000000
    );
    
    -1 "Reference data initialized: ",string[count mmref]," market makers, ",string[count symref]," symbols";
 }

/ Schema validation utility
validateQuote:{[q]
    required:`time`date`sym`bid`ask`bidSize`askSize`exchange`mmid`condition;
    missing:required except cols q;
    if[count missing; '"Missing columns: ",", " sv string missing];
    / Validate bid < ask
    if[any q[`bid] >= q[`ask]; '"Invalid quotes: bid >= ask detected"];
    / Validate positive sizes
    if[any (q[`bidSize] <= 0) or q[`askSize] <= 0; '"Invalid sizes detected"];
    1b
 }

-1 "Schema loaded. Run initRefData[] to initialize reference data.";
