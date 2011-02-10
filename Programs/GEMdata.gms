* GEMdata.gms

* Last modified by Dr Phil Bishop, 10/02/2011 (imm@ea.govt.nz)

$ontext
 This program prepares the data for a single scenario. It imports the raw scenario-specific data
 from a GDX file; undertakes some manipulations, transformations, and intergrity checks; and then
 produces another GDX file in order to pass the prepared data to GEMsolve whereupon GEM is solved.

 The GEMdata invocation requires GEMdata to be restarted from GEMdeclarations. The files called
 GEMpaths.inc and GEMsettings.inc are included in GEMdata.

 Code sections:
  1. Load input data that comes from input GDX file or is hard-coded.
  2. Initialise sets and parameters.
     a) Time/date-related sets and parameters.
     b) Various mappings, subsets and counts.
     c) Financial parameters.
     d) Fuel prices and quantity limits.
     e) Generation data.
     f) Load data.
     g) Transmission data.
     h) Reserve energy data.
     i) Hydrology output data.
  3. Display sets and parameters.
  4. Dump newly created sets and parameters into a GDX file.
  5. Archive/save input files.
$offtext


* Track memory usage.
* Higher numbers are for more detailed information inside loops. Alternatively, on the command line, type: gams xxx profile=1
*option profile = 1 ;
*option profile = 2 ;
*option profile = 3 ;

option seed = 101 ;
$include GEMpaths.inc
$include GEMsettings.inc
*$offupper onempty inlinecom { } eolcom !

* Turn the following maps on/off as desired.
$offuelxref offuellist	
*$onuelxref  onuellist	

$offsymxref offsymlist
*$onsymxref  onsymlist



*===============================================================================================
* 1. Load input data that comes from input GDX file or is hard-coded.

* Initialise set y with the modelled years as specified in GEMsettings.inc.
* NB: set y in the GDX file contains all years on which data is defined, i.e. %firstYear% and %lastYear%
*     define a subset of data years. This means that all parameters defined on set y are loaded without
*     domain checking, i.e. $load c.f. $loaddc.
Set y  / %firstYear% * %lastYear% / ;

$gdxin "%DataPath%%GDXinputFile%"
* 23 fundamental sets (i.e. all 24 less set y)
$loaddc k f fg g s o fc i r e ild p ps tupg tgc t lb rc hY v m geo col
* 41 mapping sets and subsets
* 24 technology and fuel
$loaddc mapf_k mapf_fg techColor fuelColor fuelGrpColor movers refurbish endogRetire cogen peaker hydroSched hydroPumped
$loaddc wind renew thermalTech CCStech minUtilTechs demandGen randomiseCapex linearBuildTech coal lignite gas diesel
* 7 generation
$loaddc mapGenPlant exist commit new neverBuild mapg_fc maps_r
* 6 location
$loaddc mapLocations Haywards Benmore regionCentroid zoneCentroid islandCentroid
* 2 transmission
$loaddc txUpgradeTransitions mapArcNode
* 1 load and time
$loaddc mapm_t
* 0 reserves and security
* 1 hydrology
$loaddc mapReservoirs

