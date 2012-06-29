* C:\a\GEM\Programs\GEMstochastic.inc

* A GEM input file to contain the settings related to scenarios that come from a GUI in emi.

Sets
  scenarios    "The various individual stochastic scenarios, or futures, or states of uncertainty" /
    avgHydro
    dryHydro
    h1932
    h1933
    h1934
    h1935
    h1936
    h1937
    h1938
    h1939
    h1940
    h1941
    h1942
    h1943
    h1944
    h1945
    h1946
    h1947
    h1948
    h1949
    h1950
    h1951
    h1952
    h1953
    h1954
    h1955
    h1956
    h1957
    h1958
    h1959
    h1960
    h1961
    h1962
    h1963
    h1964
    h1965
    h1966
    h1967
    h1968
    h1969
    h1970
    h1971
    h1972
    h1973
    h1974
    h1975
    h1976
    h1977
    h1978
    h1979
    h1980
    h1981
    h1982
    h1983
    h1984
    h1985
    h1986
    h1987
    h1988
    h1989
    h1990
    h1991
    h1992
    h1993
    h1994
    h1995
    h1996
    h1997
    h1998
    h1999
    h2000
    h2001
    h2002
    h2003
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
    beginSeq1935
    beginSeq1936
    beginSeq1937
    beginSeq1938
    beginSeq1939
    beginSeq1940
    beginSeq1941
    beginSeq1942
    beginSeq1943
    beginSeq1944
    beginSeq1945
    beginSeq1946
    beginSeq1947
    beginSeq1948
    beginSeq1949
    beginSeq1950
    beginSeq1951
    beginSeq1952
    beginSeq1953
    beginSeq1954
    beginSeq1955
    beginSeq1956
    beginSeq1957
    beginSeq1958
    beginSeq1959
    beginSeq1960
    beginSeq1961
    beginSeq1962
    beginSeq1963
    beginSeq1964
    beginSeq1965
    beginSeq1966
    beginSeq1967
    beginSeq1968
    beginSeq1969
    beginSeq1970
    beginSeq1971
    beginSeq1972
    beginSeq1973
    beginSeq1974
    beginSeq1975
    beginSeq1976
    beginSeq1977
    beginSeq1978
    beginSeq1979
    beginSeq1980
    beginSeq1981
    beginSeq1982
    beginSeq1983
    beginSeq1984
    beginSeq1985
    beginSeq1986
    beginSeq1987
    beginSeq1988
    beginSeq1989
    beginSeq1990
    beginSeq1991
    beginSeq1992
    beginSeq1993
    beginSeq1994
    beginSeq1995
    beginSeq1996
    beginSeq1997
    beginSeq1998
    beginSeq1999
    beginSeq2000
    beginSeq2001
    beginSeq2002
    beginSeq2003
    beginSeq2004
    beginSeq2005
    beginSeq2006
    beginSeq2007  /

  experiments  "A collection of scenarioSets to be solved for in the current runVersion. Experiments must get mapped to steps - timing, re-optimisation and dispatch" /
    oldWayFull  /

