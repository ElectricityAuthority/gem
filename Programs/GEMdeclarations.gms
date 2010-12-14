* GEMdeclarations.gms

* Last modified by Dr Phil Bishop, 06/12/2010 (imm@ea.govt.nz)

$ontext
  This program does....

 Code sections:
  1. Declare sets and parameters for data to be imported from the GDX file created by GUI.
  2. Declare sets and parameters
     - hard-coded and/or receive input from model/run configuration GUI and/or required in GEMsolve.
  3. Declare sets and parameters to be initialised in GEMdata.
  4. Declare model variables and equations.
  5. Specify the equations and declare the models.
  6. Declare the 's' parameters and specify the statements used to collect up results after each solve.
  7. Declare the 's2' parameters.
  x. xxx
$offtext

* Turn the following maps on/off as desired.
$offuelxref offuellist	
*$onuelxref  onuellist	
$offsymxref offsymlist
*$onsymxref  onsymlist


*===============================================================================================
* 1. Declare sets and parameters for data to be imported from the GDX file created by GUI.

* 26 fundamental sets
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
  geo          'Geographic co-ordinate types'
  col          'RGB color codes'
  ;

Alias (i,ii), (r,rr), (ild,ild1), (ps,pss), (hY,hY1), (col,red,green,blue) ;

* 42 mapping sets and subsets (grouped as per the navigation pane of GUI)
Sets
* 24 technology and fuel
  mapf_k(f,k)                                   'Map technology types to fuel types'
  mapf_fg(f,fg)                                 'Map fuel groups to fuel types'
  techColor(k,red,green,blue)                   'RGB color mix for technologies - to pass to plotting applications'
  fuelColor(f,red,green,blue)                   'RGB color mix for fuels - to pass to plotting applications'
  fuelGrpcolor(fg,red,green,blue)               'RGB color mix for fuel groups - to pass to plotting applications'
  movers(k)                                     'Technologies for which commissioning date can move during re-optimisation of build timing'
  refurbish(k)                                  'Technologies eligible for endogenous "refurbish or retire" decision'
  endogRetire(k)                                'Technologies eligible for endogenous retirement - in years prior to and including the refurbish or retire decision'
  cogen(k)                                      'Cogeneration technologies'
  peaker(k)                                     'Peaking plant technologies'
  hydroSched(k)                                 'Schedulable hydro technologies'
  hydroPumped(k)                                'Pumped storage hydro technologies'
  wind(k)                                       'Wind technologies'
  renew(k)                                      'Renewable technologies'
  thermalTech(k)                                'Thermal technologies'
  CCStech(k)                                    'Carbon capture and storage technologies'
  minUtilTechs(k)                               'Technologies to which minimum utilisation constraints may apply'
  demandGen(k)                                  'Demand side technologies modelled as generation'
  randomiseCapex(k)                             'Specify the technologies able to have their capital costs randomised - within some narrow user-defined range'
  linearBuildTech(k)                            'Specify the technologies able to be partially or linearly built'
  coal(f)                                       'Coal fuel'
  lignite(f)                                    'Lignite fuel'
  gas(f)                                        'Gas fuel'
  diesel(f)                                     'Diesel fuel'
* 7 generation
  mapGenPlant(g,k,i,o)                          'Generation plant mappings'
  exist(g)                                      'Generation plant that are presently operating'
  commit(g)                                     'Generation plant that are assumed to be committed'
  new(g)                                        'Potential generation plant that are neither existing nor committed'
  neverBuild(g)                                 'Generation plant that are determined a priori by user never to be built'
  mapg_fc(g,fc)                                 'Map currency types to generating plant - used to convert capex values to NZD'
  maps_r(s,r)                                   'Map VOLL plants to regions'
* 6 location
  mapLocations(i,r,e,ild)                       'Location mappings'
  Haywards(i)                                   'Haywards substation'
  Benmore(i)                                    'Benmore substation'
  regionCentroid(i,r)                           'Identify the centroid of each region with a substation'
  zoneCentroid(i,e)                             'Identify the centroid of each zone with a substation'
  islandCentroid(i,ild)                         'Identify the centroid of each island with a substation'
* 2 transmission
  txUpgradeTransitions(tupg,r,rr,ps,pss)        'Define the allowable transitions from one transmission state to another'
  mapArcNode(p,r,rr)                            'Map nodes (actually, regions) to arcs (paths) in order to build the bus-branch incidence matrix'
* 1 load and time
  mapm_t(m,t)                                   'Map months into time periods'
* 0 reserves and security
* 2 hydrology
  maphd_hY(hd,hY)                               'Map hydrology output years to the hydrology domain years'
  mapReservoirs(v,i,g)                          'Reservoir mappings'
  ;

* Declare parameters (again, grouped as per the navigation pane of GUI).
Parameters
* 20 technology and fuel
  i_plantLife(k)                                'Generation plant life, years'
  i_refurbishmentLife(k)                        'Generation plant life following refurbishment, years'
  i_retireOffsetYrs(k)                          'Number of years a technology continues to operate for after the decision to endogenously retire has been made'
  i_linearBuildMW(k)                            'Threshold MW level used to activate linearisation of binary decision variables for plants able to be linearly built'
  i_linearBuildYr(k)                            'Threshold early build year used to activate linearisation of binary decision variables for plants able to be linearly built'
  i_depRate(k)                                  'Depreciation rate for generation plant, technology specific'
  i_capCostAdjByTech(k)                         'Capital cost adjuster by technology (default = 1)'
  i_CapexExposure(k)                            'Proportion of generation plant capital expenditure that is exposed to exchange rates, i.e. the imported share of total plant capex'
  i_peakContribution(k)                         'Contribution to peak by technology'
  i_NWpeakContribution(k)                       'The no wind contribution to peak by technology'
  i_capFacTech(k)                               'An assumed (rather than modelled) technology-specific capacity factor - used when computing LRMCs based on input data (i.e. prior to solving the model)'
  i_minUtilByTech(y,k)                          'Minimum utilisation of plant by technology type, proportion (0-1 but define only when > 0)'
  i_CCSfactor(y,k)                              'Carbon capture and storage factor, i.e. share of emissions sequestered'
  i_CCScost(y,k)                                'Carbon capture and storage cost, $/t CO2e sequestered'
  i_FOFmultiplier(k,lb)                         'Forced outage factor multiplier (default = 1)'
  i_maxNrgByFuel(f)                             'Maximum proportion of total energy from any one fuel type (0-1)'
  i_fuelPrices(f,y)                             'Fuel prices by fuel type and year, $/GJ'
  i_fuelQuantities(f,y)                         'Quantitative limit on availability of various fuels by year, PJ'
  i_emissionFactors(f)                          'CO2e emissions, tonnes CO2/PJ'
  i_co2tax(y)                                   'CO2 tax by year, $/tonne CO2-equivalent'
* 32 generation
  i_nameplate(g)                                'Nameplate capacity of generating plant, MW'
  i_UnitLargestProp(g)                          'Largest proportion of generating plant output carried by a single unit at the plant'
  i_baseload(g)                                 'Force plant to be baseloaded, 0/1 (1 = baseloaded)'
  i_minUtilisation(g)                           'Switch to turn on the minimum utilisation constraint by plant (0-1, default = 0)'
  i_offlineReserve(g)                           'Plant-specific offline reserve capability, 1 = Yes, 0 = No'
  i_FixComYr(g)                                 'Fixed commissioning year for potentially new generation plant (includes plant fixed never to be built)'
  i_EarlyComYr(g)                               'Earliest possible commissioning year for each potentially new generation plant'
  i_ExogenousRetireYr(g)                        'Exogenous retirement year for generation plant'
  i_refurbDecisionYear(g)                       'Decision year for endogenous "refurbish or retire" decision for eligble generation plant'
  i_fof(g)                                      'Forced outage factor for generating plant, proportion (0-1)'
  i_heatrate(g)                                 'Heat rate of generating plant, GJ/GWh (default = 3600)'
  i_PumpedHydroMonth(g)                         'Limit on energy per month from pumped hydro plant, GWh'
  i_PumpedHydroEffic(g)                         'Efficiency of pumped energy to stored energy, MWh stored per MWh pumped < 1'
  i_minHydroCapFact(g)                          'Minimum capacity factors for selected schedulable hydro plant'
  i_maxHydroCapFact(g)                          'Maximum capacity factors for selected schedulable hydro plant (default = 1)'
  i_fixedOM(g)                                  'Fixed O&M costs by plant, $/kW/year'
  i_varOM(g)                                    'Variable O&M costs by plant, $/MWh'
  i_FuelDeliveryCost(g)                         'Fuel delivery cost, $/GJ'
  i_capitalCost(g)                              'Generation plant capital cost, foreign currency per kW'
  i_connectionCost(g)                           'Capital cost for connecting generation plant to grid, $m (NZD)'
  i_refurbCapitalCost(g)                        'Generation plant refurbishment capital cost, foreign currency per kW'
  i_plantReservesCap(g,rc)                      'Plant-specific capability per reserve class (0-1 but define only when > 0)'
  i_plantReservesCost(g,rc)                     'Plant-specific cost per reserve class, $/MWh'
  i_PltCapFact(g,m)                             'Plant-specific capacity factor (default = 1)'
  i_VOLLcap(s)                                  'Nameplate capacity of VOLL plant (1 VOLL plant/region), MW'
  i_VOLLcost(s)                                 'Value of lost load by VOLL plant (1 VOLL plant/region), $/MWh'
  i_HVDCshr(o)                                  'Share of HVDC charge to be incurred by plant owner'
  i_exRates(fc)                                 'Exchange rates (foreign currency per NZ dollar)'
  i_renewNrgShare(y)                            'Proportion of total energy to be generated from renewable sources by year (0-1 but define only when > 0)'
  i_renewCapShare(y)                            'Proportion of installed capacity that must be renewable by year (0-1 but define only when > 0)'
  i_distdGenRenew(y)                            'Distributed generation (renewable) installed by year, GWh'
  i_distdGenFossil(y)                           'Distributed generation (fossil) installed by year, GWh'
* 2 location
  i_substnCoordinates(i,geo)                    'Geographic coordinates for substations'
  i_zonalLocFacs(e)                             'Zonal location factors - adjusters of SRMC'
* 12 transmission
  i_txCapacity(r,rr,ps)                         'Transmission path capacities (bi-directional), MW'
  i_txCapacityPO(r,rr,ps)                       'Transmission path capacities with one pole out (bi-directional, HVDC link only), MW'
  i_txResistance(r,rr,ps)                       'Transmission path resistance (not really a resistance but rather a loss function coefficient), p.u. (MW)'
  i_txReactance(r,rr,ps)                        'Reactance by state of each transmission path, p.u. (MW)'
  i_txCapitalCost(r,rr,ps)                      'Transmission upgrade capital cost by path, $m'
  i_maxReservesTrnsfr(r,rr,ps,rc)               'Maximum reserves transfer capability in the direction of MW flow on the HCDC link, MW'
  i_txEarlyComYr(tupg)                          'Earliest year that a transmission upgrade can occur (this is a parameter, not a set)'
  i_txFixedComYr(tupg)                          'Fixed year in which a transmission upgrade must occur (this is a parameter, not a set)'
  i_txGrpConstraintsLHS(tgc,p)                  'Coefficients for left hand side of transmission group constraints'
  i_txGrpConstraintsRHS(tgc)                    'Coefficients for the right hand side of transmission group constraints, MW'
  i_HVDClevy(y)                                 'HVDC charge levied on new South Island plant by year, $/kW'
  i_HVDCreqRevenue(y)                           'Required HVDC revenue to be collected by year, $m (only used for reporting purposes)'