* 88 parameters 
* 20 technology and fuel parameters
$loaddc i_plantLife i_refurbishmentLife i_retireOffsetYrs i_linearBuildMW i_linearBuildYr i_depRate i_capCostAdjByTech i_CapexExposure
$loaddc i_peakContribution i_NWpeakContribution i_capFacTech
$load   i_minUtilByTech i_CCSfactor i_CCScost i_FOFmultiplier i_maxNrgByFuel i_fuelPrices i_fuelQuantities i_emissionFactors i_co2tax
* 32 generation parameters
$loaddc i_nameplate i_UnitLargestProp i_baseload i_minUtilisation i_offlineReserve i_FixComYr i_EarlyComYr i_ExogenousRetireYr i_refurbDecisionYear
$loaddc i_fof i_heatrate i_PumpedHydroMonth i_PumpedHydroEffic i_minHydroCapFact i_maxHydroCapFact i_fixedOM i_varOM i_FuelDeliveryCost
$loaddc i_capitalCost i_connectionCost i_refurbCapitalCost i_plantReservesCap i_plantReservesCost i_PltCapFact
$loaddc i_VOLLcap i_VOLLcost i_HVDCshr i_exRates
$load   i_renewNrgShare i_renewCapShare i_distdGenRenew i_distdGenFossil
* 2 location
$loaddc i_substnCoordinates i_zonalLocFacs
* 12 transmission
$load   i_txCapacity i_txCapacityPO i_txResistance i_txReactance i_txCapitalCost i_maxReservesTrnsfr
$load   i_txEarlyComYr i_txFixedComYr i_txGrpConstraintsLHS i_txGrpConstraintsRHS i_HVDClevy i_HVDCreqRevenue
* 7 load and time
$load   i_firstDataYear i_lastDataYear i_HalfHrsPerBlk i_peakLoadNZ i_peakLoadNI i_NrgDemand i_inflation
* 12 reserves and security
$load   i_ReserveSwitch i_ReserveAreas i_propWindCover i_ReservePenalty i_reserveReqMW i_bigNIgen i_nxtbigNIgen i_bigSIgen i_fkNI i_fkSI i_HVDClosses i_HVDClossesPO
* 3 hydrology
$load   i_firstHydroYear i_historicalHydroOutput i_hydroOutputAdj


* Initialise hard-coded sets (NB: previously declared in GEMdeclarations).
* - ct, d, and dt are hard-coded; n receives info from GEMsettings.
Sets
  ct                             'Capital expenditure types'    / genplt   'New generation plant'
                                                                  refplt   'Refurbish existing generation plant' /
  d                              'Discount rate classes'        / d1       "Generation investor's post-tax real weighted average cost of capital"
                                                                  d2       "Transmission investor's post-tax real weighted average cost of capital"
                                                                  d3       'Lower discount rate for CBA sensitivity analysis' 
                                                                  d4       'Central discount rate for CBA sensitivity analysis'
                                                                  d5       'Upper discount rate for CBA sensitivity analysis'    /
  dt                             'Types of discounting'         / mid      'Middle of the period within each year'
                                                                  eoy      'End of year'   /
  n                              'Piecewise linear vertices'    / n1 * n%NumVertices% /
  ;


* Only need set rt here so that including GEMstochastic works.... 
Sets rt 'Model run types' / tmg, reo, dis / ;
$include GEMstochastic.gms



*===============================================================================================
* 2. Initialise sets and parameters.

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

* Denote each hydro year set element with a real number corresponding to that year, i.e. 1932 = 1932, 1933 = 1933, ... 2007 = 2007.
hydroYearNum(hY) = i_firstHydroYear + ord(hY) - 1 ;

lastHydroYear = sum(hY$( ord(hY) = card(hY) ), hydroYearNum(hY)) ;


* Count hours per load block per time period.
hoursPerBlock(t,lb) = sum(mapm_t(m,t), 0.5 * i_HalfHrsPerBlk(m,lb)) ;


