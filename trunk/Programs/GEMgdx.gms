* GEMgdx.gms

* Last modified by Dr Phil Bishop, 12/09/2011 (imm@ea.govt.nz)

* NB: This program requires editing each time it is used - read the notes below.

$ontext
 GEMgdx is an ad hoc piece of code. Its purpose is to create data in a GDX file format to be used by GEM. More
 specifically, any data that changes or requires updating infrequently, e.g. hydrology and load, ought to be
 created herein. Besides creating the GEM GDX file, this program can also be used to perform manipulations on
 certain data, e.g. as in the case of adjustments to raw load data.

 The typical usage of this program will require GEMldc to be run first, i.e. GEMldc creates the LDC profile
 required by GEMgdx. The GDX file created by GEMldc also contains other bits of data required by GEMgdx.

 GEMgdx will read data from various file formats, e.g. Excel, GDX, databases, or text formats, and store it
 all in a single GDX file. The statements that read the files must obviously be consistent with the format
 being read. The resulting GDX file should then be plundered for the bits and pieces required by the GEM input
 files:
   - m, lb, mapm_t(m,t)
   - i_HalfHrsPerBlk(m,lb)
   - i_NrgDemand(r,y,t,lb)
   - i_historicalHydroOutput(v,hY,m)

 This program is not run as part of the normal GEM invocation.

 Specific notes as to the editing required by the user each time this program is invoked are provided below
 at the beginning of each code section.

 Code sections:
  1. Take care of preliminaries.
  2. Install sets - either hard-code or read from external files.
     Make sure you compare GXP lists - see notes at end of code section 2.
  3. Declare parameters.
  4. Load data from external files.
  5. Perform hydrology checks and adjustments.
  6. Undertake the necessary manipulations to prepare load data for GEM.
     a) Manually assign LDC weights and monthly load shares to GXPs for which you know there are none.
        Examine 'GXP checks.txt' when done to make sure all GXPs with load also have LDC weights that sum to 1.
     b) Make adjustments so as to avoid double counting embedded generation.
     c) Spritz energy over the load blocks within each month.
     d) Create the file 'GXP check.txt' to eyeball status of load and weights at each GXP.
     e) Make scenario specific adjustments to load.
          i) Phase out Tiwai by 1/6 per year for 6 years in mds3 beginning in 2022.
         ii) Adjust mds1 and mds4 for added load from electric vehicles.
        iii) Pro-rate load according to an externally provided set of adjusters by year.
     f) Aggregate load by GXPs and months to regions and time periods.
     g) Perform a few final integrity checks on load calculations.
  7. Unload data to GDX file.
** Need to finish these last two sections
  8. Read in the GXP geography and create a bna file.
  9. Dump load by GXP into a file with geography.
$offtext

$inlinecom { } eolcom !



*===============================================================================================
* 1. Take care of preliminaries.
*    - Define pointers to required directories and files.

$setglobal NumBlks          9       ! Specify the number of blocks in LDC.
$setglobal ThisScenario     std     ! Of all the scenarios in set sc, identify the one for which the GEM gdx file will be created.

* Specify input file paths and names
$setglobal DataPath         "%system.fp%..\Data\Files required to create GEM GDXs\"
$setglobal GXPgeography	    "216 GXPs geography.csv"
$setglobal RawHydroData	    "Hydro sequences by 36 reservoirs and months, 1932-2007, GWh.csv"
$setglobal RawEnergy        "Annual energy forecasts for 180 GXPs, 2012-50, GWh (Dec 2009).csv"
$setglobal ReferenceLDC     "LDC output (%NumBlks% blocks).gdx"
$setglobal Load_ProRata     "Load pro rata.csv"

* Output file name - the resulting GDX file will be placed in the programs directory; move it to data directory if it's a keeper.
$setglobal miscGDXfilename  "CheckGEM_GDXstuff%NumBlks%LB.gdx"
$setglobal GEM_GDXfilename  "GEM_2Region36ReservoirHydro%NumBlks%LB.gdx"
$setglobal GEM_LoadByPeriod "GEM_LoadByPeriod.gdx"
$setglobal GEM_LoadByMonth  "GEM_LoadByMonth.gdx"



*===============================================================================================
* 2. Install sets - either hard-code or read from external files.

