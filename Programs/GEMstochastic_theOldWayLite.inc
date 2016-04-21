* C:\a\GEM\Programs\GEMstochastic.inc

* A GEM input file to contain the settings related to scenarios that come from a GUI in emi.

Sets
  scenarios    "The various individual stochastic scenarios, or futures, or states of uncertainty" /
    avgHydro
    dryHydro
    h1932
    h1933
    h1934
    h2004
    h2005
    h2006
    h2007  /

  defaultScenario(scenarios) "Identify a default scenario to use when reporting input data summaries. Applies only to input data defined over scenarios (see GEMdata)" /
    avgHydro /

  scenarioSets "A coherent collection of scenarios to be simultaneously solved over" /
    averageHydro
    dryYrHydro
    beginSeq1932
    beginSeq1933
    beginSeq1934
    beginSeq2004
    beginSeq2005
    beginSeq2006
    beginSeq2007  /

  experiments  "A collection of scenarioSets to be solved for in the current runVersion. Experiments must get mapped to steps - timing, re-optimisation and dispatch" /
    oldWayLite  /

* Mapping sets:
  mapScenarios(scenarioSets,scenarios) "Map each scenario to a scenarioSet (i.e. 1 or more scenarios make up an scenario set)" /
    averageHydro.avgHydro
    dryYrHydro.dryHydro
    beginSeq1932.h1932
    beginSeq1933.h1933
    beginSeq1934.h1934
    beginSeq2004.h2004
    beginSeq2005.h2005
    beginSeq2006.h2006
    beginSeq2007.h2007  /

  timingSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the timing step of each experiment" /
    oldWayLite.averageHydro  /

  reoptSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the re-optimisation step of each experiment" /
    oldWayLite.dryYrHydro  /

  dispatchSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the dispatch step of each experiment" /
    oldWayLite.beginSeq1932
    oldWayLite.beginSeq1933
    oldWayLite.beginSeq1934
    oldWayLite.beginSeq2004
    oldWayLite.beginSeq2005
    oldWayLite.beginSeq2006
    oldWayLite.beginSeq2007  /

  mapSC_hY(scenarios,hY) "Map historical hydro years to scenarios (compute the average if more than one historical year is specified)" /
    avgHydro.1932
    avgHydro.1933
    avgHydro.1934
    avgHydro.1935
    avgHydro.1936
    avgHydro.1937
    avgHydro.1938
    avgHydro.1939
    avgHydro.1940
    avgHydro.1941
    avgHydro.1942
    avgHydro.1943
    avgHydro.1944
    avgHydro.1945
    avgHydro.1946
    avgHydro.1947
    avgHydro.1948
    avgHydro.1949
    avgHydro.1950
    avgHydro.1951
    avgHydro.1952
    avgHydro.1953
    avgHydro.1954
    avgHydro.1955
    avgHydro.1956
    avgHydro.1957
    avgHydro.1958
    avgHydro.1959
    avgHydro.1960
    avgHydro.1961
    avgHydro.1962
    avgHydro.1963
    avgHydro.1964
    avgHydro.1965
    avgHydro.1966
    avgHydro.1967
    avgHydro.1968
    avgHydro.1969
    avgHydro.1970
    avgHydro.1971
    avgHydro.1972
    avgHydro.1973
    avgHydro.1974
    avgHydro.1975
    avgHydro.1976
    avgHydro.1977
    avgHydro.1978
    avgHydro.1979
    avgHydro.1980
    avgHydro.1981
    avgHydro.1982
    avgHydro.1983
    avgHydro.1984
    avgHydro.1985
    avgHydro.1986
    avgHydro.1987
    avgHydro.1988
    avgHydro.1989
    avgHydro.1990
    avgHydro.1991
    avgHydro.1992
    avgHydro.1993
    avgHydro.1994
    avgHydro.1995
    avgHydro.1996
    avgHydro.1997
    avgHydro.1998
    avgHydro.1999
    avgHydro.2000
    avgHydro.2001
    avgHydro.2002
    avgHydro.2003
    avgHydro.2004
    avgHydro.2005
    avgHydro.2006
    avgHydro.2007
    dryHydro.1932
    h1932.1932
    h1933.1933
    h1934.1934
    h2004.2004
    h2005.2005
    h2006.2006
    h2007.2007  /

  mapSC_hydroSeqTypes(scenarios,hydroSeqTypes) "Map the hydrology sequence types (same or sequential) to scenarios" /
    avgHydro.same
    dryHydro.same
    h1932.sequential
    h1933.sequential
    h1934.sequential
    h2004.sequential
    h2005.sequential
    h2006.sequential
    h2007.sequential  / ;

Parameter scenarioPeakLoadFactor(scenarios) "Scenario-specific scaling factor for peak load data" /
  avgHydro 1
  dryHydro 1
  h1932 1
  h1933 1
  h1934 1
  h2004 1
  h2005 1
  h2006 1
  h2007 1  / ;

Parameter scenarioCO2TaxFactor(scenarios) "Scenario-specific scaling factor for CO2 tax data" /
  avgHydro 1
  dryHydro 1
  h1932 1
  h1933 1
  h1934 1
  h2004 1
  h2005 1
  h2006 1
  h2007 1  / ;

Parameter scenarioFuelCostFactor(scenarios) "Scenario-specific scaling factor for fuel cost data" /
  avgHydro 1
  dryHydro 1
  h1932 1
  h1933 1
  h1934 1
  h2004 1
  h2005 1
  h2006 1
  h2007 1  / ;

Parameter scenarioNRGFactor(scenarios) "Scenario-specific scaling factor for energy demand data" /
  avgHydro 1
  dryHydro 1
  h1932 1
  h1933 1
  h1934 1
  h2004 1
  h2005 1
  h2006 1
  h2007 1  / ;

Parameter weightScenariosBySet(scenarioSets,scenarios) "Assign weights to the scenarios comprising each set of scenarios" /
    averageHydro.avgHydro 1
    dryYrHydro.dryHydro 1
    beginSeq1932.h1932 1
    beginSeq1933.h1933 1
    beginSeq1934.h1934 1
    beginSeq2004.h2004 1
    beginSeq2005.h2005 1
    beginSeq2006.h2006 1
    beginSeq2007.h2007 1  / ;

* Collect the scenarioSet-to-experiments mappings by step into a single set (allSolves).
Set allSolves(experiments,steps,scenarioSets) "Scenario sets by experiment and step";
allSolves(experiments,'timing',scenarioSets)   = timingSolves(experiments,scenarioSets) ;
allSolves(experiments,'reopt',scenarioSets)    = reoptSolves(experiments,scenarioSets) ;
allSolves(experiments,'dispatch',scenarioSets) = dispatchSolves(experiments,scenarioSets) ;

Display allSolves ;



* End of file.