* 7 load and time
  i_firstDataYear                               'First data year - as a scalar, not a set'
  i_lastDataYear                                'Last data year - as a scalar, not a set'
  i_HalfHrsPerBlk(m,lb)                         'Count of half hours per load block in each month'
  i_peakLoadNZp(y,prf)                          'Peak load for New Zealand by year and load growth profile, MW'
  i_peakLoadNIp(y,prf)                          'Peak load for North Island by year and load growth profile, MW'
  i_NrgDemand(prf,r,y,t,lb)                     'Load by growth profile, region, year, time period and load block, GWh'
  i_inflation(y)                                'Inflation rates by year'
* 12 reserves and security
  i_ReserveSwitch(rc)                           'Switch to activate reserves by reserves class'
  i_ReserveAreas(rc)                            'Number of reserves areas (Single or system-wide = 1, By island = 2)'
  i_propWindCover(rc)                           'Proportion of wind to cover by reserve class (0-1 but define only when > 0)'
  i_ReservePenalty(ild,rc)                      'Reserve violation penalty, $/MWh'
  i_reserveReqMW(y,ild,rc)                      'Reserve requirement by year, island, and class, MW'
  i_bigNIgen(y)                                 'Largest North Island generation plant by year, MW'
  i_nxtbigNIgen(y)                              'Next (second) largest North Island generation plant by year, MW'
  i_bigSIgen(y)                                 'Largest South Island generation plant by year, MW'
  i_fkNI(y)                                     'Required frequency keeping in North Island by year, MW'
  i_fkSI(y)                                     'Required frequency keeping in South Island by year, MW'
  i_HVDClosses(y)                               'Maximum loss rate on HVDC link by year'
  i_HVDClossesPO(y)                             'Maximum loss rate on HVDC link with one pole out by year'
* 4 hydrology
  i_firstHydroYear                              'First year of hydrology output data (ignoring the 1st two elements of hY - multiple and average)'
  i_hydroOutput(v,hY,m)                         'Historical hydro output sequences by reservoir and month, GWh'
  i_hydroWeight(hd)                             'Weights on hydro outflows when multiple hydro outputs is used'
  i_hydroOutputAdj(y)                           'Schedulable hydro output adjuster by year (default = 1)'
  ;



*===============================================================================================
* 2. Declare sets and parameters
*     - hard-coded and/or receive input from model/run configuration GUI and/or required in GEMsolve.

Sets
* Hard-coded in GEMdata
  ct                                            'Capital expenditure types'
  d                                             'Discount rate classes'
  dt                                            'Types of discounting'
* Initialised in GEMdata using input from GEMsettings
  n                                             'Piecewise linear vertices'
  selectedGrowthProfile(prf)                    'User-specified load growth profile (Low, Medium, or High)'
* Hard-coded in GEMsolve
  rt                                            'Model run types'
  goal                                          'Goals for MIP solution procedure'
  tmg(rt)                                       'Run type TMG - determine timing'
  reo(rt)                                       'Run type REO - re-optimise timing'
  dis(rt)                                       'Run type DIS - dispatch'
* Initialised in GEMsolve using input from GEMsettings
  solveGoal(goal)                               'User-selected solve goal'
  hydroYrForTiming(hY)                          'Hydro year used to determine investment timing. Choices are Multiple, Average, 1932, 1933, ... 2007'
  hydroYrForReopt(hY)                           'Hydro year used to re-optimise investment timing. Choices are Multiple, Average, 1932, 1933, ... 2007'
* Initialised in GEMsolve
  h(hd)                                         'Selected elements of HD - used to control multiple versus single hydro years to determine build timing'
  hydroYrForDispatch(hY)                        'Hydro years used to loop over when solving DISpatch'
  activeSolve(rt,hY)                            'Collect the rt-hY index used for each solve' 
  activeHD(rt,hY,hd)                            'Collect the rt-hY-hd index used for each solve'
  dum(hd)                                       'The dummy element of set hd'
  activeRT(rt)                                  'Identify the run types actually employed in this model run'
  disHydYrs(hY)                                 'Hydro years for which DISpatch model was solved or looped over - excludes multiple and average hydro years'
  ;

Parameters
* Parameters to be initialised in GEMdata using input from GEMsettings. 
  firstYear                                     'First modelled year - as a scalar, not a set'
  lastYear                                      'Last modelled year - as a scalar, not a set'
* Scalars to be declared and initialised in GEMsettings.
  WACCg                                         "Generation investor's post-tax real weighted average cost of capital"
  WACCt                                         "Transmission investor's post-tax real weighted average cost of capital"
  depType                                       'Flag to indicate depreciation method - 1 for declining value, 0 for straight line'
  taxRate                                       'Corporate tax rate'
  txPlantLife                                   'Life of transmission equipment, years'
  txDepRate                                     'Depreciation rate for transmission equipment'
  randomCapexCostAdjuster                       'Specify the bounds for a small +/- random adjustment to generation plant capital costs'
  noRetire                                      'Number of years following and including the first modelled year for which endogenous generation plant retirement decisions are prohibited'
  gridSecurity                                  'Flag to indicate desired grid security (legitimate values are -1, 0, 1, or 2)'
*                                                  -1 = run the model with the five security constraints suppressed.
*                                                   0 = run the model with n (i.e. n-0) security.
*                                                   1 = run the model with n-1 security.
*                                                   2 = run the model with n-2 security.
  AnnualMWlimit                                 'Upper bound on total MW of new plant able to be built nationwide in any single year'
  penaltyViolateRenNrg                          'Penalty used to make renewable energy constraint feasible, $m/GWh'
  renNrgShrOn                                   'Switch to control usage of renewable energy share constraint 0=off/1=on'
  DCloadFlow                                    'Flag (0/1) to indicate use of either DC load flow (1) or transportation formulation (0)'
  useReserves                                   'Global flag (0/1) to indicate use of at least one reserve class (0 = no reserves are modelled)'
  cGenYr                                        'First year in which integer generation build decisions can become continuous, i.e. CGEN or BGEN = 0 in any year'
  noVOLLblks                                    'Number of contiguous load blocks at top of LDC for which the VOLL generators are unavailable'
  hydroOutputScalar                             'Scale the hydro output sequence used to determine the timing of new builds'
* Initialised in GEMsolve
  hydOutput(g,y,t,hd)                           'Hydro output used in each modelled year by scheduleable hydro plant'
  slacks                                        'A flag indicating slacks or penalty variables exist in at least one solution'
  timeAllowed(goal)                             'CPU seconds available for solver to spend solving the model'
  solveReport(rt,hY,*,*)                        'Collect various details about each solve of the models (both GEM and DISP)'
  indexhY(rt,hY,y)                              'Collect the hydro year number used for each modelled year of each solve'
  hydroYrIndex(hY)                              'Index to enable assignment of hydro years over the modelled years'
  numDisYrs                                     'Number of hydro years for which DISpatch model was solved or looped over - excludes multiple and average hydro years'
  ;



*===============================================================================================
* 3. Declare sets and parameters to be initialised in GEMdata.

Sets
* Time/date-related sets and parameters.
  firstYr(y)                                    'First modelled year - as a set, not a scalar'
  lastYr(y)                                     'Last modelled year - as a set, not a scalar'
  allButFirstYr(y)                              'All modelled years except the first year - as a set, not a scalar'
  firstPeriod(t)                                'First time period (i.e. period within the modelled year)'
* Various mappings, subsets and counts.
  mapg_k(g,k)                                   'Map technology types to generating plant'
  mapg_f(g,f)                                   'Map fuel types to generating plant'
  mapg_o(g,o)                                   'Map plant owners to generating plant'
  mapg_i(g,i)                                   'Map substations to generating plant'
  mapg_r(g,r)                                   'Map regions to generating plant'
  mapg_e(g,e)                                   'Map zones to generating plant'
  mapg_ild(g,ild)                               'Map islands to generating plant'
  mapi_r(i,r)                                   'Map regions to substations'
  mapi_e(i,e)                                   'Map zones to substations'
  mapild_r(ild,r)                               'Map the regions to islands'
  mapv_g(v,g)                                   'Map generating plant to reservoirs'
  thermalFuel(f)                                'Thermal fuels'
* Financial parameters.
* Fuel prices and quantity limits.
* Generation data.
  noExist(g)                                    'Generation plant that are not presently operating'
  nigen(g)                                      'North Island generation plant'
  sigen(g)                                      'South Island generation plant'
  schedHydroPlant(g)                            'Schedulable hydro generation plant'
  pumpedHydroPlant(g)                           'Pumped hydro generation plant'
  moverExceptions(g)                            'Generating plant to be excepted from the technology-based determination of movers'
  validYrBuild(g,y)                             'Valid years in which new generation plant may be built'
  integerPlantBuild(g)                          'Generating plant that must be integer built, i.e. all or nothing (unless cgenyr in RunGEM is less than LastYr)'
  linearPlantBuild(g)                           'Generating plant able to be linearly or incrementally built'
  possibleToBuild(g)                            'Generating plant that may possibly be built in any valid build year'
  possibleToRefurbish(g)                        'Generating plant that may possibly be refurbished in any valid modelled year'
  possibleToEndogRetire(g)                      'Generating plant that may possibly be endogenously retired'
  possibleToRetire(g)                           'Generating plant that may possibly be retired (exogenously or endogenously)'
  endogenousRetireDecisnYrs(g,y)                'The years in which generation plant able to be endogenously retired can take the decision to retire'
  endogenousRetireYrs(g,y)                      'The years in which generation plant able to be endogenously retired can actually be retired'
  validYrOperate(g,y,t)                         'Valid years and periods in which an existing, committed or new plant can generate. Use to fix GEN to zero in invalid years'
* Load data.
  selectedGrowthProfile(prf)                    'User-specified load growth profile (Low, Medium, or High)'
* Transmission data.
  slackBus(r)                                   'Designate a region to be the slack or reference bus'
  regLower(r,rr)                                'The lower triangular part of region-region matrix, i.e. where ord(r) > ord(rr)'
  interIsland(ild,ild1)                         'Interisland island pairings (excludes intra-island)'
  nwd(r,rr)                                     'Northward direction of flow on Benmore-Haywards HVDC'
  swd(r,rr)                                     'Southward direction of flow on Benmore-Haywards HVDC'
  paths(r,rr)                                   'All valid transmission paths'
  uniPaths(r,rr)                                'Valid unidirectional transmission paths'
  biPaths(r,rr)                                 'Valid bidirectional transmission paths'
  transitions(tupg,r,rr,ps,pss)                 'For all transmission paths, define the allowable transitions from one upgrade state to another'
  validTransitions(r,rr,ps,pss)                 'All allowed upgrade transitions on each valid path'
  allowedStates(r,rr,ps)                        'All of the allowed states (initial and upgraded) for each active path'
  notAllowedStates(r,rr,ps)                     'All r-rr-ps tuples not in the set called allowedStates'
  upgradedStates(r,rr,ps)                       'All allowed upgraded states on each path'
  txEarlyComYrSet(tupg,r,rr,ps,pss,y)           'Years prior to the earliest year in which a particular upgrade can occur - a set form of txEarlyComYr'
  txFixedComYrSet(tupg,r,rr,ps,pss,y)           'Fixed year in which a particular upgrade must occur - set form of txFixedComYr'
  vtgc(tgc)                                     'Valid transmission group constraints'
  nSegment(n)                                   'Line segments for piecewise linear transmission losses function (number of segments = number of vertices - l)'
* Reserve energy data.
  ;

Parameters
  counter                                       'A recyclable counter - set equal to zero each time before using'
* Time/date-related sets and parameters.
  yearNum(y)                                    'Real number associated with each year'
  multipleHydroYear                             'Ordinal ranking of the multiple hydrology output year'
  averageHydroYear                              'Ordinal ranking of the average hydrology output year'
  hydroYearNum(hY)                              'Real number associated with each hydrology output year'
  lastHydroYear                                 'Last year of hydrology output data - as an integer'
  hoursPerBlock(t,lb)                           'Hours per load block by time period'
* Various mappings, subsets and counts.
  numReg                                        'Number of regions (or, if you like, nodes or buses)'
