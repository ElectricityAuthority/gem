* GEMstochastic.gms

* A temporary GEM input file to contain the stuff related to outcomes that will need to come from
* a yet to be created GUI in EAME.

* Sets:
Sets
  experiments           'Complete experiments with timing, reopt and dispatch'
                                                                     / stochasticExp, lowCO2TaxExp, medCO2TaxExp, highCO2TaxExp /
  outcomes              'Stochastic outcomes or uncertainty states'  / lowCO2TaxOC, medCO2TaxOC, highCO2TaxOC /
  outcomeSets           'Sets of outcomes to be used in a run'       / stochasticSet, lowCO2TaxSet, medCO2TaxSet, highCO2TaxSet / 
  ;

* Mapping sets:
Set mapOC_hY(outcomes,hY) 'Map historical hydro output years to outcomes' /
    (lowCO2TaxOC, medCO2TaxOC,highCO2TaxOC).
                (1932,1933,1934,1935,1936,1937,1938,1939,1940,1941,1942,1943,1944,1945,1946,1947,1948,1949,1950
                 1951,1952,1953,1954,1955,1956,1957,1958,1959,1960,1961,1962,1963,1964,1965,1966,1967,1968,1969
                 1970,1971,1972,1973,1974,1975,1976,1977,1978,1979,1980,1981,1982,1983,1984,1985,1986,1987,1988
                 1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007) / ;

Set mapOC_hydroSeqTypes(outcomes,hydroSeqTypes) 'Map the way hydrology sequences are developed (same or sequential) to outcomes' /
    lowCO2TaxOC   . Same 
    medCO2TaxOC   . Same 
    highCO2TaxOC  . Same / ;

Set setOutcomes(outcomeSets, outcomes) 'the outcomes that make up an outcome set' /
    stochasticSet . (lowCO2TaxOC, medCO2TaxOC, highCO2TaxOC)
    lowCO2TaxSet  . (lowCO2TaxOC)
    medCO2TaxSet  . (medCO2TaxOC)
    highCO2TaxSet . (highCO2TaxOC) / ;

Table set_outcomeWeight(outcomeSets,outcomes)
                lowCO2TaxOC  medCO2TaxOC  highCO2TaxOC
  stochasticSet 0.333333333  0.333333333  0.3333333333
  lowCO2TaxSet  1            0            0
  medCO2TaxSet  0            1            0
  highCO2TaxSet 0            0            1 ;


Set timingRuns(experiments,outcomeSets) 'Which outcome sets are used for timing in each experiment?' /
    stochasticExp . stochasticSet
    lowCO2TaxExp  . lowCO2TaxSet
    medCO2TaxExp  . medCO2TaxSet
    highCO2TaxExp . highCO2TaxSet / ;

Set reoptRuns(experiments,outcomeSets)  'Which outcome sets are used for reoptimisation in each experiment?' /
    stochasticExp . stochasticSet
    lowCO2TaxExp  . lowCO2TaxSet
    medCO2TaxExp  . medCO2TaxSet
    highCO2TaxExp . highCO2TaxSet / ;

Set dispatchRuns(experiments,outcomeSets) 'Which outcome sets are used for dispatch in each experiment?' /
    stochasticExp . (lowCO2TaxSet, medCO2TaxSet, highCO2TaxSet)
    lowCO2TaxExp  . (lowCO2TaxSet, medCO2TaxSet, highCO2TaxSet)
    medCO2TaxExp  . (lowCO2TaxSet, medCO2TaxSet, highCO2TaxSet)
    highCO2TaxExp . (lowCO2TaxSet, medCO2TaxSet, highCO2TaxSet) / ;

* Parameters:
Parameters
  outcomePeakLoadFactor(outcomes)      / lowCO2TaxOC 1.0, medCO2TaxOC 1.0, highCO2TaxOC 1.0 /
  outcomeCO2TaxFactor(outcomes)        / lowCO2TaxOC 0.5, medCO2TaxOC 1.0, highCO2TaxOC 1.5 /
  outcomeFuelCostFactor(outcomes)      / lowCO2TaxOC 1.0, medCO2TaxOC 1.0, highCO2TaxOC 1.0 /
  outcomeNRGFactor(outcomes)           / lowCO2TaxOC 1.0, medCO2TaxOC 1.0, highCO2TaxOC 1.0 /
  penaltyLostPeak                      / 9998 / ;

Set allRuns(experiments,steps,outcomeSets);
allRuns(experiments, 'timing', outcomeSets) = timingRuns(experiments,outcomeSets);
allRuns(experiments, 'reopt', outcomeSets) = reoptRuns(experiments,outcomeSets);
allRuns(experiments, 'dispatch', outcomeSets) = dispatchRuns(experiments,outcomeSets);

* End of file.
