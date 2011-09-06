* GEMdata.gms


* Last modified by Dr Phil Bishop, 06/09/2011 (imm@ea.govt.nz)


** To do:
** See comment on line #469, i.e. "Should this next line be ord or card?"
** Formalise/fix up the override stuff once we get GEM back into emi.


$ontext
 This program prepares the data for a single run of GEM (note that a GEM run may comprise many experiments and
 scenarios). GEMdata imports the input data from GDX files, undertakes some manipulations, transformations, and
 performs integrity checks. It finishes by writing out some input data summary tables.

 The GEMdata invocation requires GEMdata to be restarted from the GEMdeclarations work file. The files
 called GEMpaths.inc, GEMsettings.inc and GEMstochastic.inc are included into GEMdata. The GEMdata work
 file is saved and used to restart GEMsolve. GEMsolve is invoked immediately after GEMdata.

 Code sections:
  1. Take care of a few preliminaries.
  2. Load input data that comes from the input GDX files (or the paths/settings include files).
  3. Initialise sets and parameters.
     a) Time/date-related sets and parameters.
     b) Various mappings, subsets and counts.
     c) Financial parameters.
     d) Generation data.
     e) Transmission data.
     f) Reserve energy data.
  4. Prepare the outcome-dependent input data; key user-specified settings are obtained from GEMstochastic.inc.
  5. Display sets and parameters.
  6. Create input data summaries.
$offtext



*===============================================================================================
* 1. Take care of a few preliminaries.

* Track memory usage.
* Higher numbers are for more detailed information inside loops. Alternatively, on the command line, type: gams xxx profile=1
*option profile = 1 ;
*option profile = 2 ;
*option profile = 3 ;

option seed = 101 ;
$include GEMpaths.inc
$include GEMsettings.inc

* Turn the following stuff on/off as desired.
*$offupper onempty inlinecom { } eolcom !
$offuelxref offuellist	
*$onuelxref  onuellist	
$offsymxref offsymlist
*$onsymxref  onsymlist

* Create and execute a batch file to archive/save selected files.
File bat "A recyclable batch file" / "%ProgPath%temp.bat" / ; bat.lw = 0 ; bat.ap = 0 ;
putclose bat
  'copy "%DataPath%%GEMinputGDX%"       "%OutPath%\%runName%\Archive\"' /
  'copy "%DataPath%%GEMnetworkGDX%"     "%OutPath%\%runName%\Archive\"' /
  'copy "%DataPath%%GEMdemandGDX%"      "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%GEMpaths.inc"        "%OutPath%\%runName%\Archive\GEMpaths - %runVersionName%.inc"' /
  'copy "%ProgPath%GEMsettings.inc"     "%OutPath%\%runName%\Archive\GEMsettings.inc"' /
  'copy "%ProgPath%GEMstochastic.inc"   "%OutPath%\%runName%\Archive\GEMstochastic.inc"' / ;
execute 'temp.bat' ;



*===============================================================================================
* 2. Load input data that comes from the input GDX files (or the paths/settings include files).
*    NB: Some symbols in the input GDX files are defined on years that may extend beyond %firstYear% and %lastYear%.
*        Hence, those symbols must be loaded without domain checking, i.e. $load c.f. $loaddc.

Set y  / %firstYear% * %lastYear% / ;

* Load the 109 network invariant symbols from GEMinputGDX.
$gdxin "%DataPath%%GEMinputGDX%"
* Sets
$loaddc k f fg g o i e tgc t lb rc hY v
$loaddc mapf_k mapf_fg techColor fuelColor fuelGrpColor movers refurbish endogRetire cogen peaker hydroSched hydroPumped
$loaddc wind renew thermalTech minUtilTechs demandGen randomiseCapex linearBuildTech coal lignite gas diesel
$loaddc mapGenPlant exist
$loaddc Haywards Benmore zoneCentroid islandCentroid
$loaddc mapm_t
$loaddc mapReservoirs
* Parameters 
$loaddc i_plantLife i_refurbishmentLife i_retireOffsetYrs i_linearBuildMW i_linearBuildYr i_depRate
$loaddc i_peakContribution i_NWpeakContribution i_capFacTech i_FOFmultiplier i_maxNrgByFuel i_emissionFactors
$load   i_minUtilByTech i_fuelPrices i_fuelQuantities i_co2tax
$loaddc i_nameplate i_UnitLargestProp i_baseload i_minUtilisation i_offlineReserve i_FixComYr i_EarlyComYr i_ExogenousRetireYr i_refurbDecisionYear
$loaddc i_fof i_heatrate i_PumpedHydroMonth i_PumpedHydroEffic i_minHydroCapFact i_maxHydroCapFact i_fixedOM i_varOM i_FuelDeliveryCost
$loaddc i_capitalCost i_connectionCost i_refurbCapitalCost i_plantReservesCap i_plantReservesCost i_PltCapFact
$loaddc i_HVDCshr
$load   i_renewNrgShare i_renewCapShare i_distdGenRenew i_distdGenFossil
$loaddc i_substnCoordinates i_zonalLocFacs
$load   i_HVDClevy
$load   i_firstDataYear i_lastDataYear i_HalfHrsPerBlk i_inflation
$loaddc i_ReserveSwitch i_ReserveAreas i_propWindCover i_ReservePenalty
$load   i_reserveReqMW i_fkNI i_largestGenerator i_smallestPole i_winterCapacityMargin i_P200ratioNZ i_P200ratioNI
$load   i_firstHydroYear i_historicalHydroOutput

* Load the 22 region/network-related symbols from GEMnetworkGDX.
$gdxin "%DataPath%%GEMnetworkGDX%"
* Sets
$loaddc s r p ps tupg maps_r mapLocations regionCentroid txUpgradeTransitions mapArcNode
* Parameters 
$loaddc i_VOLLcap i_VOLLcost
$loaddc i_txCapacity i_txCapacityPO i_txResistance i_txReactance i_txCapitalCost i_maxReservesTrnsfr
$loaddc i_txEarlyComYr i_txFixedComYr i_txGrpConstraintsLHS i_txGrpConstraintsRHS

* Load the energy demand from GEMdemandGDX.
$gdxin "%DataPath%%GEMdemandGDX%"
$load   i_NrgDemand

* Initialise set 'n' - data comes from GEMsettings.inc.
Set n 'Piecewise linear vertices' / n1 * n%NumVertices% / ;

*$ontext
** Data overrides:
** mds1, mds2 and mds5 override 3 params: i_fuelPrices, i_fuelQuantities and i_co2tax.
** mds4 overrides 1 params: i_co2tax.
Parameters
  i_fuelPricesOvrd(f,y)           'Fuel prices by fuel type and year, $/GJ'
  i_fuelQuantitiesOvrd(f,y)       'Quantitative limit on availability of various fuels by year, PJ'
  i_co2taxOvrd(y)                 'CO2 tax by year, $/tonne CO2-equivalent'
  ;