* Notes:
* - The elements of the sets declared and initialised here must be consistent with the version of the model for
*   which the GDX file is being constructed. Only those sets required to read in the raw data and to create the
*   parameters to be stored in the GDX file need to be declared, i.e. we don't need all GEM sets at this point.
* - Sets m and lb come from the LDC GDX file.
* - From time to time all set declarations may require editing. The likely candidates for editing each time this
*   program is used are: GXP, y, hY, sc, indusGXP, r, GXP_r, t, mapm_t.

Sets
  gxp            'Grid exit points' /
$include         "%DataPath%216 GXPs.dat"
                 /
  y              'Modelled calendar years'           / 2012 * 2050 /
  hY             'Hydro inflow years'                / 1932 * 2007 /
  sc             'Scenarios or assumption sets'      / std, mds1, mds3, mds4 /   ! 'std' is mandatory, others are discretionary.
  v              'Hydro reservoirs' {36}             / Aniwhenua, Arapuni, Aratiatia, Atiamuri, Aviemore, Benmore, BranchSchm, Clyde
                                                       Cobb, Coleridge, Highbank, Kaimai, Kaitawa, Karapiro, Manapouri, Mangahao, Maraetai
                                                       Matahina, Ohakuri, OhauA, OhauB, OhauC, Patea, Piripaua, Rangipo, Roxburgh, TekapoA
                                                       TekapoB, Tokaanu, Tuai, Waipapa, Waipori, DeepStream, Waitaki, Whakamaru, WheaoFlaxy /
  ild            'Islands'                           / ni, si /
  EVadjust(sc)   'Scenarios that have EV demand'     / mds1, mds4 /
  indusGXP(gxp)  'Industrial GXPs with zero EV load' / asy0111, bpt1101, bde0111, bpe0551, cyd0331, gln0331, ham0551, kaw0112
                                                       kaw0113, kin0111, kin0112, lfd1101, lfd1102, mng1101, mdn0141, npl0331
                                                       oki0111, ota0221, ota1102, sfd0331, tng0111, tng0551, tmn0551, twi2201
                                                       tku0331, twz0331, whi0111 /
  m(*)           'Months'
  lb(*)          'Load blocks'
  r              'Regions'    /
                  ni, si
*$include         "%DataPath%5 GEMlite regions.dat"
*$include         "%DataPath%18 GEM regions.dat"
                 /
  GXP_r(gxp,r)   'Map GXPs to regions'  /
$include         "%DataPath%216 GXPs to 2 regions (islands).dat"
*$include         "%DataPath%216 GXPs to 5 GEMlite regions.dat"
*$include         "%DataPath%216 GXPs to 18 GEM regions.dat"
                 /
  GXP_ild(gxp,ild) 'Map GXPs to islands'  /
$include         "%DataPath%216 GXPs to 2 regions (islands).dat"
                 / ;

$gdxin "%DataPath%%ReferenceLDC%"
$loaddc m lb

Sets
*  t              'Time periods (within a year)'      / p1  'The entire year is a single period' /
*  mapm_t(m,t)    'Map months into desired periods'   /(Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec).p1 / ;
  t              'Time periods (within a year)'      / q1  'Quarter 1'
                                                       q2  'Quarter 2'
                                                       q3  'Quarter 3'
                                                       q4  'Quarter 4' /
  mapm_t(m,t)    'Map months into desired periods'   /(Jan,Feb,Mar).q1
                                                      (Apr,May,Jun).q2
                                                      (Jul,Aug,Sep).q3
                                                      (Oct,Nov,Dec).q4 / ;
$ontext
* Alternative t and mapm_t sets
  t              'Time periods (within a year)'      / s1  'Season 1'
                                                       s2  'Season 2'  /
  mapm_t(m,t)    'Map months into desired periods'   /(Jan,Feb,Mar,Apr,May,Jun).s1
                                                      (Jul,Aug,Sep,Oct,Nov,Dec).s2  / ;
$offtext

Alias (gxp,gxpp), (lb,lbb), (m,mm) ;

* Compare GXP lists.
* Make sure the GXP list used to populate the set 'GXP' is consistent with the list used to create the reference LDC.
* Do this by reading both into a spreadsheet, sorting them alphabetically, and paste the two lists in side-by-side
* columns. If they are not the same, then make them identical. Note you can get the LDC GXP list into an Excel file
* simply by exporting from the LDC GDX file itself (right-click the GXP symbol).



*===============================================================================================
* 3. Declare parameters.

Parameters
  cntr1                          'A counter'
