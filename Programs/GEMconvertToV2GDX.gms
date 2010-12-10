* Preliminaries
$offupper offsymxref offsymlist offuellist offuelxref onempty inlinecom { } eolcom !


*===============================================================================================
* Make certain selections

$setglobal   ProgPath       "%system.fp%"
$setglobal   DataPath       "%system.fp%..\Data\"
$setglobal   MatCodePath    "%system.fp%..\Matlab code\"
$setglobal   OutPath        "%system.fp%..\Output\"

$setglobal   ThisMDS        "mds1"      ! The MDS data file you want to use.
$setglobal   numReg          2          ! Number of regions in input data.
$setglobal   numLBs          9          ! Number of laod blocks.

$setglobal   GDXinputfile   "GEM2.0 input data (%numReg%Reg %numLBs%Block %ThisMDS%).gdx"        ! i.e. the file to be read into this program
$setglobal   Finalv2GDX     "Final GEM2.0 input data (%numReg%Reg %numLBs%Block %ThisMDS%).gdx"  ! i.e. the file to be produced by this program

$setglobal   EmbedAdjNZ      198       ! MW added to NZ peak load to overcome potential double-counting of embedded generation (see note on 'Security' worksheet).
$setglobal   EmbedAdjNI      144       ! MW added to NI peak load to overcome potential double-counting of embedded generation (see note on 'Security' worksheet).


*===============================================================================================
* Declarations - sets and parameters needed to read in the GDX file that comes from the GUI.

** Still need mdsx set to read in data for refurb/retire etc - see below after the GDX read.
Set mdsx 'Market development scenarios' / '-1', mds1 * mds5 / ;
Set thisMDS(mdsx) / %thismds% / ;

* Fundamental sets
Sets
  k            'Generation technologies'
  f            'Fuels'
  fg           'Fuel groups'
  g            'Generation plant'
  s            'Shortage or VOLL plants'
  o            'Owners of generating plant'
  fc           'Currencies'
  i            'Substations'
  r            'Regions'
  e            'Zones'
  ild          'Islands'
  p            'Transmission paths (or branches)'
  ps           'Transmission path states (state of upgrade)'
  tupg         'Transmission upgrade projects'
  tgc          'Transmission group constraints'
  y            'Modelled calendar years'
  t            'Time periods (within a year)'
  prf          'Load growth profiles'
  lb           'Load blocks'
  rc           'Reserve classes'
  hY           'Hydrology output years'
  v            'Hydro reservoirs or river systems'
  hd           'Hydrology domain for multiple hydro years'
  m            '12 months'
  hdrs         'Miscellaneous column headers'
  ;

Alias (i,ii), (r,rr), (ild,ild1), (ps,pss) ;

* Mapping sets and subsets
Sets
* Various mappings
  mapm_t(m,t)                                 'Map months into time periods'
  maphd_hY(hd,hY)                             'Map hydrology output years to the hydrology domain years'
  maps_r(s,r)                                 'Map VOLL plants to regions'
  mapf_k(f,k)                                 'Map technology types to fuel types'
  mapf_fg(f,fg)                               'Map fuel groups to fuel types'
  mapLocations(i,r,e,ild)                     'Location mappings'
  mapGenPlant(g,k,i,o)                        'Generation plant mappings'
  mapReservoirs(v,i,g)                        'Reservoir mappings'
  arcNodeMap(p,r,rr)                          'Define the mapping of nodes (regions) to arcs (paths) in order to build the bus-branch incidence matrix'
* Technology
  movers(k)                                   'Technologies for which commissioning date can move during re-optimisation of build timing'
  refurbish(k)                                "Technologies eligible for endogenous 'refurbish or retire' decision"
  endogRetire(k)                              'Technologies eligible for endogenous retirement - in years prior to and including the refurbish or retire decision'
  cogen(k)                                    'Cogeneration technologies'
  peaker(k)                                   'Peaking plant technologies'
  hydroSched(k)                               'Schedulable hydro technologies'
  hydroPumped(k)                              'Pumped storage hydro technologies'
  wind(k)                                     'Wind technologies'
  renew(k)                                    'Renewable technologies'
  thermalTech(k)                              'Thermal technologies'
  CCStech(k)                                  'Carbon capture and storage technologies'
  demandGen(k)                                'Demand side technologies modelled as generation'
  randomiseCapex(k)                           'Specify the technologies able to have their capital costs randomised - within some narrow user-defined range'
  linearBuildTech(k)                          'Specify the technologies able to be partially or linearly built'
* Locations
  regionCentroid(i,r)                         'Identify the centroid of each region with a substation'
  zoneCentroid(i,e)                           'Identify the centroid of each zone with a substation'
  islandCent(i,ild)                           'Identify the centroid of each island with a substation'
* Transmission/network
  txUpgradeTransitions(tupg,r,rr,ps,pss)      'Define the allowable transitions from one transmission state to another'
  ;

Parameters
* Stuff that no longer will come from the GDX as it is transferred to something else.
  i_geocoordinates(i,hdrs)                    'Geographic coordinates for substations'
* Annual (only) data
  i_inflation(y)                              'Inflation rates by year'
  i_coalprices(y)                             'Coal prices by year, $/GJ'
  i_ligniteprices(y)                          'Lignite prices by year, $/GJ'
  i_gasprices(y)                              'Gas prices by year, $/GJ'
  i_dieselprices(y)                           'Diesel prices by year, $/GJ'
  i_gasquantity(y)                            'Gas availability by year, PJ'
  i_dieselquantity(y)                         'Diesel availability by year, PJ'
  i_renewnrgshare(y)                          'Proportion of total energy to be generated from renewable sources by year (0-1 but define only when > 0)'
  i_renewcapshare(y)                          'Proportion of installed capacity that must be renewable by year (0-1 but define only when > 0)'
  i_distdgenrenew(y)                          'Distributed generation (renewable) installed by year, GWh'
  i_distdgenfossil(y)                         'Distributed generation (fossil) installed by year, GWh'
  i_co2tax(y)                                 'CO2 tax by year, $/tonne CO2-equivalent'
  i_hydroOutputAdj(y)                         'Schedulable hydro output adjuster by year (default = 1)'
  i_HVDClevy(y)                               'HVDC charge levied on new South Island plant by year, $/kW'
  i_HVDCreqRevenue(y)                         'Required HVDC revenue to be collected by year, $m (only used for reporting purposes)'
  i_bigNIgen(y)                               'Largest North Island generation plant by year, MW'
  i_nxtbigNIgen(y)                            'Next (second) largest North Island generation plant by year, MW'
  i_bigSIgen(y)                               'Largest South Island generation plant by year, MW'
  i_fkNI(y)                                   'Required frequency keeping in North Island by year, MW'
  i_fkSI(y)                                   'Required frequency keeping in South Island by year, MW'
  i_HVDClosses(y)                             'Maximum loss rate on HVDC link by year'
  i_HVDClossesPO(y)                           'Maximum loss rate on HVDC link with one pole out by year'
* Fuel (only) data
  i_emissionfactors(f)                        'CO2e emissions, tonnes CO2/PJ'
  i_maxNrgByFuel(f)                           'Maximum proportion of total energy from any one fuel type (0-1)'
* Technology (only) data
  i_capcostadjbytech(k)                       'Capital cost adjuster by technology (default = 1)'
  i_capfacTech(k)                             'An assumed (rather than modelled) technology-specific capacity factor - used when computing LRMCs based on input data (i.e. prior to solving the model)'
  i_CapexExposure(k)                          'Proportion of generation plant capital expenditure that is exposed to exchange rates, i.e. the imported share of total plant capex'
  i_linearbuildMW(k)                          'Threshold MW level used to activate linearisation of binary decision variables for plants able to be linearly built'
  i_linearbuildYr(k)                          'Threshold early build year used to activate linearisation of binary decision variables for plants able to be linearly built'
  i_plantlife(k)                              'Generation plant life, years'
  i_refurbishmentlife(k)                      'Generation plant life following refurbishment, years'
  i_retireOffsetYrs(k)                        'Number of years a technology continues to operate for after the decision to endogenously retire has been made'
  i_deprate(k)                                'Depreciation rate for generation plant, technology specific'
  i_peakContribution(k)                       'Contribution to peak by technology'
  i_NWpeakContribution(k)                     'The no wind contribution to peak by technology'
