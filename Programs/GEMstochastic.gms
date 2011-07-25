* GEMstochastic-standard.gms

* A temporary GEM input file to contain the stuff related to outcomes that will need to come from
* a yet to be created GUI in Oasis.

* 'Standard' implies this version of GEMstochastic enables the following solves to occur:
*  - timing with average hydrology 
*  - reoptimisation with 1932 hydrology 
*  - dispatch with sequential hydrology - 76 times 

* Sets:
Sets
  experiments           'A collection of experiments, each potentially containing timing, re-optimisation and dispatch steps' /
                         standardExp /

  outcomes              'The various individual stochastic outcomes, or futures, or states of uncertainty' /
                         piAvg,  piDry
                         pi1932, pi1933, pi1934, pi1935, pi1936, pi1937, pi1938, pi1939, pi1940
*                        pi1941, pi1942, pi1943, pi1944, pi1945, pi1946, pi1947, pi1948, pi1949, pi1950
*                        pi1951, pi1952, pi1953, pi1954, pi1955, pi1956, pi1957, pi1958, pi1959, pi1960
*                        pi1961, pi1962, pi1963, pi1964, pi1965, pi1966, pi1967, pi1968, pi1969, pi1970
*                        pi1971, pi1972, pi1973, pi1974, pi1975, pi1976, pi1977, pi1978, pi1979, pi1980
*                        pi1981, pi1982, pi1983, pi1984, pi1985, pi1986, pi1987, pi1988, pi1989, pi1990
*                        pi1991, pi1992, pi1993, pi1994, pi1995, pi1996, pi1997, pi1998, pi1999, pi2000
                         pi2001, pi2002, pi2003, pi2004, pi2005, pi2006, pi2007  /

  outcomeSets           'Create sets of outcomes to be used in a solve' /
                         standardAvg, standardDry 
                         standard1932, standard1933, standard1934, standard1935, standard1936, standard1937, standard1938, standard1939, standard1940
*                        standard1941, standard1942, standard1943, standard1944, standard1945, standard1946, standard1947, standard1948, standard1949, standard1950
*                        standard1951, standard1952, standard1953, standard1954, standard1955, standard1956, standard1957, standard1958, standard1959, standard1960
*                        standard1961, standard1962, standard1963, standard1964, standard1965, standard1966, standard1967, standard1968, standard1969, standard1970
*                        standard1971, standard1972, standard1973, standard1974, standard1975, standard1976, standard1977, standard1978, standard1979, standard1980
*                        standard1981, standard1982, standard1983, standard1984, standard1985, standard1986, standard1987, standard1988, standard1989, standard1990
*                        standard1991, standard1992, standard1993, standard1994, standard1995, standard1996, standard1997, standard1998, standard1999, standard2000
                         standard2001, standard2002, standard2003, standard2004, standard2005, standard2006, standard2007  /

* Mapping sets:
  mapOutcomes(outcomeSets,outcomes) 'Map the individual outcomes to an outcome set (i.e. 1 or more outcomes make up an outcome set)' /
    standardAvg    .  piAvg
    standardDry    .  piDry
    standard1932.pi1932, standard1933.pi1933, standard1934.pi1934, standard1935.pi1935, standard1936.pi1936, standard1937.pi1937, standard1938.pi1938, standard1939.pi1939, standard1940.pi1940
*   standard1941.pi19, standard1942.pi19, standard1943.pi19, standard1944.pi19, standard1945.pi19, standard1946.pi19, standard1947.pi19, standard1948.pi19, standard1949.pi19, standard1950
*   standard1951.pi19, standard1952.pi19, standard1953.pi19, standard1954.pi19, standard1955.pi19, standard1956.pi19, standard1957.pi19, standard1958.pi19, standard1959.pi19, standard1960
*   standard1961.pi19, standard1962.pi19, standard1963.pi19, standard1964.pi19, standard1965.pi19, standard1966.pi19, standard1967.pi19, standard1968.pi19, standard1969.pi19, standard1970
*   standard1971.pi19, standard1972.pi19, standard1973.pi19, standard1974.pi19, standard1975.pi19, standard1976.pi19, standard1977.pi19, standard1978.pi19, standard1979.pi19, standard1980
*   standard1981.pi19, standard1982.pi19, standard1983.pi19, standard1984.pi19, standard1985.pi19, standard1986.pi19, standard1987.pi19, standard1988.pi19, standard1989.pi19, standard1990
*   standard1991.pi19, standard1992.pi19, standard1993.pi19, standard1994.pi19, standard1995.pi19, standard1996.pi19, standard1997.pi19, standard1998.pi19, standard1999.pi19, standard2000
    standard2001.pi2001, standard2002.pi2002, standard2003.pi2003, standard2004.pi2004, standard2005.pi2005, standard2006.pi2006, standard2007.pi2007  /

  timingSolves(experiments,outcomeSets) 'Which outcome sets are used for the timing step of each experiment?' /
    standardExp    .  standardAvg   /

  reoptSolves(experiments,outcomeSets)  'Which outcome sets are used for the reoptimisation step of each experiment?' /
    standardExp    .  standardDry   /

  dispatchSolves(experiments,outcomeSets) 'Which outcome sets are used for the dispatch step of each experiment?' /
    standardExp    .(standard1932, standard1933, standard1934, standard1935, standard1936, standard1937, standard1938, standard1939, standard1940
*                    standard1941, standard1942, standard1943, standard1944, standard1945, standard1946, standard1947, standard1948, standard1949, standard1950
*                    standard1951, standard1952, standard1953, standard1954, standard1955, standard1956, standard1957, standard1958, standard1959, standard1960
*                    standard1961, standard1962, standard1963, standard1964, standard1965, standard1966, standard1967, standard1968, standard1969, standard1970
*                    standard1971, standard1972, standard1973, standard1974, standard1975, standard1976, standard1977, standard1978, standard1979, standard1980
*                    standard1981, standard1982, standard1983, standard1984, standard1985, standard1986, standard1987, standard1988, standard1989, standard1990
*                    standard1991, standard1992, standard1993, standard1994, standard1995, standard1996, standard1997, standard1998, standard1999, standard2000
                     standard2001, standard2002, standard2003, standard2004, standard2005, standard2006, standard2007)  /

  mapOC_hY(outcomes,hY) 'Map historical hydro output years to outcomes (compute the average if more than one hydro year is specified)' /
    piAvg          . (1932*2007)
    piDry          .  1932
    pi1932.1932, pi1933.1933, pi1934.1934, pi1935.1935, pi1936.1936, pi1937.1937, pi1938.1938, pi1939.1939, pi1940.1940