* Load
  load_GXP(sc,gxp,y,m,lb)        'Load data by scenario, GXP, year, month and load block, GWh'
  i_load(sc,r,y,t,lb)            'Load data by scenario, region, year, desired time period and load block, GWh'
  i_NrgDemand(r,y,t,lb)          'Load by region, year, time period and load block, GWh'
  i_NrgDemandMonthly(r,y,m,lb)   'Load by region, year, month and load block, GWh'
  chkloadyr(y,*)                 'Sum up load by year for the purpose of checking arithmetic'
  chkload(*)                     'Sum up load globally for the purpose of checking arithmetic'
* Hydrology
  chkHydroRes(v,*)               'Check hydrology data over hydro years and time, by reservoir - GWh'
  chkHydrohYr(hY,*)              'Check hydrology data over reservoir and time, by hydro years - GWh'
  chkHydro(*)                    'Check hydrology data over hydro years, time, and reservoirs - GWh'
* Electric vehicles
  EVweightsGXP(gxp,y)            'EV weights to spritz EV demand out to GXPs'
  EVweightsBlock(m,lb)           'EV weights to spritz EV demand out to load blocks by month'
  EVdemand_spritz(y,m,lb)        'Annual EV demand spritzed out to months and load blocks'
  chkEVweights(y,*)              'Check the EV weights sum to 1'
  chkEVload(sc,*)                'Check the arithmetic associated with EVs'
* Final integrity checks on load calculations
  numGXPrawload                  'Number of GXPs with annual load in raw energy forecasts'
  numGXPload(sc)                 'Number of GXPs with load after spritzing load out to blocks and making all adjustments'
  qtyGXPrawload                  'Quantity of load in raw energy forecasts, GWh'
  qtyGXPload(sc)                 'Quantity of load at GXPs after spritzing load out to blocks and making all adjustments, GWh'
  LoadChkSum(sc,y)               'Sum of load by scenario and year, GWh'
  LoadChkThisScen(y)             'Sum of load by year for this scenario, GWh'
  ;



*===============================================================================================
* 4. Load data from external files.

Parameters
  BlockWeights(gxp,m,lb)    'Weight of energy per load block per month per GXP'
  LoadShareByMonth(gxp,m)   'Share of load by month by GXP'
  i_HalfHrsPerBlk(m,lb)     'Count of half hours per block in each month'  ;

$gdxin "%DataPath%%ReferenceLDC%"
$loaddc BlockWeights LoadShareByMonth i_HalfHrsPerBlk

Table GXPgeo(gxp,*) "Geographic co-ordinates for GXPs"
$ondelim offlisting include '%DataPath%%GXPgeography%'

Table i_historicalHydroOutput(v,hY,m) 'Historical hydro output sequences by reservoir and month, GWh'
$include "%DataPath%%RawHydroData%"

Table AnnualLoad(y,gxp)  'Energy forecasts by GXP, GWh'
$include "%DataPath%%RawEnergy%"
$offdelim onlisting

Parameter EVdemand(y) 'Incremental demand for energy from electric vehicles by year, GWh' /
  2012 24.9,   2013 36.3,   2014 49.6,   2015 64.8,   2016 82.4,   2017 102.3,  2018 125.3,  2019 151,    2020 180.2, 2021 213.8
  2022 251.9,  2023 295.1,  2024 343.9,  2025 398.9,  2026 460.6,  2027 529.9,  2028 608.9,  2029 697.4,  2030 794.2, 2031 904.1
  2032 1025.2, 2033 1157.7, 2034 1306.6, 2035 1464.7, 2036 1636.8, 2037 1825.8, 2038 2027.4, 2039 2240.7, 2040 2458.3  / ;
loop(y$( EVdemand(y) = 0 ), EVdemand(y) = EVdemand(y-1) ) ;

* Compute integrity checks on imported data.
chkloadyr(y,'ImpAnnLoad') = sum(gxp, AnnualLoad(y,gxp)) ;
chkload('ImpAnnLoad') = sum((y,gxp), AnnualLoad(y,gxp)) ;

*Display chkloadyr, chkload, EVdemand ;


*===============================================================================================
* 5. Perform hydrology checks and adjustments.

* Notes:
* - The following assumes hydrology data is in a single .csv file by reservoir.
* - Hydrology data will be stored in a parameter called i_historicalHydroOutput(v,hY,m) that
*   will be placed in the GDX file from where it will be loaded into GEM each time GEM is run.

