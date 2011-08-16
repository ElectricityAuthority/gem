* GEMstochastic.gms (Standard)

* A temporary GEM input file to contain the stuff related to outcomes that will need to come from
* a yet to be created GUI in Oasis.

* 'pi' denotes perfect information, i.e. no uncertainty dealt with in this configuration.
* 'Standard' implies this version of GEMstochastic enables the following solves to occur:
*  - timing with average hydrology 
*  - reoptimisation with 1932 hydrology 
*  - dispatch with sequential hydrology - 76 times 

* Sets:
Sets
  experiments           'A collection of experiments, each potentially containing timing, re-optimisation and dispatch steps' /
                         standardExp /

  outcomes              'The various individual stochastic outcomes, or futures, or states of uncertainty' /
*                        piAvg,  piDry, pi1932*pi2007 /
                         piAvg,  piDry, pi2004*pi2007 /

  outcomeSets           'Create sets of outcomes to be used in a solve' /
*                        standardAvg, standardDry, standard1932*standard2007 /
                         standardAvg, standardDry, standard2004*standard2007 /

* Mapping sets:
  mapOutcomes(outcomeSets,outcomes)       'Map the individual outcomes to an outcome set (i.e. 1 or more outcomes make up an outcome set)' /
    #outcomeSets:#outcomes  /

  timingSolves(experiments,outcomeSets)   'Which outcome sets are used for the timing step of each experiment?' /
    standardExp    .  standardAvg   /

  reoptSolves(experiments,outcomeSets)    'Which outcome sets are used for the reoptimisation step of each experiment?' /
    standardExp    .  standardDry   /

  dispatchSolves(experiments,outcomeSets) 'Which outcome sets are used for the dispatch step of each experiment?' /
*   standardExp    .(standard1932*standard2007) /
    standardExp    .(standard2004*standard2007) /

  mapOC_hY(outcomes,hY) 'Map historical hydro output years to outcomes (compute the average if more than one hydro year is specified)' /
    piAvg          . (1932*2007)
    piDry          .  1932
    pi2004.2004, pi2005.2005, pi2006.2006, pi2007.2007  /
*   pi1932.1932, pi1933.1933, pi1934.1934, pi1935.1935, pi1936.1936, pi1937.1937, pi1938.1938, pi1939.1939, pi1940.1940
*   pi1941.1941, pi1942.1942, pi1943.1943, pi1944.1944, pi1945.1945, pi1946.1946, pi1947.1947, pi1948.1948, pi1949.1949, pi1950.1950
*   pi1951.1951, pi1952.1952, pi1953.1953, pi1954.1954, pi1955.1955, pi1956.1956, pi1957.1957, pi1958.1958, pi1959.1959, pi1960.1960
*   pi1961.1961, pi1962.1962, pi1963.1963, pi1964.1964, pi1965.1965, pi1966.1966, pi1967.1967, pi1968.1968, pi1969.1969, pi1970.1970
*   pi1971.1971, pi1972.1972, pi1973.1973, pi1974.1974, pi1975.1975, pi1976.1976, pi1977.1977, pi1978.1978, pi1979.1979, pi1980.1980
*   pi1981.1981, pi1982.1982, pi1983.1983, pi1984.1984, pi1985.1985, pi1986.1986, pi1987.1987, pi1988.1988, pi1989.1989, pi1990.1990
*   pi1991.1991, pi1992.1992, pi1993.1993, pi1994.1994, pi1995.1995, pi1996.1996, pi1997.1997, pi1998.1998, pi1999.1999, pi2000.2000
*   pi2001.2001, pi2002.2002, pi2003.2003, pi2004.2004, pi2005.2005, pi2006.2006, pi2007.2007  /

  mapOC_hydroSeqTypes(outcomes,hydroSeqTypes) 'Map the way hydrology sequences are developed (same or sequential) to outcomes' /
    piAvg    . Same
    piDry    . Same
*  (pi1932*pi2007).Sequential  /
   (pi2004*pi2007).Sequential  /
  ;

* Parameters:
Parameters
*  outcomePeakLoadFactor(outcomes)  'Outcome-specific scaling factor for peak load data'     / perfInfAvg 1.0 /
*  outcomeCO2TaxFactor(outcomes)    'Outcome-specific scaling factor for CO2 tax data'       / perfInfAvg 1.0 /
*  outcomeFuelCostFactor(outcomes)  'Outcome-specific scaling factor for fuel cost data'     / perfInfAvg 1.0 /
*  outcomeNRGFactor(outcomes)       'Outcome-specific scaling factor for energy demand data' / perfInfAvg 1.0 /
  penaltyLostPeak                  'Penalty for failing to meet peak load constraints'      / 9998 /
  outcomePeakLoadFactor(outcomes)  'Outcome-specific scaling factor for peak load data'
  outcomeCO2TaxFactor(outcomes)    'Outcome-specific scaling factor for CO2 tax data'
  outcomeFuelCostFactor(outcomes)  'Outcome-specific scaling factor for fuel cost data'
  outcomeNRGFactor(outcomes)       'Outcome-specific scaling factor for energy demand data'
  ;

  outcomePeakLoadFactor(outcomes) = 1 ;
  outcomeCO2TaxFactor(outcomes)   = 1 ;
  outcomeFuelCostFactor(outcomes) = 1 ;
  outcomeNRGFactor(outcomes)      = 1 ;

*Table weightOutcomesBySet(outcomeSets,outcomes) 'Assign weights to the outcomes comprising each set of outcomes'
*                piAvg   piDry
*  standardAvg     1       0
*  standardDry     0       1   ;

Parameter weightOutcomesBySet(outcomeSets,outcomes) 'Assign weights to the outcomes comprising each set of outcomes' ;
weightOutcomesBySet(outcomeSets,outcomes)$mapOutcomes(outcomeSets,outcomes) = 1 ;


* Collect the outcomeSet-to-experiments mappings by step into a single set (allSolves).
Set allSolves(experiments,steps,outcomeSets) 'Outcome sets by experiment and step';
allSolves(experiments,'timing',outcomeSets)   = timingSolves(experiments,outcomeSets) ;
allSolves(experiments,'reopt',outcomeSets)    = reoptSolves(experiments,outcomeSets) ;
allSolves(experiments,'dispatch',outcomeSets) = dispatchSolves(experiments,outcomeSets) ;

Display allSolves ;

Set reportingOutcome(outcomes) 'Select a single outcome for reporting input summary data' / piAvg / ;




* End of file.
