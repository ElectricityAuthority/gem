* GEMstochastic.inc

* A GEM input file to contain the stuff related to scenarios that will need to come from a yet to be created GUI in emi.

* 'h' denotes hydro
*  - timing with average hydrology 
*  - reoptimisation with 1932 hydrology 
*  - dispatch with sequential hydrology - 76 times 

Sets
  experiments  'A collection of experiments, each potentially containing timing, re-optimisation and dispatch steps' /
    singleExp   /

  scenarios    'The various individual stochastic scenarios, or futures, or states of uncertainty' /
    avgHydro /
*   avgHydro,  dryHydro, h1932*h2007 /
*   h1992, h1998, h2000, h2002, h2003 /

  scenarioSets 'Sets of scenarios to be used in the same solve' /
    averageHydro  /
*   averageHydro, dryYrHydro, beginSeq1932*beginSeq2007 /
*   stochastic /

* Mapping sets:
  mapScenarios(scenarioSets,scenarios) 'Map each scenario to a scenarioSet (i.e. 1 or more scenarios make up an scenario set)' /
    #scenarioSets:#scenarios  /
*   stochastic  .(h1992,h1998,h2000,h2002,h2003) /

  timingSolves(experiments,scenarioSets) 'Identify the scenarioSet to be used for the timing step of each experiment' /
    singleExp   . averageHydro /
*   singleExp   . stochastic  /

* reoptSolves(experiments,scenarioSets) 'Identify the scenarioSet to be used for the re-optimisation step of each experiment' /
*   singleExp   . dryYrHydro   /

* dispatchSolves(experiments,scenarioSets) 'Identify the scenarioSet to be used for the dispatch step of each experiment' /
*   singleExp   .(beginSeq1932*beginSeq2007) /

  mapSC_hY(scenarios,hY) 'Map historical hydro output years to scenarios (Note that the average is computed if more than one hydro year is specified)' /
    avgHydro    .(1932*2007) /

*   avgHydro    .(1932*2007)
*   dryHydro    . 1932
*                           h1932.1932, h1933.1933, h1934.1934, h1935.1935, h1936.1936, h1937.1937, h1938.1938, h1939.1939
*   h1940.1940, h1941.1941, h1942.1942, h1943.1943, h1944.1944, h1945.1945, h1946.1946, h1947.1947, h1948.1948, h1949.1949
*   h1950.1950, h1951.1951, h1952.1952, h1953.1953, h1954.1954, h1955.1955, h1956.1956, h1957.1957, h1958.1958, h1959.1959
*   h1960.1960, h1961.1961, h1962.1962, h1963.1963, h1964.1964, h1965.1965, h1966.1966, h1967.1967, h1968.1968, h1969.1969
*   h1970.1970, h1971.1971, h1972.1972, h1973.1973, h1974.1974, h1975.1975, h1976.1976, h1977.1977, h1978.1978, h1979.1979
*   h1980.1980, h1981.1981, h1982.1982, h1983.1983, h1984.1984, h1985.1985, h1986.1986, h1987.1987, h1988.1988, h1989.1989
*   h1990.1990, h1991.1991, h1992.1992, h1993.1993, h1994.1994, h1995.1995, h1996.1996, h1997.1997, h1998.1998, h1999.1999
*   h2000.2000, h2001.2001, h2002.2002, h2003.2003, h2004.2004, h2005.2005, h2006.2006, h2007.2007  /

*   h1992.1992, h1998.1998, h2000.2000, h2002.2002, h2003.2003 /

  mapSC_hydroSeqTypes(scenarios,hydroSeqTypes) 'Map the way hydrology sequences are developed (same or sequential) for each scenario' /
    avgHydro    . Same  /

*   avgHydro    . Same
*   dryHydro    . Same
*  (h1932*h2007).Sequential  /

*  (h1992,h1998,h2000,h2002,h2003).same /
  ;

Parameters
  scenarioPeakLoadFactor(scenarios)            'Scenario-specific scaling factor for peak load data'
  scenarioCO2TaxFactor(scenarios)              'Scenario-specific scaling factor for CO2 tax data'
  scenarioFuelCostFactor(scenarios)            'Scenario-specific scaling factor for fuel cost data'
  scenarioNRGFactor(scenarios)                 'Scenario-specific scaling factor for energy demand data'
  weightScenariosBySet(scenarioSets,scenarios) 'Assign weights to the scenarios comprising each set of scenarios' ;

scenarioPeakLoadFactor(scenarios) = 1 ;
scenarioCO2TaxFactor(scenarios)   = 1 ;
scenarioFuelCostFactor(scenarios) = 1 ;
scenarioNRGFactor(scenarios)      = 1 ;

weightScenariosBySet(scenarioSets,scenarios)$mapScenarios(scenarioSets,scenarios) = 1 ;

*Table weightScenariosBySet(scenarioSets,scenarios) 'Assign weights to the scenarios comprising each set of scenarios'
*                h1992 h1998 h2000 h2002 h2003
*  stochastic     .08   .08   .28   .28   .28   ;


* Collect the scenarioSet-to-experiments mappings by step into a single set (allSolves).
Set allSolves(experiments,steps,scenarioSets) 'Scenario sets by experiment and step';
allSolves(experiments,'timing',scenarioSets)    = timingSolves(experiments,scenarioSets) ;
*allSolves(experiments,'reopt',scenarioSets)    = reoptSolves(experiments,scenarioSets) ;
*allSolves(experiments,'dispatch',scenarioSets) = dispatchSolves(experiments,scenarioSets) ;

Display allSolves ;




* End of file.