* Generation data
  i_minHydroCapFact(g)                        'Minimum capacity factors for selected schedulable hydro plant'
  i_maxHydroCapFact(g)                        'Maximum capacity factors for selected schedulable hydro plant (default = 1)'
  i_offlinereserve(g)                         'Plant-specific offline reserve capability, 1 = Yes, 0 = No'
  i_refurbDecisionYear(g)                     'Decision year for endogenous "refurbish or retire" decision for eligble generation plant'
  i_ExogenousRetireYr(g)                      'Exogenous retirement year for generation plant'
  i_EarlyComYr(g)                             'Earliest possible commissioning year for each potentially new generation plant'
  i_FixComYr(g)                               'Fixed commissioning year for potentially new generation plant (includes plant fixed never to be built)'
  i_baseload(g)                               'Force plant to be baseloaded, 0/1 (1 = baseloaded)'
  i_nameplate(g)                              'Nameplate capacity of generating plant, MW'
  i_heatrate(g)                               'Heat rate of generating plant, GJ/GWh (default = 3600)'
  i_fof(g)                                    'Forced outage factor for generating plant, proportion (0-1)'
  i_UnitLargestProp(g)                        'Largest proportion of generating plant output carried by a single unit at the plant'
  i_fixedOM(g)                                'Fixed O&M costs by plant, $/kW/year'
  i_varOM(g)                                  'Variable O&M costs by plant, $/MWh'
  i_PumpedHydroMonth(g)                       'Limit on energy per month from pumped hydro plant, GWh'
  i_PumpedHydroEffic(g)                       'Efficiency of pumped energy to stored energy, MWh stored per MWh pumped < 1'
  i_capitalCost(g)                            'Generation plant capital cost, foreign currency per kW'
  i_refurbcapitalcost(g)                      'Generation plant refurbishment capital cost, foreign currency per kW'
  i_minutilisation(g)                         'Switch to turn on the minimum utilisation constraint by plant (0-1, default = 0)'
  i_connectionCost(g)                         'Capital cost for connecting generation plant to grid, $m (NZD)'
  i_FuelDeliveryCost(g)                       'Fuel delivery cost, $/GJ'
  i_CurrencyIndicator(g)                      'Currency indicator (default = 1 = NZD)'
  i_VOLLcap(s)                                'Nameplate capacity of VOLL plant (1 VOLL plant/region), MW'
  i_VOLLcost(s)                               'Value of lost load by VOLL plant (1 VOLL plant/region), $/MWh'
  i_HVDCshr(o)                                'Share of HVDC charge to be incurred by plant owner'
  i_fcIndicator(fc)                           'Foreign currency indicator'
  i_exRates(fc)                               'Exchange rates (foreign currency per NZ dollar)'

  i_AnnualMWlimit                             'Upper bound on total MW of new plant able to be built nationwide in any single year'

  i_hydroweight(hd)                           'Weights on hydro outflows when multiple hydro outputs is used'
  i_PltCapFact(g,m)                           'Plant-specific capacity factor (default = 1)'
  i_FOFmultiplier(k,lb)                       'Forced outage factor multiplier (default = 1)'
  i_minutilbytech(y,k)                        'Minimum utilisation of plant by technology type, proportion (0-1 but define only when > 0)'
  i_peakloadNZp(y,prf)                        'Peak load for New Zealand by year and load growth profile, MW'
  i_peakloadNIp(y,prf)                        'Peak load for North Island by year and load growth profile, MW'
  i_ReserveSwitch(rc)                         'Switch to activate reserves by reserves class'
  i_ReserveAreas(rc)                          'Number of reserves areas (Single or system-wide = 1, By island = 2)'
  i_ReservePenalty(ild,rc)                    'Reserve violation penalty, $/MWh'
  i_reserveReq(y,ild,rc)                      'Reserve requirement by year, island, and class, MW'
  i_propwindcover(rc)                         'Proportion of wind to cover by reserve class (0-1 but define only when > 0)'
  i_NrgDemand(prf,r,y,t,lb)                   'Load by growth profile, region, year, time period and load block, GWh'
  i_HalfHrsPerBlk(m,lb)                       'Count of half hours per load block in each month'
*  i_hydroOutput(v,hY,t)                       'Historical hydro output sequences by reservoir and time period, GWh'
  i_CCSfactor(y,k)                            'Carbon capture and storage factor, i.e. share of emissions sequestered'
  i_CCScost(y,k)                              'Carbon capture and storage cost, $/t CO2e sequestered'
  i_plantreservescap(g,rc)                    'Plant-specific capability per reserve class (0-1 but define only when > 0)'
  i_plantreservescost(g,rc)                   'Plant-specific cost per reserve class, $/MWh'

  i_txCapacity(r,rr,ps)                       'Transmission path capacities (bi-directional), MW'
  i_txCapacityPO(r,rr,ps)                     'Transmission path capacities with one pole out (bi-directional, HVDC link only), MW'
  i_txResistance(r,rr,ps)                     'Transmission path resistance (not really a resistance but rather a loss function coefficient), p.u. (MW)'
  i_txReactance(r,rr,ps)                      'Reactance by state of each transmission path, p.u. (MW)'
  i_txCapitalCost(r,rr,ps)                    'Transmission upgrade capital cost by path, $m'
  i_txEarlyComYr(tupg)                        'Earliest year that a transmission upgrade can occur (this is a parameter, not a set)'
  i_txFixedComYr(tupg)                        'Fixed year in which a transmission upgrade must occur (this is a parameter, not a set)'
  i_txGrpConstraintsLHS(tgc,p)                'Coefficients for left hand side of transmission group constraints'
  i_txGrpConstraintsRHS(tgc)                  'Coefficients for the right hand side of transmission group constraints, MW'
  i_txZonalLocFacs(e)                         'Zonal location factors - adjusters of SRMC'
  i_maxReservesTrnsfr(r,rr,ps,rc)             'Maximum reserves transfer capability in the direction of MW flow on the HCDC link, MW'
  ;



*===============================================================================================
* Load the data from the GDX file.

Sets rc 'Reserve classes' / rc1 'Reserve class 1', rc2 'Reserve class 2' / ;

$gdxin "%DataPath%%GDXinputfile%"
* Fundamental sets
$loaddc y m t lb i r e ild g k f fg o s p ps tgc tupg hY v hd prf fc hdrs
* Mapping sets and subsets
$loaddc mapm_t maphd_hY maps_r mapf_k mapf_fg
$loaddc maplocations mapgenplant mapreservoirs regioncentroid zonecentroid islandcent arcnodemap txUpgradeTransitions 
$loaddc movers refurbish endogretire cogen peaker hydrosched hydropumped wind renew thermaltech CCStech demandGen randomisecapex linearbuildtech
* Parameters
$loaddc i_geocoordinates i_inflation i_fcindicator i_exrates i_coalprices i_ligniteprices i_gasprices i_dieselprices i_gasquantity i_dieselquantity
$loaddc i_renewnrgshare i_renewcapshare i_distdgenrenew i_distdgenfossil i_co2tax i_emissionfactors i_VOLLcap i_VOLLcost i_capcostadjbytech i_PltCapFact i_FOFmultiplier i_minutilbytech
$loaddc i_hydroweight i_minHydroCapFact i_maxHydroCapFact i_hydroOutputAdj i_HVDClevy i_HVDCshr i_HVDCreqRevenue
$loaddc i_peakloadNZp i_peakloadNIp i_bigNIgen i_nxtbigNIgen i_bigSIgen i_fkNI i_fkSI i_HVDClosses i_HVDClossesPO
$loaddc i_ReserveSwitch i_ReserveAreas i_ReservePenalty i_reserveReq i_propwindcover
$loaddc i_NrgDemand i_HalfHrsPerBlk i_CCSfactor i_CCScost i_plantreservescap i_plantreservescost i_offlinereserve
*$loaddc i_refurbDecisionYear i_ExogenousRetireYr
$loaddc i_EarlyComYr i_FixComYr i_AnnualMWlimit i_baseload i_nameplate i_heatrate i_fof i_UnitLargestProp i_fixedOM i_varOM
$loaddc i_PumpedHydroMonth i_PumpedHydroEffic i_capitalcost i_refurbcapitalcost i_minutilisation i_connectionCost i_FuelDeliveryCost i_CurrencyIndicator i_maxNrgByFuel
$loaddc i_capfacTech i_CapexExposure i_linearbuildMW i_linearbuildYr i_plantlife i_refurbishmentlife i_retireOffsetYrs i_deprate i_peakContribution i_NWpeakContribution
$loaddc i_txCapacity i_txCapacityPO i_txResistance i_txReactance i_txCapitalCost i_txEarlyComYr i_txFixedComYr i_txGrpConstraintsLHS i_txGrpConstraintsRHS i_txZonalLocFacs i_maxReservesTrnsfr

* Take care of refurbish/endog retirement and exog retire seperately from what comes in above:
* Sets
refurbish(k) = no ;    refurbish('Coal') = yes ;    refurbish('CCGT') = yes ;    refurbish('OCGT') = yes ;     refurbish('DslPkr') = yes ;
endogretire(k) = no ;  endogretire('Coal') = yes ;  endogretire('CCGT') = yes ;  endogretire('OCGT') = yes ;   endogretire('DslPkr') = yes ;
* Parameters
i_refurbishmentlife(k) = 0 ; i_refurbishmentlife('Coal') = 22 ; i_refurbishmentlife('CCGT') = 30 ; i_refurbishmentlife('OCGT') = 25 ; i_refurbishmentlife('DslPkr') = 25 ;
i_retireOffsetYrs(k) = 0 ;   i_retireOffsetYrs('Coal') = 5 ;    i_retireOffsetYrs('CCGT') = 6 ;    i_retireOffsetYrs('OCGT') = 8 ;    i_retireOffsetYrs('DslPkr') = 8 ;