$gdxin "%DataPath%%GEMoverrideGDX%"
$load   i_fuelPricesOvrd i_fuelQuantitiesOvrd i_co2taxOvrd
*$load   i_co2taxOvrd
if(sum((f,y), i_fuelPricesOvrd(f,y)), i_fuelPrices(f,y) = 0 ) ;         i_fuelPrices(f,y) = i_fuelPricesOvrd(f,y) ;
if(sum((f,y), i_fuelQuantitiesOvrd(f,y)), i_fuelQuantities(f,y) = 0 ) ; i_fuelQuantities(f,y) = i_fuelQuantitiesOvrd(f,y) ;
if(sum(y, i_co2taxOvrd(y)), i_co2tax(y) = 0 ) ;                         i_co2tax(y) = i_co2taxOvrd(y) ;
*$offtext



*===============================================================================================
* 3. Initialise sets and parameters.

* a) Time/date-related sets and parameters.
firstYear = %firstYear% ;
lastYear = %lastYear% ;

firstYr(y)$(ord(y) = 1) = yes ;
lastYr(y)$(ord(y) = card(y)) = yes ;

allButFirstYr(y)$(not firstYr(y)) = yes ;

yearNum(y) = firstYear + ord(y) - 1 ;

firstPeriod(t)$( ord(t) = 1 ) = yes ;

* Abort if modelled years are not a subset of data years.
abort$( %firstYear% < i_firstDataYear ) "First modelled year precedes first data year",        i_firstDataYear, firstYr ;
abort$( %lastYear%  > i_lastDataYear )  "Last modelled year is later than the last data year", i_lastDataYear, lastYr ;

* Denote each hydro year set element with a real number corresponding to that year, i.e. 1932 = 1932, 1933 = 1933,...2002 = 2002, etc.
hydroYearNum(hY) = i_firstHydroYear + ord(hY) - 1 ;

lastHydroYear = sum(hY$( ord(hY) = card(hY) ), hydroYearNum(hY)) ;


* Count hours per load block per time period.
hoursPerBlock(t,lb) = sum(mapm_t(m,t), 0.5 * i_HalfHrsPerBlk(m,lb)) ;


* b) Various mappings, subsets and counts.
* Location mappings
loop(maplocations(i,r,e,ild),
  mapi_r(i,r) = yes ;
  mapi_e(i,e) = yes ;
  mapild_r(ild,r) = yes ;
) ;
mapAggR_r('nz',r) = yes ;
mapAggR_r('ni',r) = yes$sum(mapild_r('ni',r), 1) ;
mapAggR_r('si',r) = yes$sum(mapild_r('si',r), 1) ;
* Generation plant mappings
loop(mapgenplant(g,k,i,o),
  mapg_k(g,k) = yes ;
  mapg_o(g,o) = yes ;
  mapg_i(g,i) = yes ;
) ;
mapg_f(g,f)     = yes$sum(mapg_k(g,k), mapf_k(f,k) ) ;
mapg_r(g,r)     = yes$sum(mapg_i(g,i), mapi_r(i,r) ) ;
mapg_e(g,e)     = yes$sum(mapg_i(g,i), mapi_e(i,e) ) ;
mapg_ild(g,ild) = yes$sum(mapg_r(g,r), mapild_r(ild,r) ) ;
* Reservoir mappings
loop(mapreservoirs(v,i,g),
  mapv_g(v,g) = yes ;
) ;
* Fuel mappings
loop((f,fg,thermalTech(k))$( mapf_fg(f,fg) * mapf_k(f,k) ), thermalFuel(f) = yes ) ;

* Count number of regions
numreg = card(r) ;

* Identify generation plant types
loop(hydroSched(k),  schedHydroPlant(g)$mapg_k(g,k) = yes ) ;
loop(hydroPumped(k), pumpedHydroPlant(g)$mapg_k(g,k) = yes ) ;


* c) Financial parameters.
CBAdiscountRates('WACCg') = WACCg ;
CBAdiscountRates('WACCt') = WACCt ;
CBAdiscountRates('dLow')  = discRateLow ;
CBAdiscountRates('dMed')  = discRateMed ;
CBAdiscountRates('dHigh') = discRateHigh ;

PVfacG(y,t) = 1 / ( 1 + WACCg ) ** ( (yearNum(y) - firstYear) + (ord(t) * 2 - 1) / ( 2 * card(t) ) ) ;

PVfacT(y,t) = 1 / ( 1 + WACCt ) ** ( (yearNum(y) - firstYear) + (ord(t) * 2 - 1) / ( 2 * card(t) ) ) ;

PVfacsM(y,t,d) = 1 / ( 1 + CBAdiscountRates(d) ) ** ( (yearNum(y) - firstYear) + (ord(t) * 2 - 1) / ( 2 * card(t) ) ) ;

PVfacsEY(y,d)  = 1 / ( 1 + CBAdiscountRates(d) ) ** (  yearNum(y) - firstYear + 1 ) ;

PVfacs(y,t,d,'mid') = PVfacsM(y,t,d) ;
PVfacs(y,t,d,'eoy') = PVfacsEY(y,d) ;

capexLife(k,'genplt') = i_plantLife(k) ;
capexLife(k,'refplt') = i_refurbishmentLife(k) ;

annuityFacN(y,k,ct)$WACCg = ( 1 - ( 1 + WACCg + i_inflation(y) ) ** (-capexLife(k,ct)) ) / WACCg ;

annuityFacR(k,ct)$WACCg   = ( 1 - ( 1 + WACCg ) ** (-capexLife(k,ct)) ) / WACCg ;

TxAnnuityFacN(y) = ( 1 - ( 1 + WACCt + i_inflation(y) ) ** (-txPlantLife) ) / WACCt ;
TxAnnuityFacR =    ( 1 - ( 1 + WACCt ) ** (-txPlantLife) ) / WACCt ;

* depType = 0 implies straight line depreciation; depType = 1 implies a declining balance method.
if(depType = 0,
  capRecFac(y,k,ct)$annuityFacR(k,ct)   = ( 1 - taxRate * annuityFacN(y,k,ct) / capexLife(k,ct) )  / annuityFacR(k,ct) ;
  depTCrecFac(y,k,ct)$annuityFacR(k,ct) =     ( taxRate * annuityFacN(y,k,ct) / capexLife(k,ct) )  / annuityFacR(k,ct) ;
  txCapRecFac(y)$txAnnuityFacR          = ( 1 - taxRate * txAnnuityFacN(y)    / txPlantLife )    / txAnnuityFacR ;
  txDepTCrecFac(y)$txAnnuityFacR        =     ( taxRate * txAnnuityFacN(y)    / txPlantLife )    / txAnnuityFacR ;
  else
  capRecFac(y,k,ct)$annuityFacR(k,ct)   = ( 1 - i_depRate(k) * taxRate / (WACCg + i_inflation(y) + i_depRate(k)) ) / annuityFacR(k,ct) ;
  depTCrecFac(y,k,ct)$annuityFacR(k,ct) =     ( i_depRate(k) * taxRate / (WACCg + i_inflation(y) + i_depRate(k)) ) / annuityFacR(k,ct) ;
  txCapRecFac(y)$txAnnuityFacR          = ( 1 - txDepRate    * taxRate / (WACCt + i_inflation(y) + txDepRate) )    / txAnnuityFacR ;
  txDepTCrecFac(y)$txAnnuityFacR        =     ( txDepRate    * taxRate / (WACCt + i_inflation(y) + txDepRate) )    / txAnnuityFacR ;
) ;