* Compute check sums before doing any hydrology aggregation or adjustments.
chkHydroRes(v,'b4')  = sum((hY,m), i_historicalHydroOutput(v,hY,m)) ;
chkHydrohYr(hY,'b4') = sum((v,m), i_historicalHydroOutput(v,hY,m)) ;
chkHydro('b4')       = sum((v,hY,m), i_historicalHydroOutput(v,hY,m)) ;

* Hydrology adjustments - there are none as yet...


* Compute check sums after doing hydrology adjustments.
chkHydroRes(v,'After')  = sum((hY,m), i_historicalHydroOutput(v,hY,m)) ;
chkHydrohYr(hY,'After') = sum((v,m), i_historicalHydroOutput(v,hY,m)) ;
chkHydro('After')       = sum((v,hY,m), i_historicalHydroOutput(v,hY,m)) ;

chkHydroRes(v,'Diff')   = chkHydroRes(v,'After') - chkHydroRes(v,'b4') ;
chkHydrohYr(hY,'diff')  = chkHydrohYr(hY,'After') - chkHydrohYr(hY,'b4') ;
chkHydro('Diff')        = chkHydro('After') - chkHydro('b4') ;

Display 'Hydro check sums', chkHydrohYr, chkHydroRes, chkHydro ;
abort$( abs(chkHydro('Diff')) > 1e-5 ) 'Hydrology data adjustments appear screwy' ;



*===============================================================================================
* 6. Undertake the necessary manipulations to prepare load data for GEM.

* a) Manually assign LDC weights and monthly load shares to GXPs for which you know there are none.
*    Examine 'GXP checks.txt' when done to make sure all GXPs with load also have LDC weights that sum to 1.
BlockWeights('lfd1102',m,lb) = BlockWeights('lfd1101',m,lb) ;   LoadShareByMonth('lfd1102',m) = LoadShareByMonth('lfd1101',m) ;
BlockWeights('oro1102',m,lb) = BlockWeights('oro1101',m,lb) ;   LoadShareByMonth('oro1102',m) = LoadShareByMonth('oro1101',m) ;
BlockWeights('wkm0331',m,lb) = BlockWeights('wkm2201',m,lb) ;   LoadShareByMonth('wkm0331',m) = LoadShareByMonth('wkm2201',m) ;
BlockWeights('wpr0661',m,lb) = BlockWeights('wpr0331',m,lb) ;   LoadShareByMonth('wpr0661',m) = LoadShareByMonth('wpr0331',m) ;



* b) Make adjustments so as to avoid double counting embedded generation.
*    Unfortunately, for now, it is necessary to manually relate this adjustment data to the GXP energy forecasts
*    Source: Brian Bull, Electricity Commission.
*    Substation	  Generator		Double-counted gen to add (GWh p.a.)
*    gln	  Glenbrook		290
*    wrk	  Rotokawa		220
*    ham	  Te Rapa		160
*    mat	  Aniwhenua		120
*    tga	  Kaimai		70
*    ltn	  Tararua Wind 1 and 2	240
*    asb	  Highbank		100
*    hwb          Waipori               80
*    Total                              1280
AnnualLoad(y,'gln0331') = AnnualLoad(y,'gln0331') + 290 ;
AnnualLoad(y,'wrk0331') = AnnualLoad(y,'wrk0331') + 220 ;
AnnualLoad(y,'ham0331') = AnnualLoad(y,'ham0331') + 160 ;
AnnualLoad(y,'mat1101') = AnnualLoad(y,'mat1101') + 120 ;
AnnualLoad(y,'tga0331') = AnnualLoad(y,'tga0331') + 70 ;
AnnualLoad(y,'ltn0331') = AnnualLoad(y,'ltn0331') + 240 ;
AnnualLoad(y,'asb0331') = AnnualLoad(y,'asb0331') + 100 ;
AnnualLoad(y,'hwb0331') = AnnualLoad(y,'hwb0331') + 80 ;

* Compute integrity checks on energy data after adjusting for embedded generation.
chkloadyr(y,'AftaEmbed') = sum(gxp, AnnualLoad(y,gxp)) ;
chkloadyr(y,'DiffAftaEmbed') = chkloadyr(y,'AftaEmbed') - chkloadyr(y,'ImpAnnLoad') ;
chkload('AftaEmbed') = sum((y,gxp), AnnualLoad(y,gxp)) ;
chkload('TotEmbedAdj') = sum((y), 1) * 1280 ;