* Mapping sets:
  mapScenarios(scenarioSets,scenarios) "Map each scenario to a scenarioSet (i.e. 1 or more scenarios make up an scenario set)" /
    averageHydro.avgHydro
    dryYrHydro.dryHydro
    beginSeq1932.h1932
    beginSeq1933.h1933
    beginSeq1934.h1934
    beginSeq1935.h1935
    beginSeq1936.h1936
    beginSeq1937.h1937
    beginSeq1938.h1938
    beginSeq1939.h1939
    beginSeq1940.h1940
    beginSeq1941.h1941
    beginSeq1942.h1942
    beginSeq1943.h1943
    beginSeq1944.h1944
    beginSeq1945.h1945
    beginSeq1946.h1946
    beginSeq1947.h1947
    beginSeq1948.h1948
    beginSeq1949.h1949
    beginSeq1950.h1950
    beginSeq1951.h1951
    beginSeq1952.h1952
    beginSeq1953.h1953
    beginSeq1954.h1954
    beginSeq1955.h1955
    beginSeq1956.h1956
    beginSeq1957.h1957
    beginSeq1958.h1958
    beginSeq1959.h1959
    beginSeq1960.h1960
    beginSeq1961.h1961
    beginSeq1962.h1962
    beginSeq1963.h1963
    beginSeq1964.h1964
    beginSeq1965.h1965
    beginSeq1966.h1966
    beginSeq1967.h1967
    beginSeq1968.h1968
    beginSeq1969.h1969
    beginSeq1970.h1970
    beginSeq1971.h1971
    beginSeq1972.h1972
    beginSeq1973.h1973
    beginSeq1974.h1974
    beginSeq1975.h1975
    beginSeq1976.h1976
    beginSeq1977.h1977
    beginSeq1978.h1978
    beginSeq1979.h1979
    beginSeq1980.h1980
    beginSeq1981.h1981
    beginSeq1982.h1982
    beginSeq1983.h1983
    beginSeq1984.h1984
    beginSeq1985.h1985
    beginSeq1986.h1986
    beginSeq1987.h1987
    beginSeq1988.h1988
    beginSeq1989.h1989
    beginSeq1990.h1990
    beginSeq1991.h1991
    beginSeq1992.h1992
    beginSeq1993.h1993
    beginSeq1994.h1994
    beginSeq1995.h1995
    beginSeq1996.h1996
    beginSeq1997.h1997
    beginSeq1998.h1998
    beginSeq1999.h1999
    beginSeq2000.h2000
    beginSeq2001.h2001
    beginSeq2002.h2002
    beginSeq2003.h2003
    beginSeq2004.h2004
    beginSeq2005.h2005
    beginSeq2006.h2006
    beginSeq2007.h2007  /

  timingSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the timing step of each experiment" /
    oldWayFull.averageHydro  /

  reoptSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the re-optimisation step of each experiment" /
    oldWayFull.dryYrHydro  /

  dispatchSolves(experiments,scenarioSets) "Identify the scenarioSet to be used for the dispatch step of each experiment" /
    oldWayFull.beginSeq1932
    oldWayFull.beginSeq1933
    oldWayFull.beginSeq1934
    oldWayFull.beginSeq1935
    oldWayFull.beginSeq1936
    oldWayFull.beginSeq1937
    oldWayFull.beginSeq1938
    oldWayFull.beginSeq1939
    oldWayFull.beginSeq1940
    oldWayFull.beginSeq1941
    oldWayFull.beginSeq1942
    oldWayFull.beginSeq1943
    oldWayFull.beginSeq1944
    oldWayFull.beginSeq1945
    oldWayFull.beginSeq1946
    oldWayFull.beginSeq1947
    oldWayFull.beginSeq1948
    oldWayFull.beginSeq1949
    oldWayFull.beginSeq1950
    oldWayFull.beginSeq1951
    oldWayFull.beginSeq1952
    oldWayFull.beginSeq1953
    oldWayFull.beginSeq1954
    oldWayFull.beginSeq1955
    oldWayFull.beginSeq1956
    oldWayFull.beginSeq1957
    oldWayFull.beginSeq1958
    oldWayFull.beginSeq1959
    oldWayFull.beginSeq1960
    oldWayFull.beginSeq1961
    oldWayFull.beginSeq1962
    oldWayFull.beginSeq1963
    oldWayFull.beginSeq1964
    oldWayFull.beginSeq1965
    oldWayFull.beginSeq1966
    oldWayFull.beginSeq1967
    oldWayFull.beginSeq1968
    oldWayFull.beginSeq1969
    oldWayFull.beginSeq1970
    oldWayFull.beginSeq1971
    oldWayFull.beginSeq1972
    oldWayFull.beginSeq1973
    oldWayFull.beginSeq1974
    oldWayFull.beginSeq1975
    oldWayFull.beginSeq1976
    oldWayFull.beginSeq1977
    oldWayFull.beginSeq1978
    oldWayFull.beginSeq1979
    oldWayFull.beginSeq1980
    oldWayFull.beginSeq1981
    oldWayFull.beginSeq1982
    oldWayFull.beginSeq1983
    oldWayFull.beginSeq1984
    oldWayFull.beginSeq1985
    oldWayFull.beginSeq1986
    oldWayFull.beginSeq1987
    oldWayFull.beginSeq1988
    oldWayFull.beginSeq1989
    oldWayFull.beginSeq1990
    oldWayFull.beginSeq1991
    oldWayFull.beginSeq1992
    oldWayFull.beginSeq1993
    oldWayFull.beginSeq1994
    oldWayFull.beginSeq1995
    oldWayFull.beginSeq1996
    oldWayFull.beginSeq1997
    oldWayFull.beginSeq1998
    oldWayFull.beginSeq1999
    oldWayFull.beginSeq2000
    oldWayFull.beginSeq2001
    oldWayFull.beginSeq2002
    oldWayFull.beginSeq2003
    oldWayFull.beginSeq2004
    oldWayFull.beginSeq2005
    oldWayFull.beginSeq2006
    oldWayFull.beginSeq2007  /

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
    h1935.1935
    h1936.1936
    h1937.1937
    h1938.1938
    h1939.1939
    h1940.1940
    h1941.1941
    h1942.1942
    h1943.1943
    h1944.1944
    h1945.1945
    h1946.1946
    h1947.1947
    h1948.1948
    h1949.1949
    h1950.1950
    h1951.1951
    h1952.1952
    h1953.1953
    h1954.1954
    h1955.1955
    h1956.1956
    h1957.1957
    h1958.1958
    h1959.1959
    h1960.1960
    h1961.1961
    h1962.1962
    h1963.1963
    h1964.1964
    h1965.1965
    h1966.1966
    h1967.1967
    h1968.1968
    h1969.1969
    h1970.1970
    h1971.1971
    h1972.1972
    h1973.1973
    h1974.1974
    h1975.1975
    h1976.1976
    h1977.1977
    h1978.1978
    h1979.1979
    h1980.1980
    h1981.1981
    h1982.1982
    h1983.1983
    h1984.1984
    h1985.1985
    h1986.1986
    h1987.1987
    h1988.1988
    h1989.1989
    h1990.1990
    h1991.1991
    h1992.1992
    h1993.1993
    h1994.1994
    h1995.1995
    h1996.1996
    h1997.1997
    h1998.1998
    h1999.1999
    h2000.2000
    h2001.2001
    h2002.2002
    h2003.2003
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
    h1935.sequential
    h1936.sequential
    h1937.sequential
    h1938.sequential
    h1939.sequential
    h1940.sequential
    h1941.sequential
    h1942.sequential
    h1943.sequential
    h1944.sequential
    h1945.sequential
    h1946.sequential
    h1947.sequential
    h1948.sequential
    h1949.sequential
    h1950.sequential
    h1951.sequential
    h1952.sequential
    h1953.sequential
    h1954.sequential
    h1955.sequential
    h1956.sequential
    h1957.sequential
    h1958.sequential
    h1959.sequential
    h1960.sequential
    h1961.sequential
    h1962.sequential
    h1963.sequential
    h1964.sequential
    h1965.sequential
    h1966.sequential
    h1967.sequential
    h1968.sequential
    h1969.sequential
    h1970.sequential
    h1971.sequential
    h1972.sequential
    h1973.sequential
    h1974.sequential
    h1975.sequential
    h1976.sequential
    h1977.sequential
    h1978.sequential
    h1979.sequential
    h1980.sequential
    h1981.sequential
    h1982.sequential
    h1983.sequential
    h1984.sequential
    h1985.sequential
    h1986.sequential
    h1987.sequential
    h1988.sequential
    h1989.sequential
    h1990.sequential
    h1991.sequential
    h1992.sequential
    h1993.sequential
    h1994.sequential
    h1995.sequential
    h1996.sequential
    h1997.sequential
    h1998.sequential
    h1999.sequential
    h2000.sequential
    h2001.sequential
    h2002.sequential
    h2003.sequential
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
  h1935 1
  h1936 1
  h1937 1
  h1938 1
  h1939 1
  h1940 1
  h1941 1
  h1942 1
  h1943 1
  h1944 1
  h1945 1
  h1946 1
  h1947 1
  h1948 1
  h1949 1
  h1950 1
  h1951 1
  h1952 1
  h1953 1
  h1954 1
  h1955 1
  h1956 1
  h1957 1
  h1958 1
  h1959 1
  h1960 1
  h1961 1
  h1962 1
  h1963 1
  h1964 1
  h1965 1
  h1966 1
  h1967 1
  h1968 1
  h1969 1
  h1970 1
  h1971 1
  h1972 1
  h1973 1
  h1974 1
  h1975 1
  h1976 1
  h1977 1
  h1978 1
  h1979 1
  h1980 1
  h1981 1
  h1982 1
  h1983 1
  h1984 1
  h1985 1
  h1986 1
  h1987 1
  h1988 1
  h1989 1
  h1990 1
  h1991 1
  h1992 1
  h1993 1
  h1994 1
  h1995 1
  h1996 1
  h1997 1
  h1998 1
  h1999 1
  h2000 1
  h2001 1
  h2002 1
  h2003 1
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
  h1935 1
  h1936 1
  h1937 1
  h1938 1
  h1939 1
  h1940 1
  h1941 1
  h1942 1
  h1943 1
  h1944 1
  h1945 1
  h1946 1
  h1947 1
  h1948 1
  h1949 1
  h1950 1
  h1951 1
  h1952 1
  h1953 1
  h1954 1
  h1955 1
  h1956 1
  h1957 1
  h1958 1
  h1959 1
  h1960 1
  h1961 1
  h1962 1
  h1963 1
  h1964 1
  h1965 1
  h1966 1
  h1967 1
  h1968 1
  h1969 1
  h1970 1
  h1971 1
  h1972 1
  h1973 1
  h1974 1
  h1975 1
  h1976 1
  h1977 1
  h1978 1
  h1979 1
  h1980 1
  h1981 1
  h1982 1
  h1983 1
  h1984 1
  h1985 1
  h1986 1
  h1987 1
  h1988 1
  h1989 1
  h1990 1
  h1991 1
  h1992 1
  h1993 1
  h1994 1
  h1995 1
  h1996 1
  h1997 1
  h1998 1
  h1999 1
  h2000 1
  h2001 1
  h2002 1
  h2003 1
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
  h1935 1
  h1936 1
  h1937 1
  h1938 1
  h1939 1
  h1940 1
  h1941 1
  h1942 1
  h1943 1
  h1944 1
  h1945 1
  h1946 1
  h1947 1
  h1948 1
  h1949 1
  h1950 1
  h1951 1
  h1952 1
  h1953 1
  h1954 1
  h1955 1
  h1956 1
  h1957 1
  h1958 1
  h1959 1
  h1960 1
  h1961 1
  h1962 1
  h1963 1
  h1964 1
  h1965 1
  h1966 1
  h1967 1
  h1968 1
  h1969 1
  h1970 1
  h1971 1
  h1972 1
  h1973 1
  h1974 1
  h1975 1
  h1976 1
  h1977 1
  h1978 1
  h1979 1
  h1980 1
  h1981 1
  h1982 1
  h1983 1
  h1984 1
  h1985 1
  h1986 1
  h1987 1
  h1988 1
  h1989 1
  h1990 1
  h1991 1
  h1992 1
  h1993 1
  h1994 1
  h1995 1
  h1996 1
  h1997 1
  h1998 1
  h1999 1
  h2000 1
  h2001 1
  h2002 1
  h2003 1
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
  h1935 1
  h1936 1
  h1937 1
  h1938 1
  h1939 1
  h1940 1
  h1941 1
  h1942 1
  h1943 1
  h1944 1
  h1945 1
  h1946 1
  h1947 1
  h1948 1
  h1949 1
  h1950 1
  h1951 1
  h1952 1
  h1953 1
  h1954 1
  h1955 1
  h1956 1
  h1957 1
  h1958 1
  h1959 1
  h1960 1
  h1961 1
  h1962 1
  h1963 1
  h1964 1
  h1965 1
  h1966 1
  h1967 1
  h1968 1
  h1969 1
  h1970 1
  h1971 1
  h1972 1
  h1973 1
  h1974 1
  h1975 1
  h1976 1
  h1977 1
  h1978 1
  h1979 1
  h1980 1
  h1981 1
  h1982 1
  h1983 1
  h1984 1
  h1985 1
  h1986 1
  h1987 1
  h1988 1
  h1989 1
  h1990 1
  h1991 1
  h1992 1
  h1993 1
  h1994 1
  h1995 1
  h1996 1
  h1997 1
  h1998 1
  h1999 1
  h2000 1
  h2001 1
  h2002 1
  h2003 1
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
    beginSeq1935.h1935 1
    beginSeq1936.h1936 1
    beginSeq1937.h1937 1
    beginSeq1938.h1938 1
    beginSeq1939.h1939 1
    beginSeq1940.h1940 1
    beginSeq1941.h1941 1
    beginSeq1942.h1942 1
    beginSeq1943.h1943 1
    beginSeq1944.h1944 1
    beginSeq1945.h1945 1
    beginSeq1946.h1946 1
    beginSeq1947.h1947 1
    beginSeq1948.h1948 1
    beginSeq1949.h1949 1
    beginSeq1950.h1950 1
    beginSeq1951.h1951 1
    beginSeq1952.h1952 1
    beginSeq1953.h1953 1
    beginSeq1954.h1954 1
    beginSeq1955.h1955 1
    beginSeq1956.h1956 1
    beginSeq1957.h1957 1
    beginSeq1958.h1958 1
    beginSeq1959.h1959 1
    beginSeq1960.h1960 1
    beginSeq1961.h1961 1
    beginSeq1962.h1962 1
    beginSeq1963.h1963 1
    beginSeq1964.h1964 1
    beginSeq1965.h1965 1
    beginSeq1966.h1966 1
    beginSeq1967.h1967 1
    beginSeq1968.h1968 1
    beginSeq1969.h1969 1
    beginSeq1970.h1970 1
    beginSeq1971.h1971 1
    beginSeq1972.h1972 1
    beginSeq1973.h1973 1
    beginSeq1974.h1974 1
    beginSeq1975.h1975 1
    beginSeq1976.h1976 1
    beginSeq1977.h1977 1
    beginSeq1978.h1978 1
    beginSeq1979.h1979 1
    beginSeq1980.h1980 1
    beginSeq1981.h1981 1
    beginSeq1982.h1982 1
    beginSeq1983.h1983 1
    beginSeq1984.h1984 1
    beginSeq1985.h1985 1
    beginSeq1986.h1986 1
    beginSeq1987.h1987 1
    beginSeq1988.h1988 1
    beginSeq1989.h1989 1
    beginSeq1990.h1990 1
    beginSeq1991.h1991 1
    beginSeq1992.h1992 1
    beginSeq1993.h1993 1
    beginSeq1994.h1994 1
    beginSeq1995.h1995 1
    beginSeq1996.h1996 1
    beginSeq1997.h1997 1
    beginSeq1998.h1998 1
    beginSeq1999.h1999 1
    beginSeq2000.h2000 1
    beginSeq2001.h2001 1
    beginSeq2002.h2002 1
    beginSeq2003.h2003 1
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
