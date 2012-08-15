* GEMldc.gms

* Last modified by Dr Phil Bishop, 15/08/2012 (imm@ea.govt.nz)

* NB: Aspects of this program require editing each time it is used - read the notes below.

$ontext
 GEMldc is an ad hoc piece of code. Its purpose is to create a LDC profile for use in GEM. More specifically,
 half-hourly, metered data by GXP is extracted from the CDS for an entire year, and is used to create a reference
 LDC profile. That profile is then used to allocate annual energy forecasts by GXP to the blocks of the desired
 LDC when creating a load file for GEM.

 This program only needs to be run whenever a new LDC or load file is required, i.e. this program is not run as
 part of the GEM invocation.

 Notes:
 1. The trading period nomenclature to deal with daylight saving is as per Gnash. That is, TPs 5 and 6 (i.e.
    2.00am-3.00am) are omitted on a short day, and TPs 4.5 and 5.5 are added on a long day.
 2. Preparing load by GXP data (e.g. ..\Data\GEM energy demand GDX\historical_GXP_load_data_Mar10.txt):
    a. Extract half-hourly data from Gnash to produce a file of load by GXP by trading period by day
       for a reference year:
       - seperate date field into 3 fields - year, month number, and day number (1st 3 cols of file).
       - 4th column (col D) is trading period number.
       - 5th column (col E) is GXP name.
       - 6th column (col F) is offtake in GWh.
       - note that this file will be quite big (~80+ MB and more than 3 million rows).
    b. Create a list of unique GXP names to be found in the file (~200).
    c. Count rows in GXP load file so you can check that you read it into GAMS completely, e.g. open the
       file using a text editor and note the row count.
    d. Put the following header row at the top of the load by GXP file:
       y	mn	d	tp	gxp	GWh
       Note that the header row and the file itself is delimited, with tabs in this case (altho' any delimiter
       will do).
    e. Using a text editor, put quotes around the trading period elements 4.5 and 5.5, the daylight saving period.
       In other words, replace the string <tab>4.5<tab> and <tab>5.5<tab> with <tab>"4.5"<tab> and <tab>"5.5"<tab>,
       respectively. In epsilon, a tab character is ^I, i.e. Ctrl-Q, Ctrl-I.

 Code sections:
  1. Take care of preliminaries.
  2. Install sets required to read in data and declare various parameters.
  3. Install the raw data and make adjustments.
     NB: This section may require editing by user
  4. Define a scheme for splitting each month into blocks of the LDC.
     NB: This section may require editing by user
     a) Put a fixed (user-specified) number of half hours into each block
     b) Distribute a (user-specified) percentage of national load to each block.
     c) Some other scheme yet to be defined...
  5. Sort/rank the national data, compute national and GXP LDCs, and perform some integrity checks.
  6. Assign load to blocks of LDC.
  7. Write various output files.
$offtext

$inlinecom { } eolcom !


*===============================================================================================
* 1. Take care of preliminaries.

$setglobal NumRows              3088735  ! Number of rows in raw data file.
$setglobal NumBlks              9        ! Specify the number of blocks in LDC.
$setglobal NumRecsYr            17520    ! Specify the maximum number of expected (d-tp) records per year
$setglobal NumRecsMth           1500     ! Specify the maximum number of expected (d-tp) records per month
$setglobal FirstYear            2008     ! Specify the first year the data covers (i.e. year need not be a calendar year)
$setglobal LastYear             2009     ! Specify the last year the data covers (i.e. year need not be a calendar year).

$setglobal Scheme               1        ! Choose a scheme for putting half hours into load blocks, i.e. defining width of load blocks:
                                         ! 1 = hard-code the number of HHs per load block - see code section 3a below.
                                         ! 2 = distribute a percentage of national load to each block - see code section 3b below.
                                         ! 3 = nothing as yet...

* Specify input file paths and names
$setglobal DataPath            "%system.fp%..\Data\GEM energy demand GDX\"
$setglobal OfftakeByGXPdata    "historical_GXP_load_data_Mar10.txt"
$setglobal FileOfGXPNames      "historical_GXP_list_Mar10.txt"
* Specify output file names
$setglobal LDCoutput           "LDC data (%NumBlks% blocks).gdx"



*===============================================================================================
* 2. Install sets required to read in data and declare various parameters.

