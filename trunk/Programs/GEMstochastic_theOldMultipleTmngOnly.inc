* C:\a\GEM\Programs\GEMstochastic.inc

* A GEM input file to contain the settings related to scenarios that come from a GUI in emi.

Sets
  scenarios    "The various individual stochastic scenarios, or futures, or states of uncertainty" /
    h2003
    h2002
    h2000
    h1998
    h1992  /

  defaultScenario(scenarios) "Identify a default scenario to use when reporting input data summaries. Applies only to input data defined over scenarios (see GEMdata)" /
    h2003 /

  scenarioSets "A coherent collection of scenarios to be simultaneously solved over" /
    stochastic  /

  experiments  "A collection of scenarioSets to be solved for in the current runVersion. Experiments must get mapped to steps - timing, re-optimisation and dispatch" /
    multipleHydro  /

* Mapping sets:
  mapScenarios(scenarioSets,scenarios) "Map each scenario to a scenarioSet (i.e. 1 or more scenarios make up an scenario set)" /
    stochastic.h1992
    stochastic.h1998
    stochastic.h2000
    stochastic.h2002
    stochastic.h2003  /

  timingSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the timing step of each experiment" /
    multipleHydro.stochastic  /

* reoptSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the re-optimisation step of each experiment" / /

* dispatchSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the dispatch step of each experiment" / /

  mapSC_hY(scenarios,hY) "Map historical hydro years to scenarios (compute the average if more than one historical year is specified)" /
    h2003.2003
    h2002.2002
    h2000.2000
    h1998.1998
    h1992.1992  /

  mapSC_hydroSeqTypes(scenarios,hydroSeqTypes) "Map the hydrology sequence types (same or sequential) to scenarios" /
    h2003.same
    h2002.same
    h2000.same
    h1998.same
    h1992.same  / ;

Parameter scenarioPeakLoadFactor(scenarios) "Scenario-specific scaling factor for peak load data" /
  h2003 1
  h2002 1
  h2000 1
  h1998 1
  h1992 1  / ;

Parameter scenarioCO2TaxFactor(scenarios) "Scenario-specific scaling factor for CO2 tax data" /
  h2003 1
  h2002 1
  h2000 1
  h1998 1
  h1992 1  / ;

Parameter scenarioFuelCostFactor(scenarios) "Scenario-specific scaling factor for fuel cost data" /
  h2003 1
  h2002 1
  h2000 1
  h1998 1
  h1992 1  / ;

Parameter scenarioNRGFactor(scenarios) "Scenario-specific scaling factor for energy demand data" /
  h2003 1
  h2002 1
  h2000 1
  h1998 1
  h1992 1  / ;

Parameter weightScenariosBySet(scenarioSets,scenarios) "Assign weights to the scenarios comprising each set of scenarios" /
    stochastic.h1992 0.08
    stochastic.h1998 0.08
    stochastic.h2000 0.28
    stochastic.h2002 0.28
    stochastic.h2003 0.28  / ;

* Collect the scenarioSet-to-experiments mappings by step into a single set (allSolves).
Set allSolves(experiments,steps,scenarioSets) "Scenario sets by experiment and step";
allSolves(experiments,'timing',scenarioSets)   = timingSolves(experiments,scenarioSets) ;
* allSolves(experiments,'reopt',scenarioSets)    = reoptSolves(experiments,scenarioSets) ;
* allSolves(experiments,'reopt',scenarioSets)    = reoptSolves(experiments,scenarioSets) ;

Display allSolves ;



* End of file.