* Financial parameters.
  CBAdiscountRates(d)                           'CBA discount rates - for reporting results only'
  PVfacG(y,t)                                   "Generation investor's present value factor by period"
  PVfacT(y,t)                                   "Transmission investor's present value factor by period"
  PVfacsM(y,t,d)                                'Present value factors as at middle of period for generation, transmission, and CBA discounting in post-solve calculations'
  PVfacsEY(y,d)                                 'Present value factors as at end of year for generation, transmission, and CBA discounting in post-solve calculations'
  PVfacs(y,t,d,dt)                              'All present value factors - for generation, transmission, and CBA discounting in post-solve calculations'
  capexLife(k,ct)                               'Plant life by technology and capex type, years'
  annuityFacN(y,k,ct)                           'Nominal annuity factor by technology, year and type of capex - depends on annual inflation rate'
  annuityFacR(k,ct)                             'Real annuity factor by technology and type of capex'
  txAnnuityFacN(y)                              'Nominal transmission annuity factor and year - depends on annual inflation rate'
  txAnnuityFacR                                 'Real transmission annuity factor'
  capRecFac(y,k,ct)                             'Capital recovery factor by technology including a nominal accounting treatment of depreciation tax credit'
  depTCrecFac(y,k,ct)                           'Recovery factor by technology for just the depreciation tax credit portion of capRecFac'
  txCapRecFac(y)                                'Capital recovery factor for transmission - including a nominal accounting treatment of depreciation tax credit'
  txDeptCRecFac(y)                              'Recovery factor for just the depreciation tax credit portion of txcaprecfac'
* Fuel prices and quantity limits.
  SRMC(g,y)                                     'Short run marginal cost of each generation project by year, $/MWh'
  totalFuelCost(g,y)                            'Total fuel cost - price plus fuel delivery charge all times heatrate - by plant and year, $/MWh'
  CO2taxByPlant(g,y)                            'CO2 tax by plant and year, $/MWh'
  CO2CaptureStorageCost(g,y)                    'Carbon capture and storage cost by plant and year, $/MWh'
* Generation data.
  initialCapacity(g)                            'Capacity of existing generating plant in the first modelled year'
  capitalCost(g)                                'Generation plant capital cost, foreign currency per kW'
  capexPlant(g)                                 'Capital cost for new generation plant, $/MW'
  capCharge(g,y)                                'Annualised or levelised capital charge for new generation plant, $/MW/yr'
  refurbCapexPlant(g)                           'Capital cost for refurbishing existing generation plant, $/MW'
  refurbCapCharge(g,y)                          'Annualised or levelised capital charge for refurbishing existing generation plant, $/MW/yr'
  exogMWretired(g,y)                            'Exogenously retired MW by plant and year, MW'
  continueAftaEndogRetire(g)                    'Number of years a generation plant keeps going for after the decision to endogenously retire has been made'
  WtdAvgFOFmultiplier(k,lb)                     'FOF multiplier by technology and load block - averaged using hours in block as weights (default = 1)'
  reservesCapability(g,rc)                      'Generating plant reserve capability per reserve class, MW'
  peakConPlant(g,y)                             'Contribution to peak of each generating plant by year'
  NWpeakConPlant(g,y)                           'Contribution to peak when there is no wind of each generating plant by year'
  maxCapFactPlant(g,t,lb)                       'Maximum capacity factor by plant - incorporates forced outage rates'
  minCapFactPlant(g,y,t)                        'Minimum capacity factor - only defined for schedulable hydro and wind at this stage'
* Load data.
  AClossFactors(ild)                            'Upwards adjustment to load to account for AC (or intraregional) losses'
  NrgDemand(r,y,t,lb)                           'Load (or energy demand) by region, year, time period and load block for selected growth profile, GWh (used to create ldcMW)'
  ldcMW(r,y,t,lb)                               'MW at each block by region, year and period'
  peakLoadNZ(y)                                 'Peak load for New Zealand by year for selected growth profile, MW'
  peakLoadNI(y)                                 'Peak load for North Island by year for selected growth profile, MW'
  bigNIgen(y)                                   'Largest North Island generation plant by year, MW'
  nxtbigNIgen(y)                                'Next (second) largest North Island generation plant by year, MW'
* Transmission data.
  locFac_Recip(e)                               'Reciprocal of zonally-based location factors'
  txEarlyComYr(tupg,r,rr,ps,pss)                'Earliest year that a transmission upgrade can occur (a parameter, not a set)'
  txFixedComYr(tupg,r,rr,ps,pss)                'Fixed year in which a transmission upgrade must occur (a parameter, not a set)'
  reactanceYr(r,rr,y)                           'Reactance by year for each transmission path. Units are p.u.'
  susceptanceYr(r,rr,y)                         'Susceptance by year for each transmission path. Units are p.u.'
  BBincidence(p,r)                              'Bus-branch incidence matrix'
  pCap(r,rr,ps,n)                               'Capacity per piecewise linear segment, MW'
  pLoss(r,rr,ps,n)                              'Losses per piecewise linear segment, MW'
  bigLoss(r,rr,ps)                              'Upper bound on losses along path r-rr when in state ps, MW'
  slope(r,rr,ps,n)                              'Slope of each piecewise linear segment'
  intercept(r,rr,ps,n)                          'Intercept of each piecewise linear segment'
  txCapitalCost(r,rr,ps)                        'Capital cost of transmission upgrades by path and state, $m'
  txCapCharge(r,rr,ps,y)                        'Annualised or levelised capital charge for new transmission investment - $m/yr'
* Reserve energy data.
  reservesAreas(rc)                             'Reserves areas (single area or systemwide = 1, Island-based reserves = 2)'
  singleReservesReqF(rc)                        'Flag to inidicate if there is a single systemwide reserve requirement'
  reserveViolationPenalty(ild,rc)               'Reserve violation penalty, $/MWh'
  windCoverPropn(rc)                            'Proportion of wind to be covered by reserves, (0-1)'
  bigM(ild,ild1)                                'A large positive number'
* Hydrology output data
  hydroOutput(v,hY,m)                           'Historical hydro output sequences by reservoir and month, GWh'
  ;



*===============================================================================================
* 4. Declare model variables and equations.


*+++++++++++++++++++++++++
* Code to do the non-free reserves stuff. 
*   - Need to decide whether to retain/formalise this stuff. For example, can it be accomodated
*     within the standard reserves formulation?
Set stp 'Steps'  / stp1 * stp5 / ;

Parameters
  largestNIplant                                "Get this from the peak security data - but you can't have it vary by year"   / 385 /  
  largestSIplant                                "Get this from the peak security data - but you can't have it vary by year"   / 125 /  
  freeReserves(r,rr,ps)                         'Free reserves, MW'
  nonFreeReservesCap(r,rr,ps)                   'Non-free reserves max capacity (i.e. amount that the system must pay for), MW'
  bigSwd(r,rr)                                  'Biggest value of non-free reserves in southward direction'
  bigNwd(r,rr)                                  'Biggest value of non-free reserves in northward direction'
  pNFresvCap(r,rr,stp)                          'Capacity of each piece (or step) of non-free reserves, MW'
  pNFresvCost(r,rr,stp)                         'Constant cost of each non-free piece (or step) of function, $/MWh'
  ;

Positive Variables
  RESVCOMPONENTS(r,rr,y,t,lb,hd,stp)            'Non-free reserve components, MW'
  ;
Equations
  calc_nfreserves(r,rr,y,t,lb,hd)               'Calculate non-free reserve components' 
  resv_capacity(r,rr,y,t,lb,hd,stp)             'Calculate and impose the relevant capacity on each step of free reserves'
  ;
*+++++++++++++++++++++++++


Free Variables
  TOTALCOST                                     'Discounted total system costs over all modelled years, $m (objective function value)'
  TX(r,rr,y,t,lb,hd)                            'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
  THETA(r,y,t,lb,hd)                            'Bus voltage angle'

Binary Variables
  BGEN(g,y)                                     'Binary variable to identify build year for new generation plant'
  BRET(g,y)                                     'Binary variable to identify endogenous retirement year for the eligble generation plant'
  ISRETIRED(g)                                  'Binary variable to identify if the plant has actually been endogenously retired (0 = not retired, 1 = retired)'
  BTX(r,rr,ps,y)                                'Binary variable indicating the current state of a transmission path'
  NORESVTRFR(ild,ild1,y,t,lb,hd)                'Is there available capacity on the HVDC link to transfer energy reserves (0 = Yes, 1 = No)'

Positive Variables
  REFURBCOST(g,y)                               'Annualised generation plant refurbishment expenditure charge, $'
  GENBLDCONT(g,y)                               'Continuous variable to identify build year for new scalable generation plant - for plant in linearPlantBuild set'
  CGEN(g,y)                                     'Continuous variable to identify build year for new scalable generation plant - for plant in integerPlantBuild set (CGEN or BGEN = 0 in any year)'
  BUILD(g,y)                                    'New capacity installed by generating plant and year, MW'
  RETIRE(g,y)                                   'Capacity endogenously retired by generating plant and year, MW'
  CAPACITY(g,y)                                 'Cumulative nameplate capacity at each generating plant in each year, MW'
  TXCAPCHARGES(r,rr,y)                          'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  GEN(g,y,t,lb,hd)                              'Generation by generating plant and block, GWh'
  VOLLGEN(s,y,t,lb,hd)                          'Generation by VOLL plant and block, GWh'
  PUMPEDGEN(g,y,t,lb,hd)                        'Energy from pumped hydro (treated like demand), GWh'
  SPILL(g,y,t,hd)                               'Hydro spill, GWh'
  LOSS(r,rr,y,t,lb,hd)                          'Transmission losses along each path, MW'
  TXPROJVAR(tupg,y)                             'Continuous 0-1 variable indicating whether an upgrade project is applied'
  TXUPGRADE(r,rr,ps,pss,y)                      'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
* Reserve variables
  RESV(g,rc,y,t,lb,hd)                          'Reserve energy supplied, MWh'
  RESVVIOL(rc,ild,y,t,lb,hd)                    'Reserve energy supply violations, MWh'
  RESVTRFR(rc,ild,ild1,y,t,lb,hd)               'Reserve energy transferred from one island to another, MWh'
  RESVREQINT(rc,ild,y,t,lb,hd)                  'Internally determined energy reserve requirement, MWh'
* Penalty variables
  RENNRGPENALTY(y)                              'Penalty used to make renewable energy constraint feasible, GWh'
* Slack variables
  ANNMWSLACK(y)                                 'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  SEC_NZSLACK(y)                                'Slack with arbitrarily high cost - used to make NZ security constraint feasible, MW'
  SEC_NI1SLACK(y)                               'Slack with arbitrarily high cost - used to make NI1 security constraint feasible, MW'
  SEC_NI2SLACK(y)                               'Slack with arbitrarily high cost - used to make NI2 security constraint feasible, MW'
  NOWIND_NZSLACK(y)                             'Slack with arbitrarily high cost - used to make NZ no wind constraint feasible, MW'
  NOWIND_NISLACK(y)                             'Slack with arbitrarily high cost - used to make NI no wind constraint feasible, MW'
  RENCAPSLACK(y)                                'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  HYDROSLACK(y)                                 'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  MINUTILSLACK(y)                               'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  FUELSLACK(y)                                  'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'