* d) Generation data.
* Derive various generating plant subsets.
* i) Existing plant - remove any plant where i_nameplate(g) = 0 from exist(g).
exist(g)$( i_nameplate(g) = 0 ) = no ;

* ii) A plant is not an existing plant if it hasn't been defined to be existing - remove any plant where i_nameplate(g) = 0 from noExist(g).
noExist(g)$( not exist(g) ) = yes ;
noExist(g)$( i_nameplate(g) = 0 ) = no ;

* iii) Define plant that are never able to be built. A plant is never to be built if it already exists, if (i_fixComYr or i_EarlyComYr) > lastYear,
* or if i_nameplate <= 0.
neverBuild(noExist(g))$( (i_fixComYr(g) > lastYear) or (i_EarlyComYr(g) > lastYear) ) = yes ;
neverBuild(g)$( i_nameplate(g) <= 0 ) = yes ;

* iv) Define committed plant. To be a committed plant, the plant must not exist, it must not be in the neverBuild set, and
* it must have a fixed commissioning year that is greater than or equal to the first modelled year.
commit(noExist(g))$( (i_fixComYr(g) >= firstYear) * (not neverBuild(g)) ) = yes ;

* v) Define new plant. A plant is (potentially) new if it is not existing, not committed, and not a member of the neverBuild set.
new(noExist(g))$( not ( commit(g) or neverBuild(g) ) ) = yes ;

* vi) Define the years in which it is valid for a generating plant to be built. The plant must either be committed or (potentially)
* new, and the plant can't be a member of the neverBuild set
validYrBuild(commit(g),y)$( yearNum(y) = i_fixComYr(g) ) = yes ;
validYrBuild(new(g),y)$( yearNum(y) >= i_EarlyComYr(g) ) = yes ;
validYrBuild(neverBuild(g),y) = no ;

* vii) Identify the plant that may be built, i.e. it doesn't already exist or it is not otherwise prevented from being built.
possibleToBuild(g)$sum(y$validYrBuild(g,y), 1) = yes ;

* viii) Identify generation plant that can be linearly or incrementally built.
loop((g,k)$( noExist(g) * linearBuildTech(k) * mapg_k(g,k) * ( not i_fixComYr(g) ) ),
  linearPlantBuild(g)$( i_nameplate(g) >= i_linearBuildMW(k) ) = yes ;
  linearPlantBuild(g)$( i_EarlyComYr(g) >= i_linearBuildYr(k) ) = yes ;
) ;

* ix) Identify generation plant that must be integer build (must be integer if not linear).
integerPlantBuild(noExist(g))$( not linearPlantBuild(g) ) = yes ;
integerPlantBuild(neverBuild(g)) = no ;

* x) Identify exceptions to the technology-determined list of plant movers, i.e. if user fixes build year to a legitimate value, then
* don't allow the plant to be a mover.
loop(movers(k), moverExceptions(noExist(g))$( mapg_k(g,k) * ( i_fixComYr(g) >= firstYear ) * ( i_fixComYr(g) <= lastYear ) ) = yes ) ;

* xi) Define the years in which it is valid for a generating plant to operate. The plant must exist; if plant is committed, it is valid to
* operate it in any year beginning with the year in which it is commissioned; if plant is new, it is valid to operate it in any year beginning
* with the earliest year in which it may be commissioned; it is not valid to operate any plant that has come to the end of its refurbished life
* (i.e. can't repeatedly refurbish); it is not valid to operate any plant that has been exogenously retired, or decommissioned; and it is not
* valid to operate any plant that is never able to be built.
validYrOperate(exist(g),y,t) = yes ;
validYrOperate(commit(g),y,t)$( yearNum(y) >= i_fixComYr(g) ) = yes ;
validYrOperate(new(g),y,t)$( yearNum(y) >= i_EarlyComYr(g) ) = yes ;
validYrOperate(g,y,t)$( i_refurbDecisionYear(g) * ( yearNum(y) > i_refurbDecisionYear(g) + sum(mapg_k(g,k), i_refurbishmentLife(k)) ) ) = no ;
validYrOperate(g,y,t)$( i_ExogenousRetireYr(g) * ( yearNum(y) >= i_ExogenousRetireYr(g) ) ) = no ;
validYrOperate(neverBuild(g),y,t) = no ;

* xii) North and South Island plant
nigen(g)$mapg_ild(g,'ni') = yes ;  nigen(neverBuild(g)) = no ;
sigen(g)$mapg_ild(g,'si') = yes ;  sigen(neverBuild(g)) = no ;

* Define capacity of existing plant in first modelled year. Be aware that if capacity is committed in the first modelled year, the plant
* will be in the commit(g) and noExist(g) sets.
initialCapacity(exist(g)) = i_nameplate(g) ;

* Define exogenously retired MW by plant and year.
exogMWretired(g,y)$( i_ExogenousRetireYr(g) * ( yearNum(y) = i_ExogenousRetireYr(g) ) ) = i_nameplate(g) ;

* Identify all generation plant that may be endogenously retired.
possibleToEndogRetire(g)$i_refurbDecisionYear(g) = yes ;

* Identify all generation plant that may be retired (endogenously or exogenously).
possibleToRetire(g)$( possibleToEndogRetire(g) or i_ExogenousRetireYr(g) ) = yes ;

* Define contribution to peak capacity by plant
peakConPlant(g,y)   = sum(mapg_k(g,k), i_peakContribution(k) ) ;
NWpeakConPlant(g,y) = sum(mapg_k(g,k), i_NWpeakContribution(k) ) ;
peakConPlant(g,y)$schedHydroPlant(g)   = sum(mapg_k(g,k), i_peakContribution(k) ) ;
NWpeakConPlant(g,y)$schedHydroPlant(g) = sum(mapg_k(g,k), i_NWpeakContribution(k) ) ;

* Initialise the FOF multiplier - compute a weighted average using annual hours per load block as the weights.
WtdAvgFOFmultiplier(k,lb) = sum(t, hoursPerBlock(t,lb) * i_FOFmultiplier(k,lb)) / sum(t, hoursPerBlock(t,lb)) ;

* Derive the minimum and maximum capacity factors for each plant and period.
* First average over time (i.e. over the months mapped to each period t) and assign to maxCapFactPlant.
maxCapFactPlant(g,t,lb)$sum(mapm_t(m,t), 1) = sum(mapm_t(m,t), i_PltCapFact(g,m) ) / sum(mapm_t(m,t), 1) ;
* Then, set all scheduable hydro max capacity factors to zero.
loop(mapg_k(g,hydroSched(k)), maxCapFactPlant(g,t,lb) = 0 ) ;
* Now, overwrite max capacity factor for hydro with user-defined, non-zero i_maxHydroCapFact(g) values.
maxCapFactPlant(g,t,lb)$i_maxHydroCapFact(g) = i_maxHydroCapFact(g) ;
* Now adjust all max capacity factors for forced outage factor.
maxCapFactPlant(g,t,lb) = maxCapFactPlant(g,t,lb) * sum(mapg_k(g,k), (1 - i_fof(g) * WtdAvgFOFmultiplier(k,lb)) ) ;
* Min capacity factor only meaningfully defined for hydro units.
minCapFactPlant(schedHydroPlant(g),y,t) = i_minHydroCapFact(g) ;
* But it is also 'non-meaningfully' defined to a low non-zero value for wind plant.
loop(mapg_k(g,wind(k)), minCapFactPlant(g,y,t) = .001 ) ;