Table refurbDecYr(g,mdsx)
             mds1    mds2    mds3    mds4    mds5
Southdn      2018    2018    2018
TaranCC      2018    2018    2018    2018    2018
OtahuB       2019            2019    2019    2019
HlyUnit5     2027    2027    2027    2027    2027
HlyUnit6     2021    2021    2021    2021    2021
SthE105      2024    2024    2024    2024    2024
HuntC1       2017    2017    2017    2017    2017
HuntC2                       2018    2018    2018
HuntC3               2019    2019    2019    2019
HuntC4       2020    2020    2020    2020    2020 ;

i_refurbDecisionYear(g) = 0 ;  i_refurbDecisionYear(g) = refurbDecYr(g,'%ThisMDS%') ;

Table exogRetYr(g,mdsx)
             mds1    mds2    mds3    mds4    mds5
Southdn                              2048    2048
OtahuB               2020
HuntC2       2018    2020
HuntC3       2020
Wairaki      2013    2013    2013    2013    2013
Ngawha       2020
Whirina      2029    2029    2029    2029    2029 ;


i_ExogenousRetireYr(g) = 0 ; i_ExogenousRetireYr(g) = exogRetYr(g,'%ThisMDS%') ;

i_refurbcapitalcost(g) = 0 ;
i_refurbcapitalcost('Southdn') = 480 ;   i_refurbcapitalcost('TaranCC') = 480 ;
i_refurbcapitalcost('OtahuB') = 480 ;    i_refurbcapitalcost('HlyUnit5') = 492 ;
i_refurbcapitalcost('HlyUnit6') = 400 ;  i_refurbcapitalcost('SthE105') = 368 ;
i_refurbcapitalcost('HuntC1') = 864 ;    i_refurbcapitalcost('HuntC2') = 864 ;
i_refurbcapitalcost('HuntC3') = 864 ;    i_refurbcapitalcost('HuntC4') = 864 ;
*i_refurbcapitalcost(g)$( i_refurbDecisionYear(g) = 0 ) = 0 ;

i_CurrencyIndicator('Southdn') = 1 ;   i_CurrencyIndicator('TaranCC') = 1 ;
i_CurrencyIndicator('OtahuB') = 1 ;    i_CurrencyIndicator('HlyUnit5') = 1 ;
i_CurrencyIndicator('HlyUnit6') = 1 ;  i_CurrencyIndicator('SthE105') = 1 ;
i_CurrencyIndicator('HuntC1') = 1 ;    i_CurrencyIndicator('HuntC2') = 1 ;
i_CurrencyIndicator('HuntC3') = 1 ;    i_CurrencyIndicator('HuntC4') = 1 ;
i_CurrencyIndicator(g)$( i_CurrencyIndicator(g) = 0 ) = 1 ;

*Display refurbish, endogretire, i_refurbishmentlife, i_retireOffsetYrs, i_refurbDecisionYear, i_ExogenousRetireYr, i_refurbcapitalcost, i_CurrencyIndicator ;


*===============================================================================================
* More declarations - sets and parameters not read in from GDX file.

Sets
  geo                            'Geographic co-ordinate types' / Easting  'New Zealand Transverse Mercator, metres'
                                                                  Northing 'New Zealand Transverse Mercator, metres'
                                                                  Long     'Degrees of longitude - note that the minutes are expressed as a decimal'
                                                                  Lat      'Degrees of latitude - note that the minutes are expressed as a decimal' /
  coal(f)                        'Coal fuel'                    / coal /
  lignite(f)                     'Lignite fuel'                 / lig /
  gas(f)                         'Gas fuel'                     / gas / 
  diesel(f)                      'Diesel fuel'                  / dsl /
  Haywards(i)                    'Haywards substation'          / hay /
  Benmore(i)                     'Benmore substation'           / ben /
  col                            'RGB color mix'                / 0 * 255   /
  exist(g)                       'Generation plant that are presently operating'
  commit(g)                      'Generation plant that are assumed to be committed'
  new(g)                         'Potential generation plant that are neither existing nor committed'
  neverBuild(g)                  'Generation plant that are determined a priori by user never to be built'

Alias (col,red,green,blue) ;

Sets
  techColor(k,red,green,blue)       'RGB color mix for technologies - to pass to plotting applications'
  fuelColor(f,red,green,blue)       'RGB color mix for fuels - to pass to plotting applications'
  fuelGrpcolor(fg,red,green,blue)   'RGB color mix for fuel groups - to pass to plotting applications'
  ;

* If you want any of these sets to come from the GDX/GUI, put their declaration above this line.
$setglobal NumVertices  4        ! Number of vertices for piecewise linear transmission losses function (number of vertices = number of segments  + l)

Sets
  rt                             'Model run types'              / tmg      'Run model GEM to determine optimal timing of new builds'
                                                                  reo      'Run model GEM to re-optimise timing while allowing specified plants to move'
                                                                  dis      'Run model DISP with build forced and timing fixed'   /
  dt                             'Types of discounting'         / mid      'Middle of the period within each year'
                                                                  eoy      'End of year'   /
  ct                             'Capital expenditure types'    / genplt   'New generation plant'
                                                                  refplt   'Refurbish existing generation plant' /
  n                              'Piecewise linear vertices'    / n1 * n%NumVertices% /
  d                              'Discount rate classes'        / d1       "Generation investor's post-tax real weighted average cost of capital"
                                                                  d2       "Transmission investor's post-tax real weighted average cost of capital"
                                                                  d3       'Lower discount rate for CBA sensitivity analysis' 
                                                                  d4       'Central discount rate for CBA sensitivity analysis'
                                                                  d5       'Upper discount rate for CBA sensitivity analysis'    /
  selectedGrowthProfile(prf)     'User-specified load growth profile (Low, Medium, or High)'                            / medium /
  hydroYrForTiming(hY)           'Hydro output year to use when solving GEM to get the build timing decision'           / Average /
  hydroYrForReopt(hY)            'Hydro output year to use when solving GEM to re-optimise the build timing decision'   / 1932 /
  buildsoln(rt)                  'Determine which run type element to use for reporting results related to building generation or transmission'
  firstyr(y)                     'First modelled year - as a set, not a scalar'
  lastyr(y)                      'Last modelled year - as a set, not a scalar'
  allButFirstYr(y)               'All modelled years except the first year - as a set, not a scalar'
  firstPeriod(t)                 'First time period (i.e. period within the modelled year)'
  thermalFuel(f)                 'Thermal fuels'
  mapi_r(i,r)                    'Map regions to substations'
  mapi_e(i,e)                    'Map zones to substations'
  mapi_ild(i,ild)                'Map islands to substations'
  mape_r(e,r)                    'Map the regions to zones'
  mapild_r(ild,r)                'Map the regions to islands'
  mapg_k(g,k)                    'Map technology types to generating plant'
  mapg_o(g,o)                    'Map plant owners to generating plant'
  mapg_i(g,i)                    'Map substations to generating plant'
  mapg_f(g,f)                    'Map fuel types to generating plant'
  mapg_fg(g,fg)                  'Map fuel groups to generating plant'
  mapg_r(g,r)                    'Map regions to generating plant'
  mapg_e(g,e)                    'Map zones to generating plant'
  mapg_ild(g,ild)                'Map islands to generating plant'
  mapg_fc(g,fc)                  'Map currency types to generating plant - used to convert capex values to NZD'
  mapv_i(v,i)                    'Map substations to reservoirs'
  mapv_g(v,g)                    'Map generating plant to reservoirs'
  schedHydroPlant(g)             'Schedulable hydro generation plant'
  pumpedHydroPlant(g)            'Pumped hydro generation plant'
  noexist(g)                     'Generation plant that are not presently operating'
  nigen(g)                       'North Island generation plant'
  sigen(g)                       'South Island generation plant'
  moverExceptions(g)             'Generating plant to be excepted from the technology-based determination of movers'
  validYrOperate(g,y,t)          'Valid years and periods in which an existing, committed or new plant can generate. Use to fix GEN to zero in invalid years'
  validYrBuild(g,y)              'Valid years in which new generation plant may be built'
  possibleToBuild(g)             'Generating plant that may possibly be built in any valid build year'
  linearPlantBuild(g)            'Generating plant able to be linearly or incrementally built'
  integerPlantBuild(g)           'Generating plant that must be integer built, i.e. all or nothing (unless cgenyr in RunGEM is less than LastYr)'
  possibleToEndogRetire(g)       'Generating plant that may possibly be endogenously retired'
  possibleToRetire(g)            'Generating plant that may possibly be retired (exogenously or endogenously)'
  possibleToRefurbish(g)         'Generating plant that may possibly be refurbished in any valid modelled year'
  endogenousRetireDecisnYrs(g,y) 'The years in which generation plant able to be endogenously retired can take the decision to retire'
  endogenousRetireYrs(g,y)       'The years in which generation plant able to be endogenously retired can actually be retired'
  slackBus(r)                    'Designate a region to be the slack or reference bus'
  regLower(r,rr)                 'The lower triangular part of region-region matrix, i.e. where ord(r) > ord(rr)'
  interIsland(ild,ild1)          'Interisland island pairings (excludes intra-island)'
  nwd(r,rr)                      'Northward direction of flow on Benmore-Haywards HVDC'
  swd(r,rr)                      'Southward direction of flow on Benmore-Haywards HVDC'
  transitions(tupg,r,rr,ps,pss)  'For all transmission paths, define the allowable transitions from one upgrade state to another'
  AllowedStates(r,rr,ps)         'All of the allowed states (initial and upgraded) for each active path'
  notAllowedStates(r,rr,ps)      'All r-rr-ps tuples not in the set called AllowedStates'
  paths(r,rr)                    'All valid transmission paths'
  uniPaths(r,rr)                 'Valid unidirectional transmission paths'
  biPaths(r,rr)                  'Valid bidirectional transmission paths'
  upgradedStates(r,rr,ps)        'All allowed upgraded states on each path'
  validTransitions(r,rr,ps,pss)  'All allowed upgrade transitions on each valid path'
  txEarlyComYrSet(tupg,r,rr,ps,pss,y) 'Years prior to the earliest year in which a particular upgrade can occur - a set form of txEarlyComYr'
  txFixedComYrSet(tupg,r,rr,ps,pss,y) 'Fixed year in which a particular upgrade must occur - set form of txFixedComYr'
  vtgc(tgc)                      'Valid transmission group constraints'
  nsegment(n)                    'Line segments for piecewise linear transmission losses function (number of segments = number of vertices - l)'
  ;