Equations
  objectivefn                                   'Calculate discounted total system costs over all modelled years, $m'
  calc_refurbcost(g,y)                          'Calculate the annualised generation plant refurbishment expenditure charge in each year, $'
  calc_txcapcharges(r,rr,y)                     'Calculate cumulative annualised transmission capital charges in each modelled year, $m'
  bldgenonce(g)                                 'If new generating plant is to be built, ensure it is built only once'
  buildcapint(g,y)                              'If new integer plant is built, ensure built capacity is equal to nameplate capacity'
  buildcapcont(g,y)                             'If new scalable plant is built, ensure built capacity does not exceed nameplate capacity'
  annnewmwcap(y)                                'Restrict aggregate new capacity built in a single year to be less than a specified MW'
  endogpltretire(g,y)                           'Calculate the MW to endogenously retire'
  endogretonce(g)                               'Can only endogenously retire a plant once'
  balance_capacity(g,y)                         'Year to year capacity balance relationship for all plant, MW'
  bal_supdem(r,y,t,lb,hd)                       'Balance supply and demand in each region, year, time period and load block'
  security_nz(y)                                'Ensure enough capacity to meet peak demand in NZ if largest generator is out, ignoring tx limits'
  security_ni1(y)                               'Ensure enough capacity to meet peak demand in NI if largest generator is out, considering tx limits'
  security_ni2(y)                               'Ensure enough capacity to meet peak demand in NI if tx capacity is out'
  nowind_nz(y)                                  'Ensure enough capacity to meet peak demand in NZ when all wind is off'
  nowind_ni(y)                                  'Ensure enough capacity to meet peak demand in NI when all wind is off'
  limit_maxgen(g,y,t,lb,hd)                     'Ensure generation in each block does not exceed capacity implied by max capacity factors'
  limit_mingen(g,y,t,lb,hd)                     'Ensure generation in each block exceeds capacity implied by min capacity factors'
  minutil(g,k,y,hd)                             'Ensure generation by certain technology type meets a minimum utilisation'
  limit_fueluse(f,y,hd)                         'Quantum of each fuel used and possibly constrained, PJ'
  limit_nrg(f,y,hd)                             'Impose a limit on total energy generated by any one fuel type'
  minreq_rennrg(y,hd)                           'Impose a minimum requirement on total energy generated from all renewable sources'
  minreq_rencap(y)                              'Impose a minimum requirement on installed renewable capacity'
  limit_hydro(g,y,t,hd)                         'Limit hydro generation to according to inflows and spill'
  limit_pumpgen1(g,y,t,hd)                      'Limit output from pumped hydro in a period to the quantity pumped'
  limit_pumpgen2(g,y,t,hd)                      'Limit output from pumped hydro in a period to the assumed storage'
  limit_pumpgen3(g,y,t,lb,hd)                   "Pumped MW can be no more than the scheme's installed MW"
  boundtxloss(r,rr,ps,y,t,lb,n,hd)              'Sort out which segment of the loss function to operate on'
  tx_capacity(r,rr,y,t,lb,hd)                   'Calculate the relevant transmission capacity'
  tx_projectdef(tupg,r,rr,ps,pss,y)             'Associate projects to individual upgrades'
  tx_onestate(r,rr,y)                           'A link must be in exactly one state in any given year'
  tx_upgrade(r,rr,ps,y)                         'Make sure the upgrade of a link corresponds to a legitimate state-to-state transition'
  tx_oneupgrade(r,rr,y)                         'Only one upgrade per path in a single year'
  tx_dcflow(r,rr,y,t,lb,hd)                     'DC load flow equation'
  tx_dcflow0(r,rr,y,t,lb,hd)                    'DC load flow equation'
  equatetxloss(r,rr,y,t,lb,hd)                  'Ensure that losses in both directions are equal'
  txGrpConstraint(tgc,y,t,lb,hd)                'Group transmission constraints'
  resvsinglereq1(rc,ild,y,t,lb,hd)              'Single reserve energy requirement constraint 1'
  genmaxresv1(g,y,t,lb,hd)                      'Limit the amount of energy reserves per generator'
  resvtrfr1(ild,ild1,y,t,lb,hd)                 'Limit on the amount of reserve energy transfer - constraint 1'
  resvtrfr2(rc,ild,ild1,y,t,lb,hd)              'Limit on the amount of reserve energy transfer - constraint 2'
  resvtrfr3(rc,ild,ild1,y,t,lb,hd)              'Limit on the amount of reserve energy transfer - constraint 3'
  resvrequnit(g,rc,ild,y,t,lb,hd)               'Reserve energy requirement based on the largest dispatched unit'
  resvreq2(rc,ild,y,t,lb,hd)                    'Island reserve energy requirement - constraint 2'
  resvreqhvdc(rc,ild,y,t,lb,hd)                 'Reserve energy requirement based on the HVDC transfer taking into account self-cover'
  resvtrfr4(ild1,ild,y,t,lb,hd)                 'Limit on the amount of reserve energy transfer - constraint 4'
  resvtrfrdef(ild,ild1,y,t,lb,hd)               'Constraint that defines if reserve energy transfer is available'
  resvoffcap(g,y,t,lb,hd)                       'Offline energy reserve capability'
  resvreqwind(rc,ild,y,t,lb,hd)                 'Reserve energy requirement based on a specified proportion of dispatched wind generation'
  ;


*===============================================================================================
* 5. Specify the equations and declare the models.

* NB: Uppercase = variables; lowercase = parameters.

* Objective function - discounted total cost, $m.
objectivefn..
  TOTALCOST =e=
* Add in slacks at arbitrarily high cost.
  9999 * sum(y, ANNMWSLACK(y) ) +
  9998 * sum(y$(gridSecurity > -1), SEC_NZSLACK(y) + SEC_NI1SLACK(y) + SEC_NI2SLACK(y) ) +
  9997 * sum(y, NOWIND_NZSLACK(y) + NOWIND_NISLACK(y) ) +
  9996 * sum(y$i_renewcapshare(y), RENCAPSLACK(y) ) +
  9995 * sum(y, HYDROSLACK(y) ) +
  9994 * sum(y, MINUTILSLACK(y) ) +
  9993 * sum(y, FUELSLACK(y) ) +
* Reserve violation costs (really a 'slack' but not called a slack), $m
  1e-6 * sum((rc,ild,y,t,lb,h), i_hydroWeight(h) * RESVVIOL(rc,ild,y,t,lb,h) * reserveViolationPenalty(ild,rc) ) +
* Add in penalties at high but not arbitrarily high cost.
  penaltyViolateRenNrg * sum(y$renNrgShrOn, RENNRGPENALTY(y) ) +
* Fixed, variable and HVDC costs - discounted and adjusted for tax
* NB: Fixed costs are scaled by 1/card(t) to convert annual costs to a periodic basis coz discounting is done by period.
* NB: The HVDC charge applies only to committed and new SI projects.
  1e-6 * sum((y,t), PVfacG(y,t) * (1 - taxRate) * (
           sum(h, sum((s,lb), 1e3 * i_hydroWeight(h) * VOLLGEN(s,y,t,lb,h) * i_VOLLcost(s) ) ) +
           sum(h, sum((g,lb)$validYrOperate(g,y,t), 1e3 * i_hydroWeight(h) * GEN(g,y,t,lb,h) * srmc(g,y) * sum(mapg_e(g,e), locFac_Recip(e)) ) ) +
           ( 1/card(t) ) * 1e3 * (
           sum(g, i_fixedOM(g) * CAPACITY(g,y)) +
           sum((g,k,o)$((not demandGen(k)) * sigen(g) * possibleToBuild(g) * mapg_k(g,k) * mapg_o(g,o)), i_HVDCshr(o) * i_HVDClevy(y) * CAPACITY(g,y))
           )
         ) ) +
* Generation capital expenditure - discounted
  1e-6 * sum((y,firstPeriod(t),possibleToBuild(g)), PVfacG(y,t) * capcharge(g,y) * CAPACITY(g,y) ) +
* Generation refurbishment expenditure - discounted
  1e-6 * sum((y,firstPeriod(t),PossibleToRefurbish(g))$refurbcapcharge(g,y), PVfacG(y,t) * REFURBCOST(g,y) ) +
* Transmission capital expenditure - discounted
  sum((paths,y,firstPeriod(t)),   PVfacT(y,t) * TXCAPCHARGES(paths,y) ) +
* Cost of providing reserves ($m) - discounted and adjusted for tax.
  1e-6 * sum((g,rc,y,t,lb,h), PVfacG(y,t) * (1 - taxRate) * i_hydroWeight(h) * RESV(g,rc,y,t,lb,h) *  i_plantreservescost(g,rc) ) +
*+++++++++++++++++
* More non-free reserves code.
* Cost of providing reserves ($m) - discounted and adjusted for tax (last term of objective function).
  1e-6 * sum((paths,y,t,lb,h,stp)$( nwd(paths) or swd(paths) ),
                               PVfacG(y,t) * (1 - taxRate) * i_hydroWeight(h) * (hoursPerBlock(t,lb) * RESVCOMPONENTS(paths,y,t,lb,h,stp)) * pnfresvcost(paths,stp) ) ;

* Calculate non-free reserve components. 
calc_nfreserves(paths(r,rr),y,t,lb,h)$( nwd(r,rr) or swd(r,rr) )..
  sum(stp, RESVCOMPONENTS(r,rr,y,t,lb,h,stp)) =g= TX(r,rr,y,t,lb,h) - sum(allowedStates(r,rr,ps), BTX(r,rr,ps,y) * freereserves(r,rr,ps)) ;

* Calculate and impose the relevant capacity on each step of free reserves.
resv_capacity(paths,y,t,lb,h,stp)$( nwd(paths) or swd(paths) )..
  RESVCOMPONENTS(paths,y,t,lb,h,stp) =l= pnfresvcap(paths,stp) ;
*++++++++++++++++++

* Compute the annualised generation plant refurbishment expenditure charge in each year.
calc_refurbcost(PossibleToRefurbish(g),y)$refurbcapcharge(g,y)..
  REFURBCOST(g,y) =e= i_nameplate(g) * refurbcapcharge(g,y) - ISRETIRED(g) * i_nameplate(g) * refurbcapcharge(g,y) ;

* Compute the cumulative annualised transmission upgrade capital expenditure charges.
calc_txcapcharges(paths,y)..
  TXCAPCHARGES(paths,y) =e= TXCAPCHARGES(paths,y-1) + sum(validTransitions(paths,pss,ps), txcapcharge(paths,ps,y) * TXUPGRADE(paths,pss,ps,y) ) ;

* Ensure new plant is built no more than once, if at all (NB: =l= c.f. =e= coz build is not mandatory).
bldGenOnce(possibleToBuild(g))..
  sum(validYrBuild(g,y), ( BGEN(g,y) + CGEN(g,y) )$integerPlantBuild(g) + GENBLDCONT(g,y)$linearPlantBuild(g) ) =l= 1 ;

* If new 'integer or continuous' plant is built, ensure built capacity does not exceed nameplate capacity.
buildCapInt(g,y)$( possibleToBuild(g) * integerPlantBuild(g) * validYrBuild(g,y) )..
  BUILD(g,y) =e= ( BGEN(g,y) + CGEN(g,y) ) * i_nameplate(g) ;

* If new 'continuous' plant is built, ensure built capacity does not exceed nameplate capacity.
buildCapCont(g,y)$( possibleToBuild(g) * linearPlantBuild(g) * validYrBuild(g,y) )..
  BUILD(g,y) =e= GENBLDCONT(g,y) * i_nameplate(g) ;

* Restrict aggregate new capacity built in a single year to be less than AnnualMWlimit (max allowable limit = 3000MW).
AnnNewMWcap(y)$( AnnualMWlimit <> 9999 )..
  sum(validYrBuild(possibleToBuild(g),y), BUILD(g,y)) =l= AnnualMWlimit + ANNMWSLACK(y) ;

* Calculate the year and MW to endogenously retire.
endogpltretire(endogenousRetireDecisnYrs(g,y))..
  RETIRE(g,y+continueAftaEndogRetire(g)) =e= BRET(g,y) * i_nameplate(g) ;

* Can only endogenously retire a plant once (ISRETIRED is a binary -- 0 = not retired, 1 = retired).
endogretonce(possibleToEndogRetire(g))..
  sum(endogenousRetireDecisnYrs(g,y), BRET(g,y)) =e= ISRETIRED(g) ;