* Identify all the generation plant that may possibly be refurbished or endogenously retired and the years in which that retirement may/will occur.
loop((g,k)$( exist(g) * refurbish(k) * mapg_k(g,k) * i_refurbcapitalcost(g) * i_refurbDecisionYear(g) ),
  possibleToRefurbish(g) = yes ;
  if(endogretire(k),
    endogenousRetireDecisnYrs(g,y)$( ( yearNum(y) >= firstYear + noRetire                        ) * ( yearNum(y) <= i_refurbDecisionYear(g) ) ) = yes ;
    endogenousRetireYrs(g,y)$(       ( yearNum(y) >= firstYear + noRetire + i_retireOffsetYrs(k) ) * ( yearNum(y) <= i_refurbDecisionYear(g) + i_retireOffsetYrs(k) ) ) = yes ;
  else
    endogenousRetireDecisnYrs(g,y)$( ( yearNum(y) >= firstYear + noRetire                        ) * ( yearNum(y) = i_refurbDecisionYear(g) ) ) = yes ;
    endogenousRetireYrs(g,y)$(       ( yearNum(y) >= firstYear + noRetire + i_retireOffsetYrs(k) ) * ( yearNum(y) = i_refurbDecisionYear(g) + i_retireOffsetYrs(k) ) ) = yes ;
  ) ;
) ;

* Compute the years a plant must keep going for after the decision to endogenously retire it has been made
loop(refurbish(k),
  continueAftaEndogRetire(g)$( possibleToEndogRetire(g) * mapg_k(g,k) ) = i_retireOffsetYrs(k) ;
) ;

* Define capital costs for new generation plant:
* - Capital costs are first calculated as if capex is lumpy. After any adjustments, they are then converted
*   to a levelised or annualised basis (i.e. see capCharge).

* First, transfer i_capitalCost to capexPlant and i_refurbCapitalCost to refurbCapexPlant, and convert both to $/MW.
capexPlant(g)       = 1e3 * i_capitalCost(g) ;
refurbCapexPlant(g) = 1e3 * i_refurbCapitalCost(g) ;

* Next, randomly adjust capexPlant to create mathematically different costs - this helps the solver but makes no
* appreciable economic difference provided randomCapexCostAdjuster is small.
loop(randomiseCapex(k),
  capexPlant(noExist(g))$mapg_k(g,k) =
  uniform( (capexPlant(g) - randomCapexCostAdjuster * capexPlant(g)),(capexPlant(g) + randomCapexCostAdjuster * capexPlant(g)) ) ;
) ;

* Zero out any refubishment capex costs if the plant is not actually a candidate for refurbishment.
refurbCapexPlant(g)$( not possibleToRefurbish(g) ) = 0 ;

* Now add on the 'variablised' connection costs to the adjusted plant capital costs - continue to yield NZ$/MW.
capexPlant(g)$i_nameplate(g) = capexPlant(g) + ( 1e6 * i_connectionCost(g) / i_nameplate(g) ) ;

* Finally, convert lumpy capital costs to levelised capital charge (units are now NZ$/MW/yr).
capCharge(g,y)       = capexPlant(g) * sum(mapg_k(g,k), capRecFac(y,k,'genplt')) ;
refurbCapCharge(g,y) = refurbCapexPlant(g) * sum(mapg_k(g,k), capRecFac(y,k,'refplt')) ;
refurbCapCharge(g,y)$( yearNum(y) < i_refurbDecisionYear(g) ) = 0 ;
refurbCapCharge(g,y)$( yearNum(y) > i_refurbDecisionYear(g) + sum(mapg_k(g,k), i_refurbishmentLife(k)) ) = 0 ;

* Calculate reserve capability per generating plant.
reservesCapability(g,rc)$i_plantReservesCap(g,rc) = i_nameplate(g) * i_plantReservesCap(g,rc) ;


