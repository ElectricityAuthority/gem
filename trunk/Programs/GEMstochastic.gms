* GEMstochastic.gms

* A temporary GEM input file to contain the stuff related to outcomes that will need to come from
* a yet to be created GUI in EAME.

* Sets:
Sets
  outcomes              'Stochastic outcomes or uncertainty states'  / averageSame, averageSeq, m1992, m1998, m2000, m2002, m2003 /
  hydroTypes            'Types of hydro sequences to use'            / Same, Sequential /
  chooseHydroYears(hY)  'Used for calculation of hydro sequences'
  ;

* Mapping sets:
Set mapoc_hY(outcomes,hY) 'Map historical hydro output years to outcomes' /
    averageSame.(1932,1933,1934,1935,1936,1937,1938,1939,1940,1941,1942,1943,1944,1945,1946,1947,1948,1949,1950
                 1951,1952,1953,1954,1955,1956,1957,1958,1959,1960,1961,1962,1963,1964,1965,1966,1967,1968,1969
                 1970,1971,1972,1973,1974,1975,1976,1977,1978,1979,1980,1981,1982,1983,1984,1985,1986,1987,1988
                 1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007)
    averageSeq .(1932,1933,1934,1935,1936,1937,1938,1939,1940,1941,1942,1943,1944,1945,1946,1947,1948,1949,1950
                 1951,1952,1953,1954,1955,1956,1957,1958,1959,1960,1961,1962,1963,1964,1965,1966,1967,1968,1969
                 1970,1971,1972,1973,1974,1975,1976,1977,1978,1979,1980,1981,1982,1983,1984,1985,1986,1987,1988
                 1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007)
    m1992      . 1992
    m1998      . 1998
    m2000      . 2000
    m2002      . 2002
    m2003      . 2003 / ;

Set hydroType(outcomes,hydroTypes) 'Map the way hydrology sequences are developed (same or sequential) to outcomes' /
    averageSame. Same 
    averageSeq . Sequential 
    m1992      . Same
    m1998      . Same
    m2000      . Same
    m2002      . Same
    m2003      . Same / ;

Set map_rt_oc(rt,outcomes) 'Map outcomes to run types' ;
map_rt_oc('tmg','averageSame') = yes ;
map_rt_oc('reo','averageSame') = yes ;
map_rt_oc('dis','averageSeq')  = yes ;


* Parameters:
Parameters
  outcomePeakLoadFactor(outcomes)      / averageSame 1, averageSeq 1, m1992 1, m1998 1, m2000 1, m2002 1, m2003 1 /
  outcomeCO2TaxFactor(outcomes)        / averageSame 1, averageSeq 1, m1992 1, m1998 1, m2000 1, m2002 1, m2003 1 /
  outcomeFuelCostFactor(outcomes)      / averageSame 1, averageSeq 1, m1992 1, m1998 1, m2000 1, m2002 1, m2003 1 /
  outcomeNRGFactor(outcomes)           / averageSame 1, averageSeq 1, m1992 1, m1998 1, m2000 1, m2002 1, m2003 1 /
  penaltyLostPeak                      / 9998 / ;

Table rt_outcomeWeight(rt,outcomes)
       averageSame   averageSeq
  tmg       1
  reo       1
  dis                     1       ;



* End of file.