* Capacity in year y equals capacity in year y-1 plus builds in y minus retirements in y.
balance_capacity(g,y)..
  CAPACITY(g,y) =e= InitialCapacity(g)$firstYr(y) + CAPACITY(g,y-1)$allButFirstYr(y) + BUILD(g,y)$possibleToBuild(g) - RETIRE(g,y)$endogenousRetireYrs(g,y) - exogMWretired(g,y) ;

* VOLL + Supply + net imports = demand in each block + any pumped generation.
bal_supdem(r,y,t,lb,h)..
  sum(maps_r(s,r), VOLLGEN(s,y,t,lb,h)) +
  sum(mapg_r(g,r)$validYrOperate(g,y,t), GEN(g,y,t,lb,h)) +
* Transmission and losses with transportation formulation
 (sum(rr$paths(rr,r), ( ( TX(rr,r,y,t,lb,h) - LOSS(rr,r,y,t,lb,h) ) * hoursPerBlock(t,lb) * 0.001 ) ) -
  sum(rr$paths(r,rr),   ( TX(r,rr,y,t,lb,h) * hoursPerBlock(t,lb) * 0.001 ) ) )$( DCloadFlow = 0 ) +
* Transmission and losses with DC load flow formulation
 (sum(rr$paths(rr,r), ( ( TX(rr,r,y,t,lb,h) - 0.5 * LOSS(rr,r,y,t,lb,h) ) * hoursPerBlock(t,lb) * 0.001 ) ) )$( DCloadFlow = 1 )
  =g=
  ldcMW(r,y,t,lb) * hoursPerBlock(t,lb) * 0.001 +
  sum(g$( mapg_r(g,r) * pumpedHydroPlant(g) * validYrOperate(g,y,t) ), PUMPEDGEN(g,y,t,lb,h)) ;

* Ensure reserve requirements can be met at peak in both islands with largest NI unit out.
security_NZ(y)$(gridSecurity > -1)..
  SEC_NZSLACK(y) +
  sum(g, CAPACITY(g,y) * peakConPlant(g,y) ) -
  bigNIgen(y) - nxtbigNIgen(y) - i_bigSIgen(y) - i_fkNI(y) - i_fkSI(y) -
  sum((paths(r,rr),allowedStates(paths,ps))$nwd(paths), i_txCapacity(paths,ps) * BTX(paths,ps,y) ) * i_HVDClosses(y)
  =g= peakLoadNZ(y) ;

* Ensure reserve requirements can be met at peak in North island with largest NI unit out.
security_NI1(y)$(gridSecurity > -1)..
  SEC_NI1SLACK(y) +
  sum(nigen(g), CAPACITY(g,y) * peakConPlant(g,y) ) -
  bigNIgen(y) - nxtbigNIgen(y) - i_fkNI(y) +
  sum((paths(r,rr),allowedStates(paths,ps))$nwd(paths), i_txCapacity(paths,ps) * BTX(paths,ps,y) ) * (1 - i_HVDClosses(y))
  =g= peakLoadNI(y) ;

* Ensure reserve requirements can be met at peak in North island with the loss of one HVDC pole.
security_NI2(y)$(gridSecurity > -1)..
  SEC_NI2SLACK(y) +
  sum(nigen(g), CAPACITY(g,y) * peakConPlant(g,y) ) -
  bigNIgen(y) - i_fkNI(y) +
  sum((paths(r,rr),allowedStates(paths,ps))$nwd(paths), i_txCapacityPO(paths,ps) * BTX(paths,ps,y) ) * (1 - i_HVDClossesPO(y))
  =g= peakLoadNI(y) ;

* Ensure NZ cold-year winter peak can be met without any wind.
noWind_NZ(y)$(gridSecurity > -1)..
  NOWIND_NZSLACK(y) +
  sum(mapg_k(g,k)$( not wind(k) ), CAPACITY(g,y) * NWpeakConPlant(g,y) ) -
  i_fkNI(y) - i_fkSI(y) -
  sum((paths(r,rr),allowedStates(paths,ps))$nwd(paths), i_txCapacity(paths,ps) * BTX(paths,ps,y) ) * i_HVDClosses(y)
  =g= peakLoadNZ(y) ;

* Ensure NI cold-year winter peak can be met without any wind.
noWind_NI(y)$(gridSecurity > -1)..
  NOWIND_NISLACK(y) +
  sum(mapg_k(g,k)$( nigen(g) and (not wind(k)) ), CAPACITY(g,y) * NWpeakConPlant(g,y) ) -
  i_fkNI(y) +
  sum((paths(r,rr),allowedStates(paths,ps))$nwd(paths), i_txCapacity(paths,ps) * BTX(paths,ps,y) ) * (1 - i_HVDClosses(y))
  =g= peakLoadNI(y) ;

* Ensure generation is less than capacity times max capacity factor in each block.
limit_maxgen(validYrOperate(g,y,t),lb,h)$( ( exist(g) or possibleToBuild(g) ) * ( not useReserves ) )..
  GEN(g,y,t,lb,h) =l= 0.001 * CAPACITY(g,y) * maxCapFactPlant(g,t,lb) * hoursPerBlock(t,lb) ;

* Ensure generation is greater than capacity times min capacity factor in each block.
limit_mingen(validYrOperate(g,y,t),lb,h)$minCapFactPlant(g,y,t)..
  GEN(g,y,t,lb,h) =g= 0.001 * CAPACITY(g,y) * minCapFactPlant(g,y,t) * hoursPerBlock(t,lb) ;

* Minimum ultilisation of plant by technology.
minutil(g,k,y,h)$( i_minutilisation(g) * i_minUtilByTech(y,k) * mapg_k(g,k) )..
  sum((t,lb)$validYrOperate(g,y,t), GEN(g,y,t,lb,h)) + MINUTILSLACK(y) =g= i_minUtilByTech(y,k) * 8.76 * CAPACITY(g,y) * (1 - i_fof(g)) ;

* Thermal fuel limits.
limit_fueluse(thermalfuel(f),y,h)$( ( gas(f) * (i_fuelQuantities(f,y) > 0) * (i_fuelQuantities(f,y) < 999) ) or ( diesel(f) * (i_fuelQuantities(f,y) > 0) ) )..
  1e-6 * sum((g,t,lb)$( mapg_f(g,f) * validYrOperate(g,y,t) ), i_heatrate(g) * GEN(g,y,t,lb,h) ) =l= i_fuelQuantities(f,y) + FUELSLACK(y) ;

* Impose a limit on total energy generated from any one fuel type.
limit_Nrg(f,y,h)$i_maxNrgByFuel(f)..
  sum((g,t,lb)$( mapg_f(g,f) * validYrOperate(g,y,t) ), GEN(g,y,t,lb,h)) =l= i_maxNrgByFuel(f) * sum((g,t,lb)$validYrOperate(g,y,t), GEN(g,y,t,lb,h)) ;

* Impose a minimum requirement on total energy generated from all renewable sources.
minReq_RenNrg(y,h)$renNrgShrOn..
  i_renewNrgShare(y) * ( sum((g,t,lb)$validYrOperate(g,y,t), GEN(g,y,t,lb,h)) + i_distdGenRenew(y) + i_distdGenFossil(y) ) =l=
  sum((g,k,t,lb)$( mapg_k(g,k) * renew(k) * validYrOperate(g,y,t)), GEN(g,y,t,lb,h)) + i_distdGenRenew(y) +
  RENNRGPENALTY(y) ;

* Impose a minimum requirement on installed renewable capacity.
minReq_RenCap(y)$i_renewCapShare(y)..
  i_renewCapShare(y) * sum(possibleToBuild(g), 8.76 * CAPACITY(g,y) * (1 - i_fof(g)) ) =l=
  sum((g,k)$( possibleToBuild(g) * mapg_k(g,k) * renew(k) ), 8.76 * CAPACITY(g,y) * (1 - i_fof(g)) ) +
  RENCAPSLACK(y) ;

* Limit hydro according to energy available in inflows less spill (needs to be =e= if SPILL is costless).
limit_hydro(validYrOperate(g,y,t),h)$schedHydroPlant(g)..
  sum(lb, GEN(g,y,t,lb,h)) + SPILL(g,y,t,h) =l= hydOutput(g,y,t,h) + HYDROSLACK(y) ;

* Over the period, ensure that generation from pumped hydro is less than the energy pumped.
limit_pumpgen1(validYrOperate(g,y,t),h)$pumpedHydroPlant(g)..
  sum(lb, GEN(g,y,t,lb,h)) =l= i_PumpedHydroEffic(g) * sum(lb, PUMPEDGEN(g,y,t,lb,h) ) ;

* Over the period, ensure that the energy pumped is less than the storage capacity.
limit_pumpgen2(validYrOperate(g,y,t),h)$pumpedHydroPlant(g)..
  i_PumpedHydroEffic(g) * sum(lb, PUMPEDGEN(g,y,t,lb,h) ) =l= sum(mapm_t(m,t), 1) * i_PumpedHydroMonth(g) ;

* The MW pumped can be no greater than the capacity of the project.
limit_pumpgen3(validYrOperate(g,y,t),lb,h)$pumpedHydroPlant(g)..
  PUMPEDGEN(g,y,t,lb,h) =l= 0.001 * CAPACITY(g,y) * maxCapFactPlant(g,t,lb) * hoursPerBlock(t,lb) ;

* Piecewise linear transmission losses.
boundTxloss(paths(r,rr),ps,y,t,lb,nsegment(n),h)$( allowedStates(paths,ps) * bigloss(paths,ps) )..
  LOSS(paths,y,t,lb,h) =g=
  intercept(paths,ps,n) + slope(paths,ps,n) * TX(paths,y,t,lb,h) - bigloss(paths,ps) * ( 1 - BTX(paths,ps,y) ) ;

* Calculate the relevant transmission capacity and impose it.
tx_capacity(paths,y,t,lb,h)..
  TX(paths,y,t,lb,h) =l= sum(allowedStates(paths,ps), i_txCapacity(paths,ps) * BTX(paths,ps,y)) ;

* Associate projects to individual upgrades (also ensures both directions of a path get upgraded together).
tx_projectdef(transitions(tupg,paths,ps,pss),y)..
  TXPROJVAR(tupg,y) =e= TXUPGRADE(paths,ps,pss,y) ;

* A link must be in exactly one state in any given year.
tx_onestate(paths,y)..
  sum(allowedStates(paths,ps), BTX(paths,ps,y)) =e= 1 ;

* Make sure the upgrade of a link corresponds to a legitimate state-to-state transition.
tx_upgrade(paths,ps,y)$upgradedStates(paths,ps)..
  sum(validTransitions(paths,pss,ps), TXUPGRADE(paths,pss,ps,y)) - sum(validTransitions(paths,ps,pss), TXUPGRADE(paths,ps,pss,y) ) =e=
  BTX(paths,ps,y) - BTX(paths,ps,y-1) ;

* Only one upgrade per path in a single year.
tx_oneupgrade(paths,y)..
  sum(upgradedStates(paths,ps), sum(validTransitions(paths,pss,ps), TXUPGRADE(paths,pss,ps,y) )) =l= 1 ;

* DC load flow equation for all paths.
tx_dcflow(r,rr,y,t,lb,h)$( DCloadFlow * susceptanceyr(r,rr,y) * regLower(r,rr) )..
  TX(r,rr,y,t,lb,h) =e= susceptanceyr(r,rr,y) * ( THETA(r,y,t,lb,h) - THETA(rr,y,t,lb,h) ) ;

* Ensure that for flow on links without reactance the flow from r to rr = - flow from rr to r
tx_dcflow0(r,rr,y,t,lb,h)$( DCloadFlow * paths(r,rr) * regLower(r,rr) )..
  TX(r,rr,y,t,lb,h) + TX(rr,r,y,t,lb,h) =e= 0 ;

