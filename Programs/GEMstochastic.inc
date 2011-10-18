* GEMstochastic.inc

* A GEM input file to contain the stuff related to scenarios that will need to come from a yet to be created GUI in emi.

* 'h' denotes hydro
*  - timing with average hydrology 
*  - reoptimisation with 1932 hydrology 
*  - dispatch with sequential hydrology - 76 times 

Sets
  experiments  'A collection of experiments, each potentially containing timing, re-optimisation and dispatch steps' /
    singleExp /

  scenarios    'The various individual stochastic scenarios, or futures, or states of uncertainty' /
    avgHydro /
*   avgHydro,  dryHydro, h1990*h2003 /
*   avgHydro,  dryHydro, h1932*h2007 /
*   h1992, h1998, h2000, h2002, h2003 /
*   5hAvg, 5h1932*5h2007 /

  scenarioSets 'Sets of scenarios to be used in the same solve' /
    averageHydro  /
*   averageHydro, dryYrHydro, beginSeq1990*beginSeq2003 /
*   averageHydro, dryYrHydro, beginSeq1932*beginSeq2007 /
*   stochastic /
*   standard5h,   standard1932*standard2007 /

* Mapping sets:
  mapScenarios(scenarioSets,scenarios) 'Map each scenario to a scenarioSet (i.e. 1 or more scenarios make up an scenario set)' /
    #scenarioSets:#scenarios  /
*   stochastic  .(h1992,h1998,h2000,h2002,h2003) /

  timingSolves(experiments,scenarioSets) 'Identify the scenarioSet to be used for the timing step of each experiment' /
    singleExp   . averageHydro  /
*   singleExp   . stochastic  /

* reoptSolves(experiments,scenarioSets) 'Identify the scenarioSet to be used for the re-optimisation step of each experiment' /
*   singleExp   . dryYrHydro   /

* dispatchSolves(experiments,scenarioSets) 'Identify the scenarioSet to be used for the dispatch step of each experiment' /
*   singleExp   .(beginSeq1990*beginSeq2003) /
*   singleExp   .(beginSeq1932*beginSeq2007) /

  mapSC_hY(scenarios,hY) 'Map historical hydro output years to scenarios (Note that the average is computed if more than one hydro year is specified)' /
    avgHydro    .(1932*2007) /

*   avgHydro    .(1990*2003)
*   dryHydro    . 1932
*   h1990.1990, h1991.1991, h1992.1992, h1993.1993, h1994.1994, h1995.1995, h1996.1996, h1997.1997, h1998.1998, h1999.1999
*   h2000.2000, h2001.2001, h2002.2002, h2003.2003 /

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

*   5h2004.2004, 5h2005.2005, 5h2006.2006, 5h2007.2007  /

*                             5h1932.1932, 5h1933.1933, 5h1934.1934, 5h1935.1935, 5h1936.1936, 5h1937.1937, 5h1938.1938, 5h1939.1939
*   5h1940.1940, 5h1941.1941, 5h1942.1942, 5h1943.1943, 5h1944.1944, 5h1945.1945, 5h1946.1946, 5h1947.1947, 5h1948.1948, 5h1949.1949
*   5h1950.1950, 5h1951.1951, 5h1952.1952, 5h1953.1953, 5h1954.1954, 5h1955.1955, 5h1956.1956, 5h1957.1957, 5h1958.1958, 5h1959.1959
*   5h1960.1960, 5h1961.1961, 5h1962.1962, 5h1963.1963, 5h1964.1964, 5h1965.1965, 5h1966.1966, 5h1967.1967, 5h1968.1968, 5h1969.1969
*   5h1970.1970, 5h1971.1971, 5h1972.1972, 5h1973.1973, 5h1974.1974, 5h1975.1975, 5h1976.1976, 5h1977.1977, 5h1978.1978, 5h1979.1979
*   5h1980.1980, 5h1981.1981, 5h1982.1982, 5h1983.1983, 5h1984.1984, 5h1985.1985, 5h1986.1986, 5h1987.1987, 5h1988.1988, 5h1989.1989
*   5h1990.1990, 5h1991.1991, 5h1992.1992, 5h1993.1993, 5h1994.1994, 5h1995.1995, 5h1996.1996, 5h1997.1997, 5h1998.1998, 5h1999.1999
*   5h2000.2000, 5h2001.2001, 5h2002.2002, 5h2003.2003, 5h2004.2004, 5h2005.2005, 5h2006.2006, 5h2007.2007  /

  mapSC_hydroSeqTypes(scenarios,hydroSeqTypes) 'Map the way hydrology sequences are developed (same or sequential) for each scenario' /
    avgHydro    . Same  /
*   avgHydro    . Same
*   dryHydro    . Same
*  (h1990*h2003).Sequential  /
*  (h1932*h2007).Sequential  /
*  (h1992,h1998,h2000,h2002,h2003).same /
*  (5h2004*5h2007).Sequential  /
*  (5h1932*5h2007).Sequential  /
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
