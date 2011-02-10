* GEMstochastic.gms

* A temporary GEM input file to contain the stuff related to outcomes that will need to come from
* a yet to be created GUI in EAME.

* Sets:
Set outcomes  'Stochastic outcomes or uncertainty states'  / Average, m1992, m1998, m2000, m2002, m2003 / ;

Set mapoc_hY(outcomes,hY) 'Map historical hydro output years to outcomes' /
    average.(1932,1933,1934,1935,1936,1937,1938,1939,1940,1941,1942,1943,1944,1945,1946,1947,1948,1949,1950
             1951,1952,1953,1954,1955,1956,1957,1958,1959,1960,1961,1962,1963,1964,1965,1966,1967,1968,1969
             1970,1971,1972,1973,1974,1975,1976,1977,1978,1979,1980,1981,1982,1983,1984,1985,1986,1987,1988
             1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007)
    m1992  . 1992
    m1998  . 1998
    m2000  . 2000
    m2002  . 2002
    m2003  . 2003 / ;

set map_rt_oc(rt,outcomes) ;
map_rt_oc('tmg','average') = yes ;
map_rt_oc('reo','average') = yes ;
map_rt_oc('dis','average') = yes ;


* Parameters:
Parameter outcomePeakLoadFactor(outcomes) / average 1, m1992 1, m1998 1, m2000 1, m2002 1, m2003 1 / ;
parameter outcomeCO2TaxFactor(outcomes)   / average 1, m1992 1, m1998 0, m2000 1, m2002 1, m2003 1 / ;
parameter outcomeFuelCostFactor(outcomes) / average 1, m1992 1, m1998 1, m2000 1, m2002 1, m2003 1 / ;

Parameter rt_outcomeWeight(rt,outcomes)   /  tmg.average 1, reo.average 1, dis.average 1   / ;

parameter penaltyLostPeak / 9998 / ;

* End of file.