* Ensure equality of losses in both directions for the DC load flow representation
* NB: No need for this constraint if the maximum losses on a link = 0 since then the loss variable is fixed in GEMsolve
equatetxloss(r,rr,y,t,lb,h)$( DCloadFlow * paths(r,rr) * regLower(r,rr) * sum(ps, bigloss(r,rr,ps)) )..
  LOSS(r,rr,y,t,lb,h) =e=  LOSS(rr,r,y,t,lb,h) ;

* Transmission group constraints, i.e. in addition to individual branch limits. Use to cater for contingencies, stability limits, etc.
***txGrpConstraint(vtgc,y,t,lb,h)$txconstraintactive(y,t,vtgc)..
txGrpConstraint(vtgc,y,t,lb,h)$DCloadFlow..
  sum((p,paths(r,rr))$( (bbincidence(p,r) = 1) * (bbincidence(p,rr) = -1) ), i_txGrpConstraintsLHS(vtgc,p) * TX(paths,y,t,lb,h) )
  =l= i_txGrpConstraintsRHS(vtgc) ;

* Meet the single reserve requirement.
resvsinglereq1(rc,ild,y,t,lb,h)$( useReserves * singleReservesReqF(rc) )..
  sum(g, RESV(g,rc,y,t,lb,h)) + RESVVIOL(rc,ild,y,t,lb,h) =g= RESVREQINT(rc,ild,y,t,lb,h) ;

* Generator energy constraint - substitute for limit_maxgen when reserves are used.
genmaxresv1(validYrOperate(g,y,t),lb,h)$( useReserves * ( exist(g) or possibleToBuild(g) ) )..
  1000 * GEN(g,y,t,lb,h) + sum(rc, RESV(g,rc,y,t,lb,h)) =l= CAPACITY(g,y) * maxCapFactPlant(g,t,lb) * hoursPerBlock(t,lb) ;

* Reserve transfers - Constraint 1.
resvtrfr1(ild1,ild,y,t,lb,h)$( useReserves * interIsland(ild1,ild) )..
  sum( rc, RESVTRFR(rc,ild1,ild,y,t,lb,h) ) +
  hoursPerBlock(t,lb) * sum((r,rr)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr)), TX(r,rr,y,t,lb,h) )
  =l= hoursPerBlock(t,lb) * sum((r,rr,ps)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacity(r,rr,ps) * BTX(r,rr,ps,y) ) ;

* Reserve transfers - Constraint 2.
resvtrfr2(rc,ild1,ild,y,t,lb,h)$( useReserves * interIsland(ild1,ild) * ( not singleReservesReqF(rc) ) )..
  RESVTRFR(rc,ild1,ild,y,t,lb,h)
  =l= hoursPerBlock(t,lb) * sum((r,rr,ps)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) ), i_maxReservesTrnsfr(r,rr,ps,rc) * BTX(r,rr,ps,y) ) ;

* Reserve transfers - Constraint 3.
resvtrfr3(rc,ild1,ild,y,t,lb,h)$( useReserves * interIsland(ild1,ild) * ( not singleReservesReqF(rc) ) )..
  RESVTRFR(rc,ild1,ild,y,t,lb,h) =l= sum(mapg_ild(g,ild1), RESV(g,rc,y,t,lb,h) ) ;

* Internal reserve requirement determined by the largest dispatched unit during each period.
resvrequnit(g,rc,ild,y,t,lb,h)$( validYrOperate(g,y,t) * useReserves * ( exist(g) or possibleToBuild(g) ) * mapg_ild(g,ild) *
                                  ( (i_reserveReqMW(y,ild,rc) = -1) or (i_reserveReqMW(y,ild,rc) = -3) )  )..
  RESVREQINT(rc,ild,y,t,lb,h) =g= 1000 * GEN(g,y,t,lb,h) * i_UnitLargestProp(g) ;

* Internal island reserve requirement.
resvreq2(rc,ild,y,t,lb,h)$( useReserves * ( not singleReservesReqF(rc) ) )..
  sum(mapg_ild(g,ild), RESV(g,rc,y,t,lb,h) ) + sum(interIsland(ild1,ild), RESVTRFR(rc,ild1,ild,y,t,lb,h) ) +
  RESVVIOL(rc,ild,y,t,lb,h) =g= RESVREQINT(rc,ild,y,t,lb,h) ;

* Internal reserve requirement determined by the HVDC transfer taking into account self-cover.
resvreqhvdc(rc,ild,y,t,lb,h)$( useReserves * ( not singleReservesReqF(rc) ) )..
  RESVREQINT(rc,ild,y,t,lb,h) =g=
  hoursPerBlock(t,lb) * sum((r,rr,ild1)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) * interIsland(ild,ild1) ), TX(r,rr,y,t,lb,h) ) -
  hoursPerBlock(t,lb) * sum((r,rr,ps,ild1)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) * interIsland(ild,ild1) ), i_txCapacityPO(r,rr,ps) * BTX(r,rr,ps,y) ) ;

* Reserve energy transfer - Constraint 4.
resvtrfr4(interIsland(ild1,ild),y,t,lb,h)$useReserves..
  sum(rc, RESVTRFR(rc,ild1,ild,y,t,lb,h) )
  =l= hoursPerBlock(t,lb) * sum((r,rr,ps)$(paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr)) , i_txCapacity(r,rr,ps)) * ( 1 - NORESVTRFR(ild1,ild,y,t,lb,h) ) ;

* Constraint that defines the reserve transfer capability.
resvtrfrdef(interIsland(ild1,ild),y,t,lb,h)$useReserves..
  sum((r,rr)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) ), TX(r,rr,y,t,lb,h) ) -
  sum((r,rr,ps)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacityPO(r,rr,ps) * BTX(r,rr,ps,y) )
  =l= NORESVTRFR(ild1,ild,y,t,lb,h) * bigm(ild1,ild) ;

* Constraint to define the offline reserve capability.
resvoffcap(validYrOperate(g,y,t),lb,h)$( useReserves * ( exist(g) or possibleToBuild(g) ) * (sum(rc, reservesCapability(g,rc))) * ( not i_offlineReserve(g) ) )..
  sum(rc, RESV(g,rc,y,t,lb,h)) =l= 1000 * GEN(g,y,t,lb,h) ;

* Constraint to ensure that reserves cover a certain proportion of wind generation.
resvreqwind(rc,ild,y,t,lb,h)$( useReserves * ( (i_reserveReqMW(y,ild,rc) = -2) or (i_reserveReqMW(y,ild,rc) = -3) ) * windCoverPropn(rc) )..
  RESVREQINT(rc,ild,y,t,lb,h)
  =g= windCoverPropn(rc) * sum(mapg_k(g,k)$( wind(k) * mapg_ild(g,ild) * validYrOperate(g,y,t) ), 1000 * GEN(g,y,t,lb,h) ) ;

Model GEM Generation expansion model  /
  objectivefn, calc_refurbcost, calc_txcapcharges,   balance_capacity, bal_supdem
  bldGenOnce, buildCapInt, buildCapCont, annNewMWcap, endogpltretire, endogretonce
  security_nz, security_ni1,  security_ni2, nowind_nz, nowind_ni
  limit_maxgen, limit_mingen, minutil, limit_fueluse, limit_Nrg, minReq_RenNrg, minReq_RenCap, limit_hydro
  limit_pumpgen1, limit_pumpgen2, limit_pumpgen3
  boundTxloss, tx_capacity, tx_projectdef, tx_onestate, tx_upgrade, tx_oneupgrade
  tx_dcflow, tx_dcflow0, equatetxloss, txGrpConstraint
  resvsinglereq1, genmaxresv1, resvtrfr1, resvtrfr2, resvtrfr3, resvrequnit
  resvreq2, resvreqhvdc, resvtrfr4, resvtrfrdef, resvoffcap, resvreqwind
*++++++++++
* More non-free reserves code.
  calc_nfreserves, resv_capacity
*++++++++++
  / ;

* DISPatch is identical to GEM except 6 constraints are dropped:
* - bldGenOnce, buildCapInt, buildCapCont, annNewMWcap, endogpltretire and endogretonce.
Model DISP Dispatch model with build forced and timing fixed  /
  objectivefn, calc_refurbcost, calc_txcapcharges,   balance_capacity, bal_supdem
  security_nz, security_ni1,  security_ni2, nowind_nz, nowind_ni
  limit_maxgen, limit_mingen, minutil, limit_fueluse, limit_Nrg, minReq_RenNrg, minReq_RenCap, limit_hydro
  limit_pumpgen1, limit_pumpgen2, limit_pumpgen3
  boundTxloss, tx_capacity, tx_projectdef, tx_onestate, tx_upgrade, tx_oneupgrade
  tx_dcflow, tx_dcflow0, equatetxloss, txGrpConstraint
  resvsinglereq1, genmaxresv1, resvtrfr1, resvtrfr2, resvtrfr3, resvrequnit
  resvreq2, resvreqhvdc, resvtrfr4, resvtrfrdef, resvoffcap, resvreqwind
*++++++++++
* More non-free reserves code.
  calc_nfreserves, resv_capacity
*++++++++++
  / ;



*===============================================================================================
* 6. Declare the 's' parameters and specify the statements used to collect up results after each solve.
*    NB: The 's' prefix denotes 'solution' to model.
*        Multiply $m/GWh by 1000 to get $/MWh.
*        Divide $m/GWh by 100 to get cents per kWh.
*        Units not yet verified in all cases and some descriptions could be made more meaningful.

Parameters
*+++++++++++++++++++++++++
* More non-free reserves code.
* Positive Variables
  s_RESVCOMPONENTS(rt,hY,r,rr,y,t,lb,hd,stp)    'Non-free reserve components, MW'
* Equations
  s_calc_nfreserves(rt,hY,r,rr,y,t,lb,hd)       'Calculate non-free reserve components' 
  s_resv_capacity(rt,hY,r,rr,y,t,lb,hd,stp)     'Calculate and impose the relevant capacity on each step of free reserves'
*+++++++++++++++++++++++++
* Free Variables
  s_TOTALCOST(rt,hY)                            'Discounted total system costs over all modelled years, $m (objective function value)'
  s_TX(rt,hY,r,rr,y,t,lb,hd)                    'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice)'
  s_THETA(rt,hY,r,y,t,lb,hd)                    'Bus voltage angle'
* Binary Variables
  s_BGEN(rt,hY,g,y)                             'Binary variable to identify build year for new generation plant'
  s_BRET(rt,hY,g,y)                             'Binary variable to identify endogenous retirement year for the eligble generation plant'
  s_ISRETIRED(rt,hY,g)                          'Binary variable to identify if the plant has actually been endogenously retired (0 = not retired, 1 = retired)'
  s_BTX(rt,hY,r,rr,ps,y)                        'Binary variable indicating the current state of a transmission path'
  s_NORESVTRFR(rt,hY,ild,ild1,y,t,lb,hd)        'Is there available capacity on the HVDC link to transfer energy reserves (0 = Yes, 1 = No)'
* Positive Variables
  s_REFURBCOST(rt,hY,g,y)                       'Annualised generation plant refurbishment expenditure charge, $'
  s_GENBLDCONT(rt,hY,g,y)                       'Continuous variable to identify build year for new scalable generation plant - for plant in linearPlantBuild set'
  s_CGEN(rt,hY,g,y)                             'Continuous variable to identify build year for new scalable generation plant - for plant in integerPlantBuild set (CGEN or BGEN = 0 in any year)'
  s_BUILD(rt,hY,g,y)                            'New capacity installed by generating plant and year, MW'
  s_RETIRE(rt,hY,g,y)                           'Capacity endogenously retired by generating plant and year, MW'
  s_CAPACITY(rt,hY,g,y)                         'Cumulative nameplate capacity at each generating plant in each year, MW'
  s_TXCAPCHARGES(rt,hY,r,rr,y)                  'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  s_GEN(rt,hY,g,y,t,lb,hd)                      'Generation by generating plant and block, GWh'
  s_VOLLGEN(rt,hY,s,y,t,lb,hd)                  'Generation by VOLL plant and block, GWh'
  s_PUMPEDGEN(rt,hY,g,y,t,lb,hd)                'Energy from pumped hydro (treated like demand), GWh'
  s_SPILL(rt,hY,g,y,t,hd)                       'Hydro spill, GWh'
  s_LOSS(rt,hY,r,rr,y,t,lb,hd)                  'Transmission losses along each path, MW'
  s_TXPROJVAR(rt,hY,tupg,y)                     'Continuous 0-1 variable indicating whether an upgrade project is applied'
  s_TXUPGRADE(rt,hY,r,rr,ps,pss,y)              'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