* e) Transmission data.
* Let the last region declared be the slack bus (note that set r may not be ordered if users don't maintain unique set elements).
slackBus(r) = no ;
slackBus(r)$( ord(r) = card(r) ) = yes ;

* Define the lower triangular part of region-region matrix, i.e. ord(r) > ord(rr).
regLower(r,rr) = no ;
regLower(r,rr)$( ord(r) > ord(rr) ) = yes ;

* Define interisland flows.
interIsland(ild,ild1)$( ord(ild) <> ord(ild1) ) = yes ;

* Define regions at each end of NI-SI HVDC link.
loop((Benmore(i),Haywards(ii)),
  nwd(r,rr)$( mapi_r(i,r) * mapi_r(ii,rr) ) = yes ;
  swd(r,rr)$( mapi_r(ii,r) * mapi_r(i,rr) ) = yes ;
) ;

* Compute the reciprocal of the zonally-based location factors (and then set equal to 1 if more than 2 regions).
locFac_Recip(e)$i_zonalLocFacs(e) = 1 / i_zonalLocFacs(e) ;
locFac_Recip(e)$( numreg > 2 ) = 1 ;

* Make sure intraregional capacities and line characteristics are zero.
i_txCapacity(r,r,ps) = 0 ;
i_txCapacityPO(r,r,ps) = 0 ;
i_txResistance(r,r,ps) = 0 ;
i_txReactance(r,r,ps) = 0 ;

* Assign allowable transitions from one transmission state to another.
transitions(tupg,r,rr,ps,pss) = txUpgradeTransitions(tupg,r,rr,ps,pss) ;
transitions(tupg,rr,r,ps,pss)$txUpgradeTransitions(tupg,r,rr,ps,pss) = txUpgradeTransitions(tupg,r,rr,ps,pss) ;
* Now remove any illegitimate values from transitions.
transitions(tupg,r,rr,ps,pss)$( i_txCapacity(r,rr,pss) = 0 )  = no ;
transitions(tupg,r,rr,ps,pss)$( sameas(tupg,'exist') and (i_txCapacity(r,rr,ps) = 0) )  = no ;
transitions(tupg,r,rr,ps,pss)$sameas(tupg,'exist') = no ;
transitions(tupg,r,rr,ps,pss)$sameas(pss,'initial') = no ;
transitions(tupg,r,r,ps,pss) = no ;
transitions(tupg,r,rr,ps,ps) = no ;

* Identify all possible states on all paths by recursively applying 'transitions'. First, kick things off
* by initialising the cases where a non-zero capacity is defined on existing paths.
allowedStates(r,rr,'initial')$i_txCapacity(r,rr,'initial') = yes ;
counter = 0 ;
repeat
*** Should this next line be ord or card?
  counter = card(allowedStates) ;
  allowedStates(r,rr,pss)$sum(transitions(tupg,r,rr,ps,pss)$allowedStates(r,rr,ps), 1 ) = yes ;
until counter = card(allowedStates) ;

* Identify all r-rr-ps tuples not in allowedStates.
notAllowedStates(r,rr,ps) = yes ;
notAllowedStates(allowedStates) = no ;

* Identify all existing or potential interregional transmission paths. Then identify the ones that are uni- versus bi-directional.
paths(r,rr)$sum(allowedStates(r,rr,ps), 1 ) = yes ;
biPaths(r,rr)$( paths(r,rr) * paths(rr,r) ) = yes ;
uniPaths(paths) = yes ;
uniPaths(biPaths) = no ;

* Identify all upgrade states on all transmission paths.
upgradedStates(allowedStates(r,rr,ps))$( not sameas(ps,'initial') ) = yes ;

* Identify the allowable upgrade transition sequence for each valid transmission path.
validTransitions(paths(r,rr),ps,pss)$sum(transitions(tupg,r,rr,ps,pss), 1 ) = yes ;

* Assign earliest and fixed transmission upgrade years (let earliest year be the first year if no earliest year is specified).
txEarlyComYr(tupg,paths(r,rr),ps,pss)$i_txEarlyComYr(tupg) = i_txEarlyComYr(tupg) ;
txEarlyComYr(tupg,paths(rr,r),ps,pss)$txEarlyComYr(tupg,r,rr,ps,pss) = txEarlyComYr(tupg,r,rr,ps,pss) ;
txEarlyComYr(transitions)$( not txEarlyComYr(transitions) ) = firstYear ;
txEarlyComYr(tupg,paths,ps,pss)$( not transitions(tupg,paths,ps,pss) ) = 0 ;

txFixedComYr(tupg,paths(r,rr),ps,pss)$i_txFixedComYr(tupg) = i_txFixedComYr(tupg) ;
txFixedComYr(tupg,paths(rr,r),ps,pss)$txFixedComYr(tupg,r,rr,ps,pss) = txFixedComYr(tupg,r,rr,ps,pss) ;
txFixedComYr(tupg,paths,ps,pss)$( not transitions(tupg,paths,ps,pss) ) = 0 ;

* Represent early and fixed transmission investment years as sets.
txEarlyComYrSet(transitions,y)$( yearNum(y) < txEarlyComYr(transitions) ) = yes ;
** Can this next line be right?
txEarlyComYrSet(transitions,y)$( txFixedComYr(transitions) > lastYear ) = yes ;
txFixedComYrSet(transitions,y)$( txFixedComYr(transitions) = yearNum(y) ) = yes ;

* Calculate reactance and susceptance by year - this assumes exogenous or fixed timing of transmission expansion
* decisions, otherwise it stays at the level of initial year.
reactanceYr(paths,y) = i_txReactance(paths,'initial') ;
loop((tupg,paths,ps,pss)$txFixedComYr(tupg,paths,ps,pss),
  reactanceYr(paths,y)$( yearNum(y) >= txFixedComYr(tupg,paths,ps,pss) ) = i_txReactance(paths,pss) ;
) ;

susceptanceYr(paths,y)$reactanceYr(paths,y) = 1 / reactanceYr(paths,y) ;

* Assign bus-branch incidence and group constraint data.
loop(mapArcNode(p,r,rr),
  BBincidence(p,r)  =  1 ;
  BBincidence(p,rr) = -1 ;
) ;

* Identify transmission group constraints as valid if LHS and RHS coefficients are non-zero. 
validTGC(tgc)$( sum(p$i_txGrpConstraintsLHS(tgc,p), 1) * i_txGrpConstraintsRHS(tgc) ) = yes ;

* Initialise the line segment set (i.e. number segments = number of vertices - 1).
nsegment(n)$( ord(n) < card(n) ) = yes ;

* Determine capacity of each segment, i.e. uniform between 0 and i_txCapacity(r,rr,ps). Note that there is no
* special reason why the segments must be of uniform sizes.
pCap(paths(r,rr),ps,n)$(card(n) - 1 ) = (ord(n) - 1) * i_txCapacity(paths,ps) / (card(n) - 1 ) ;

* Then use the quadratic loss function to compute losses at max capacity of each piece/segment.
pLoss(paths(r,rr),ps,n) = i_txResistance(paths,ps) * ( pCap(paths,ps,n)**2 ) ;

* Figure out the upper bound on losses.
bigLoss(paths,ps) = smax(n, pLoss(paths,ps,n) ) ;

* Now compute the slope and intercept terms to be used in the loss functions in GEM.
slope(paths(r,rr),ps,nsegment(n))$[ (pCap(paths,ps,n+1) - pCap(paths,ps,n)) > eps ] =
  [pLoss(paths,ps,n+1) - pLoss(paths,ps,n)] / [pCap(paths,ps,n+1) - pCap(paths,ps,n)] ;

intercept(paths(r,rr),ps,nsegment(n)) = pLoss(paths,ps,n) - slope(paths,ps,n) * pCap(paths,ps,n) ;

* Assign transmission upgrade capital costs.
* For sake of clarity, associate half of the cost with each direction, unless the path is unidirectional.
txCapitalCost(r,rr,ps)$bipaths(r,rr) = 0.5 * i_txCapitalCost(r,rr,ps) ;
txCapitalCost(rr,r,ps)$txCapitalCost(r,rr,ps) = 0.5 * i_txCapitalCost(r,rr,ps) ;
txCapitalCost(r,rr,ps)$unipaths(r,rr) = i_txCapitalCost(r,rr,ps) ;
txCapitalCost(r,rr,ps)$( unipaths(r,rr) and (txCapitalCost(r,rr,ps) = 0) ) = i_txCapitalCost(rr,r,ps) ;

* Convert lumpy txCapitalCost ($m) to levelised TxCapCharge ($m/yr).
txCapCharge(r,rr,ps,y) = txCapitalCost(r,rr,ps) * txCapRecFac(y) ;


* f) Reserve energy data.
reservesAreas(rc) = min(2, max(1, i_ReserveAreas(rc) ) ) ;

singleReservesReqF(rc)$( reservesAreas(rc) = 1 ) = 1 ;

reserveViolationPenalty(ild,rc) = max(0, i_ReservePenalty(ild,rc) ) ;

windCoverPropn(rc) = min(1, max(0, i_propWindCover(rc) ) ) ;

bigM(ild1,ild) =
 smax((paths(r,rr),ps)$( mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacity(paths,ps) ) -
 smin((paths(r,rr),ps)$( mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacityPO(paths,ps) ) ;




*+++++++++++++++++++++++++
* More code to do the non-free reserves stuff. 
* Estimate free reserves by path state.
freeReserves(nwd(r,rr),ps)$allowedStates(nwd,ps) = i_txCapacityPO(nwd,ps) + largestNIplant ;
freeReserves(swd(r,rr),ps)$allowedStates(swd,ps) = i_txCapacityPO(swd,ps) + largestSIplant ;

* Estimate non-free reserves by path state.
nonFreeReservesCap(paths(r,rr),ps)$( allowedStates(paths,ps) and (nwd(paths) or swd(paths)) ) = i_txCapacity(paths,ps) - freeReserves(paths,ps) ;

* Figure out capacities (really, upper bounds) of non-free reserves by step.
* a) Find the biggest value in each direction
bigSwd(swd) = smax(ps, nonFreeReservesCap(swd,ps)) ;
bigNwd(nwd) = smax(ps, nonFreeReservesCap(nwd,ps)) ;
* b) Set the first step to be 100
pNFresvCap(paths(r,rr),stp)$( nwd(paths) or swd(paths) ) = 100 ;
* c) Set subsequent steps to be 100 more than the previous step
loop(stp$( ord(stp) > 1),
  pNFresvCap(paths(r,rr),stp)$( ord(stp) > 1 and (nwd(paths) or swd(paths)) ) = pNFresvCap(paths,stp-1) + 100 ;
) ;
* d) Set the last step to be the biggest value over all states
pNFresvCap(swd,stp)$( ord(stp) = card(stp) ) = bigswd(swd) ;
pNFresvCap(nwd,stp)$( ord(stp) = card(stp) ) = bignwd(nwd) ;