Sets
  y               'Reference calendar years'                 / %FirstYear% * %LastYear% /
  tp              'Trading periods'                          / 1 * 4, '4.5', 5, '5.5', 6 * 48 /
  mn              'Reference month numbers'                  / 1 * 12 /
  d               'Reference days'                           / 1 * 31 /
  fy              'Fold into a single annual dimension'      / fy1 * fy%NumRecsYr% /
  f               'Fold into a single monthly dimension'     / f1  * f%NumRecsMth% /
  m               'Months'                                   / Jan   'January'
                                                               Feb   'February'
                                                               Mar   'March'
                                                               Apr   'April'
                                                               May   'May'
                                                               Jun   'June'
                                                               Jul   'July'
                                                               Aug   'August'
                                                               Sep   'September'
                                                               Oct   'October'
                                                               Nov   'November'
                                                               Dec   'December'  /
$ontext
* A 4 block regime
  lb              'Load blocks'                              / b1    'Peak block'
                                                               b2    'Top shoulder block'
                                                               b3    'A big fat baseload block'
                                                               b4    'Off-peak block' /
$offtext
*$ontext
* A 9 block regime
  lb              'Load blocks'                              / b1l   'Low wind top block'
                                                               b1w   'Windy top block'
                                                               b2l   'Low wind second block'
                                                               b2w   'Windy second block'
                                                               b3l   'Low wind third block'
                                                               b3w   'Windy third block'
                                                               b4    'Fourth block'
                                                               b5    'Fifth block'
                                                               b6    'Sixth/last block'  /
*$offtext
$ontext
* A 15 block regime
  lb              'Load blocks'                              / b1l   'Low wind top block'
                                                               b1w   'Windy top block'
                                                               b2l   'Low wind second block'
                                                               b2w   'Windy second block'
                                                               b3l   'Low wind third block'
                                                               b3w   'Windy third block'
                                                               b4l   'Low wind fourth block'
                                                               b4w   'Windy fourth block'
                                                               b9    'Ninth block'
                                                               b10   'Tenth block'
                                                               b11   'Eleventh block'
                                                               b12   'Twelfth block'
                                                               b13   'Thirteenth block'
                                                               b14   'Fourteenth block'
                                                               b15   'Fifteenth/last block'  /
$offtext
  mapm_mn(m,mn)        'Map month numbers to actual month labels'   / #m:#mn /
  msub(m)              'Subset of months (m) used in the current data file'
  mdt(m,d,tp)          '(m,d,tp)-tuples that are actually used'
  dt(d,tp)             '(d,tp)-tuples that are actually used'
  mf(m,f)              '(m,f)-tuples that are actually used'
  foldy(m,d,tp,fy)     'Mapping of set fy into (m,d,tp)-tuples for the year'
  fold(d,tp,f)         'Mapping of set f into (d,tp)-tuples for each month'
  mapwidth(m,lb,f)     'Map sorted half hours (indexed on f) to blocks in months'
  currentlb(m,lb)      'The current block of the current month' 
  missingblock(lb)     'The missing load block - see code section 3a'
  gxp                  'Grid exit points' /
$offlisting include   "%DataPath%%FileOfGXPNames%"
  /
  fixedwt(gxp)         'GXPs with known issues - make the block weights proportional to block width' /
*                       GXPs from the 1 Oct 2008 - 30 Sept 2009 HH'ly data
                        koe0331, twh0331, asb0661, aby0111, cyd0331, bwk1101, kmo0331, swn2201
                        sfd2201, kum0661, hwa1101, hwa1102, arg1101, kpa1101, ppi2201, wkm2201
                        mat1101, wwd1102, wwd1103
  / ;

Alias (m,mm), (lb,lbb), (f,ff) ;

Sets
  currentf(f)          'Identify the current element of set f'  / f1 /
  fmap(m,lb,f,ff)      'Map f to ff for each month-block tuple'
  actGXP(gxp)          'GXPs with data (after adjustments) associated with them'
  GXPlite(gxp,m)       'GXPs without any HHs in at least one block of at least one month'
  ;

*Display y, tp, mn, d, m, lb, fy, f, mapm_mn, gxp ;