Parameters
  i_WACCg                        "Generation investor's post-tax real weighted average cost of capital"                           / 0.08 /
  i_WACCt                        "Transmission investor's post-tax real weighted average cost of capital"                         / 0.08 /
  i_depType                      'Flag to indicate depreciation method - 1 for declining value, 0 for straight line'              / 1 /
  i_taxRate                      'Corporate tax rate'                                                                             / .30 /
  i_hydroOutputScalar            'Scale the hydro output sequence used to determine the timing of new builds'                     / 0.97 /
  i_penaltyViolateRenNrg         'Penalty used to make renewable energy constraint feasible, $m/GWh'                              / 0.4  /
  i_renNrgShrOn                  'Switch to control usage of renewable energy share constraint 0=off/1=on'                        / 1  /
  i_noRetire                     'Number of years following and including the first modelled year for which endogenous generation plant retirement decisions are prohibited' / 2 /
  i_randomCapexCostAdjuster      'Specify the bounds for a small +/- random adjustment to generation plant capital costs'         / 0 /
  i_txPlantLife                  'Life of transmission equipment, years'                                                          / 60 /
  i_txDepRate                    'Depreciation rate for transmission equipment'                                                   /.06 /
  i_AClossFactorNI               'Upwards adjustment to load to account for NI AC (or intraregional) losses'                      / 0.0368 / ! .0368 for 2-region and .0120 for 18-region
  i_AClossFactorSI               'Upwards adjustment to load to account for SI AC (or intraregional) losses'                      / 0.0534 / ! .0534 for 2-region and .0180 for 18-region
  i_useReserves                  'Global flag (0/1) to indicate use of at least one reserve class (0 = no reserves are modelled)' / 0 /
  i_DCloadFlow                   'Flag (0/1) to indicate use of either DC load flow (1) or transportation formulation (0)'        / 0 /
  i_security                     'Flag to indicate desired grid security (legitimate values are -1, 0, 1, or 2)'                  / 1 /
                                 ! -1 = run the model with the five security constraints suppressed.
                                 !  0 = run the model with n (i.e. n-0) security.
                                 !  1 = run the model with n-1 security.
                                 !  2 = run the model with n-2 security.
  i_firstYear                    'First modelled year - as a scalar, not a set'                                                     / 2010 /
  i_lastYear                     'Last modelled year - as a scalar, not a set'                                                      / 2050 /
  i_firstHydroYear               'First year of hydrology output data (ignoring the 1st two elements of hY - multiple and average)' / 1932 /
  i_lastHydroYear                'Last year of hydrology output data (ignoring the 1st two elements of hY - multiple and average)'  / 2007 /
  i_fuelPrices(f,y)              'Fuel prices by fuel type and year, $/GJ'
  i_fuelQuantities(f,y)          'Quantitative limit on availability of various fuels by year, PJ'
  i_reserveReqMW(y,ild,rc)       'Reserve requirement by year, island, and reserve class, MW'
  i_zonalLocFacs(e)              'Zonal location factors - adjusters of SRMC'
* If you want any of these parameters to come from the GDX/GUI, put their declarations above this line.
  counter                        'A recyclable counter - set equal to zero each time before using'
  yearnum(y)                     'Real number associated with each year'
  multipleHydroYear              'Ordinal ranking of the multiple hydrology output year'
  averageHydroYear               'Ordinal ranking of the average hydrology output year'
  HydroYearNum(hY)               'Real number associated with each hydrology output year'
  hoursPerBlock(t,lb)            'Hours per load block by time period'
  numReg                         'Number of regions (or, if you like, nodes or buses)'
  CBAdiscountRates(d)            'CBA discount rates - for reporting results only'
  pvfacg(y,t)                    "Generation investor's present value factor by period"
  pvfact(y,t)                    "Transmission investor's present value factor by period"
  pvfacsM(y,t,d)                 'Present value factors as at middle of period for Generation, Transmission, and CBA discounting in post-solve calculations'
  pvfacsEY(y,d)                  'Present value factors as at end of year for Generation, Transmission, and CBA discounting in post-solve calculations'
  pvfacs(y,t,d,dt)               'All present value factors - for Generation, Transmission, and CBA discounting in post-solve calculations'
  capexlife(k,ct)                'Plant life by technology and capex type, years'
  annuityfacn(y,k,ct)            'Nominal annuity factor by technology, year and type of capex - depends on annual inflation rate'
  annuityfacr(k,ct)              'Real annuity factor by technology and type of capex'
  caprecfac(y,k,ct)              'Capital recovery factor by technology including a nominal accounting treatment of depreciation tax credit'
  deptcrecfac(y,k,ct)            'Recovery factor by technology for just the depreciation tax credit portion of caprecfac'
  totalFuelCost(g,y)             'Total fuel cost - price plus fuel delivery charge all times heatrate - by plant and year, $/MWh'
  CO2taxByPlant(g,y)             'CO2 tax by plant and year, $/MWh'
  CO2CaptureStorageCost(g,y)     'Carbon capture and storage cost by plant and year, $/MWh'
  SRMC(g,y)                      'Short run marginal cost of each generation project by year, $/MWh'
  reservesCapability(g,rc)       'Generating plant reserve capability per reserve class, MW'
  initialCapacity(g)             'Capacity of existing generating plant in the first modelled year'
  exogMWretired(g,y)             'Exogenously retired MW by plant and year, MW'
  peakConPlant(g,y)              'Contribution to peak of each generating plant by year'
  NWpeakConPlant(g,y)            'Contribution to peak when there is no wind of each generating plant by year'
  WtdAvgFOFmultiplier(k,lb)      'FOF multiplier by technology and load block - averaged using hours in block as weights (default = 1)'
  maxCapFactPlant(g,t,lb)        'Maximum capacity factor by plant - incorporates forced outage rates'
  minCapFactPlant(g,y,t)         'Minimum capacity factor - only defined for schedulable hydro and wind at this stage'
  continueAftaEndogRetire(g)     'Number of years a generation plant keeps going for after the decision to endogenously retire has been made'
  capitalCost(g)                 'Generation plant capital cost, foreign currency per kW'
  capexPlant(g)                  'Capital cost for new generation plant, $/MW'
  refurbCapexPlant(g)            'Capital cost for refurbishing existing generation plant, $/MW'
  capCharge(g,y)                 'Annualised or levelised capital charge for new generation plant, $/MW/yr'
  refurbCapCharge(g,y)           'Annualised or levelised capital charge for refurbishing existing generation plant, $/MW/yr'
  AClossFactors(ild)             'Upwards adjustment to load to account for AC (or intraregional) losses'
  NrgDemand(r,y,t,lb)            'Load (or energy demand) by region, year, time period and load block for selected growth profile, GWh (used to create ldcMW)'
  ldcMW(r,y,t,lb)                'MW at each block by region, year and period'
  peakLoadNZ(y)                  'Peak load for New Zealand by year for selected growth profile, MW'
  peakLoadNI(y)                  'Peak load for North Island by year for selected growth profile, MW'
  bigNIgen(y)                    'Largest North Island generation plant by year, MW'
  nxtbigNIgen(y)                 'Next (second) largest North Island generation plant by year, MW'
  locfac_recip(e)                'Reciprocal of zonally-based location factors'
  txEarlyComYr(tupg,r,rr,ps,pss) 'Earliest year that a transmission upgrade can occur (this is a parameter, not a set)'
  txFixedComYr(tupg,r,rr,ps,pss) 'Fixed year in which a transmission upgrade must occur (this is a parameter, not a set)'
  reactanceYr(r,rr,y)            'Reactance by year for each transmission path. Units are p.u.'
  susceptanceYr(r,rr,y)          'Susceptance by year for each transmission path. Units are p.u.'
  BBincidence(p,r)               'Bus-branch incidence matrix'
  pCap(r,rr,ps,n)                'Capacity per piecewise linear segment, MW'
  pLoss(r,rr,ps,n)               'Losses per piecewise linear segment, MW'
  bigLoss(r,rr,ps)               'Upper bound on losses along path r-rr when in state ps, MW'
  slope(r,rr,ps,n)               'Slope of each piecewise linear segment'
  intercept(r,rr,ps,n)           'Intercept of each piecewise linear segment'
  txAnnuityFacn(y)               'Nominal transmission annuity factor and year - depends on annual inflation rate'
  txAnnuityFacr                  'Real transmission annuity factor'
  txCapRecFac(y)                 'Capital recovery factor for transmission - including a nominal accounting treatment of depreciation tax credit'
  txDeptCRecFac(y)               'Recovery factor for just the depreciation tax credit portion of txcaprecfac'
  txCapitalCost(r,rr,ps)         'Capital cost of transmission upgrades by path and state, $m'
  txCapCharge(r,rr,ps,y)         'Annualised or levelised capital charge for new transmission investment - $m/yr'
  reservesAreas(rc)              'Reserves areas (Single area or systemwide = 1, Island-based reserves = 2)'
  singleReservesReqF(rc)         'Flag to inidicate if there is a single systemwide reserve requirement'
  reserveViolationPenalty(ild,rc)'Reserve violation penalty, $/MWh'
  windCoverPropn(rc)             'Proportion of wind to be covered by reserves, (0-1)'
  bigM(ild,ild1)                 'A large positive number'
  ;