* Figure out costs by step - note that this cost function is entirely fabricated but it gives seemingly reasonable values.
pNFresvCost(paths(r,rr),stp)$( nwd(paths) or swd(paths) ) = .0000009 * ( pnfresvcap(paths,stp)**3 ) + 150 ;

* Cap the cost of the last step at the cost of VOLL.
pNFresvCost(paths(r,rr),stp)$( pNFresvCost(paths,stp) > 500 ) = 500 ;
*+++++++++++++++++++++++++




*===============================================================================================
* 4. Prepare the outcome-dependent input data; key user-specified settings are obtained from GEMstochastic.inc.

$include GEMstochastic.inc

* Pro-rate weightOutcomesBySet values so that weights sum to exactly one for each outcomeSets:
counter = 0 ;
loop(outcomeSets,
  counter = sum(outcomes, weightOutcomesBySet(outcomeSets,outcomes)) ;
  weightOutcomesBySet(outcomeSets,outcomes)$counter = weightOutcomesBySet(outcomeSets,outcomes) / counter ;
  counter = 0 ;
) ;

* Compute the short-run marginal cost (and its components) for each generating plant, $/MWh.
totalFuelCost(g,y,outcomes) = 1e-3 * i_heatrate(g) * sum(mapg_f(g,f), ( i_fuelPrices(f,y) * outcomeFuelCostFactor(outcomes) + i_FuelDeliveryCost(g) ) ) ;

CO2taxByPlant(g,y,outcomes) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_co2tax(y) * outcomeCO2TaxFactor(outcomes) * i_emissionFactors(f) ) ;

SRMC(g,y,outcomes) = i_varOM(g) + totalFuelCost(g,y,outcomes) + CO2taxByPlant(g,y,outcomes) ;

* If SRMC is zero or negligible (< .05) for any plant, assign a positive small value.
SRMC(g,y,outcomes)$( SRMC(g,y,outcomes) < .05 ) = 1e-3 * ord(g) / card(g) ;

* Capture the island-wide AC loss adjustment factors.
AClossFactors('ni') = %AClossesNI% ;
AClossFactors('si') = %AClossesSI% ;

* Transfer i_NrgDemand to NrgDemand and adjust for intraregional AC transmission losses and the outcome-specific energy factor.
NrgDemand(r,y,t,lb,outcomes) = sum(mapild_r(ild,r), (1 + AClossFactors(ild)) * i_NrgDemand(r,y,t,lb)) * outcomeNRGfactor(outcomes) ;

* Use the GWh of NrgDemand and hours per LDC block to compute ldcMW (MW).
ldcMW(r,y,t,lb,outcomes)$hoursPerBlock(t,lb) = 1e3 * NrgDemand(r,y,t,lb,outcomes) / hoursPerBlock(t,lb) ;

* Calculate peak load as peak:average ratio and adjust by the outcome-specific peak load factor.
peakLoadNZ(y,outcomes) = outcomePeakLoadFactor(outcomes) * i_P200ratioNZ(y) * ( 1 / 8.76 ) * sum((r,t,lb)$mapAggR_r('nz',r), NrgDemand(r,y,t,lb,outcomes)) ;
peakLoadNI(y,outcomes) = outcomePeakLoadFactor(outcomes) * i_P200ratioNI(y) * ( 1 / 8.76 ) * sum((r,t,lb)$mapAggR_r('ni',r), NrgDemand(r,y,t,lb,outcomes)) ;

* Transfer hydro output for all hydro years from i_historicalHydroOutput to historicalHydroOutput (no outcome-specific adjustment factors at this time).
historicalHydroOutput(v,hY,m) = i_historicalHydroOutput(v,hY,m) ;



*===============================================================================================
* 5. Display sets and parameters.

$ontext 

** This piece of code has not kept pace with all the changes to GEMdata.

Display
* Sets
* Time/date-related sets and parameters.
  firstYr, lastYr, allButFirstYr, firstPeriod
* Various mappings, subsets and counts.
  mapg_k, mapg_f, mapg_o, mapg_i, mapg_r, mapg_e, mapg_ild, mapi_r, mapi_e, mapild_r, mapv_g, thermalFuel
* Financial parameters.
* Fuel prices and quantity limits.
* Generation data.
  noExist, nigen, sigen, schedHydroPlant, pumpedHydroPlant, moverExceptions, validYrBuild, integerPlantBuild, linearPlantBuild
  possibleToBuild, possibleToRefurbish, possibleToEndogRetire, possibleToRetire, endogenousRetireDecisnYrs, endogenousRetireYrs, validYrOperate
* Load data.
* Transmission data.
  slackBus, regLower, interIsland, nwd, swd, paths, uniPaths, biPaths, transitions, validTransitions, allowedStates, notAllowedStates
  upgradedStates, txEarlyComYrSet, txFixedComYrSet, validTGC, nSegment,
* Reserve energy data.
* Parameters
* Time/date-related sets and parameters.
  counter, yearNum, hydroYearNum, hoursPerBlock
* Various mappings, subsets and counts.
  numReg
* Financial parameters.
  CBAdiscountRates, PVfacG, PVfacT, PVfacsM, PVfacsEY, PVfacs, capexLife, annuityFacN, annuityFacR, txAnnuityFacN, txAnnuityFacR
  capRecFac, depTCrecFac, txCapRecFac, txDeptCRecFac
* Fuel prices and quantity limits.
* Generation data.
  initialCapacity, capexPlant, capCharge, refurbCapexPlant, refurbCapCharge, exogMWretired, continueAftaEndogRetire
  WtdAvgFOFmultiplier, reservesCapability, peakConPlant, NWpeakConPlant, maxCapFactPlant, minCapFactPlant
* Load data.
* Transmission data.
  locFac_Recip, txEarlyComYr, txFixedComYr, reactanceYr, susceptanceYr, BBincidence, pCap, pLoss, bigLoss, slope, intercept
  txCapitalCost, txCapCharge
* Reserve energy data.
  reservesAreas, reserveViolationPenalty, windCoverPropn, bigM
  ;
$offtext



*===============================================================================================
* 6. Create input data summaries.