Parameters 
  cntr1                          'A counter'
  cntr2(m)                       'A monthly counter'
  countRecords(*)                'Count records from various data arrays'
  TotalLoad(*)                   'Total load for entire reference year, GWh'
  GXPchecks(gxp,*)               'Various checks and counts by GXP'
  Sort3_NatChk(m)                'Check national data after sort3 and abort if there is an error'
  Sort3_GXPChk(gxp,m)            'Check GXP data after sort3 and abort if there is an error'

  NatLoadByHH(m,d,tp)            'National load for every half hour (or trading period) of each month of the year, GWh'
  NatLoadByHH_sort1(m,f)         'Sorted national load (in descending order) for each month, GWh'
  NatLoadByHHyr_sort1(fy)        'Sorted national load (in descending order) for entire year, GWh'
  NatLoadByHH_sort2(m,lb,f)      'National load per block of LDC, original f mapping, GWh'
  NatLoadByHH_sort3(m,lb,f)      'National load per block of LDC, condensed f mapping, GWh'

  GXPLoadByHH(gxp,m,d,tp)        'Load by GXP for every half hour (or trading period) of each month of the year, GWh'
  GXPLoadByHH_sort1(gxp,m,f)     'GXP load sorted (in order of national load) for each month of the year, GWh'
  GXPLoadByHH_sort2(gxp,m,lb,f)  'GXP load per block of LDC, original f mapping, GWh'
  GXPLoadByHH_sort3(gxp,m,lb,f)  'GXP load per block of LDC, condensed f mapping, GWh'

  i_HalfHrsPerBlk(m,lb)          'Count of half hours per block in each month'
  TargetLoad(m,lb)               'National load to be found in each block of LDC - use to get load shares by block'
  ThisTarget(m)                  'National load target in this month, GWh'
  ThisBlockLoad(m)               'National load in this block of the month, GWh'

  unsorted_yr(fy)                'Unsorted annual load data, GWh'
  unsorted(f)                    'Unsorted monthly load data, GWh'
  FYindex(fy)                    'The annual fold index'
  Findex(f)                      'The monthly fold index for a given month'
  KeepTrack(m,d,tp,f)            'Keep track of Findex value for each month of ranked national data'
  HHsPerNatBlock(m,lb)           'Half hours per block in monthly national LDC'
  HHsPerGXPBlock(gxp,m,lb)       'Half hours per block in monthly GXP LDC'

  BlockWeights(gxp,m,lb)         'Weight of energy per load block per month per GXP'
  CheckWeights(gxp,m)            'Weights must sum to one for each month and GXP'
  LoadShareByMonth(gxp,m)        'Share of load by month by GXP'
  ;

Files
  foldmap           'Elements of fold mapping'                                    / 'FoldSetsIntoOne_month.txt' /
  foldymap          'Elements of foldy mapping'                                   / 'FoldSetsIntoOne_year.txt' /
  natloadannual     'National annual load sorted and folded into a single index'  / 'National annual sorted load.csv' /
  natloadmonthly    'National monthly load sorted and folded into a single index' / 'National monthly sorted load.csv' /
  natloadmonthLDC   'National monthly load sorted into a LDC'                     / 'National monthly LDC.csv' /
  GXPloadmonthly    'GXP monthly load sorted and folded into a single index'      / 'GXP monthly sorted load.csv' /
  GXPloadmonthLDC   'GXP monthly load sorted into a LDC'                          / 'GXP monthly LDC.csv' /
  ;

foldmap.lw = 0 ;
foldymap.lw = 0 ;
natloadannual.pc = 5 ;     natloadannual.pw = 9999 ;
natloadmonthly.pc = 5 ;    natloadmonthly.pw = 9999 ;
natloadmonthLDC.pc = 5 ;   natloadmonthLDC.pw = 9999 ;
GXPloadmonthly.pc = 5 ;    GXPloadmonthly.pw = 9999 ;
GXPloadmonthLDC.pc = 5 ;   GXPloadmonthLDC.pw = 9999 ;

abort$( %NumBlks% <> card(lb) )        'The specified number of blocks does not match the set lb', '%NumBlks%', lb ;
abort$( %Scheme% < 1 or %Scheme% > 2 ) 'No such scheme exists with the number %Scheme%' ;



*===============================================================================================
* 3. Install the raw data and make adjustments.