*===============================================================================================
* Initialise sets and parameters.

* a) Time/date-related sets and parameters.
firstYr(y)$(ord(y) = 1) = yes ;
lastYr(y)$(ord(y) = card(y)) = yes ;

allButFirstYr(y)$(not firstYr(y)) = yes ;

yearnum(y) = i_firstYear + ord(y) - 1 ;

firstPeriod(t)$( ord(t) = 1 ) = yes ;

* Denote 'multiple' hydrology year with a '1'; denote 'average' hydrology year with a '2'; and denote each actual hydrology
* year with a real number corresponding to that year, i.e. 1932 = 1932, 1933 = 1933, ... 2007 = 2007.
loop(hY$sameas(hY,'Multiple'), multipleHydroYear = ord(hY) ) ;
loop(hY$sameas(hY,'Average'),  averageHydroYear = ord(hY) ) ;

HydroYearNum(hY)$sameas(hY,'Multiple') = multipleHydroYear ;
HydroYearNum(hY)$sameas(hY,'Average')  = averageHydroYear ;

HydroYearNum(hY)$( ord(hY) > averageHydroYear) = i_firstHydroYear + ord(hY) - multipleHydroYear - averageHydroYear ;

* Count hours per load block per time period.
hoursPerBlock(t,lb) = sum(mapm_t(m,t), 0.5 * i_HalfHrsPerBlk(m,lb)) ;


* b) Create various mappings.
* Location mappings
loop(maplocations(i,r,e,ild),
  mapi_r(i,r) = yes ;
  mapi_e(i,e) = yes ;
  mapi_ild(i,ild) = yes ;
  mape_r(e,r) = yes ;
  mapild_r(ild,r) = yes ;
) ;
* Generation plant mappings
loop(mapgenplant(g,k,i,o),
  mapg_k(g,k) = yes ;
  mapg_o(g,o) = yes ;
  mapg_i(g,i) = yes ;
) ;
mapg_f(g,f)     = yes$sum(mapg_k(g,k), mapf_k(f,k) ) ;
mapg_fg(g,fg)   = yes$sum(mapg_f(g,f), mapf_fg(f,fg) ) ;
mapg_r(g,r)     = yes$sum(mapg_i(g,i), mapi_r(i,r) ) ;
mapg_e(g,e)     = yes$sum(mapg_i(g,i), mapi_e(i,e) ) ;
mapg_ild(g,ild) = yes$sum(mapg_r(g,r), mapild_r(ild,r) ) ;
mapg_fc(g,fc)$(  i_fcindicator(fc) = i_CurrencyIndicator(g) ) = yes ;
* Reservoir mappings
loop(mapreservoirs(v,i,g),
  mapv_i(v,i) = yes ;
  mapv_g(v,g) = yes ;
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
CBAdiscountRates('d1') = i_WACCg ;
CBAdiscountRates('d2') = i_WACCt ;
CBAdiscountRates('d3') = .04 ;
CBAdiscountRates('d4') = .07 ;
CBAdiscountRates('d5') = .10 ;

PVfacG(y,t) = 1 / ( 1 + i_WACCg ) ** ( (yearnum(y) - i_firstYear) + (ord(t) * 2 - 1) / ( 2 * card(t) ) ) ;

PVfacT(y,t) = 1 / ( 1 + i_WACCt ) ** ( (yearnum(y) - i_firstYear) + (ord(t) * 2 - 1) / ( 2 * card(t) ) ) ;

PVfacsM(y,t,d) = 1 / ( 1 + CBAdiscountRates(d) ) ** ( (yearnum(y) - i_firstYear) + (ord(t) * 2 - 1) / ( 2 * card(t) ) ) ;

PVfacsEY(y,d)  = 1 / ( 1 + CBAdiscountRates(d) ) ** (  yearnum(y) - i_firstYear + 1 ) ;

pvfacs(y,t,d,'mid') = PVfacsM(y,t,d) ;
pvfacs(y,t,d,'eoy') = PVfacsEY(y,d) ;

capexlife(k,'genplt') = i_plantlife(k) ;
capexlife(k,'refplt') = i_refurbishmentlife(k) ;

annuityfacn(y,k,ct)$i_WACCg = ( 1 - ( 1 + i_WACCg + i_inflation(y) ) ** (-capexlife(k,ct)) ) / i_WACCg ;

annuityfacr(k,ct)$i_WACCg   = ( 1 - ( 1 + i_WACCg ) ** (-capexlife(k,ct)) ) / i_WACCg ;

* i_depType = 0 implies straight line depreciation; i_depType = 1 implies a declining balance method.
if(i_depType = 0,
  caprecfac(y,k,ct)$annuityfacr(k,ct)   = ( 1 - i_taxRate * annuityfacn(y,k,ct) / capexlife(k,ct) )  / annuityfacr(k,ct) ;
  deptcrecfac(y,k,ct)$annuityfacr(k,ct) =     ( i_taxRate * annuityfacn(y,k,ct) / capexlife(k,ct) )  / annuityfacr(k,ct) ;
  else
  caprecfac(y,k,ct)$annuityfacr(k,ct)   = ( 1 - i_deprate(k) * i_taxRate / (i_WACCg + i_inflation(y) + i_deprate(k)) ) / annuityfacr(k,ct) ;
  deptcrecfac(y,k,ct)$annuityfacr(k,ct) =     ( i_deprate(k) * i_taxRate / (i_WACCg + i_inflation(y) + i_deprate(k)) ) / annuityfacr(k,ct) ;
) ;


* d) Fuel prices and limits
i_fuelPrices(f,y)$coal(f)    = i_coalprices(y) ;
i_fuelPrices(f,y)$lignite(f) = i_ligniteprices(y) ;
i_fuelPrices(f,y)$gas(f)     = i_gasprices(y) ;
i_fuelPrices(f,y)$diesel(f)  = i_dieselprices(y) ;

i_fuelQuantities(f,y)$gas(f)    = i_gasquantity(y) ;
i_fuelQuantities(f,y)$diesel(f) = i_dieselquantity(y) ;

* Define short run marginal cost (and its components) of each generating plant.
totalFuelCost(g,y) = 1e-3 * i_heatrate(g) * sum(mapg_f(g,f), ( i_fuelPrices(f,y) + i_FuelDeliveryCost(g) ) ) ;

CO2taxByPlant(g,y) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_co2tax(y) * (1 - i_CCSfactor(y,k)) * i_emissionfactors(f) ) ;

CO2CaptureStorageCost(g,y) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_CCScost(y,k) * i_CCSfactor(y,k) * i_emissionfactors(f) ) ;

SRMC(g,y) = i_varOM(g) + totalFuelCost(g,y) + CO2taxByPlant(g,y) + CO2CaptureStorageCost(g,y) ;

* If srmc is zero or negligible (< .05) for any plant, assign a positive small value.
SRMC(g,y)$( SRMC(g,y) < .05 ) = .05 * ord(g) / card(g) ;


* e) Generation data.
* Calculate reserve capability per generating plant.
reservesCapability(g,rc)$i_plantreservescap(g,rc) = i_nameplate(g) * i_plantreservescap(g,rc) ;