* c) Spritz energy over the load blocks within each month.
load_GXP('std',gxp,y,m,lb) = BlockWeights(gxp,m,lb) * LoadShareByMonth(gxp,m) * AnnualLoad(y,gxp) ;

* Compute integrity checks on energy data after spritzing it out to load blocks.
chkloadyr(y,'SpritzAllGXP') = sum((gxp,m,lb), load_GXP('std',gxp,y,m,lb)) ;
chkload('SpritzAllGXP') = sum((gxp,y,m,lb), load_GXP('std',gxp,y,m,lb)) ;



* d) Create the file 'GXP check.txt' to eyeball status of load and weights at each GXP.
File GXPcheck / 'GXP check.txt' / ; GXPcheck.lw = 0 ;
cntr1 = 0 ;
put GXPcheck 'Num' @6 'GXP' @17 'AnnLoad?' @28 'GXPload?' @37 'MthShare?' @47 'Block?' @54 'SumWeights' ;
loop(gxp$sum((y), AnnualLoad(y,gxp)),
  cntr1 = cntr1 + 1
  put / cntr1:<3:0 @6 gxp.tl @20, 'y' @31 ;
  if(sum((y,m,lb), load_GXP('std',gxp,y,m,lb)), put 'y' else put '-' ) ; put @40 ;
  if(sum(m,            LoadShareByMonth(gxp,m)),       put 'y' else put '-' ) ; put @49
  if(sum((m,lb),       BlockWeights(gxp,m,lb)),        put 'y' else put '-' ) ;
  put @58 (sum((m,lb), BlockWeights(gxp,m,lb))):<6:0 ;
) ;
put / ;
loop(gxp$( sum((y), AnnualLoad(y,gxp)) = 0 ),
  cntr1 = cntr1 + 1
  put / cntr1:<3:0 @6 gxp.tl @20, '-' @31 ;
  if(sum((y,m,lb), load_GXP('std',gxp,y,m,lb)), put 'y' else put '-' ) ; put @40 ;
  if(sum(m,            LoadShareByMonth(gxp,m)),       put 'y' else put '-' ) ; put @49
  if(sum((m,lb),       BlockWeights(gxp,m,lb)),        put 'y' else put '-' ) ;
  put @58 (sum((m,lb), BlockWeights(gxp,m,lb))):<6:0 ;
) ;


* e) Make sceanrio specific adjustments to load.
*    First, assign the GXP load data to all scenarios ('std').
load_GXP(sc,gxp,y,m,lb) = load_GXP('std',gxp,y,m,lb) ;
chkload('b4ScenAdj') = sum((sc,gxp,y,m,lb), load_GXP(sc,gxp,y,m,lb)) ;

* i) Phase out Tiwai by 1/6 per year for 6 years in mds3 beginning in 2022.
parameter reduction(m,lb) ; reduction(m,lb) = 1/6 * load_GXP('mds3','twi2201','2021',m,lb) ;

load_GXP('mds3','twi2201','2022',m,lb) = load_GXP('mds3','twi2201','2022',m,lb) - 1 * reduction(m,lb) ;
load_GXP('mds3','twi2201','2023',m,lb) = load_GXP('mds3','twi2201','2023',m,lb) - 2 * reduction(m,lb) ;
load_GXP('mds3','twi2201','2024',m,lb) = load_GXP('mds3','twi2201','2024',m,lb) - 3 * reduction(m,lb) ;
load_GXP('mds3','twi2201','2025',m,lb) = load_GXP('mds3','twi2201','2025',m,lb) - 4 * reduction(m,lb) ;
load_GXP('mds3','twi2201','2026',m,lb) = load_GXP('mds3','twi2201','2026',m,lb) - 5 * reduction(m,lb) ;
load_GXP('mds3','twi2201','2027',m,lb) = 0 ;
loop(y$( ord(y) > 16 ), load_GXP('mds3','twi2201',y,m,lb) = 0 ) ;
* NB: ord(y) > 16 implies 2028 if first year is 2012.
chkload('QtyTYadj') = sum((sc,gxp,y,m,lb), load_GXP(sc,gxp,y,m,lb)) - chkload('SpritzAllGXP') ;