* Load the raw data file
Table RawLoadbyGXP(y,mn,d,tp,gxp,*) 'Load by GXP'
$ondelim include "%DataPath%%OfftakeByGXPdata%"
$offdelim onlisting
  ;

countRecords('RawfileB4Adj') = sum((y,mn,d,tp,gxp)$RawLoadbyGXP(y,mn,d,tp,gxp,'GWh'), 1) ;
totalload('RawfileB4Adj')    = sum((y,mn,d,tp,gxp), RawLoadbyGXP(y,mn,d,tp,gxp,'GWh')) ;
abort$( countRecords('RawfileB4Adj') <> %NumRows% ) 'Raw data not imported properly' ;


* Make a few adjustments/tweaks:
*$ontext
* Tweaks for the 1 Oct 2008 - 30 Sept 2009 HH'ly data
RawLoadbyGXP(y,mn,d,tp,'lfd1101','GWh') = RawLoadbyGXP(y,mn,d,tp,'lfd1101','GWh') + RawLoadbyGXP(y,mn,d,tp,'lfd1102','GWh') ;
RawLoadbyGXP(y,mn,d,tp,'lfd1102','GWh') = 0 ;

RawLoadbyGXP(y,mn,d,tp,'oro1101','GWh') = RawLoadbyGXP(y,mn,d,tp,'oro1101','GWh') + RawLoadbyGXP(y,mn,d,tp,'oro1102','GWh') ;
RawLoadbyGXP(y,mn,d,tp,'oro1102','GWh') = 0 ;

RawLoadbyGXP(y,mn,d,tp,'rfn1101','GWh') = RawLoadbyGXP(y,mn,d,tp,'rfn1101','GWh') + RawLoadbyGXP(y,mn,d,tp,'rfn1102','GWh') ;
RawLoadbyGXP(y,mn,d,tp,'rfn1102','GWh') = 0 ;

RawLoadbyGXP(y,mn,d,tp,'wpr0331','GWh') = RawLoadbyGXP(y,mn,d,tp,'wpr0331','GWh') + RawLoadbyGXP(y,mn,d,tp,'wpr0661','GWh') ;
RawLoadbyGXP(y,mn,d,tp,'wpr0661','GWh') = 0 ;
*$offtext

countRecords('RawfileAftAdj') = sum((y,mn,d,tp,gxp)$RawLoadbyGXP(y,mn,d,tp,gxp,'GWh'), 1) ;
totalload('RawfileAftAdj')    = sum((y,mn,d,tp,gxp), RawLoadbyGXP(y,mn,d,tp,gxp,'GWh')) ;



*===============================================================================================
* 4. Define a scheme for splitting each month into blocks of the LDC.

* a) Put a fixed (user-specified) number of half hours into each block
*    Edit 'InitialHHsPerBlk' according to blocks specified in set 'lb'.
*    Leave one (and only one!) block in the middle (flat part) of the LDC with zero HHs (residual HHs will be assigned automatically to this block).

* A 4 block regime
*Parameter InitialHHsPerBlk(lb) 'Number of half hour trading periods in each block' /
*  b1  1,   b2  100,   b3  0,   b4 300  / ;

* A 9 block regime
Parameter InitialHHsPerBlk(lb) 'Number of half hour trading periods in each block' /
  b1l  1,   b1w  3,   b2l 12,   b2w 36,   b3l 40,   b3w 120,   b4  0,   b5 400,   b6 160  / ;

* A 15 block regime
*Parameter InitialHHsPerBlk(lb) 'Number of half hour trading periods in each block' /
*  b1l  1,   b1w  3,   b2l 2,    b2w 6,    b3l 4,    b3w 12,   b4l 8,   b4w 24,   b9 100
*  b10 200,  b11 300,  b12 0,    b13 300,  b14 100,  b15 50  / ;

loop(lb$( InitialHHsPerBlk(lb) = 0 ), missingblock(lb) = yes ) ;
abort$( card(missingblock) <> 1 ) 'There must be only one load block with zero HHs assigned to it', InitialHHsPerBlk ;
abort$( sum(lb, InitialHHsPerBlk(lb)) > 16000/12 ) 'Not enough HHs left in the year to allocate to the missing block', InitialHHsPerBlk ;
i_HalfHrsPerBlk(m,lb) = InitialHHsPerBlk(lb) ;