* Derive various generating plant subsets.
* Existing plant [i.e. exist(g) and i_nameplate(g) > 0, then exist(g) = yes].
exist(g)$( ord(g) <= 46 ) = yes ;
exist(g)$( i_nameplate(g) = 0 ) = no ;
* Not an existing plant.
noexist(g)$( not exist(g) ) = yes ;
noexist(g)$( i_nameplate(g) = 0 ) = no ;

* Neverbuild - a plant is never built if it doesn't exist and i_fixComYr or i_EarlyComYr > i_lastYear.
* Also, if i_nameplate <= 0.
neverbuild(noexist(g))$( i_fixComYr(g) > i_lastYear or i_EarlyComYr(g) > i_lastYear ) = yes ;
neverbuild(g)$( i_nameplate(g) <= 0 ) = yes ;
* Committed - build year is fixed by user at something greater than or equal to firstyear, and plant is not in the neverbuild set.
commit(noexist(g))$( ( i_fixComYr(g) >= i_firstYear ) * ( not neverbuild(g) ) ) = yes ;
* New - a plant is 'new' if it's neither existing nor committed nor in the neverbuild set.
new(noexist(g))$( not ( commit(g) or neverbuild(g) ) ) = yes ;
* North and South Island plant
nigen(g)$mapg_ild(g,'ni') = yes ;  nigen(neverbuild(g)) = no ;
sigen(g)$mapg_ild(g,'si') = yes ;  sigen(neverbuild(g)) = no ;

* Identify exceptions to the technology-determined list of plant movers, i.e. if user fixes build year to a legitimate value, then
* don't allow the plant to be a mover.
loop(movers(k), moverExceptions(noexist(g))$( mapg_k(g,k) * ( i_fixComYr(g) >= i_firstYear ) * ( i_fixComYr(g) <= i_lastYear ) ) = yes ) ;

* Define the valid years in which a generating plant may operate.
* Existing.
validYrOperate(exist(g),y,t) = yes ;
* For committed plant, define valid operating years based on the year the capacity is assumed to become operational.
validYrOperate(commit(g),y,t)$( yearnum(y) >= i_fixComYr(g) ) = yes ;
* For new plant, define valid operating years based on the earliest commissioning year.
validYrOperate(new(g),y,t)$( yearnum(y) >= i_EarlyComYr(g) ) = yes ;
* Remove plant facing an endogenous refurbishment/retirement decision for the years after the refurbished kit has reached the end of its life.
validYrOperate(g,y,t)$( i_refurbDecisionYear(g) * ( yearnum(y) > i_refurbDecisionYear(g) + sum(mapg_k(g,k), i_refurbishmentlife(k)) ) ) = no ;
* Remove decommissioned plant and palnt unable to ever be built from validYrOperate.
validYrOperate(g,y,t)$( i_ExogenousRetireYr(g) * ( yearnum(y) >= i_ExogenousRetireYr(g) ) ) = no ;
validYrOperate(neverbuild(g),y,t) = no ;

* Define the valid years in which a new plant may be built.
validYrBuild(commit(g),y)$( yearnum(y) = i_fixComYr(g) ) = yes ;
validYrBuild(new(g),y)$( yearnum(y) >= i_EarlyComYr(g) ) = yes ;
validYrBuild(neverbuild(g),y) = no ;

* Identify the plant that may be built, i.e. it doesn't already exist or it is not otherwise prevented from being built.
possibleToBuild(g)$sum(y$validYrBuild(g,y), 1) = yes ;

* Identify generation plant that can be linearly or incrementally built, and those that must be integer builds.
loop((g,k)$( noexist(g) * linearbuildtech(k) * mapg_k(g,k) * ( not i_fixComYr(g) ) ),
  linearPlantBuild(g)$( i_nameplate(g) >= i_linearbuildMW(k) ) = yes ;
  linearPlantBuild(g)$( i_EarlyComYr(g) >= i_linearbuildYr(k) ) = yes ;
) ;
* If not able to be linearly built, then must be integer build.
integerPlantBuild(noexist(g))$( not linearPlantBuild(g) ) = yes ;
integerPlantBuild(neverbuild(g)) = no ;

* Define capacity of existing plant in first modelled year. Note that if capacity is committed in the first modelled
* year, it is treated as 'new' plant capacity as far as GEM is concerned.
initialCapacity(exist(g)) = i_nameplate(g) ;

* Define exogenously retired MW by plant and year.
exogMWretired(g,y)$( i_ExogenousRetireYr(g) * ( yearnum(y) = i_ExogenousRetireYr(g) ) ) = i_nameplate(g) ;

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
    endogenousRetireDecisnYrs(g,y)$( ( yearnum(y) >= i_firstYear + i_noRetire                        ) * ( yearnum(y) <= i_refurbDecisionYear(g) ) ) = yes ;
    endogenousRetireYrs(g,y)$(       ( yearnum(y) >= i_firstYear + i_noRetire + i_retireOffsetYrs(k) ) * ( yearnum(y) <= i_refurbDecisionYear(g) + i_retireOffsetYrs(k) ) ) = yes ;
  else
    endogenousRetireDecisnYrs(g,y)$( ( yearnum(y) >= i_firstYear + i_noRetire                        ) * ( yearnum(y) = i_refurbDecisionYear(g) ) ) = yes ;
    endogenousRetireYrs(g,y)$(       ( yearnum(y) >= i_firstYear + i_noRetire + i_retireOffsetYrs(k) ) * ( yearnum(y) = i_refurbDecisionYear(g) + i_retireOffsetYrs(k) ) ) = yes ;
  ) ;
) ;

* Compute the years a plant must keep going for after the decision to endogenously retire it has been made
loop(refurbish(k),
  continueAftaEndogRetire(g)$( possibleToEndogRetire(g) * mapg_k(g,k) ) = i_retireOffsetYrs(k) ;
) ;

* Define capital costs for new generation plant:
* - Capital costs are first calculated as if capex is lumpy. They are possible adjusted according to one of two
*   adjustments, and are then converted to a levelised or annualised basis (i.e. see capCharge).

* First, transfer i_capitalCost to capitalCost.
capitalCost(g) = i_capitalCost(g) ;

* Next, randomly adjust capitalCost to create mathematically different costs - this helps the solver but makes no appreciable economic difference
* provided i_randomCapexCostAdjuster is small.
loop(randomisecapex(k),
  capitalCost(noexist(g))$mapg_k(g,k) =
  uniform( (capitalCost(g) - i_randomCapexCostAdjuster * capitalCost(g)),(capitalCost(g) + i_randomCapexCostAdjuster * capitalCost(g)) ) ;
) ;

* Now convert capital cost of plant ('capitalCost' and 'i_refurbCapitalCost') from foreign currency to NZ$/MW and, in the case
* of foreign or imported costs, scale up the capex cost to include the local capex component.
loop(fc,
  if(sameas(fc,'nzd'),
    capexPlant(g)$mapg_fc(g,fc)       = 1e3 * 1 / i_exrates(fc) * capitalCost(g) ;
    refurbCapexPlant(g)$mapg_fc(g,fc) = 1e3 * 1 / i_exrates(fc) * i_refurbCapitalCost(g) ;
    else
    capexPlant(g)$mapg_fc(g,fc)       = 1e3 * 1 / i_exrates(fc) * capitalCost(g)         * ( 1 + (1 - sum(mapg_k(g,k), i_CapexExposure(k))) ) ;
    refurbCapexPlant(g)$mapg_fc(g,fc) = 1e3 * 1 / i_exrates(fc) * i_refurbCapitalCost(g) * ( 1 + (1 - sum(mapg_k(g,k), i_CapexExposure(k))) ) ;
  ) ;
) ;

* Zero out any refubishment capex costs if the plant is not actually a candidate for refurbishment.
refurbCapexPlant(g)$( not possibleToRefurbish(g) ) = 0 ;

* Now adjust (lumpy) capex cost by the technology specific adjuster.
loop(k, capexPlant(g)$(       mapg_k(g,k) * noexist(g) ) = capexPlant(g)       * i_CapCostAdjByTech(k) ) ;
loop(k, refurbCapexPlant(g)$( mapg_k(g,k) * exist(g) )   = refurbCapexPlant(g) * i_CapCostAdjByTech(k) ) ;

* Now add on the 'variablised' connection costs to the adjusted plant capital costs - continue to yield NZ$/MW.
capexPlant(g)$i_nameplate(g) = capexPlant(g) + ( 1e6 * i_connectionCost(g) / i_nameplate(g) ) ;

* finally, convert lumpy capital costs to levelised capital charge (units are now NZ$/MW/yr).
capCharge(g,y)       = capexPlant(g)       * sum(mapg_k(g,k), caprecfac(y,k,'genplt')) ;
refurbCapCharge(g,y) = refurbCapexPlant(g) * sum(mapg_k(g,k), caprecfac(y,k,'refplt')) ;
refurbCapCharge(g,y)$( yearnum(y) < i_refurbDecisionYear(g) ) = 0 ;
refurbCapCharge(g,y)$( yearnum(y) > i_refurbDecisionYear(g) + sum(mapg_k(g,k), i_refurbishmentlife(k)) ) = 0 ;