* ii) Adjust mds1 and mds4 for added load from electric vehicles.
*     Compute weights to spritz EV load by year out to GXPs.
EVweightsGXP(gxp,y)$( (not indusGXP(gxp)) and sum(gxpp$(not indusGXP(gxpp)), AnnualLoad(y,gxpp)) ) =
  AnnualLoad(y,gxp) / sum(gxpp$(not indusGXP(gxpp)), AnnualLoad(y,gxpp)) ;
chkEVweights(y,'GXPs') = sum(gxp, EVweightsGXP(gxp,y)) ;

* Compute weights to spritz EV load by year out to the load blocks within each month (make it proportional to width of blocks).
EVweightsBlock(m,lb) = i_HalfHrsPerBlk(m,lb) / sum((mm,lbb), i_HalfHrsPerBlk(mm,lbb)) ;
chkEVweights(y,'MthsAndBlks') = sum((m,lb), EVweightsBlock(m,lb)) ;

* Spritz out EV demand to months and load blocks.
EVdemand_spritz(y,m,lb) = EVweightsBlock(m,lb) * EVdemand(y) ;

* Spritz incremental EV load out to GXPs and add to existing load by GXP; Check load totals before and after.
chkEVload(sc,'b4') = sum((gxp,y,m,lb), load_GXP(sc,gxp,y,m,lb)) ;

load_GXP(sc,gxp,y,m,lb)$EVadjust(sc) = load_GXP(sc,gxp,y,m,lb) + EVweightsGXP(gxp,y) * EVdemand_spritz(y,m,lb) ;

chkEVload(sc,'After') = sum((gxp,y,m,lb), load_GXP(sc,gxp,y,m,lb)) ;
chkEVload(sc,'Diff')  = chkEVload(sc,'After') - chkEVload(sc,'b4') ;

chkload('QtyEVadj') = sum((sc,gxp,y,m,lb), load_GXP(sc,gxp,y,m,lb)) - chkload('SpritzAllGXP') - chkload('QtyTYadj') ;

Display chkEVweights, chkEVload ;


* Compute check sums on energy data after doing all the scenario specific adjustments.
chkloadyr(y,'AftScenAdj') = sum((sc,gxp,m,lb), load_GXP(sc,gxp,y,m,lb)) ;
chkload('AftScenAdj') = sum((sc,gxp,y,m,lb), load_GXP(sc,gxp,y,m,lb)) ;
chkload('QtyScenAdj') = chkload('QtyTYadj') + chkload('QtyEVadj') ;


$ontext
* iii) Pro-rate load according to an externally provided set of adjusters defined on year. This adjustment was motivated
*      by MED who use GEM in conjunction with their energy sector model (SADEM), and need to iterate GEM and SADEM until
*      convergence is obtained. An external file of adjustment factors is required. Load, i.e. load_GXP(sc,gxp,y,m,lb), is
*      then adjusted by the year-specific scalars read into proRata (see below).

Parameters
  chkProload(y,*)  'Check the arithmetic associated with pro-rating load'
  load_proRata(y)  'Adjustment factors to scale load by year' /
$ondelim offlisting include "%DataPath%\%Load_Prorata%"
$offdelim onlisting
  / ;

* Make sure the scalars default to 1 for all years for which they are not sensibly defined. 
load_proRata(y)$( abs(load_proRata(y)) < 0.5 ) = 1 ;
load_proRata(y)$( abs(load_proRata(y)) > 2.0 ) = 1 ;

* Compute check sums on energy data before pro-rating.
chkProload(y,'Before') = sum((gxp,m,lb), load_GXP("%ThisScenario%",gxp,y,m,lb)) ;

* Adjust load using pro rating factors.
load_GXP("%ThisScenario%",gxp,y,m,lb) = load_prorata(y) * load_GXP("%ThisScenario%",gxp,y,m,lb) ;

* Compute check sums on energy data after pro-rating.
chkProload(y,'After') = sum((gxp,m,lb), load_GXP("%ThisScenario%",gxp,y,m,lb)) ;
chkProload(y,'Diff')  = chkProload(y,'Before') - chkProload(y,'After') ;

display load_proRata, chkProload ;
$offtext



* f) Aggregate load by GXPs and months to regions and time periods.
i_load(sc,r,y,t,lb) = sum((gxp_r(gxp,r),mapm_t(m,t)), load_GXP(sc,gxp,y,m,lb)) ;

i_NrgDemandMonthly(r,y,m,lb) = sum(gxp_r(gxp,r), load_GXP("%ThisScenario%",gxp,y,m,lb)) ;