* Reserve variables
  s_RESV(rt,hY,g,rc,y,t,lb,hd)                  'Reserve energy supplied, MWh'
  s_RESVVIOL(rt,hY,rc,ild,y,t,lb,hd)            'Reserve energy supply violations, MWh'
  s_RESVTRFR(rt,hY,rc,ild,ild1,y,t,lb,hd)       'Reserve energy transferred from one island to another, MWh'
  s_RESVREQINT(rt,hY,rc,ild,y,t,lb,hd)          'Internally determined energy reserve requirement, MWh'
* Penalty variables
  s_RENNRGPENALTY(rt,hY,y)                      'Penalty used to make renewable energy constraint feasible, GWh'
* Slack variables
  s_ANNMWSLACK(rt,hY,y)                         'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  s_SEC_NZSLACK(rt,hY,y)                        'Slack with arbitrarily high cost - used to make NZ security constraint feasible, MW'
  s_SEC_NI1SLACK(rt,hY,y)                       'Slack with arbitrarily high cost - used to make NI1 security constraint feasible, MW'
  s_SEC_NI2SLACK(rt,hY,y)                       'Slack with arbitrarily high cost - used to make NI2 security constraint feasible, MW'
  s_NOWIND_NZSLACK(rt,hY,y)                     'Slack with arbitrarily high cost - used to make NZ no wind constraint feasible, MW'
  s_NOWIND_NISLACK(rt,hY,y)                     'Slack with arbitrarily high cost - used to make NI no wind constraint feasible, MW'
  s_RENCAPSLACK(rt,hY,y)                        'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  s_HYDROSLACK(rt,hY,y)                         'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  s_MINUTILSLACK(rt,hY,y)                       'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  s_FUELSLACK(rt,hY,y)                          'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'
* Equations (ignore the objective function)
  s_calc_refurbcost(rt,hY,g,y)                  'Calculate the annualised generation plant refurbishment expenditure charge in each year, $'
  s_calc_txcapcharges(rt,hY,r,rr,y)             'Calculate cumulative annualised transmission capital charges in each modelled year, $m'
  s_bldgenonce(rt,hY,g)                         'If new generating plant is to be built, ensure it is built only once'
  s_buildcapint(rt,hY,g,y)                      'If new integer plant is built, ensure built capacity is equal to nameplate capacity'
  s_buildcapcont(rt,hY,g,y)                     'If new scalable plant is built, ensure built capacity does not exceed nameplate capacity'
  s_annnewmwcap(rt,hY,y)                        'Restrict aggregate new capacity built in a single year to be less than a specified MW'
  s_endogpltretire(rt,hY,g,y)                   'Calculate the MW to endogenously retire'
  s_endogretonce(rt,hY,g)                       'Can only endogenously retire a plant once'
  s_balance_capacity(rt,hY,g,y)                 'Year to year capacity balance relationship for all plant, MW'
  s_bal_supdem(rt,hY,r,y,t,lb,hd)               'Balance supply and demand in each region, year, time period and load block'
  s_security_nz(rt,hY,y)                        'Ensure enough capacity to meet peak demand in NZ if largest generator is out, ignoring tx limits'
  s_security_ni1(rt,hY,y)                       'Ensure enough capacity to meet peak demand in NI if largest generator is out, considering tx limits'
  s_security_ni2(rt,hY,y)                       'Ensure enough capacity to meet peak demand in NI if tx capacity is out'
  s_nowind_nz(rt,hY,y)                          'Ensure enough capacity to meet peak demand in NZ when all wind is off'
  s_nowind_ni(rt,hY,y)                          'Ensure enough capacity to meet peak demand in NI when all wind is off'
  s_limit_maxgen(rt,hY,g,y,t,lb,hd)             'Ensure generation in each block does not exceed capacity implied by max capacity factors'
  s_limit_mingen(rt,hY,g,y,t,lb,hd)             'Ensure generation in each block exceeds capacity implied by min capacity factors'
  s_minutil(rt,hY,g,k,y,hd)                     'Ensure generation by certain technology type meets a minimum utilisation'
  s_limit_fueluse(rt,hY,f,y,hd)                 'Quantum of each fuel used and possibly constrained, PJ'
  s_limit_nrg(rt,hY,f,y,hd)                     'Impose a limit on total energy generated by any one fuel type'
  s_minreq_rennrg(rt,hY,y,hd)                   'Impose a minimum requirement on total energy generated from all renewable sources'
  s_minreq_rencap(rt,hY,y)                      'Impose a minimum requirement on installed renewable capacity'
  s_limit_hydro(rt,hY,g,y,t,hd)                 'Limit hydro generation to according to inflows and spill'
  s_limit_pumpgen1(rt,hY,g,y,t,hd)              'Limit output from pumped hydro in a period to the quantity pumped'
  s_limit_pumpgen2(rt,hY,g,y,t,hd)              'Limit output from pumped hydro in a period to the assumed storage'
  s_limit_pumpgen3(rt,hY,g,y,t,lb,hd)           "Pumped MW can be no more than the scheme's installed MW"
  s_boundtxloss(rt,hY,r,rr,ps,y,t,lb,n,hd)      'Sort out which segment of the loss function to operate on'
  s_tx_capacity(rt,hY,r,rr,y,t,lb,hd)           'Calculate the relevant transmission capacity'
  s_tx_projectdef(rt,hY,tupg,r,rr,ps,pss,y)     'Associate projects to individual upgrades'
  s_tx_onestate(rt,hY,r,rr,y)                   'A link must be in exactly one state in any given year'
  s_tx_upgrade(rt,hY,r,rr,ps,y)                 'Make sure the upgrade of a link corresponds to a legitimate state-to-state transition'
  s_tx_oneupgrade(rt,hY,r,rr,y)                 'Only one upgrade per path in a single year'
  s_tx_dcflow(rt,hY,r,rr,y,t,lb,hd)             'DC load flow equation'
  s_tx_dcflow0(rt,hY,r,rr,y,t,lb,hd)            'DC load flow equation'
  s_equatetxloss(rt,hY,r,rr,y,t,lb,hd)          'Ensure that losses in both directions are equal'
  s_txGrpConstraint(rt,hY,tgc,y,t,lb,hd)        'Group transmission constraints'
  s_resvsinglereq1(rt,hY,rc,ild,y,t,lb,hd)      'Single reserve energy requirement constraint 1'
  s_genmaxresv1(rt,hY,g,y,t,lb,hd)              'Limit the amount of energy reserves per generator'
  s_resvtrfr1(rt,hY,ild,ild1,y,t,lb,hd)         'Limit on the amount of reserve energy transfer - constraint 1'
  s_resvtrfr2(rt,hY,rc,ild,ild1,y,t,lb,hd)      'Limit on the amount of reserve energy transfer - constraint 2'
  s_resvtrfr3(rt,hY,rc,ild,ild1,y,t,lb,hd)      'Limit on the amount of reserve energy transfer - constraint 3'
  s_resvrequnit(rt,hY,g,rc,ild,y,t,lb,hd)       'Reserve energy requirement based on the largest dispatched unit'
  s_resvreq2(rt,hY,rc,ild,y,t,lb,hd)            'Island reserve energy requirement - constraint 2'
  s_resvreqhvdc(rt,hY,rc,ild,y,t,lb,hd)         'Reserve energy requirement based on the HVDC transfer taking into account self-cover'
  s_resvtrfr4(rt,hY,ild1,ild,y,t,lb,hd)         'Limit on the amount of reserve energy transfer - constraint 4'
  s_resvtrfrdef(rt,hY,ild,ild1,y,t,lb,hd)       'Constraint that defines if reserve energy transfer is available'
  s_resvoffcap(rt,hY,g,y,t,lb,hd)               'Offline energy reserve capability'
  s_resvreqwind(rt,hY,rc,ild,y,t,lb,hd)         'Reserve energy requirement based on a specified proportion of dispatched wind generation'
  ;

* Now push the statements that collect up results into a file called CollectResults.txt. This file gets $include'd into GEMsolve.gms
$onecho > CollectResults.txt
*++++++++++
* More non-free reserves code.
* Positive Variables
  s_RESVCOMPONENTS(rt,hY,r,rr,y,t,lb,h,stp)  = RESVCOMPONENTS.l(r,rr,y,t,lb,h,stp) ;
* Equations
  s_calc_nfreserves(rt,hY,r,rr,y,t,lb,h)     = calc_nfreserves.m(r,rr,y,t,lb,h) ;
  s_resv_capacity(rt,hY,r,rr,y,t,lb,h,stp)   = resv_capacity.m(r,rr,y,t,lb,h,stp) ;
*++++++++++
* Misc params
*  s_hydOutput(rt,hY,g,y,t,h)                = hydOutput(g,y,t,h) ;
* Free variables.
  s_TOTALCOST(rt,hY)                         = TOTALCOST.l ;
  if(DCloadFlow = 1,
    s_TX(rt,hY,r,rr,y,t,lb,h)$( TX.l(r,rr,y,t,lb,h) > 0 ) = TX.l(r,rr,y,t,lb,h) ;
    else
    s_TX(rt,hY,r,rr,y,t,lb,h) = TX.l(r,rr,y,t,lb,h) ;
  ) ;
  s_THETA(rt,hY,r,y,t,lb,h)                  = THETA.l(r,y,t,lb,h) ;
* Binary Variables
  s_BRET(rt,hY,g,y)                          = BRET.l(g,y) ;
  s_ISRETIRED(rt,hY,g)                       = ISRETIRED.l(g) ;
  s_BTX(rt,hY,r,rr,ps,y)                     = BTX.l(r,rr,ps,y) ;
  s_NORESVTRFR(rt,hY,ild,ild1,y,t,lb,h)      = NORESVTRFR.l(ild,ild1,y,t,lb,h) ;
* Positive Variables
  s_REFURBCOST(rt,hY,g,y)                    = REFURBCOST.l(g,y) ;
  s_BUILD(rt,hY,g,y)                         = BUILD.l(g,y) ;
  s_RETIRE(rt,hY,g,y)                        = RETIRE.l(g,y) ;
  s_CAPACITY(rt,hY,g,y)                      = CAPACITY.l(g,y) ;
  s_TXCAPCHARGES(rt,hY,paths,y)              = TXCAPCHARGES.l(paths,y) ;
  s_GEN(rt,hY,g,y,t,lb,h)                    = GEN.l(g,y,t,lb,h) ;
  s_VOLLGEN(rt,hY,s,y,t,lb,h)                = VOLLGEN.l(s,y,t,lb,h) ;
  s_PUMPEDGEN(rt,hY,g,y,t,lb,h)              = PUMPEDGEN.l(g,y,t,lb,h) ;
  s_SPILL(rt,hY,g,y,t,h)                     = SPILL.l(g,y,t,h) ;
  s_LOSS(rt,hY,r,rr,y,t,lb,h)                = LOSS.l(r,rr,y,t,lb,h) ;
  s_TXPROJVAR(rt,hY,tupg,y)                  = TXPROJVAR.l(tupg,y) ;
  s_TXUPGRADE(rt,hY,r,rr,ps,pss,y)           = TXUPGRADE.l(r,rr,ps,pss,y) ;