* b) Distribute a (user-specified) percentage of national load to each block.
* A 4 block regime
*Parameter width(lb) 'Percentage in each block'  /
*  b1 1,   b2 5,   b3 84,   b4 10 / ;
*width('b3') = 0 ;
*width('b3') = 100 - sum(lb, width(lb)) ;

* A 9 block regime
Parameter width(lb) 'Percentage in each block'  /
  b1l 11,   b1w 11,   b2l 11,   b2w 11,   b3l 11,   b3w 12,   b4 11,   b5 11,   b6 11  / ;

* A 15 block regime
*Parameter width(lb) 'Percentage in each block'  / (b1l,b1w,b2l,b2w,b3l,b3w,b4l,b4w,b9,b10,b11,b12,b13,b14,b15) 5 / ;
*width('b12') = 0 ;
*width('b12') = 100 - sum(lb, width(lb)) ;

* Normalize width of blocks such that sum of all widths adds up to 1.0
Scalar sumwidth ; sumwidth = sum(lb, width(lb)) ;
width(lb) = width(lb) / sumwidth ;



* c) Some other scheme yet to be defined...



*===============================================================================================
* 5. Sort/rank the national data, compute national and GXP LDCs, and perform some integrity checks.

* Drop the year index and change month number to month label.
GXPLoadByHH(gxp,m,d,tp) = sum((y,mn)$mapm_mn(m,mn), RawLoadbyGXP(y,mn,d,tp,gxp,'GWh')) ;

* Figure out which GXPs actually have data associated with them.
actGXP(gxp)$sum((m,d,tp), GXPLoadByHH(gxp,m,d,tp)) = yes ;

* Figure out share of load by month by GXP.
LoadShareByMonth(gxp,m)$sum((mm,d,tp), GXPLoadByHH(gxp,mm,d,tp)) = sum((d,tp), GXPLoadByHH(gxp,m,d,tp)) / sum((mm,d,tp), GXPLoadByHH(gxp,mm,d,tp)) ;

* Sum over all GXPs to get national load
NatLoadByHH(m,d,tp) = sum(actGXP(gxp), GXPLoadByHH(gxp,m,d,tp)) ;

* Figure out which months are in use.
msub(m)$sum((d,tp), NatLoadByHH(m,d,tp)) = yes ;

* Figure out which month-day-trading period combos and day-trading period combos are in use.
mdt(m,d,tp)$NatLoadByHH(m,d,tp) = yes ;
dt(d,tp)$sum(m, NatLoadByHH(m,d,tp)) = yes ;

* Form the set foldy and fold.
option foldy(mdt:fy) ;
option fold(dt:f) ;

* Create sorted national annual data - only need this so that the full annual LDC can be plotted.
unsorted_yr(fy) = sum(foldy(mdt,fy), NatLoadByHH(mdt)) ;
$libinclude rank unsorted_yr fy fyindex
NatLoadByHHyr_sort1(fy + (card(fy) + 1 - fyindex(fy) - ord(fy))) = unsorted_yr(fy) ;

* Sort the national load by month. Then sort the load by GXP according to the national monthly ranking.
$libinclude rank
loop(msub(m),
* Rank national data for each month ready for sorting
  unsorted(f) = sum(fold(dt,f), NatLoadByHH(m,dt)) ;
$ libinclude rank unsorted f findex
  KeepTrack(m,fold(dt,f)) = findex(f) ;
* Sort national data for each month
  NatLoadByHH_sort1(m,f + (card(f) + 1 - findex(f) - ord(f))) = sum(fold(dt,f), NatLoadByHH(m,dt)) ;
* Sort GXP data according to order of national data
  GXPLoadByHH_sort1(gxp,m,f + (card(f) + 1 - findex(f) - ord(f))) = sum(fold(dt,f), GXPLoadByHH(gxp,m,dt)) ;
) ;

* Figure out which (m,f)-tuples are actually used.
mf(m,f)$NatLoadByHH_sort1(m,f) = yes ;

* Perform integrity checks.
countRecords('byGXPHH')  = sum((gxp,m,d,tp)$GXPLoadByHH(gxp,m,d,tp), 1) ;
countRecords('NatHH')    = sum((m,d,tp)$NatLoadByHH(m,d,tp), 1) ;
countRecords('NatSort1') = sum((m,f)$NatLoadByHH_sort1(m,f), 1) ;
countRecords('NumGXPs')  = card(gxp) ;
countRecords('GXPwData') = card(actGXP) ;