*   pi1941.1941, pi1942.1942, pi1943.19, pi1944.19, pi1945.19, pi1946.19, pi1947.19, pi1948.19, pi1949.19, pi1950.1950
*   pi1951.1951, pi1952.1952, pi1953.19, pi1954.19, pi1955.19, pi1956.19, pi1957.19, pi1958.19, pi1959.19, pi1960.1960
*   pi1961.1961, pi1962.1962, pi1963.19, pi1964.19, pi1965.19, pi1966.19, pi1967.19, pi1968.19, pi1969.19, pi1970.1970
*   pi1971.1971, pi1972.1972, pi1973.19, pi1974.19, pi1975.19, pi1976.19, pi1977.19, pi1978.19, pi1979.19, pi1980.1980
*   pi1981.1981, pi1982.1982, pi1983.19, pi1984.19, pi1985.19, pi1986.19, pi1987.19, pi1988.19, pi1989.19, pi1990.1990
*   pi1991.1991, pi1992.1992, pi1993.19, pi1994.19, pi1995.19, pi1996.19, pi1997.19, pi1998.19, pi1999.19, pi2000.2000
    pi2001.2001, pi2002.2002, pi2003.2003, pi2004.2004, pi2005.2005, pi2006.2006, pi2007.2007  /

  mapOC_hydroSeqTypes(outcomes,hydroSeqTypes) 'Map the way hydrology sequences are developed (same or sequential) to outcomes' /
    piAvg    . Same
    piDry    . Same
   (pi1932, pi1933, pi1934, pi1935, pi1936, pi1937, pi1938, pi1939, pi1940
*   pi1941, pi1942, pi1943, pi1944, pi1945, pi1946, pi1947, pi1948, pi1949, pi1950
*   pi1951, pi1952, pi1953, pi1954, pi1955, pi1956, pi1957, pi1958, pi1959, pi1960
*   pi1961, pi1962, pi1963, pi1964, pi1965, pi1966, pi1967, pi1968, pi1969, pi1970
*   pi1971, pi1972, pi1973, pi1974, pi1975, pi1976, pi1977, pi1978, pi1979, pi1980
*   pi1981, pi1982, pi1983, pi1984, pi1985, pi1986, pi1987, pi1988, pi1989, pi1990
*   pi1991, pi1992, pi1993, pi1994, pi1995, pi1996, pi1997, pi1998, pi1999, pi2000
    pi2001, pi2002, pi2003, pi2004, pi2005, pi2006, pi2007).Sequential  /
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

Set set_weightOutcomesBySet(outcomeSets,outcomes) 'Assign weights to the outcomes comprising each set of outcomes'  / #outcomeSets:#outcomes / ;
Parameter weightOutcomesBySet(outcomeSets,outcomes) 'Assign weights to the outcomes comprising each set of outcomes' ;
weightOutcomesBySet(outcomeSets,outcomes)$set_weightOutcomesBySet(outcomeSets,outcomes) = 1 ;



* Collect the outcomeSet-to-experiments mappings by step into a single set (allSolves).
Set allSolves(experiments,steps,outcomeSets) 'Outcome sets by experiment and step';
allSolves(experiments,'timing',outcomeSets)   = timingSolves(experiments,outcomeSets) ;
allSolves(experiments,'reopt',outcomeSets)    = reoptSolves(experiments,outcomeSets) ;
allSolves(experiments,'dispatch',outcomeSets) = dispatchSolves(experiments,outcomeSets) ;

Display allSolves ;



* End of file.