i_NrgDemand(r,y,t,lb) = i_load("%ThisScenario%",r,y,t,lb) ;

* Compute check sums on energy data after it has been aggregated to regions and time periods.
chkloadyr(y,'Aggregate') = sum((sc,lb,r,t), i_load(sc,r,y,t,lb)) ;
chkload('Aggregate') = sum((sc,y,lb,r,t), i_load(sc,r,y,t,lb)) ;

chkloadyr(y,'AggDiff') = chkloadyr(y,'Aggregate') - chkloadyr(y,'AftScenAdj') ;
chkload('AggDiff') = chkload('Aggregate') - chkload('AftScenAdj') ;



* g) Perform a few final integrity checks on load calculations.
numGXPrawload  = sum(gxp$sum(y, AnnualLoad(y,gxp)), 1) ;
numGXPload(sc) = sum(gxp$sum((y,lb,m), load_GXP(sc,gxp,y,m,lb)), 1) ;

qtyGXPrawload  = sum((y,gxp), AnnualLoad(y,gxp)) ;
qtyGXPload(sc) = sum((y,lb,gxp,m), load_GXP(sc,gxp,y,m,lb)) ;

LoadChkSum(sc,y) = sum((lb,r,t), i_load(sc,r,y,t,lb)) ;

LoadChkThisScen(y) = sum((lb,r,t), i_NrgDemand(r,y,t,lb)) ;

option chkload:5:0:1 ;
display 'Load check sums', numGXPrawload, numGXPload, qtyGXPrawload, qtyGXPload, LoadChkSum, LoadChkThisScen, chkloadyr, chkload  ;



*===============================================================================================
* 7. Unload data to GDX file.

* Notes:
* - The parameters included in this 'execute_unload' statement must be consistent with the load statement in
*   GEMbase. In other words, GEMbase expects to find certain parameters in this GDX file - and those parameters
*   get put into that GDX file right here.
* - Before unloading, round the decimals to avoid carrying along bogus precision.

Execute_Unload '%miscGDXfilename%'  m, t, mapm_t, lb, i_HalfHrsPerBlk, chkHydroRes, chkHydrohYr, chkHydro, i_historicalHydroOutput, LoadChkSum, i_load  ;

Execute_Unload '%GEM_GDXfilename%'  m, t, mapm_t, lb, i_HalfHrsPerBlk, i_historicalHydroOutput, LoadChkThisScen, i_NrgDemand  ;
Execute_Unload '%GEM_LoadByPeriod%' i_NrgDemand ;
Execute_Unload '%GEM_LoadByMonth%'  i_NrgDemandMonthly ;



$stop
** Need to finish these last two sections
*===============================================================================================
* 8. Read in the GXP geography and create a bna file.

* Notes:
* - The bna format is able to be read by many popular GIS applications, e.g. Mapviewer.
* - Comment in/out the loop statement according to the co-ordinates desired, i.e. Easting/Northing or Lat/Long.


file GXPbna / "GXP geography.bna" / ; GXPbna.lw = 0 ; put GXPbna ;
*loop(gxp, put'"', gxp.tl, '","', gxp.te(gxp), '",1,', GXPgeo(gxp,'Long'):12:3, ',', GXPgeo(gxp,'Lat'):12:3 / ) ;
loop(gxp, put'"', gxp.tl, '","', gxp.te(gxp), '",1,', GXPgeo(gxp,'Easting'):12:3, ',', GXPgeo(gxp,'Northing'):12:3 / ) ;



*===============================================================================================
* 9. Dump load by GXP into a file with geography.

File loadGXP / "Annual load by GXP with geography (GWh).txt" / ;
loadGXP.pc = 6 ; loadGXP.lw = 0 ; loadGXP.pw = 9999 ;

put loadGXP 'Scenario' 'GXP' 'GXP description' 'Easting' 'Northing' 'Long' 'Lat' ; loop(y, put y.tl ) ;
loop((sc,gxp)$( sum((y,lb,m), load_GXP(sc,y,lb,gxp,m)) ),
  put / sc.tl, gxp.tl, gxp.te(gxp), GXPgeo(gxp,'Easting'), GXPgeo(gxp,'Northing'), GXPgeo(gxp,'Long'), GXPgeo(gxp,'Lat') ;
  loop(y,
    put ( sum((lb,m), load_GXP(sc,y,lb,gxp,m) ) ) ;
  ) ;
) ;





* End of file.