totalload('byGXPHH')  = sum((gxp,m,d,tp), GXPLoadByHH(gxp,m,d,tp)) ;
totalLoad('NatHH')    = sum((m,d,tp), NatLoadByHH(m,d,tp)) ;
totalload('NatSort1') = sum((m,f), NatLoadByHH_sort1(m,f)) ;

GXPchecks(gxp,'rawGWh')    = sum((m,d,tp), GXPLoadByHH(gxp,m,d,tp)) ;
GXPchecks(gxp,'Sort1')     = sum((m,f), GXPLoadByHH_sort1(gxp,m,f)) ;
GXPchecks(gxp,'diffSort1') = GXPchecks(gxp,'rawGWh') - GXPchecks(gxp,'Sort1') ; 
GXPchecks(gxp,'diffSort1')$( abs(GXPchecks(gxp,'diffSort1')) < 1.0e-5 ) = 0 ;



*===============================================================================================
* 6. Assign load to blocks of LDC.

* Compute HHs per load block if scheme 1 is to be used.
* Partition 'f' into blocks such that each block contains a prescribed number of half hours.
$if not %scheme%==1 $goto NoFixNber
i_HalfHrsPerBlk(m,missingblock) = sum(mf(m,f), 1) - sum(lb, InitialHHsPerBlk(lb)) ;
cntr1 = 0 ; cntr2(m) = 0 ;
loop((m,lb),
  loop(mf(m,f)$( (cntr1 < i_HalfHrsPerBlk(m,lb)) * (ord(f) > cntr2(m)) ),
    cntr1 = cntr1 + 1 ;
    cntr2(m) = cntr2(m) + 1 ;
    mapwidth(m,lb,f) = yes ;
  ) ;
  cntr1 = 0 ;
) ;
$label NoFixNber

* Compute HHs per load block if scheme 2 is to be used.
* Partition 'f' into blocks such that national load in each block is ~( width(lb) * TargetLoad(m,lb) ).
$if not %scheme%==2 $goto NoFixLoadPropn
TargetLoad(m,lb) = width(lb) * sum((d,tp), NatLoadByHH(m,d,tp)) ;
currentlb(msub,lb)$( ord(lb) = 1 ) = yes ;
ThisTarget(m) = sum(currentlb(m,lb),TargetLoad(m,lb));
loop(f$sum(m, NatLoadByHH_sort1(m,f)),
  mapwidth(currentlb,f) = yes ;
  ThisBlockLoad(m) = sum(mapwidth(m,lb,ff)$currentlb(m,lb), NatLoadByHH_sort1(m,ff)) ;
  loop(m$( ThisBlockLoad(m) > ThisTarget(m) + 1.0e-5 ),
    currentlb(m,lb) = currentlb(m,lb-1) ;
    ThisTarget(m) = sum(currentlb(m,lb), TargetLoad(m,lb)) ;
  ) ;
) ;
$label NoFixLoadPropn

* Do a little stocktake/check when devising new load block schemes.
Parameter numHHsPerMonth(m,*)  'Number of HHs per month according to various measures' ;
numHHsPerMonth(m,'mf')        = sum(mf(m,f), 1) ;
numHHsPerMonth(m,'HHsPerBlk') = sum(lb, i_HalfHrsPerBlk(m,lb)) ;
numHHsPerMonth(m,'MapWidth')  = sum(mapwidth(m,lb,f), 1) ;
Display width, i_HalfHrsPerBlk, numHHsPerMonth ;
*$stop

* Assign sorted national and GXP load to blocks within the month.
NatLoadByHH_sort2(m,lb,f)     = sum(mapwidth(m,lb,f), NatLoadByHH_sort1(m,f)) ;
GXPLoadByHH_sort2(gxp,m,lb,f) = sum(mapwidth(m,lb,f), GXPLoadByHH_sort1(gxp,m,f)) ;

* NB: the fmap and sort3 stuff is only helpful for creating LDC plots. The block weights
*     could just as easily be created from the sort2 results.
 