* Declare input data summary files.
Files
  stochasticSummary / "%OutPath%%runName%\Input data checks\%runName% - %runVersionName% - Stochastic summary.txt" /
  plantData         / "%OutPath%%runName%\Input data checks\%runName% - %runVersionName% - Plant summary.txt" /
  capexStats        / "%OutPath%%runName%\Input data checks\%runName% - %runVersionName% - Capex, MW and GWh summaries.txt" /
  loadSummary       / "%OutPath%%runName%\Input data checks\%runName% - %runVersionName% - Load summary.txt" /
  lrmc_inData       / "%OutPath%%runName%\Input data checks\%runName% - %runVersionName% - LRMC estimates based on GEM input data (non-existing plant only).csv" /
  ;

stochasticSummary.lw = 0 ; stochasticSummary.pw = 999 ;
plantData.lw = 0 ;         plantData.pw = 999 ;
capexStats.lw = 0 ;        capexStats.pw = 999 ;
loadSummary.lw = 0 ;       loadSummary.pw = 999 ;
lrmc_inData.pc = 5 ;       lrmc_inData.nd = 1 ;


* Do the calculations.
assumedGWh(g) = sum(mapg_k(g,k), 8.76 * i_capFacTech(k) * i_nameplate(g)) ;
assumedGWh(pumpedHydroPlant(g)) = i_PumpedHydroEffic(g) * sum(mapm_t(m,t), 1) * i_PumpedHydroMonth(g) ;

MWtoBuild(k,aggR) = sum((possibleToBuild(g),r)$( mapg_k(g,k) * mapg_r(g,r) * mapAggR_r(aggR,r) ), i_nameplate(g)) ;
GWhtoBuild(k,aggR) = sum((possibleToBuild(g),r)$( mapg_k(g,k) * mapg_r(g,r) * mapAggR_r(aggR,r) ), assumedGWh(g)) ;

loop(defaultOutcome(outcomes),

  loadByRegionYear(r,y) = sum((t,lb), NrgDemand(r,y,t,lb,outcomes)) ;
  loadByAggRegionYear(aggR,y) = sum(mapAggR_r(aggR,r), loadByRegionYear(r,y)) ; 

  peakLoadByYearAggR(y,'nz') = peakLoadNZ(y,outcomes) ;
  peakLoadByYearAggR(y,'ni') = peakLoadNI(y,outcomes) ;
  peakLoadByYearAggR(y,'si') = peakLoadByYearAggR(y,'nz') - peakLoadByYearAggR(y,'ni') ;

) ;

capexStatistics(k,aggR,'count') = sum((g,r)$( mapg_k(g,k) * mapg_r(g,r) * mapAggR_r(aggR,r) * possibleToBuild(g) ), 1 ) ; 
capexStatistics(k,aggR,'min')$capexStatistics(k,aggR,'count')   = smin((g,r)$( mapg_k(g,k) * mapg_r(g,r) * mapAggR_r(aggR,r) * possibleToBuild(g) ), 1e-3 * capexPlant(g) ) ; 
capexStatistics(k,aggR,'max')$capexStatistics(k,aggR,'count')   = smax((g,r)$( mapg_k(g,k) * mapg_r(g,r) * mapAggR_r(aggR,r) * possibleToBuild(g) ), 1e-3 * capexPlant(g) ) ; 
capexStatistics(k,aggR,'range')$capexStatistics(k,aggR,'count') = capexStatistics(k,aggR,'max') - capexStatistics(k,aggR,'min') ;
capexStatistics(k,aggR,'mean')$capexStatistics(k,aggR,'count')  =
  sum((g,r)$( mapg_k(g,k) * mapg_r(g,r) * mapAggR_r(aggR,r) * possibleToBuild(g) ), 1e-3 * capexPlant(g) ) / capexStatistics(k,aggR,'count') ; 
capexStatistics(k,aggR,'variance')$capexStatistics(k,aggR,'count') =
  sum((g,r)$( mapg_k(g,k) * mapg_r(g,r) * mapAggR_r(aggR,r) * possibleToBuild(g) ), sqr(1e-3 * capexPlant(g) - capexStatistics(k,aggR,'mean')) ) / capexStatistics(k,aggR,'count') ; 
capexStatistics(k,aggR,'stdDev') = sqrt(capexStatistics(k,aggR,'variance')) ;
capexStatistics(k,aggR,'stdDev%')$capexStatistics(k,aggR,'mean') = 100 * capexStatistics(k,aggR,'stdDev') / capexStatistics(k,aggR,'mean') ;


* Write the experiment-outcomeSets-outcomes summary.
put stochasticSummary 'Summary of mappings, weights and factors relating to experiments, outcomeSets, and outcomes.' // @61 'Outcome' @71
  'Outcome factors:' @110 'Same => averaged over the listed hydro years; Sequential => listed hydro year maps to first modelled year.' /
  'Experiments' @18 'Steps' @28 'outcomeSets' @45 'Outcomes' @61 'Weight' @71 'PeakLoad' @81 'Co2' @91 'FuelCost' @101 'Energy' @110
  'SeqType' @121 'Hydro years' ;
loop(allSolves(experiments,steps,outcomeSets),
  put / experiments.tl @18 steps.tl @28 outcomeSets.tl @45
  loop(mapOutcomes(outcomeSets,outcomes),
    put outcomes.tl @56 weightOutcomesBySet(outcomeSets,outcomes):10:3, outcomePeakLoadFactor(outcomes):10:3
      outcomeCO2TaxFactor(outcomes):10:3, outcomeFuelCostFactor(outcomes):10:3, outcomeNRGFactor(outcomes):10:3
    put @110 ;
    loop(mapOC_hydroSeqTypes(outcomes,hydroSeqTypes), put hydroSeqTypes.tl:<11 ) ;
    loop(mapOC_hY(outcomes,hY), put hY.tl:<5 ) ;
  ) ;
);


* Write the plant data summaries.
$set plantDataHdr 'MW  Capex     HR  varOM  fixOM  Exist noExst Commit New NvaBld ErlyYr FixYr inVbld inVopr Retire EndogY ExogYr  Mover' ;
put plantData, 'Various plant data - based on user-supplied data and the machinations of GEMdata.gms.' //
  'First modelled year:'        @38 firstYear:<4:0 /
  'Last modelled year:'         @38 lastYear:<4:0 //
  'Summary counts' /
  'Plant in input file:'        @38 card(g):<4:0 /
  'Existing plant:'             @38 card(exist):<4:0 /
  'Committed plant:'            @38 card(commit):<4:0 /
  'Plant not able to be built:' @38 card(neverBuild):<4:0 /
  'Plant able to be retired:'   @38 card(possibleToRetire):<4:0 //

  'VoLL plant (note that VoLL plant are not counted with generating plant)' /
  'VoLL plant count:'                   @38 (sum(s$i_VOLLcap(s), 1)):<4:0 /
  'Average VoLL plant capacity, MW:'    @38 (sum(s, i_VOLLcap(s))  / card(s)):<4:0 /
  'Average VoLL plant cost, $/MWh:'     @38 (sum(s, i_VOLLcost(s)) / card(s)):<4:0 //

  'Technologies with randomised capex:' @38 if(sum(movers(k), 1), loop(movers(k), put k.tl, ', ' ) else put 'There are none' ) put /
  'Randomised cost range (+/-), %:'     @38 (100 * randomCapexCostAdjuster):<5:1 //

  'Notes:' /
  'MW - nameplate MW.' /
  'Capex - Capital cost of new plant, $/kW. Includes any connection cost and randomisation - as levelised and used in objective function.' / 
  'HR - Heat rate of generating plant, GJ/GWh' /
  'varOM - Variable O&M costs by plant, $/MWh' /
  'fixOM - Fixed O&M costs by plant, $/kW/year' /
  'Exist - plant already exists.' /
  'noExst - plant does not exist but may be a candidate for building.' /
  'Commit - plant is committed to be built in the single year given in the column entitled FixYr.' /
  'New - plant is potentially able to be built but no earlier than the year given in the ErlyYr column.' /
  'NvaBld - plant is defined by user to be never able to be built.' /
  'ErlyYr - the earliest year in which a new plant can be built.' /
  'FixYr - the year in which committed plant will be built or, if 3333, the plant can never be built.' /
  'inVbld - the plant is in the set called validYrBuild.' /
  'inVopr - the plant is in the set called validYrOperate.' /
  'Retire - plant is able to be retired, either exogenouosly or endogenously (see next 2 columns).' /
  'EndogY - year in which endogenous retire/refurbish decision is made.' /
  'ExogYr - year in which plant is exogenously retired.' /
  'Mover - plant for which the commissioning date is able to move if the timing run is re-optimised.' //
  'Existing plant' /
  'Plant number/name' @20 'Technology' @34 "%plantDataHdr%" ;