* f) Load data.
AClossFactors('ni') = i_AClossFactorNI ;
AClossFactors('si') = i_AClossFactorSI ;

* Transfer i_NrgDemand to NrgDemand for the selected growth profile and adjust for intraregional AC transmission losses.
NrgDemand(r,y,t,lb) = sum((selectedGrowthProfile(prf),mapild_r(ild,r)), (1 + AClossFactors(ild)) * i_NrgDemand(prf,r,y,t,lb)) ;

* Use GWh of NrgDemand and hours per LDC block to get ldcMW (MW).
ldcMW(r,y,t,lb)$hoursPerBlock(t,lb) = 1e3 * NrgDemand(r,y,t,lb) / hoursPerBlock(t,lb) ;

* i) System security data.
* Pull out peak load (MW) for the selected growth profile and adjust for embedded generation.
peakLoadNZ(y) = sum(selectedGrowthProfile(prf), i_peakloadNZp(y,prf)) + %embedAdjNZ% ;
peakLoadNI(y) = sum(selectedGrowthProfile(prf), i_peakloadNIp(y,prf)) + %embedAdjNI% ;

bigNIgen(y) = i_BigNIgen(y) ;
nxtbigNIgen(y) = i_nxtBigNIgen(y) ;

* Set largest two NI generators to zero if n security level is desired (assumes biggest SI generator < 2 biggest NI generators).
BigNIgen(y)$( i_security = 0 ) = 0 ;
nxtBigNIgen(y)$( i_security = 0 ) = 0 ;

* Set the 2nd largest NI generator to zero if n-1 security level is desired (assumes biggest SI generator < biggest NI generator).
nxtBigNIgen(y)$( i_security = 1 ) = 0 ;