* Establish a mapping between f and ff to facilitate a move from the original f mapping to the condensed f mapping.
loop((m,lb)$sum(f, NatLoadByHH_sort2(m,lb,f)),
  currentf(currentf) = no ;
  currentf(f)$( ord(f) = 1 ) = yes;
  loop(f$NatLoadByHH_sort2(m,lb,f),
    fmap(m,lb,f,currentf) = yes ;
    currentf(ff) = currentf(ff-1) ;
  ) ;
) ;

* Assign sorted national and GXP load to blocks within the month - according to condensed f mapping.
NatLoadByHH_sort3(m,lb,ff)     = sum(fmap(m,lb,f,ff), NatLoadByHH_sort2(m,lb,f)) ;
GXPLoadByHH_sort3(gxp,m,lb,ff) = sum(fmap(m,lb,f,ff), GXPLoadByHH_sort2(gxp,m,lb,f)) ;

BlockWeights(gxp,m,lb)$sum((lbb,f), GXPLoadByHH_sort3(gxp,m,lbb,f)) = sum(f, GXPLoadByHH_sort3(gxp,m,lb,f)) / sum((lbb,f), GXPLoadByHH_sort3(gxp,m,lbb,f)) ;

* Overwrite block weights for selected GXPs.
BlockWeights(fixedwt(gxp),m,lb)$sum((f,lbb)$mapwidth(m,lbb,f), 1) = sum(f$mapwidth(m,lb,f), 1) / sum((f,lbb)$mapwidth(m,lbb,f), 1) ;

CheckWeights(gxp,m) = sum(lb, BlockWeights(gxp,m,lb)) ;

* Perform more integrity checks.
HHsPerNatBlock(m,lb)     = sum(mapwidth(m,lb,f), 1) ;
HHsPerGXPBlock(gxp,m,lb) = sum(f$GXPLoadByHH_sort3(gxp,m,lb,f), 1) ;

countRecords('NatSort2') = sum((m,lb,f)$NatLoadByHH_sort2(m,lb,f), 1) ;
countRecords('NatSort3') = sum((m,lb,f)$NatLoadByHH_sort3(m,lb,f), 1) ;

totalload('NatSort2') = sum((m,lb,f), NatLoadByHH_sort2(m,lb,f)) ;
totalload('NatSort3') = sum((m,lb,f), NatLoadByHH_sort3(m,lb,f)) ;
totalload('GXPsort1') = sum((gxp,m,f), GXPLoadByHH_sort1(gxp,m,f)) ;
totalLoad('GXPsort2') = sum((gxp,m,lb,f), GXPLoadByHH_sort2(gxp,m,lb,f)) ;
totalload('GXPsort3') = sum((gxp,m,lb,f), GXPLoadByHH_sort3(gxp,m,lb,f)) ;

GXPchecks(gxp,'Sort2')     = sum((m,lb,f), GXPLoadByHH_sort2(gxp,m,lb,f)) ;
GXPchecks(gxp,'Sort3')     = sum((m,lb,f), GXPLoadByHH_sort3(gxp,m,lb,f)) ;
GXPchecks(gxp,'diffSort2') = GXPchecks(gxp,'rawGWh') - GXPchecks(gxp,'Sort2') ; 
GXPchecks(gxp,'diffSort3') = GXPchecks(gxp,'rawGWh') - GXPchecks(gxp,'Sort3') ; 
GXPchecks(gxp,'diffSort2')$( abs(GXPchecks(gxp,'diffSort2')) < 1.0e-5 ) = 0 ;
GXPchecks(gxp,'diffSort3')$( abs(GXPchecks(gxp,'diffSort3')) < 1.0e-5 ) = 0 ;

Option FYindex:0, countRecords:0, totalload:0, GXPchecks:0 ;
*Display msub, FYindex, GXPchecks, countRecords, totalload  ;

* Figure out which GXPs have no HHs in at least one load block of at least one month.
loop((gxp,m,lb),
  GXPlite(gxp,m)$( BlockWeights(gxp,m,lb) = 0 ) = yes ;
) ;

* Abort if sort 3 data doesn't add up to what we started with.
Sort3_NatChk(m) = sum((lb,f), NatLoadByHH_sort3(m,lb,f)) - sum(dt, NatLoadByHH(m,dt)) ;
Sort3_GXPChk(gxp,m) = sum((lb,f), GXPLoadByHH_sort3(gxp,m,lb,f)) - sum(dt, GXPLoadByHH(gxp,m,dt)) ;
abort$( sum(m, abs(Sort3_NatChk(m))) > 1.0e-5 )           'Should be close to zero', Sort3_NatChk ;
abort$( sum((gxp,m), abs(Sort3_GXPChk(gxp,m))) > 1.0e-5 ) 'Should be close to zero', Sort3_GXPChk ;