counter = 0 ;
loop((k,exist(g))$mapg_k(g,k),
  counter = counter + 1 ;
  put / counter:<4:0, g.tl:<15, k.tl:<12, i_nameplate(g):4:0, (1e-3*capexPlant(g)):7:0, i_heatrate(g):7:0, i_varOM(g):7:1, i_fixedOM(g):7:1, @67 'Y' @73 '-' @81 ;
  if(commit(g),       put 'Y' else put '-' ) put @87 ;
  if(new(g),          put 'Y' else put '-' ) put @92 ;
  if(neverBuild(g),   put 'Y' else put '-' ) put @98 ;
  if(i_EarlyComYr(g), put i_EarlyComYr(g):4:0 else put '-' ) put @105 ;
  if(i_fixComYr(g),   put i_fixComYr(g):4:0   else put '-' ) put @112 ;
  if(sum(y,     validYrBuild(g,y)),     put 'Y' else put '-' ) put @120 ;
  if(sum((y,t), validYrOperate(g,y,t)), put 'Y' else put '-' ) put @126 ;
  if(possibleToRetire(g),     put 'Y' else put '-' ) put @132 ;
  if(i_refurbDecisionYear(g), put i_refurbDecisionYear(g):>4:0 else put '-' ) put @139 ;
  if(i_ExogenousRetireYr(g),  put i_ExogenousRetireYr(g):>4:0  else put '-' ) put @148 '-' @155 g.te(g) ;
) ;
put // 'Non-existing plant' @34 "%plantDataHdr%" ;
loop((k,g)$( (not exist(g)) and mapg_k(g,k) ),
  counter = counter + 1 ;
  put / counter:<4:0, g.tl:<15, k.tl:<12, i_nameplate(g):4:0, (1e-3*capexPlant(g)):7:0, i_heatrate(g):7:0, i_varOM(g):7:1, i_fixedOM(g):7:1, @67 '-' @73 'Y' @81 ;
  if(commit(g),       put 'Y' else put '-' ) put @87 ;
  if(new(g),          put 'Y' else put '-' ) put @92 ;
  if(neverBuild(g),   put 'Y' else put '-' ) put @98 ;
  if(i_EarlyComYr(g), put i_EarlyComYr(g):4:0 else put '-' ) put @105 ;
  if(i_fixComYr(g),   put i_fixComYr(g):4:0   else put '-' ) put @112 ;
  if(sum(y,     validYrBuild(g,y)),     put 'Y' else put '-' ) put @120 ;
  if(sum((y,t), validYrOperate(g,y,t)), put 'Y' else put '-' ) put @126 ;
  if(possibleToRetire(g),     put 'Y' else put '-' ) put @132 ;
  if(i_refurbDecisionYear(g), put i_refurbDecisionYear(g):>4:0 else put '-' ) put @139 ;
  if(i_ExogenousRetireYr(g),  put i_ExogenousRetireYr(g):>4:0  else put '-' ) put @148 ;
  if(sum(movers(k), 1) and not moverExceptions(g), put 'Y' else put '-' ) ;   put @155 g.te(g) ;
) ;


* Write the capex statistics.
put capexStats 'Descriptive statistics of plant capex (lumpy and including grid connection costs).' //
  'First modelled year:' @22 firstYear:<4:0 /
  'Last modelled year:'  @22 lastYear:<4:0 / ;
loop(stat, put / stat.tl @13 '- ' stat.te(stat) ) ;
put // @24 ; loop(stat, put stat.tl:>10 ) ;
loop(k,
  counter = 0 ;
  put / k.tl @15 ;
  loop(aggR,
    if(counter = 0, put aggR.tl else put / @15 aggR.tl ) ;
    counter = 1 ;
    put @24 ;
    loop(stat,
      if(not ord(stat) = card(stat), put capexStatistics(k,aggR,stat):>10:0 else put capexStatistics(k,aggR,stat):>10:1 ) ;
    ) ;
  ) ;
) ;
put /// 'MW available for installation by technology and island' / @15 loop(aggR, put aggR.te(aggR):>15 ) ;
loop(k,
  put / k.tl @15 loop(aggR, put MWtoBuild(k,aggR):>15:0 ) ;
) ;
put /// 'Assumed GWh from all plant available for installation by technology and island' / @15 loop(aggR, put aggR.te(aggR):>15 ) ;
loop(k,
  put / k.tl @15 loop(aggR, put GWhtoBuild(k,aggR):>15:0 ) ;
) ;


* Write the load summaries.
put loadSummary 'Energy and peak load by region/island and year, GWh' /
  ' - GWh energy grossed-up by AC loss factors and scaled by outcome-specific energy factor' /
  ' - GWh energy and peak load reported here relates only to the default outcome (' ;
  loop(defaultOutcome(outcomes), put outcomes.tl ) put ').' ;

put // 'Intraregional AC loss factors, %' ;
loop(ild, put / @2 ild.tl @14 (100 * AClossFactors(ild)):>10:2 ) ;

put // 'Outcome-specific energy factors' ;
loop(outcomes, put / @2 outcomes.tl @14 outcomeNRGfactor(outcomes):>10:2 ) ;

put // 'Energy, GWh' @14 loop(r, put r.tl:>10 ) loop(aggR, put aggR.tl:>10 ) ;
loop(y,
  put / @2 y.tl @14
  loop(r,    put loadByRegionYear(r,y):>10:0 ) ;
  loop(aggR, put loadByAggRegionYear(aggR,y):>10:0 ) ;
) ;

put // 'Peak load, MW' @14 loop(aggR, put aggR.tl:>10 ) ;
loop(y, put / @2 y.tl @14  loop(aggR, put peakLoadByYearAggR(y,aggR):>10:0 ) ) ;


* Include code to compute and write out LRMC of all non-existing plant.
$include GEMlrmc.gms



* End of file.