* b) Various mappings, subsets and counts.
* Location mappings
loop(maplocations(i,r,e,ild),
  mapi_r(i,r) = yes ;
  mapi_e(i,e) = yes ;
*  mapi_ild(i,ild) = yes ;
*  mape_r(e,r) = yes ;
  mapild_r(ild,r) = yes ;
) ;
* Generation plant mappings
loop(mapgenplant(g,k,i,o),
  mapg_k(g,k) = yes ;
  mapg_o(g,o) = yes ;
  mapg_i(g,i) = yes ;
) ;
mapg_f(g,f)     = yes$sum(mapg_k(g,k), mapf_k(f,k) ) ;
*mapg_fg(g,fg)   = yes$sum(mapg_f(g,f), mapf_fg(f,fg) ) ;
mapg_r(g,r)     = yes$sum(mapg_i(g,i), mapi_r(i,r) ) ;
mapg_e(g,e)     = yes$sum(mapg_i(g,i), mapi_e(i,e) ) ;
mapg_ild(g,ild) = yes$sum(mapg_r(g,r), mapild_r(ild,r) ) ;
* Reservoir mappings
loop(mapreservoirs(v,i,g),
  mapv_g(v,g) = yes ;
*  mapv_i(v,i) = yes ;
) ;
* Fuel mappings
loop((f,fg,thermalTech(k))$( mapf_fg(f,fg) * mapf_k(f,k) ),
  thermalFuel(f) = yes ;
) ;

* Count number of regions
numreg = card(r) ;

* Identify generation plant types
loop(hydroSched(k),  schedHydroPlant(g)$mapg_k(g,k) = yes ) ;
loop(hydroPumped(k), pumpedHydroPlant(g)$mapg_k(g,k) = yes ) ;


* c) Financial parameters.
CBAdiscountRates('d1') = WACCg ;
CBAdiscountRates('d2') = WACCt ;
CBAdiscountRates('d3') = .04 ;
CBAdiscountRates('d4') = .07 ;
CBAdiscountRates('d5') = .10 ;

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


* d) Fuel prices and quantity limits.
* Define short run marginal cost (and its components) of each generating plant.
totalFuelCost(g,y,outcomes) = 1e-3 * i_heatrate(g) * sum(mapg_f(g,f), ( i_fuelPrices(f,y) + i_FuelDeliveryCost(g) ) ) ;

CO2taxByPlant(g,y,outcomes) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_co2tax(y) * (1 - i_CCSfactor(y,k)) * i_emissionFactors(f) ) ;

CO2CaptureStorageCost(g,y) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_CCScost(y,k) * i_CCSfactor(y,k) * i_emissionFactors(f) ) ;

SRMC(g,y,outcomes) = i_varOM(g) + totalFuelCost(g,y,outcomes) + CO2taxByPlant(g,y,outcomes) + CO2CaptureStorageCost(g,y) ;

* If SRMC is zero or negligible (< .05) for any plant, assign a positive small value.
SRMC(g,y,outcomes)$( SRMC(g,y,outcomes) < .05 ) = .05 * ord(g) / card(g) ;


* e) Generation data.
* Calculate reserve capability per generating plant.
reservesCapability(g,rc)$i_plantReservesCap(g,rc) = i_nameplate(g) * i_plantReservesCap(g,rc) ;

* Derive various generating plant subsets.
* Existing plant [i.e. exist(g) and i_nameplate(g) > 0, then exist(g) = yes].
exist(g)$( ord(g) <= 46 ) = yes ;
exist(g)$( i_nameplate(g) = 0 ) = no ;
* Not an existing plant.
noExist(g)$( not exist(g) ) = yes ;
noExist(g)$( i_nameplate(g) = 0 ) = no ;

* neverBuild - a plant is never built if it doesn't exist and i_fixComYr or i_EarlyComYr > lastYear.
* Also, if i_nameplate <= 0.
neverBuild(noExist(g))$( i_fixComYr(g) > lastYear or i_EarlyComYr(g) > lastYear ) = yes ;
neverBuild(g)$( i_nameplate(g) <= 0 ) = yes ;
* Committed - build year is fixed by user at something greater than or equal to firstyear, and plant is not in the neverBuild set.
commit(noExist(g))$( ( i_fixComYr(g) >= firstYear ) * ( not neverBuild(g) ) ) = yes ;
* New - a plant is 'new' if it's neither existing nor committed nor in the neverBuild set.
new(noExist(g))$( not ( commit(g) or neverBuild(g) ) ) = yes ;
* North and South Island plant
nigen(g)$mapg_ild(g,'ni') = yes ;  nigen(neverBuild(g)) = no ;
sigen(g)$mapg_ild(g,'si') = yes ;  sigen(neverBuild(g)) = no ;

