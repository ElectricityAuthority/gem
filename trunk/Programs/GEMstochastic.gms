* GEMstochastic.gms

* A temporary GEM input file to contain the stuff related to outcomes that will need to come from
* a yet to be created GUI in EAME.

* Sets:
Sets
  runs                  'Separate runs of timing or dispatch'        / timing, reopt, stochastic, lowCO2TaxRun, medCO2TaxRun, highCO2TaxRun /
  outcomes              'Stochastic outcomes or uncertainty states'  / lowCO2TaxOC, medCO2TaxOC, highCO2TaxOC /
  hydroTypes            'Types of hydro sequences to use'            / Same, Sequential /
  ;

* Mapping sets:
Set mapoc_hY(outcomes,hY) 'Map historical hydro output years to outcomes' /
    (lowCO2TaxOC, medCO2TaxOC,highCO2TaxOC).
                (1932,1933,1934,1935,1936,1937,1938,1939,1940,1941,1942,1943,1944,1945,1946,1947,1948,1949,1950
                 1951,1952,1953,1954,1955,1956,1957,1958,1959,1960,1961,1962,1963,1964,1965,1966,1967,1968,1969
                 1970,1971,1972,1973,1974,1975,1976,1977,1978,1979,1980,1981,1982,1983,1984,1985,1986,1987,1988
                 1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007) / ;

Set hydroType(outcomes,hydroTypes) 'Map the way hydrology sequences are developed (same or sequential) to outcomes' /
    lowCO2TaxOC   . Same 
    medCO2TaxOC   . Same 
    highCO2TaxOC  . Same / ;

Set map_runs_outcomes(runs,outcomes) 'Which outcomes are in which run?' /
    stochastic    . (lowCO2TaxOC, medCO2TaxOC, highCO2TaxOC)
    lowCO2TaxRun  . (lowCO2TaxOC)
    medCO2TaxRun  . (medCO2TaxOC)
    highCO2TaxRun . (highCO2TaxOC) / ;

Set map_reopt_outcomes(runs,outcomes) 'Which outcomes are in each reopt run?' /
    stochastic    . (lowCO2TaxOC, medCO2TaxOC, highCO2TaxOC)
    lowCO2TaxRun  . (lowCO2TaxOC)
    medCO2TaxRun  . (medCO2TaxOC)
    highCO2TaxRun . (highCO2TaxOC) / ;

Set map_rt_runs(rt,runs) 'Which runs do do for each run type?' /
    tmg           . (stochastic, lowCO2TaxRun, medCO2TaxRun, highCO2TaxRun)
    dis           . (lowCO2TaxRun, medCO2TaxRun, highCO2TaxRun) / ;


* Parameters:
Parameters
  outcomePeakLoadFactor(outcomes)      / lowCO2TaxOC 1.0, medCO2TaxOC 1.0, highCO2TaxOC 1.0 /
  outcomeCO2TaxFactor(outcomes)        / lowCO2TaxOC 0.5, medCO2TaxOC 1.0, highCO2TaxOC 1.5 /
  outcomeFuelCostFactor(outcomes)      / lowCO2TaxOC 1.0, medCO2TaxOC 1.0, highCO2TaxOC 1.0 /
  outcomeNRGFactor(outcomes)           / lowCO2TaxOC 1.0, medCO2TaxOC 1.0, highCO2TaxOC 1.0 /
  penaltyLostPeak                      / 9998 / ;

Table run_outcomeWeight(runs,outcomes)
                lowCO2TaxOC  medCO2TaxOC  highCO2TaxOC
  stochastic    0.333333333  0.333333333  0.3333333333
  lowCO2TaxRun  1            0            0
  medCO2TaxRun  0            1            0
  highCO2TaxRun 0            0            1 ;

* End of file.