* j) Transmission data.
* Let the last region declared be the slack bus (note that set r may not be ordered if users don't maintain unique set elements).
slackbus(r) = no ;
slackbus(r)$( ord(r) = card(r) ) = yes ;

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
i_zonalLocFacs(e) = i_txZonalLocFacs(e) ;
locfac_recip(e)$i_zonalLocFacs(e) = 1 / i_zonalLocFacs(e) ;
locfac_recip(e)$( numreg > 2 ) = 1 ;

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
AllowedStates(r,rr,'initial')$i_txCapacity(r,rr,'initial') = yes ;
counter = 0 ;
repeat
  counter = card(AllowedStates) ;
  AllowedStates(r,rr,pss)$sum(transitions(tupg,r,rr,ps,pss)$AllowedStates(r,rr,ps), 1 ) = yes ;
until counter = card(AllowedStates) ;

* Identify all r-rr-ps tuples not in AllowedStates.
notAllowedStates(r,rr,ps) = yes ;
notAllowedStates(AllowedStates) = no ;

* Identify all existing or potential interregional transmission paths. Then identify the ones that are uni- versus bi-directional.
paths(r,rr)$sum(AllowedStates(r,rr,ps), 1 ) = yes ;
biPaths(r,rr)$( paths(r,rr) * paths(rr,r) ) = yes ;
uniPaths(paths) = yes ;
uniPaths(biPaths) = no ;

* Identify all upgrade states on all transmission paths.
upgradedStates(AllowedStates(r,rr,ps))$( not sameas(ps,'initial') ) = yes ;

* Identify the allowable upgrade transition sequence for each valid transmission path.
validTransitions(paths(r,rr),ps,pss)$sum(transitions(tupg,r,rr,ps,pss), 1 ) = yes ;

* Assign earliest and fixed transmission upgrade years (let earliest year be the first year if no earliest year is specified).
txEarlyComYr(tupg,paths(r,rr),ps,pss)$i_txEarlyComYr(tupg) = i_txEarlyComYr(tupg) ;
txEarlyComYr(tupg,paths(rr,r),ps,pss)$txEarlyComYr(tupg,r,rr,ps,pss) = txEarlyComYr(tupg,r,rr,ps,pss) ;
txEarlyComYr(transitions)$( not txEarlyComYr(transitions) ) = i_firstYear ;
txEarlyComYr(tupg,paths,ps,pss)$( not transitions(tupg,paths,ps,pss) ) = 0 ;

txFixedComYr(tupg,paths(r,rr),ps,pss)$i_txFixedComYr(tupg) = i_txFixedComYr(tupg) ;
txFixedComYr(tupg,paths(rr,r),ps,pss)$txFixedComYr(tupg,r,rr,ps,pss) = txFixedComYr(tupg,r,rr,ps,pss) ;
txFixedComYr(tupg,paths,ps,pss)$( not transitions(tupg,paths,ps,pss) ) = 0 ;

* Represent early and fixed transmission investment years as sets.
txEarlyComYrSet(transitions,y)$( yearnum(y) < txEarlyComYr(transitions) ) = yes ;
** Can this next line be right?
txEarlyComYrSet(transitions,y)$( txFixedComYr(transitions) > i_lastYear ) = yes ;
txFixedComYrSet(transitions,y)$( txFixedComYr(transitions) = yearnum(y) ) = yes ;

* Calculate reactance and susceptance by year - this assumes exogenous or fixed timing of transmission expansion decisions, otherwise
* it stays at the level of initial year.
reactanceYr(paths,y) = i_txReactance(paths,'initial') ;
loop((tupg,paths,ps,pss)$txFixedComYr(tupg,paths,ps,pss),
  reactanceYr(paths,y)$( yearnum(y) >= txFixedComYr(tupg,paths,ps,pss) ) = i_txReactance(paths,pss) ;
) ;

susceptanceYr(paths,y)$reactanceYr(paths,y) = 1 / reactanceYr(paths,y) ;

* Assign bus-branch incidence and group constraint data.
loop(arcnodemap(p,r,rr),
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

TxAnnuityFacn(y) = ( 1 - ( 1 + i_WACCt + i_inflation(y) ) ** (-i_txPlantLife) ) / i_WACCt ;

TxAnnuityFacr = ( 1 - ( 1 + i_WACCt ) ** (-i_txPlantLife) ) / i_WACCt ;

* i_depType = 0 implies straight line depreciation; i_depType = 1 implies a declining balance method.
if(i_depType = 0,
  txCapRecFac(y)$txAnnuityFacr   = ( 1 - i_taxRate * txAnnuityFacn(y) / i_txPlantLife ) / txAnnuityFacr ;
  txDeptCRecFac(y)$txAnnuityFacr =     ( i_taxRate * txAnnuityFacn(y) / i_txPlantLife ) / txAnnuityFacr ;
  else
  txCapRecFac(y)$txAnnuityFacr   = ( 1 - i_txDepRate * i_taxRate / (i_WACCt + i_inflation(y) + i_txDepRate) ) / txAnnuityFacr ;
  txDeptCRecFac(y)$txAnnuityFacr =     ( i_txDepRate * i_taxRate / (i_WACCt + i_inflation(y) + i_txDepRate) ) / txAnnuityFacr ;
) ;

* Convert lumpy txCapitalCost ($m) to levelised TxCapCharge ($m/yr).
txCapCharge(r,rr,ps,y) = txCapitalCost(r,rr,ps) * txCapRecFac(y) ;



* k) Reserve energy data.
reservesAreas(rc) = min(2, max(1, i_ReserveAreas(rc) ) ) ;

singleReservesReqF(rc)$( reservesAreas(rc) = 1 ) = 1 ;

reserveViolationPenalty(ild,rc) = max(0, i_ReservePenalty(ild,rc) ) ;

i_reserveReqMW(y,ild,rc) = i_reserveReq(y,ild,rc) ;

windCoverPropn(rc) = min(1, max(0, i_propwindcover(rc) ) ) ;

bigM(ild1,ild) =
 smax((paths(r,rr),ps)$( mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacity(paths,ps) ) -
 smin((paths(r,rr),ps)$( mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacityPO(paths,ps) ) ;

* Do the RGB colors for k, f, and fg
techColor('Coal','255','0','0') = yes ;
techColor('CoalCog','255','204','153') = yes ;
techColor('Coal_DY','153','0','153') = yes ;
techColor('IGCC','255','153','0') = yes ;
techColor('IGCC_CCS','102','0','102') = yes ;
techColor('Lig','51','51','51') = yes ;
techColor('IGCC_Lig','153','153','153') = yes ;
techColor('IGCC_LigCCS','128','128','128') = yes ;
techColor('CCGT','255','204','0') = yes ;
techColor('CCGT_CCS','255','255','153') = yes ;
techColor('GasCog','153','153','0') = yes ;
techColor('OCGT','255','124','0') = yes ;
techColor('DslPkr','204','204','204') = yes ;
techColor('GasPkr','255','153','204') = yes ;
techColor('DslRecip','153','0','0') = yes ;
techColor('BioPkr','153','204','153') = yes ;
techColor('Geo','255','153','153') = yes ;
techColor('BioCog','204','255','153') = yes ;
techColor('OthCog','178','178','128') = yes ;
techColor('HydPD','0','102','204') = yes ;
techColor('HydPk','0','0','128') = yes ;
techColor('HydRR','153','204','255') = yes ;
techColor('HydSC','0','0','255') = yes ;
techColor('HydDG','0','204','255') = yes ;
techColor('Wind','0','255','0') = yes ;
techColor('WindDG','204','255','204') = yes ;
techColor('Wave','204','255','255') = yes ;
techColor('Tide','0','255','255') = yes ;
techColor('Solar','255','255','0') = yes ;
techColor('DSM','0','0','0') = yes ;
techColor('IL','0','153','153') = yes ;

fuelColor('Coal','255','0','0') = yes ;
fuelColor('Lig','128','128','128') = yes ;
fuelColor('Gas','153','51','102') = yes ;
fuelColor('Dsl','178','178','128') = yes ;
fuelColor('Geo','255','153','153') = yes ;
fuelColor('Bio','204','255','153') = yes ;
fuelColor('BioD','255','204','153') = yes ;
fuelColor('Oth','204','204','204') = yes ;
fuelColor('Hyd','0','0','255') = yes ;
fuelColor('Wind','0','255','0') = yes ;
fuelColor('Mrn','204','255','255') = yes ;
fuelColor('Sol','255','255','0') = yes ;
fuelColor('DSM','153','153','153') = yes ;

fuelGrpColor('Therm','255','0','0') = yes ;
fuelGrpColor('Hydro','0','0','255') = yes ;
fuelGrpColor('Renew','0','255','255') = yes ;
fuelGrpColor('DSM','153','153','153') = yes ;



*===============================================================================================
* Display all computed sets and parameters and create a new reference GDX file.

$ontext 
Display
* Sets
  firstYr, lastYr, allButFirstYr, firstPeriod
  mapi_r, mapi_e, mapi_ild, mape_r, mapild_r, mapg_k, mapg_o, mapg_i, mapg_f, mapg_fg, mapg_r, mapg_e, mapg_ild, mapg_fc, mapv_i, mapv_g, thermalFuel
  schedHydroPlant, pumpedHydroPlant, exist, noexist, neverbuild, commit, new, nigen, sigen, moverExceptions, validYrOperate, validYrBuild
  possibleToBuild, linearPlantBuild, integerPlantBuild, possibleToEndogRetire, possibleToRetire, possibleToRefurbish, endogenousRetireDecisnYrs
  endogenousRetireYrs, nwd, swd, regLower, interIsland, transitions, AllowedStates, notAllowedStates, paths, uniPaths, biPaths, upgradedStates, validTransitions
  txEarlyComYrSet, txFixedComYrSet, vtgc, nsegment
* Parameters
  i_firstYear, i_lastYear, yearnum, i_firstHydroYear, i_lastHydroYear, multipleHydroYear, averageHydroYear, HydroYearNum, hoursPerBlock, numreg
  CBAdiscountRates, pvfacg, pvfact, pvfacsM, pvfacsEY, pvfacs, capexlife, AnnuityFacn, AnnuityFacr, caprecfac, deptcrecfac
  i_fuelPrices, i_fuelQuantities, totalFuelCost, CO2taxByPlant, CO2CaptureStorageCost, SRMC
  reservesCapability, initialCapacity, exogMWretired, peakConPlant, NWpeakConPlant, WtdAvgFOFmultiplier, maxCapFactPlant, minCapFactPlant
  continueAftaEndogRetire, capitalCost, capexPlant, refurbCapexPlant, capCharge, refurbCapCharge, AClossFactors, NrgDemand, ldcMW, peakLoadNZ, peakLoadNI, bigNIgen, nxtbigNIgen
  locfac_recip, txEarlyComYr, txFixedComYr, reactanceYr, susceptanceYr, BBincidence, pCap, pLoss, bigLoss, slope, intercept, txCapitalCost, txCapCharge
  txAnnuityFacn, txAnnuityFacr, txCapRecFac, txDeptCRecFac
  reservesAreas, singleReservesReqF, reserveViolationPenalty, i_reserveReqMW, windCoverPropn, bigM
  ;
$offtext


* Do a couple of changes:
Sets
  minUtilTechs(k)       'Technologies to which minimum utilisation constraints may apply' / Coal, Lig, CCGT, CCGT_CCS, GasCog, OCGT /
  mapGeo(hdrs,geo)     / Easting.Easting, Northing.Northing, Long.Long, Lat.Lat /
  mapArcNode(p,r,rr)    'Map nodes (actually, regions) to arcs (paths) in order to build the bus-branch incidence matrix'
  islandCentroid(i,ild) 'Identify the centroid of each island with a substation'
  ;

mapArcNode(p,r,rr)$arcnodemap(p,r,rr) = arcnodemap(p,r,rr) ;
islandCentroid(i,ild) = islandCent(i,ild) ;

* Fix a bug in 18 region file - the TTER centroids got added to the 18 region ones and need to be removed.
regionCentroid(i,r)$( ord(i) > 93 ) = no ;
regionCentroid('col',r) = no ;
regionCentroid('hbk',r) = no ;

Scalars
  i_firstDataYear  'First year on which data is defined'  / 2010 /
  i_lastDataYear   'Last year on which data is defined'   / 2050 /
  ;

Parameters
  i_substnCoordinates(i,geo)    'Geographic coordinates for substations'
  ;

i_substnCoordinates(i,geo) = sum(mapgeo(hdrs,geo), i_geocoordinates(i,hdrs)) ;
i_substnCoordinates(i,'lat') = (-1) * i_substnCoordinates(i,'lat') ;
*Display i_substnCoordinates, mapArcNode ;

*****
* Replace hydro output with monthly data instead of quarterly
Table hydoutput_st(v,hY,m) 'Hydro output sequences by reservoir and time period, GWh'
$ondelim include "C:\a\GEM\Data\Source data\Hydro sequences by 36 reservoirs and months, 1932-2007, GWh.csv"
$offdelim
Parameter i_hydroOutput(v,hY,m) 'Historical hydro output sequences by reservoir and month, GWh' ;
i_hydroOutput(v,hY,m) = hydoutput_st(v,hY,m) ;
****


* Write out the GEM2.0 GDX file:
Execute_unload '%Finalv2GDX%'
* 26 fundamental sets
  k f fg g s o fc i r e ild p ps tupg tgc y t prf lb rc hY v hd m geo col
* 42 subsets and mapping sets
* - 24 tech and fuel subsets
  mapf_k mapf_fg techColor fuelColor fuelGrpColor movers refurbish endogRetire cogen peaker hydroSched hydroPumped
  wind renew thermalTech CCStech minUtilTechs demandGen randomiseCapex linearBuildTech coal lignite gas diesel
* - 7 generation
  mapGenPlant exist commit new neverBuild maps_r mapg_fc
* - 6 location
  mapLocations Haywards Benmore regionCentroid zoneCentroid islandCentroid
* - 2 transmission
  txUpgradeTransitions mapArcNode
* - 1 load and time
  mapm_t
* - 0 reserves and security
* - 2 hydrology
  maphd_hY mapReservoirs

* 20 technology and fuel parameters
  i_plantLife i_refurbishmentLife i_retireOffsetYrs i_linearBuildMW i_linearBuildYr i_depRate i_capCostAdjByTech i_CapexExposure
  i_peakContribution i_NWpeakContribution i_capFacTech
  i_minUtilByTech i_CCSfactor i_CCScost i_FOFmultiplier i_maxNrgByFuel i_fuelPrices i_fuelQuantities i_emissionFactors i_co2tax
* 32 generation parameters
  i_nameplate i_UnitLargestProp i_baseload i_minUtilisation i_offlineReserve i_FixComYr i_EarlyComYr i_ExogenousRetireYr i_refurbDecisionYear
  i_fof i_heatrate i_PumpedHydroMonth i_PumpedHydroEffic i_minHydroCapFact i_maxHydroCapFact i_fixedOM i_varOM i_FuelDeliveryCost
  i_capitalCost i_connectionCost i_refurbCapitalCost i_plantReservesCap i_plantReservesCost i_PltCapFact
  i_VOLLcap i_VOLLcost i_HVDCshr i_exRates
  i_renewNrgShare i_renewCapShare i_distdGenRenew i_distdGenFossil
* 2 location
  i_substnCoordinates i_zonalLocFacs
* 12 transmission
  i_txCapacity i_txCapacityPO i_txResistance i_txReactance i_txCapitalCost i_maxReservesTrnsfr
  i_txEarlyComYr i_txFixedComYr i_txGrpConstraintsLHS i_txGrpConstraintsRHS i_HVDClevy i_HVDCreqRevenue
* 7 load and time
  i_firstDataYear i_lastDataYear i_HalfHrsPerBlk i_peakLoadNZp i_peakLoadNIp i_NrgDemand i_inflation
* 12 reserves and security
  i_ReserveSwitch i_ReserveAreas i_propWindCover i_ReservePenalty i_reserveReqMW i_bigNIgen i_nxtbigNIgen i_bigSIgen i_fkNI i_fkSI i_HVDClosses i_HVDClossesPO
* 4 hydrology
  i_firstHydroYear i_hydroOutput i_hydroWeight i_hydroOutputAdj
  ;