* Identify exceptions to the technology-determined list of plant movers, i.e. if user fixes build year to a legitimate value, then
* don't allow the plant to be a mover.
loop(movers(k), moverExceptions(noExist(g))$( mapg_k(g,k) * ( i_fixComYr(g) >= firstYear ) * ( i_fixComYr(g) <= lastYear ) ) = yes ) ;

* Define the valid years in which a generating plant may operate.
* Existing.
validYrOperate(exist(g),y,t) = yes ;
* For committed plant, define valid operating years based on the year the capacity is assumed to become operational.
validYrOperate(commit(g),y,t)$( yearNum(y) >= i_fixComYr(g) ) = yes ;
* For new plant, define valid operating years based on the earliest commissioning year.
validYrOperate(new(g),y,t)$( yearNum(y) >= i_EarlyComYr(g) ) = yes ;
* Remove plant facing an endogenous refurbishment/retirement decision for the years after the refurbished kit has reached the end of its life.
validYrOperate(g,y,t)$( i_refurbDecisionYear(g) * ( yearNum(y) > i_refurbDecisionYear(g) + sum(mapg_k(g,k), i_refurbishmentLife(k)) ) ) = no ;
* Remove decommissioned plant and palnt unable to ever be built from validYrOperate.
validYrOperate(g,y,t)$( i_ExogenousRetireYr(g) * ( yearNum(y) >= i_ExogenousRetireYr(g) ) ) = no ;
validYrOperate(neverBuild(g),y,t) = no ;

* Define the valid years in which a new plant may be built.
validYrBuild(commit(g),y)$( yearNum(y) = i_fixComYr(g) ) = yes ;
validYrBuild(new(g),y)$( yearNum(y) >= i_EarlyComYr(g) ) = yes ;
validYrBuild(neverBuild(g),y) = no ;

* Identify the plant that may be built, i.e. it doesn't already exist or it is not otherwise prevented from being built.
possibleToBuild(g)$sum(y$validYrBuild(g,y), 1) = yes ;

* Identify generation plant that can be linearly or incrementally built, and those that must be integer builds.
loop((g,k)$( noExist(g) * linearBuildTech(k) * mapg_k(g,k) * ( not i_fixComYr(g) ) ),
  linearPlantBuild(g)$( i_nameplate(g) >= i_linearBuildMW(k) ) = yes ;
  linearPlantBuild(g)$( i_EarlyComYr(g) >= i_linearBuildYr(k) ) = yes ;
) ;
* If not able to be linearly built, then must be integer build.
integerPlantBuild(noExist(g))$( not linearPlantBuild(g) ) = yes ;
integerPlantBuild(neverBuild(g)) = no ;

* Define capacity of existing plant in first modelled year. Note that if capacity is committed in the first modelled
* year, it is treated as 'new' plant capacity as far as GEM is concerned.
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
peakConPlant(g,y)$schedHydroPlant(g)   = sum(mapg_k(g,k), i_peakContribution(k) * i_hydroOutputAdj(y) ) ;
NWpeakConPlant(g,y)$schedHydroPlant(g) = sum(mapg_k(g,k), i_NWpeakContribution(k) * i_hydroOutputAdj(y) ) ;

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
minCapFactPlant(schedHydroPlant(g),y,t) = i_minHydroCapFact(g) * i_hydroOutputAdj(y) ;
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