* Abort if a single GXP has no HHs in any month for the missing load block.
loop((gxp,m,missingblock(lb))$HHsPerGXPBlock(gxp,m,lb),
  abort$( HHsPerGXPBlock(gxp,m,lb) < 1 ) 'At least one GXP with load has no HHs assigned to the (big) missing block', HHsPerGXPBlock ;
) ;



*===============================================================================================
* 7. Write various output files.

Execute_Unload "%LDCoutput%", gxp, m, lb, mapm_mn, msub, mdt, dt, mf, foldy, fold, fmap, FYindex, KeepTrack, mapwidth
  BlockWeights, CheckWeights, LoadShareByMonth, i_HalfHrsPerBlk, GXPchecks, GXPlite, fixedwt, countRecords, totalload, Sort3_NatChk, Sort3_GXPChk
  HHsPerNatBlock, HHsPerGXPBlock, NatLoadByHHyr_sort1, NatLoadByHH, NatLoadByHH_sort1, NatLoadByHH_sort2, NatLoadByHH_sort3
  GXPLoadByHH, GXPLoadByHH_sort1, GXPLoadByHH_sort2, GXPLoadByHH_sort3 ;

put natloadannual 'FY', 'FYindex' 'GWh' ;
loop(fy$NatLoadByHHyr_sort1(fy),
  put / fy.tl, FYindex(fy), NatLoadByHHyr_sort1(fy) ;
) ;

put natloadmonthly 'Month', 'F', 'New Zealand' ;
loop((m,f)$NatLoadByHH_sort1(m,f),
  put / m.tl, f.tl, NatLoadByHH_sort1(m,f) ;
) ;

* This...
*put natloadmonthly 'F' ; loop(m, put m.tl ) ;
*loop(f$sum(m, NatLoadByHH_sort1(m,f)),
*  put / f.tl ; loop(m, put NatLoadByHH_sort1(m,f)) ;
*) ;
* or this...
*put natloadmonthly 'F' 'GWh' 'Month' 'day' 'TP' 'Findex';
*loop((m,d,tp,f)$( KeepTrack(m,d,tp,f) * NatLoadByHH_sort1(m,f) ),
*  put / f.tl, NatLoadByHH_sort1(m,f), m.tl, d.tl, tp.tl, KeepTrack(m,d,tp,f) ;
*) ;

put natloadmonthLDC 'Month' ; loop(lb, put lb.tl ) ;
loop((m,f)$sum(lb, NatLoadByHH_sort2(m,lb,f)),
  put / m.tl, loop(lb, if(NatLoadByHH_sort2(m,lb,f), put NatLoadByHH_sort2(m,lb,f) else put '' ) ) ;
) ;

put GXPloadmonthly 'Month' 'F' ; loop(gxp, put gxp.tl ) ;
loop((m,f)$sum(gxp, GXPLoadByHH_sort1(gxp,m,f)),
  put / m.tl, f.tl ;
  loop(gxp, put GXPLoadByHH_sort1(gxp,m,f) ) ;
) ;

$stop
put GXPloadmonthLDC 'GXP' 'Month' ; loop(lb, put lb.tl ) ;
loop((gxp,m,f)$sum(lb, GXPLoadByHH_sort2(gxp,m,lb,f)),
  put / gxp.tl, m.tl ;
  loop(lb, if(GXPLoadByHH_sort2(gxp,m,lb,f), put GXPLoadByHH_sort2(gxp,m,lb,f) else put '' ) ) ;
) ;

* Write out set 'fold' to a text file - mapping of days and trading periods to a unidimensinal set called f.
put foldmap loop(fold(d,tp,f), put d.tl, ".'", tp.tl, "'.", f.tl / ) ; 

* Write out set 'foldy' to a text file - mapping of months, days and trading periods to a unidimensinal set called fy.
put foldymap loop(foldy(m,d,tp,fy), put m.tl, '.', d.tl, ".'", tp.tl, "'.", fy.tl / ) ; 





* End of file.