* Reserve variables
  s_RESV(rt,hY,g,rc,y,t,lb,h)                = RESV.l(g,rc,y,t,lb,h) ;
  s_RESVVIOL(rt,hY,rc,ild,y,t,lb,h)          = RESVVIOL.l(RC,ILD,y,t,lb,h) ;
  s_RESVTRFR(rt,hY,rc,ild,ild1,y,t,lb,h)     = RESVTRFR.l(rc,ild1,ild,y,t,lb,h) ;
  s_RESVREQINT(rt,hY,rc,ild,y,t,lb,h)        = RESVREQINT.l(rc,ild,y,t,lb,h) ;
* Penalty variables
  s_RENNRGPENALTY(rt,hY,y)                   = RENNRGPENALTY.l(y) ;
* Slack variables
  s_ANNMWSLACK(rt,hY,y)                      = ANNMWSLACK.l(y) ;
  s_SEC_NZSLACK(rt,hY,y)                     = SEC_NZSLACK.l(y) ;
  s_SEC_NI1SLACK(rt,hY,y)                    = SEC_NI1SLACK.l(y) ;
  s_SEC_NI2SLACK(rt,hY,y)                    = SEC_NI2SLACK.l(y) ;
  s_NOWIND_NZSLACK(rt,hY,y)                  = NOWIND_NZSLACK.l(y) ;
  s_NOWIND_NISLACK(rt,hY,y)                  = NOWIND_NISLACK.l(y) ;
  s_RENCAPSLACK(rt,hY,y)                     = RENCAPSLACK.l(y) ;
  s_HYDROSLACK(rt,hY,y)                      = HYDROSLACK.l(y) ;
  s_MINUTILSLACK(rt,hY,y)                    = MINUTILSLACK.l(y) ;
  s_FUELSLACK(rt,hY,y)                       = FUELSLACK.l(y) ;
* Equations, i.e. marginal values. (ignore the objective function)
  s_calc_refurbcost(rt,hY,g,y)               = calc_refurbcost.m(g,y) ;
  s_calc_txcapcharges(rt,hY,paths,y)         = calc_txcapcharges.m(paths,y) ;
  s_balance_capacity(rt,hY,g,y)              = balance_capacity.m(g,y) ;
  s_bal_supdem(rt,hY,r,y,t,lb,h)             = bal_supdem.m(r,y,t,lb,h) ;
  s_security_nz(rt,hY,y)                     = security_NZ.m(y) ;
  s_security_ni1(rt,hY,y)                    = security_NI1.m(y) ;
  s_security_ni2(rt,hY,y)                    = security_NI2.m(y) ;
  s_nowind_nz(rt,hY,y)                       = noWind_NZ.m(y) ;
  s_nowind_ni(rt,hY,y)                       = noWind_NI.m(y) ;
  s_limit_maxgen(rt,hY,g,y,t,lb,h)           = limit_maxgen.m(g,y,t,lb,h) ;
  s_limit_mingen(rt,hY,g,y,t,lb,h)           = limit_mingen.m(g,y,t,lb,h) ;
  s_minutil(rt,hY,g,k,y,h)                   = minutil.m(g,k,y,h) ;
  s_limit_fueluse(rt,hY,f,y,h)               = limit_fueluse.m(f,y,h) ;
  s_limit_nrg(rt,hY,f,y,h)                   = limit_nrg.m(f,y,h) ;
  s_minreq_rennrg(rt,hY,y,h)                 = minReq_renNrg.m(y,h) ;
  s_minreq_rencap(rt,hY,y)                   = minReq_renCap.m(y) ;
  s_limit_hydro(rt,hY,g,y,t,h)               = limit_hydro.m(g,y,t,h) ;
  s_limit_pumpgen1(rt,hY,g,y,t,h)            = limit_pumpgen1.m(g,y,t,h) ;
  s_limit_pumpgen2(rt,hY,g,y,t,h)            = limit_pumpgen2.m(g,y,t,h) ;
  s_limit_pumpgen3(rt,hY,g,y,t,lb,h)         = limit_pumpgen3.m(g,y,t,lb,h) ;
  s_boundtxloss(rt,hY,r,rr,ps,y,t,lb,n,h)    = boundtxloss.m(r,rr,ps,y,t,lb,n,h) ;
  s_tx_capacity(rt,hY,r,rr,y,t,lb,h)         = tx_capacity.m(r,rr,y,t,lb,h) ;
  s_tx_projectdef(rt,hY,tupg,r,rr,ps,pss,y)  = tx_projectdef.m(tupg,r,rr,ps,pss,y) ;
  s_tx_onestate(rt,hY,r,rr,y)                = tx_onestate.m(r,rr,y) ;
  s_tx_upgrade(rt,hY,r,rr,ps,y)              = tx_upgrade.m(r,rr,ps,y) ;
  s_tx_oneupgrade(rt,hY,r,rr,y)              = tx_oneupgrade.m(r,rr,y) ;
  s_tx_dcflow(rt,hY,r,rr,y,t,lb,h)           = tx_dcflow.m(r,rr,y,t,lb,h) ;
  s_tx_dcflow0(rt,hY,r,rr,y,t,lb,h)          = tx_dcflow0.m(r,rr,y,t,lb,h) ;
  s_equatetxloss(rt,hY,r,rr,y,t,lb,h)        = equatetxloss.m(r,rr,y,t,lb,h) ;
  s_txGrpConstraint(rt,hY,tgc,y,t,lb,h)      = txGrpConstraint.m(tgc,y,t,lb,h) ;
  s_resvsinglereq1(rt,hY,rc,ild,y,t,lb,h)    = resvsinglereq1.m(rc,ild,y,t,lb,h) ;
  s_genmaxresv1(rt,hY,g,y,t,lb,h)            = genmaxresv1.m(g,y,t,lb,h) ;
  s_resvtrfr1(rt,hY,ild,ild1,y,t,lb,h)       = resvtrfr1.m(ild,ild1,y,t,lb,h) ;
  s_resvtrfr2(rt,hY,rc,ild,ild1,y,t,lb,h)    = resvtrfr2.m(rc,ild,ild1,y,t,lb,h) ;
  s_resvtrfr3(rt,hY,rc,ild,ild1,y,t,lb,h)    = resvtrfr3.m(rc,ild,ild1,y,t,lb,h) ;
  s_resvrequnit(rt,hY,g,rc,ild,y,t,lb,h)     = resvrequnit.m(g,rc,ild,y,t,lb,h) ;
  s_resvreq2(rt,hY,rc,ild,y,t,lb,h)          = resvreq2.m(rc,ild,y,t,lb,h) ;
  s_resvreqhvdc(rt,hY,rc,ild,y,t,lb,h)       = resvreqhvdc.m(rc,ild,y,t,lb,h) ;
  s_resvtrfr4(rt,hY,ild1,ild,y,t,lb,h)       = resvtrfr4.m(ild1,ild,y,t,lb,h) ;
  s_resvtrfrdef(rt,hY,ild,ild1,y,t,lb,h)     = resvtrfrdef.m(ild,ild1,y,t,lb,h) ;
  s_resvoffcap(rt,hY,g,y,t,lb,h)             = resvoffcap.m(g,y,t,lb,h) ;
  s_resvreqwind(rt,hY,rc,ild,y,t,lb,h)       = resvreqwind.m(rc,ild,y,t,lb,h) ;
* Now write the statements that are contingent on the model type being solved.
* NB: these statements will not be executed when included in GEMsolve if RunType = 2.
$if %RunType%==2 $goto skip
* Variables
  s_BGEN(rt,hY,g,y)           = BGEN.l(g,y) ;
  s_GENBLDCONT(rt,hY,g,y)     = GENBLDCONT.l(g,y) ;
  s_CGEN(rt,hY,g,y)           = CGEN.l(g,y) ;
* Equations
  s_bldgenonce(rt,hY,g)       = bldGenOnce.m(g) ;
  s_buildcapint(rt,hY,g,y)    = buildCapInt.m(g,y) ;
  s_buildcapcont(rt,hY,g,y)   = buildCapCont.m(g,y) ;
  s_annnewmwcap(rt,hY,y)      = annNewMWcap.m(y) ;
  s_endogpltretire(rt,hY,g,y) = endogpltretire.m(g,y) ;
  s_endogretonce(rt,hY,g)     = endogretonce.m(g) ;
$label skip
$offecho



*===============================================================================================
* 7. Declare the 's2' parameters.

* NB: The 's2' parameters are intialised at the end of GEMsolve, dumped into a GDX file, and passed along to GEMreports.

Parameters
* Free variables
  s2_TOTALCOST(rt)                              'Discounted total system costs over all modelled years, $m (objective function value)'
  s2_TX(rt,r,rr,y,t,lb,hd)                      'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
* Binary Variables
  s2_BRET(rt,g,y)                               'Binary variable to identify endogenous retirement year for the eligble generation plant'
  s2_ISRETIRED(rt,g)                            'Binary variable to identify if the plant has actually been endogenously retired (0 = not retired, 1 = retired)'
  s2_BTX(rt,r,rr,ps,y)                          'Binary variable indicating the current state of a transmission path'
* Positive Variables
  s2_REFURBCOST(rt,g,y)                         'Annualised generation plant refurbishment expenditure charge, $'
  s2_BUILD(rt,g,y)                              'New capacity installed by generating plant and year, MW'
  s2_RETIRE(rt,g,y)                             'Capacity endogenously retired by generating plant and year, MW'
  s2_CAPACITY(rt,g,y)                           'Cumulative nameplate capacity at each generating plant in each year, MW'
  s2_TXCAPCHARGES(rt,r,rr,y)                    'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  s2_GEN(rt,g,y,t,lb,hd)                        'Generation by generating plant and block, GWh'
  s2_VOLLGEN(rt,s,y,t,lb,hd)                    'Generation by VOLL plant and block, GWh'
  s2_PUMPEDGEN(rt,g,y,t,lb,hd)                  'Energy from pumped hydro (treated like demand), GWh'
  s2_LOSS(rt,r,rr,y,t,lb,hd)                    'Transmission losses along each path, MW'
  s2_TXPROJVAR(rt,tupg,y)                       'Continuous 0-1 variable indicating whether an upgrade project is applied'
  s2_TXUPGRADE(rt,r,rr,ps,pss,y)                'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
  s2_RESV(rt,g,rc,y,t,lb,hd)                    'Reserve energy supplied, MWh'
  s2_RESVVIOL(rt,rc,ild,y,t,lb,hd)              'Reserve energy supply violations, MWh'
  s2_RESVTRFR(rt,rc,ild,ild1,y,t,lb,hd)         'Reserve energy transferred from one island to another, MWh'
* Penalty variables
  s2_RENNRGPENALTY(rt,y)                        'Penalty used to make renewable energy constraint feasible, GWh'
* Slack variables
  s2_ANNMWSLACK(rt,y)                           'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  s2_SEC_NZSLACK(rt,y)                          'Slack with arbitrarily high cost - used to make NZ security constraint feasible, MW'
  s2_SEC_NI1SLACK(rt,y)                         'Slack with arbitrarily high cost - used to make NI1 security constraint feasible, MW'
  s2_SEC_NI2SLACK(rt,y)                         'Slack with arbitrarily high cost - used to make NI2 security constraint feasible, MW'
  s2_NOWIND_NZSLACK(rt,y)                       'Slack with arbitrarily high cost - used to make NZ no wind constraint feasible, MW'
  s2_NOWIND_NISLACK(rt,y)                       'Slack with arbitrarily high cost - used to make NI no wind constraint feasible, MW'
  s2_RENCAPSLACK(rt,y)                          'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  s2_HYDROSLACK(rt,y)                           'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  s2_MINUTILSLACK(rt,y)                         'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  s2_FUELSLACK(rt,y)                            'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'
* Equations, i.e. marginal values. (ignore the objective function)
  s2_bal_supdem(rt,r,y,t,lb,hd)                 'Balance supply and demand in each region, year, time period and load block'
*++++++++++
* More non-free reserves code.
  s2_RESVCOMPONENTS(rt,r,rr,y,t,lb,hd,stp)      'Non-free reserve components, MW'
*++++++++++
  ;





* End of file.