* First, transfer i_capitalCost to capitalCost (do this coz don't want to be overwriting any of the i_xxx data).
capitalCost(g) = i_capitalCost(g) ;

* Next, randomly adjust capitalCost to create mathematically different costs - this helps the solver but makes no
* appreciable economic difference provided randomCapexCostAdjuster is small.
loop(randomiseCapex(k),
  capitalCost(noExist(g))$mapg_k(g,k) =
  uniform( (capitalCost(g) - randomCapexCostAdjuster * capitalCost(g)),(capitalCost(g) + randomCapexCostAdjuster * capitalCost(g)) ) ;
) ;

* Now, convert capital cost of plant ('capitalCost' and 'i_refurbCapitalCost') from foreign currency to NZ$/MW and, in
* the case of foreign or imported costs, scale up the capex cost to include the local capex component.
loop(fc,
  if(sameas(fc,'nzd'),
    capexPlant(g)$mapg_fc(g,fc)       = 1e3 * 1 / i_exRates(fc) * capitalCost(g) ;
    refurbCapexPlant(g)$mapg_fc(g,fc) = 1e3 * 1 / i_exRates(fc) * i_refurbCapitalCost(g) ;
    else
    capexPlant(g)$mapg_fc(g,fc)       = 1e3 * 1 / i_exRates(fc) * capitalCost(g)         * ( 1 + (1 - sum(mapg_k(g,k), i_CapexExposure(k))) ) ;
    refurbCapexPlant(g)$mapg_fc(g,fc) = 1e3 * 1 / i_exRates(fc) * i_refurbCapitalCost(g) * ( 1 + (1 - sum(mapg_k(g,k), i_CapexExposure(k))) ) ;
  ) ;
) ;

* Zero out any refubishment capex costs if the plant is not actually a candidate for refurbishment.
refurbCapexPlant(g)$( not possibleToRefurbish(g) ) = 0 ;

* Now adjust (lumpy) capex cost by the technology specific adjuster.
loop(k, capexPlant(g)$(       mapg_k(g,k) * noExist(g) ) = capexPlant(g)       * i_CapCostAdjByTech(k) ) ;
loop(k, refurbCapexPlant(g)$( mapg_k(g,k) * exist(g) )   = refurbCapexPlant(g) * i_CapCostAdjByTech(k) ) ;

* Now add on the 'variablised' connection costs to the adjusted plant capital costs - continue to yield NZ$/MW.
capexPlant(g)$i_nameplate(g) = capexPlant(g) + ( 1e6 * i_connectionCost(g) / i_nameplate(g) ) ;

* Finally, convert lumpy capital costs to levelised capital charge (units are now NZ$/MW/yr).
capCharge(g,y)       = capexPlant(g)       * sum(mapg_k(g,k), capRecFac(y,k,'genplt')) ;
refurbCapCharge(g,y) = refurbCapexPlant(g) * sum(mapg_k(g,k), capRecFac(y,k,'refplt')) ;
refurbCapCharge(g,y)$( yearNum(y) < i_refurbDecisionYear(g) ) = 0 ;
refurbCapCharge(g,y)$( yearNum(y) > i_refurbDecisionYear(g) + sum(mapg_k(g,k), i_refurbishmentLife(k)) ) = 0 ;


* f) Load data.
AClossFactors('ni') = %AClossesNI% ;
AClossFactors('si') = %AClossesSI% ;


* Transfer i_NrgDemand to NrgDemand and adjust for intraregional AC transmission losses.
NrgDemand(r,y,t,lb) = sum(mapild_r(ild,r), (1 + AClossFactors(ild)) * i_NrgDemand(r,y,t,lb)) ;

* Use GWh of NrgDemand and hours per LDC block to get ldcMW (MW).
ldcMW(r,y,t,lb)$hoursPerBlock(t,lb) = 1e3 * NrgDemand(r,y,t,lb) / hoursPerBlock(t,lb) ;

* i) System security data.
* Transfer i_peakLoadNZ/NI to peakLoadNZ/NI and adjust for embedded generation.
peakLoadNZ(y,outcomes) = ( i_peakLoadNZ(y) + %embedAdjNZ% ) * outcomePeakLoadFactor(outcomes) ;
peakLoadNI(y,outcomes) = ( i_peakLoadNI(y) + %embedAdjNI% ) * outcomePeakLoadFactor(outcomes) ;

bigNIgen(y) = i_BigNIgen(y) ;
nxtbigNIgen(y) = i_nxtBigNIgen(y) ;

* Set largest two NI generators to zero if n security level is desired (assumes biggest SI generator < 2 biggest NI generators).
BigNIgen(y)$( gridSecurity = 0 ) = 0 ;
nxtBigNIgen(y)$( gridSecurity = 0 ) = 0 ;

* Set the 2nd largest NI generator to zero if n-1 security level is desired (assumes biggest SI generator < biggest NI generator).
nxtBigNIgen(y)$( gridSecurity = 1 ) = 0 ;


* g) Transmission data.
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
vtgc(tgc)$( sum(p$i_txGrpConstraintsLHS(tgc,p), 1) * i_txGrpConstraintsRHS(tgc) ) = yes ;

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


* h) Reserve energy data.
reservesAreas(rc) = min(2, max(1, i_ReserveAreas(rc) ) ) ;

singleReservesReqF(rc)$( reservesAreas(rc) = 1 ) = 1 ;

reserveViolationPenalty(ild,rc) = max(0, i_ReservePenalty(ild,rc) ) ;

windCoverPropn(rc) = min(1, max(0, i_propWindCover(rc) ) ) ;

bigM(ild1,ild) =
 smax((paths(r,rr),ps)$( mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacity(paths,ps) ) -
 smin((paths(r,rr),ps)$( mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacityPO(paths,ps) ) ;


* i) Hydrology output data.
* Assign hydro output for all hydro years and compute the simple arithmetic average hydro sequence.
*historicalHydroOutput(v,hY,m) = i_historicalHydroOutput(v,hY,m) ;
*historicalHydroOutput(v,'Average',m) = sum(hY, historicalHydroOutput(v,hY,m)) / ( lastHydroYear - i_firstHydroYear + 1 ) ;

* i) Hydrology output data.
* Assign hydro output for all hydro years and compute the simple arithmetic average hydro sequence.
historicalHydroOutput(v,hY,m) = i_historicalHydroOutput(v,hY,m) ;



*===============================================================================================
* 3. Display sets and parameters.

$ontext 

** This piece of code has not kept pace with all the changes to GEMdata.

Display
* Sets
* Time/date-related sets and parameters.
  firstYr, lastYr, allButFirstYr, firstPeriod
* Various mappings, subsets and counts.
  mapg_k, mapg_f, mapg_o, mapg_i, mapg_r, mapg_e, mapg_ild, mapg_fc, mapi_r, mapi_e, mapild_r, mapv_g, thermalFuel
* Financial parameters.
* Fuel prices and quantity limits.
* Generation data.
  noExist, nigen, sigen, schedHydroPlant, pumpedHydroPlant, moverExceptions, validYrBuild, integerPlantBuild, linearPlantBuild
  possibleToBuild, possibleToRefurbish, possibleToEndogRetire, possibleToRetire, endogenousRetireDecisnYrs, endogenousRetireYrs, validYrOperate
* Load data.
* Transmission data.
  slackBus, regLower, interIsland, nwd, swd, paths, uniPaths, biPaths, transitions, validTransitions, allowedStates, notAllowedStates
  upgradedStates, txEarlyComYrSet, txFixedComYrSet, vtgc, nSegment,
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
  SRMC, totalFuelCost, CO2taxByPlant, CO2CaptureStorageCost
* Generation data.
  initialCapacity, capitalCost, capexPlant, capCharge, refurbCapexPlant, refurbCapCharge, exogMWretired, continueAftaEndogRetire
  WtdAvgFOFmultiplier, reservesCapability, peakConPlant, NWpeakConPlant, maxCapFactPlant, minCapFactPlant
* Load data.
  AClossFactors, NrgDemand, ldcMW, peakLoadNZ, peakLoadNI, bigNIgen, nxtbigNIgen,
* Transmission data.
  locFac_Recip, txEarlyComYr, txFixedComYr, reactanceYr, susceptanceYr, BBincidence, pCap, pLoss, bigLoss, slope, intercept
  txCapitalCost, txCapCharge
* Reserve energy data.
  reservesAreas, reserveViolationPenalty, windCoverPropn, bigM
  ;
$offtext



*===============================================================================================
* 4. Dump newly created sets and parameters into a GDX file.


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




Execute_Unload "%GEMdataGDX%",
*+++++++++++++++++++++++++
* More code to do the non-free reserves stuff. 
  freeReserves nonFreeReservesCap bigSwd bigNwd pNFresvCap pNFresvCost
*+++++++++++++++++++++++++
* Sets
* Re-declared and initialised
  y ct d dt n
* Time/date-related sets
  firstYr lastYr allButFirstYr firstPeriod
* Various mappings, subsets and counts.
  mapg_k mapg_f mapg_o mapg_i mapg_r mapg_e mapg_ild mapg_fc mapi_r mapi_e mapild_r mapv_g thermalFuel
* Financial
* Fuel prices and quantity limits.
* Generation data.
  exist commit new neverBuild
  noExist nigen sigen schedHydroPlant pumpedHydroPlant moverExceptions validYrBuild integerPlantBuild linearPlantBuild
  possibleToBuild possibleToRefurbish possibleToEndogRetire possibleToRetire endogenousRetireDecisnYrs endogenousRetireYrs
  validYrOperate
* Load data.
* Transmission data.
  slackBus regLower interIsland nwd swd paths uniPaths biPaths transitions validTransitions allowedStates notAllowedStates
  upgradedStates txEarlyComYrSet txFixedComYrSet vtgc nSegment
* Parameters
* Time/date-related sets and parameters.
  lastYear yearNum hydroYearNum lastHydroYear hoursPerBlock
* Various mappings, subsets and counts.
  numReg
* Financial parameters.
  CBAdiscountRates PVfacG PVfacT PVfacsM PVfacsEY PVfacs capexLife annuityFacN annuityFacR txAnnuityFacN txAnnuityFacR
  capRecFac depTCrecFac txCapRecFac txDeptCRecFac
* Fuel prices and quantity limits.
  SRMC totalFuelCost CO2taxByPlant CO2CaptureStorageCost
* Generation data.
  initialCapacity capitalCost capexPlant capCharge refurbCapexPlant refurbCapCharge exogMWretired continueAftaEndogRetire
  WtdAvgFOFmultiplier reservesCapability peakConPlant NWpeakConPlant maxCapFactPlant minCapFactPlant
* Load data.
  AClossFactors NrgDemand ldcMW peakLoadNZ peakLoadNI bigNIgen nxtbigNIgen
* Transmission data.
  locFac_Recip txEarlyComYr txFixedComYr reactanceYr susceptanceYr BBincidence pCap pLoss bigLoss slope intercept
  txCapitalCost txCapCharge
* Reserve energy data.
  reservesAreas reserveViolationPenalty windCoverPropn bigM singleReservesReqF
* Hydrology output data.
  historicalHydroOutput
  ;



*===============================================================================================
* 5. Archive/save input files.

* Create and execute a batch file to archive/save selected files.
File bat "A recyclable batch file" / "%ProgPath%temp.bat" / ; bat.lw = 0 ; bat.ap = 0 ;
putclose bat
  'copy "%DataPath%%GDXinputFile%"      "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%GEMsettings.inc"     "%OutPath%\%runName%\Archive\GEMsettings.inc"' /
  'copy "%ProgPath%GEMpaths.inc"        "%OutPath%\%runName%\Archive\GEMpaths - %scenarioName%.inc"' /
  'copy "%ProgPath%%GEMdataGDX%"        "%OutPath%\%runName%\GDX\"' /
  ;
execute 'temp.bat' ;




* End of file.
