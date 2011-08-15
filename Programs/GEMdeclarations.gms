* GEMdeclarations.gms

* Last modified by Dr Phil Bishop, 16/08/2011 (imm@ea.govt.nz)

$ontext
  This program declares all of the symbols (sets, scalars, parameters, variables and equations used throughout
  the various GEM codes - up to and including GEMsolve, the program that solves the models. Symbols required only
  for post-solve reporting purposes are declared in GEMreports.
  In a very few cases (a handful of sets), the symbols are intialised here as well. In other words, the membership
  of those sets is assigned at the time of declaration. In all other cases, set membership and data values are obtained
  from user-specified input files, or are computed using the imported data.
  The GEMdeclarations work file is saved and used at invocation to restart GEMdata.

 Code sections:
  1. Declare sets and parameters - the data for which is imported from an input GDX file.
  2. Declare remaining sets and parameters.
     a) Hard-coded sets.
     b) Outcome-specific sets and parameters.
     c) Various GEM configuration sets and parameters. 
     d) Declare all remaining sets and parameters.
  3. Declare model variables and equations.
  4. Specify the equations and declare the models.
  5. Declare the 's' parameters and specify the statements used to collect up results after each solve.
  6. Declare the 's2' parameters for use in GEMreports.
$offtext

* Turn the following maps on/off as desired.
$offuelxref offuellist	
*$onuelxref  onuellist	
$offsymxref offsymlist
*$onsymxref  onsymlist



*===============================================================================================
* 1. Declare sets and parameters - the data for which is imported from an input GDX file.

* 23 fundamental sets
Sets
  k            'Generation technologies'
  f            'Fuels'
  fg           'Fuel groups'
  g            'Generation plant'
  s            'Shortage or VOLL plants'
  o            'Owners of generating plant'
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
  lb           'Load blocks'
  rc           'Reserve classes'
  hY           'Hydrology output years'
  v            'Hydro reservoirs or river systems'
  m            '12 months'
  geo          'Geographic co-ordinate types'
  col          'RGB color codes'
  ;

Alias (i,ii), (r,rr), (ild,ild1), (ps,pss), (hY,hY1), (col,red,green,blue) ;

* 37 mapping sets and subsets (grouped as per the navigation pane of Oasis)
Sets
* 24 technology and fuel
  mapf_k(f,k)                                   'Map technology types to fuel types'
  mapf_fg(f,fg)                                 'Map fuel groups to fuel types'
  techColor(k,red,green,blue)                   'RGB color mix for technologies - to pass to plotting applications'
  fuelColor(f,red,green,blue)                   'RGB color mix for fuels - to pass to plotting applications'
  fuelGrpcolor(fg,red,green,blue)               'RGB color mix for fuel groups - to pass to plotting applications'
  movers(k)                                     'Technologies for which commissioning date can move during re-optimisation of build timing'
  refurbish(k)                                  'Technologies eligible for endogenous "refurbish or retire" decision'
  endogRetire(k)                                'Technologies eligible for endogenous retirement in years prior to and including the refurbish/retire decision'
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
  randomiseCapex(k)                             'Specify the technologies able to have their capital costs randomised within some narrow user-defined range'
  linearBuildTech(k)                            'Specify the technologies able to be partially or linearly built'
  coal(f)                                       'Coal fuel'
  lignite(f)                                    'Lignite fuel'
  gas(f)                                        'Gas fuel'
  diesel(f)                                     'Diesel fuel'
* 3 generation
  mapGenPlant(g,k,i,o)                          'Generation plant mappings'
  exist(g)                                      'Generation plant that are presently operating'
  maps_r(s,r)                                   'Map regions to VOLL plants'
* 6 location
  mapLocations(i,r,e,ild)                       'Location mappings'
  Haywards(i)                                   'Haywards substation'
  Benmore(i)                                    'Benmore substation'
  regionCentroid(i,r)                           'Identify the centroid of each region with a substation'
  zoneCentroid(i,e)                             'Identify the centroid of each zone with a substation'
  islandCentroid(i,ild)                         'Identify the centroid of each island with a substation'
* 2 transmission
  txUpgradeTransitions(tupg,r,rr,ps,pss)        'Define the allowable transitions from one transmission path state to another'
  mapArcNode(p,r,rr)                            'Map nodes (actually, regions) to arcs (paths) in order to build the bus-branch incidence matrix'
* 1 load and time
  mapm_t(m,t)                                   'Map time periods to months'
* 0 reserves and security
* 1 hydrology
  mapReservoirs(v,i,g)                          'Reservoir mappings'
  ;

* Declare 81 parameters (again, grouped as per the navigation pane of Oasis).
Parameters
* 18 technology and fuel
  i_plantLife(k)                                'Generation plant life, years'
  i_refurbishmentLife(k)                        'Generation plant life following refurbishment, years'
  i_retireOffsetYrs(k)                          'Number of years a technology continues to operate for after the decision to endogenously retire has been made'
  i_linearBuildMW(k)                            'Threshold MW level used to activate linearisation of binary decision variables for plants able to be linearly built'
  i_linearBuildYr(k)                            'Threshold early build year used to activate linearisation of binary decision variables for plants able to be linearly built'
  i_depRate(k)                                  'Depreciation rate for generation plant, technology specific'
  i_peakContribution(k)                         'Contribution to peak by technology'
  i_NWpeakContribution(k)                       'The no wind contribution to peak by technology'
  i_capFacTech(k)                               'An assumed (rather than modelled) technology-specific capacity factor - used when computing LRMCs based on input data (i.e. prior to solving the model)'
  i_FOFmultiplier(k,lb)                         'Forced outage factor multiplier (default = 1)'
  i_maxNrgByFuel(f)                             'Maximum proportion of total energy from any one fuel type (0-1)'
  i_emissionFactors(f)                          'CO2e emissions, tonnes CO2/PJ'
  i_minUtilByTech(y,k)                          'Minimum utilisation of plant by technology type, proportion (0-1 but define only when > 0)'
  i_CCSfactor(y,k)                              'Carbon capture and storage factor, i.e. share of emissions sequestered'
  i_CCScost(y,k)                                'Carbon capture and storage cost, $/t CO2e sequestered'
  i_fuelPrices(f,y)                             'Fuel prices by fuel type and year, $/GJ'
  i_fuelQuantities(f,y)                         'Quantitative limit on availability of various fuels by year, PJ'
  i_co2tax(y)                                   'CO2 tax by year, $/tonne CO2-equivalent'
* 31 generation
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
  i_capitalCost(g)                              'Generation plant capital cost, $/kW'
  i_connectionCost(g)                           'Capital cost for connecting generation plant to grid, $m (NZD)'
  i_refurbCapitalCost(g)                        'Generation plant refurbishment capital cost, $/kW'
  i_plantReservesCap(g,rc)                      'Plant-specific capability per reserve class (0-1 but define only when > 0)'
  i_plantReservesCost(g,rc)                     'Plant-specific cost per reserve class, $/MWh'
  i_PltCapFact(g,m)                             'Plant-specific capacity factor (default = 1)'
  i_VOLLcap(s)                                  'Nameplate capacity of VOLL plant (1 VOLL plant/region), MW'
  i_VOLLcost(s)                                 'Value of lost load by VOLL plant (1 VOLL plant/region), $/MWh'
  i_HVDCshr(o)                                  'Share of HVDC charge to be incurred by plant owner'
  i_renewNrgShare(y)                            'Proportion of total energy to be generated from renewable sources by year (0-1 but define only when > 0)'
  i_renewCapShare(y)                            'Proportion of installed capacity that must be renewable by year (0-1 but define only when > 0)'
  i_distdGenRenew(y)                            'Distributed generation (renewable) installed by year, GWh'
  i_distdGenFossil(y)                           'Distributed generation (fossil) installed by year, GWh'
* 2 location
  i_substnCoordinates(i,geo)                    'Geographic coordinates for substations'
  i_zonalLocFacs(e)                             'Zonal location factors - adjusters of SRMC'
* 11 transmission
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
* 5 load and time
  i_firstDataYear                               'First data year - as a scalar, not a set'
  i_lastDataYear                                'Last data year - as a scalar, not a set'
  i_HalfHrsPerBlk(m,lb)                         'Count of half hours per load block in each month'
  i_NrgDemand(r,y,t,lb)                         'Load by region, year, time period and load block, GWh'
  i_inflation(y)                                'Inflation rates by year'
* 11 reserves and security
  i_ReserveSwitch(rc)                           'Switch to activate reserves by reserves class'
  i_ReserveAreas(rc)                            'Number of reserves areas (Single or system-wide = 1, By island = 2)'
  i_propWindCover(rc)                           'Proportion of wind to cover by reserve class (0-1 but define only when > 0)'
  i_ReservePenalty(ild,rc)                      'Reserve violation penalty, $/MWh'
  i_reserveReqMW(y,ild,rc)                      'Reserve requirement by year, island, and class, MW'
  i_fkNI(y)                                     'Required frequency keeping in North Island by year, MW'
  i_largestGenerator(y)                         'Largest generation plant by year, MW'
  i_smallestPole(y)                             'Delivered capacity in North Island of smallest pole on HVDC link by year, MW'
  i_winterCapacityMargin(y)                     'Required winter capacity margin, MW' 
  i_P200ratioNZ(y)                              'Desired ratio of peak demand MW to average demand MW (derived from forecast GWh energy demand), New Zealand'   
  i_P200ratioNI(y)                              'Desired ratio of peak demand MW to average demand MW (derived from forecast GWh energy demand), North Island'   
* 3 hydrology
  i_firstHydroYear                              'First year of hydrology output data'
  i_historicalHydroOutput(v,hY,m)               'Historical hydro output sequences by reservoir and month, GWh'
  i_hydroOutputAdj(y)                           'Schedulable hydro output adjuster by year (default = 1)'
  ;



*===============================================================================================
* 2. Declare remaining sets and parameters.
*    a) Hard-coded sets.
*    b) Outcome-specific sets and parameters.
*    c) Various GEM configuration sets and parameters. 
*    d) Declare all remaining sets and parameters.

* a) Hard-coded sets (non-development users have no need to change these set elements).
Sets
  n                                             'Piecewise linear vertices'
  ct                                            'Capital expenditure types'           / genplt     'New generation plant'
                                                                                        refplt     'Refurbish existing generation plant' /
  d                                             'Discount rate classes'               / WACCg      "Generation investor's post-tax real weighted average cost of capital"
                                                                                        WACCt      "Transmission investor's post-tax real weighted average cost of capital"
                                                                                        dLow       'Lower discount rate for CBA sensitivity analysis' 
                                                                                        dMed       'Central discount rate for CBA sensitivity analysis'
                                                                                        dHigh      'Upper discount rate for CBA sensitivity analysis'    /
  dt                                            'Types of discounting'                / mid        'Middle of the period within each year'
                                                                                        eoy        'End of year'   /
  goal                                          'Goals for MIP solution procedure'    / QDsol      'Find a quick and dirty solution using a user-specified optcr'
                                                                                        VGsol      'Find a very good solution reasonably quickly'
                                                                                        MinGap     'Minimize the gap between best possible and best found'  /
  steps                                         'Steps in an experiment'              / timing     'Solve the timing problem, i.e. timing of new generation/or transmission investment'
                                                                                        reopt      'Solve the re-optimised timing problem (generally with a drier hydro sequence) while allowing peakers to move'
                                                                                        dispatch   'Solve for the dispatch only with investment timing fixed'  /
  hydroSeqTypes                                 'Types of hydro sequences to use'     / Same       'Use the same sequence of hydro years to be used in every modelled year'
                                                                                        Sequential 'Use a sequentially developed mapping of hydro years to modelled years' /
  aggR                                          'Aggregate regional entities'         / nz         'New Zealand'
                                                                                        ni         'North Island'
                                                                                        si         'South Island' / ;

* b) Outcome-specific sets and parameters - see (mostly) GEMstochastic.
Sets
  experiments                                   'A collection of experiments, each potentially containing timing, re-optimisation and dispatch steps'
  outcomes                                      'The various individual stochastic outcomes, or futures, or states of uncertainty'
  oc(outcomes)                                  '(Dynamically) selected elements of outcomes'
  outcomeSets                                   'Create sets of outcomes to be used in a solve'
  mapOutcomes(outcomeSets,outcomes)             'Map the individual outcomes to an outcome set (i.e. 1 or more outcomes make up an outcome set)'
  timingSolves(experiments,outcomeSets)         'Which outcome sets are used for the timing step of each experiment?'
  reoptSolves(experiments,outcomeSets)          'Which outcome sets are used for the reoptimisation step of each experiment?'
  dispatchSolves(experiments,outcomeSets)       'Which outcome sets are used for the dispatch step of each experiment?'
  allSolves(experiments,steps,outcomeSets)      'Outcome sets by experiment and step'
  mapOC_hY(outcomes,hY)                         'Map historical hydro output years to outcomes (compute the average if more than one hydro year is specified)'
  mapOC_hydroSeqTypes(outcomes,hydroSeqTypes)   'Map the way types of hydrology sequences are developed (same or sequential) to outcomes'
  mapHydroYearsToModelledYears(experiments,steps,outcomeSets,outcomes,y,hY) 'Collect the mapping of hydro years to modelled modelled years for all experiments-steps-outcomeSets tuples'
  sumSolves(outcomeSets)                        'Figure out which solves to sum over when computing post-solve results averaged over outcomeSets' ;

Parameters
  outcomePeakLoadFactor(outcomes)               'Outcome-specific scaling factor for peak load data'
  outcomeCO2TaxFactor(outcomes)                 'Outcome-specific scaling factor for CO2 tax data'
  outcomeFuelCostFactor(outcomes)               'Outcome-specific scaling factor for fuel cost data'
  outcomeNRGFactor(outcomes)                    'Outcome-specific scaling factor for energy demand data'
  penaltyLostPeak                               'Penalty for failing to meet peak load constraints'
  weightOutcomesBySet(outcomeSets,outcomes)     'Assign weights to the outcomes comprising each set of outcomes'
  outcomeWeight(outcomes)                       'Individual outcome weights'
  modelledHydroOutput(g,y,t,outcomes)           'Hydro output used in each modelled year by scheduleable hydro plant'
  allModelledHydroOutput(experiments,steps,outcomeSets,g,y,t,outcomes) 'Collect the hydro output used in each modelled year by scheduleable hydro plant for all experiments-steps-outcomeSets tuples'
  solveReport(experiments,steps,outcomeSets,*)  'Collect various details about each solve of the models (both GEM and DISP)'
  numSolves                                     'Figure out the number of solves to sum over when computing post-solve results averaged over outcomeSets' ;

* c) Various GEM configuration sets and parameters - see (mostly) GEMsettings.
Sets
  solveGoal(goal)                               'The user-selected solve goal'  ;

Parameters
  firstYear                                     'First modelled year - as a scalar, not a set'
  lastYear                                      'Last modelled year - as a scalar, not a set'
  noRetire                                      'Number of years following and including the first modelled year for which endogenous generation plant retirement decisions are prohibited'
  AnnualMWlimit                                 'Upper bound on total MW of new plant able to be built nationwide in any single year'
  penaltyViolateRenNrg                          'Penalty used to make renewable energy constraint feasible, $m/GWh'
  renNrgShrOn                                   'Switch to control usage of renewable energy share constraint 0=off/1=on'
  DCloadFlow                                    'Flag (0/1) to indicate use of either DC load flow (1) or transportation formulation (0)'
  useReserves                                   'Global flag (0/1) to indicate use of at least one reserve class (0 = no reserves are modelled)'
  cGenYr                                        'First year in which integer generation build decisions can become continuous, i.e. CGEN or BGEN = 0 in any year'
  noVOLLblks                                    'Number of contiguous load blocks at top of LDC for which the VOLL generators are unavailable'
  randomCapexCostAdjuster                       'Specify the bounds for a small +/- random adjustment to generation plant capital costs'
  slacks                                        'A flag indicating slack variables exist in at least one solution'
  penalties                                     'A flag indicating penalty variables exist in at least one solution'  ;

* d) Declare all remaining sets and parameters - to be initialised/computed in GEMdata or GEMsolve.
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
  mapAggR_r(aggR,r)                             'Map the regions to aggregated regional entities (this is primarily to facilitate reporting)'
  mapv_g(v,g)                                   'Map generating plant to reservoirs'
  thermalFuel(f)                                'Thermal fuels'
* Financial parameters.
* Fuel prices and quantity limits.
* Generation data.
  noExist(g)                                    'Generation plant that are not presently operating'
  commit(g)                                     'Generation plant that are assumed to be committed'
  new(g)                                        'Potential generation plant that are neither existing nor committed'
  neverBuild(g)                                 'Generation plant that are determined a priori by user never to be built'
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
  validTGC(tgc)                                 'Valid transmission group constraints'
  nSegment(n)                                   'Line segments for piecewise linear transmission losses function (number of segments = number of vertices - l)'
* Reserve energy data.
* Hydrology.
  chooseHydroYears(hY)                          'Used for calculation of hydro sequences'  ;

Parameters
  counter                                       'A recyclable counter - set equal to zero each time before using'
* Time/date-related sets and parameters.
  yearNum(y)                                    'Real number associated with each year'
  hydroYearNum(hY)                              'Real number associated with each hydrology output year'
  lastHydroYear                                 'Last year of hydrology output data - as an integer'
  hoursPerBlock(t,lb)                           'Hours per load block by time period'
* Various mappings, subsets and counts.
  numReg                                        'Number of regions (or, if you like, nodes or buses)'
* Financial parameters.
  WACCg                                         "Generation investor's post-tax real weighted average cost of capital"
  WACCt                                         "Transmission investor's post-tax real weighted average cost of capital"
  depType                                       'Flag to indicate depreciation method - 1 for declining value, 0 for straight line'
  taxRate                                       'Corporate tax rate'
  txPlantLife                                   'Life of transmission equipment, years'
  txDepRate                                     'Depreciation rate for transmission equipment'
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
  SRMC(g,y,outcomes)                            'Short run marginal cost of each generation project by year and outcome, $/MWh'
  totalFuelCost(g,y,outcomes)                   'Total fuel cost - price plus fuel delivery charge all times heatrate - by plant, year and outcome, $/MWh'
  CO2taxByPlant(g,y,outcomes)                   'CO2 tax by plant, year and outcome, $/MWh'
  CO2CaptureStorageCost(g,y)                    'Carbon capture and storage cost by plant and year, $/MWh'
* Generation data.
  initialCapacity(g)                            'Capacity of existing generating plant in the first modelled year'
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
  NrgDemand(r,y,t,lb,outcomes)                  'Load (or energy demand) by region, year, time period and load block, GWh (used to create ldcMW)'
  ldcMW(r,y,t,lb,outcomes)                      'MW at each block by region, year and period'
  peakLoadNZ(y,outcomes)                        'Peak load for New Zealand by year, MW'
  peakLoadNI(y,outcomes)                        'Peak load for North Island by year, MW'
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
  historicalHydroOutput(v,hY,m)                 'Historical hydro output sequences by reservoir and month, GWh'
  hydroOutputScalar                             'Scale the hydro output sequence used to determine the timing of new builds'
  ;



*===============================================================================================
* 3. Declare model variables and equations.

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
  RESVCOMPONENTS(r,rr,y,t,lb,outcomes,stp)      'Non-free reserve components, MW'
  ;
Equations
  calc_nfreserves(r,rr,y,t,lb,outcomes)         'Calculate non-free reserve components' 
  resv_capacity(r,rr,y,t,lb,outcomes,stp)       'Calculate and impose the relevant capacity on each step of free reserves'
  ;
*+++++++++++++++++++++++++

Free Variables
  TOTALCOST                                     'Discounted total system costs over all modelled years, $m (objective function value)'
  OUTCOME_COSTS(outcomes)                       'Discounted costs that might vary by outcome, $m (a component of objective function value)'
  TX(r,rr,y,t,lb,outcomes)                      'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
  THETA(r,y,t,lb,outcomes)                      'Bus voltage angle'

Binary Variables
  BGEN(g,y)                                     'Binary variable to identify build year for new generation plant'
  BRET(g,y)                                     'Binary variable to identify endogenous retirement year for the eligble generation plant'
  ISRETIRED(g)                                  'Binary variable to identify if the plant has actually been endogenously retired (0 = not retired, 1 = retired)'
  BTX(r,rr,ps,y)                                'Binary variable indicating the current state of a transmission path'
  NORESVTRFR(ild,ild1,y,t,lb,outcomes)          'Is there available capacity on the HVDC link to transfer energy reserves (0 = Yes, 1 = No)'

Positive Variables
  REFURBCOST(g,y)                               'Annualised generation plant refurbishment expenditure charge, $'
  GENBLDCONT(g,y)                               'Continuous variable to identify build year for new scalable generation plant - for plant in linearPlantBuild set'
  CGEN(g,y)                                     'Continuous variable to identify build year for new scalable generation plant - for plant in integerPlantBuild set (CGEN or BGEN = 0 in any year)'
  BUILD(g,y)                                    'New capacity installed by generating plant and year, MW'
  RETIRE(g,y)                                   'Capacity endogenously retired by generating plant and year, MW'
  CAPACITY(g,y)                                 'Cumulative nameplate capacity at each generating plant in each year, MW'
  TXCAPCHARGES(r,rr,y)                          'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  GEN(g,y,t,lb,outcomes)                        'Generation by generating plant and block, GWh'
  VOLLGEN(s,y,t,lb,outcomes)                    'Generation by VOLL plant and block, GWh'
  PUMPEDGEN(g,y,t,lb,outcomes)                  'Energy from pumped hydro (treated like demand), GWh'
  LOSS(r,rr,y,t,lb,outcomes)                    'Transmission losses along each path, MW'
  TXPROJVAR(tupg,y)                             'Continuous 0-1 variable indicating whether an upgrade project is applied'
  TXUPGRADE(r,rr,ps,pss,y)                      'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
* Reserve variables
  RESV(g,rc,y,t,lb,outcomes)                    'Reserve energy supplied, MWh'
  RESVVIOL(rc,ild,y,t,lb,outcomes)              'Reserve energy supply violations, MWh'
  RESVTRFR(rc,ild,ild1,y,t,lb,outcomes)         'Reserve energy transferred from one island to another, MWh'
  RESVREQINT(rc,ild,y,t,lb,outcomes)            'Internally determined energy reserve requirement, MWh'
* Penalty variables
  RENNRGPENALTY(y)                              'Penalty with cost of penaltyViolateRenNrg - used to make renewable energy constraint feasible, GWh'
  PEAK_NZ_PENALTY(y,outcomes)                   'Penalty with cost of penaltyLostPeak - used to make NZ security constraint feasible, MW'
  PEAK_NI_PENALTY(y,outcomes)                   'Penalty with cost of penaltyLostPeak - used to make NI security constraint feasible, MW'
  NOWINDPEAK_NI_PENALTY(y,outcomes)             'Penalty with cost of penaltyLostPeak - used to make NI no wind constraint feasible, MW'
* Slack variables
  ANNMWSLACK(y)                                 'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  RENCAPSLACK(y)                                'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  HYDROSLACK(y)                                 'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  MINUTILSLACK(y)                               'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  FUELSLACK(y)                                  'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'

Equations
  objectivefn                                   'Calculate discounted total system costs over all modelled years, $m'
  calc_outcomeCosts(outcomes)                   'Calculate discounted costs that might vary by outcome'
  calc_refurbcost(g,y)                          'Calculate the annualised generation plant refurbishment expenditure charge in each year, $'
  calc_txcapcharges(r,rr,y)                     'Calculate cumulative annualised transmission capital charges in each modelled year, $m'
  bldgenonce(g)                                 'If new generating plant is to be built, ensure it is built only once'
  buildcapint(g,y)                              'If new integer plant is built, ensure built capacity is equal to nameplate capacity'
  buildcapcont(g,y)                             'If new scalable plant is built, ensure built capacity does not exceed nameplate capacity'
  annnewmwcap(y)                                'Restrict aggregate new capacity built in a single year to be less than a specified MW'
  endogpltretire(g,y)                           'Calculate the MW to endogenously retire'
  endogretonce(g)                               'Can only endogenously retire a plant once'
  balance_capacity(g,y)                         'Year to year capacity balance relationship for all plant, MW'
  bal_supdem(r,y,t,lb,outcomes)                 'Balance supply and demand in each region, year, time period and load block'
  peak_nz(y,outcomes)                           'Ensure enough capacity to meet peak demand and the winter capacity margin in NZ'
  peak_ni(y,outcomes)                           'Ensure enough capacity to meet peak demand in NI subject to contingencies'
  noWindPeak_ni(y,outcomes)                     'Ensure enough capacity to meet peak demand in NI  subject to contingencies when wind is low'
  limit_maxgen(g,y,t,lb,outcomes)               'Ensure generation in each block does not exceed capacity implied by max capacity factors'
  limit_mingen(g,y,t,lb,outcomes)               'Ensure generation in each block exceeds capacity implied by min capacity factors'
  minutil(g,k,y,outcomes)                       'Ensure generation by certain technology type meets a minimum utilisation'
  limit_fueluse(f,y,outcomes)                   'Quantum of each fuel used and possibly constrained, PJ'
  limit_nrg(f,y,outcomes)                       'Impose a limit on total energy generated by any one fuel type'
  minreq_rennrg(y,outcomes)                     'Impose a minimum requirement on total energy generated from all renewable sources'
  minreq_rencap(y)                              'Impose a minimum requirement on installed renewable capacity'
  limit_hydro(g,y,t,outcomes)                   'Limit hydro generation to according to inflows'
  limit_pumpgen1(g,y,t,outcomes)                'Limit output from pumped hydro in a period to the quantity pumped'
  limit_pumpgen2(g,y,t,outcomes)                'Limit output from pumped hydro in a period to the assumed storage'
  limit_pumpgen3(g,y,t,lb,outcomes)             "Pumped MW can be no more than the scheme's installed MW"
  boundtxloss(r,rr,ps,y,t,lb,n,outcomes)        'Sort out which segment of the loss function to operate on'
  tx_capacity(r,rr,y,t,lb,outcomes)             'Calculate the relevant transmission capacity'
  tx_projectdef(tupg,r,rr,ps,pss,y)             'Associate projects to individual upgrades'
  tx_onestate(r,rr,y)                           'A link must be in exactly one state in any given year'
  tx_upgrade(r,rr,ps,y)                         'Make sure the upgrade of a link corresponds to a legitimate state-to-state transition'
  tx_oneupgrade(r,rr,y)                         'Only one upgrade per path in a single year'
  tx_dcflow(r,rr,y,t,lb,outcomes)               'DC load flow equation'
  tx_dcflow0(r,rr,y,t,lb,outcomes)              'DC load flow equation'
  equatetxloss(r,rr,y,t,lb,outcomes)            'Ensure that losses in both directions are equal'
  txGrpConstraint(tgc,y,t,lb,outcomes)          'Group transmission constraints'
  resvsinglereq1(rc,ild,y,t,lb,outcomes)        'Single reserve energy requirement constraint 1'
  genmaxresv1(g,y,t,lb,outcomes)                'Limit the amount of energy reserves per generator'
  resvtrfr1(ild,ild1,y,t,lb,outcomes)           'Limit on the amount of reserve energy transfer - constraint 1'
  resvtrfr2(rc,ild,ild1,y,t,lb,outcomes)        'Limit on the amount of reserve energy transfer - constraint 2'
  resvtrfr3(rc,ild,ild1,y,t,lb,outcomes)        'Limit on the amount of reserve energy transfer - constraint 3'
  resvrequnit(g,rc,ild,y,t,lb,outcomes)         'Reserve energy requirement based on the largest dispatched unit'
  resvreq2(rc,ild,y,t,lb,outcomes)              'Island reserve energy requirement - constraint 2'
  resvreqhvdc(rc,ild,y,t,lb,outcomes)           'Reserve energy requirement based on the HVDC transfer taking into account self-cover'
  resvtrfr4(ild1,ild,y,t,lb,outcomes)           'Limit on the amount of reserve energy transfer - constraint 4'
  resvtrfrdef(ild,ild1,y,t,lb,outcomes)         'Constraint that defines if reserve energy transfer is available'
  resvoffcap(g,y,t,lb,outcomes)                 'Offline energy reserve capability'
  resvreqwind(rc,ild,y,t,lb,outcomes)           'Reserve energy requirement based on a specified proportion of dispatched wind generation'
  ;



*===============================================================================================
* 4. Specify the equations and declare the models.

* NB: Uppercase = variables; lowercase = parameters.

* Objective function - discounted total cost, $m.
objectivefn..
  TOTALCOST =e=
* Add in slacks at arbitrarily high cost.
  9999 * sum(y, ANNMWSLACK(y) ) +
  9998 * sum(y$i_renewCapShare(y), RENCAPSLACK(y) ) +
  9997 * sum(y, HYDROSLACK(y) ) +
  9996 * sum(y, MINUTILSLACK(y) ) +
  9995 * sum(y, FUELSLACK(y) ) +
* Add in penalties at user-defined high, but not necessarily arbitrarily high, cost.
  penaltyViolateRenNrg * sum(y$renNrgShrOn, RENNRGPENALTY(y) ) +
* Fixed, variable and HVDC costs - discounted and adjusted for tax
* NB: Fixed costs are scaled by 1/card(t) to convert annual costs to a periodic basis coz discounting is done by period.
* NB: The HVDC charge applies only to committed and new SI projects.
  1e-6 * sum((y,t), PVfacG(y,t) * (1 - taxRate) * (
           ( 1/card(t) ) * 1e3 * (
           sum(g, i_fixedOM(g) * CAPACITY(g,y)) +
           sum((g,k,o)$((not demandGen(k)) * sigen(g) * possibleToBuild(g) * mapg_k(g,k) * mapg_o(g,o)), i_HVDCshr(o) * i_HVDClevy(y) * CAPACITY(g,y))
           )
         ) ) +
* Generation capital expenditure - discounted
  1e-6 * sum((y,firstPeriod(t),possibleToBuild(g)), PVfacG(y,t) * capCharge(g,y) * CAPACITY(g,y) ) +
* Generation refurbishment expenditure - discounted
  1e-6 * sum((y,firstPeriod(t),PossibleToRefurbish(g))$refurbCapCharge(g,y), PVfacG(y,t) * REFURBCOST(g,y) ) +
* Transmission capital expenditure - discounted
  sum((paths,y,firstPeriod(t)),   PVfacT(y,t) * TXCAPCHARGES(paths,y) ) +
* Costs by outcome - computed in following equation
  sum(oc, outcomeWeight(oc) * OUTCOME_COSTS(oc)) ;

calc_outcomeCosts(oc)..
  OUTCOME_COSTS(oc) =e=
* Reserve violation costs, $m
  1e-6 * sum((rc,ild,y,t,lb), RESVVIOL(rc,ild,y,t,lb,oc) * reserveViolationPenalty(ild,rc) ) +
* Lost peak load penalties - why aren't they discounted and adjusted for tax?
  penaltyLostPeak * sum(y, PEAK_NZ_PENALTY(y,oc) + PEAK_NI_PENALTY(y,oc) + NOWINDPEAK_NI_PENALTY(y,oc) ) +
* Various costs, discounted and adjusted for tax
  1e-6 * (1 - taxRate) * sum((y,t,lb), PVfacG(y,t) * (
* Lost load
    sum(s, 1e3 * VOLLGEN(s,y,t,lb,oc) * i_VOLLcost(s) ) +
* Generation costs
    sum(g$validYrOperate(g,y,t), 1e3 * GEN(g,y,t,lb,oc) * srmc(g,y,oc) * sum(mapg_e(g,e), locFac_Recip(e)) ) +
* Cost of providing reserves ($m)
    sum((g,rc), RESV(g,rc,y,t,lb,oc) * i_plantReservesCost(g,rc) ) +
*++++++++++++++++++
* More non-free reserves code.
* Cost of providing reserves ($m)
    sum((paths,stp)$( nwd(paths) or swd(paths) ), hoursPerBlock(t,lb) * RESVCOMPONENTS(paths,y,t,lb,oc,stp) * pNFresvcost(paths,stp) )
  ) )  ;

* Calculate non-free reserve components. 
calc_nfreserves(paths(r,rr),y,t,lb,oc)$( nwd(r,rr) or swd(r,rr) )..
  sum(stp, RESVCOMPONENTS(r,rr,y,t,lb,oc,stp)) =g= TX(r,rr,y,t,lb,oc) - sum(allowedStates(r,rr,ps), BTX(r,rr,ps,y) * freereserves(r,rr,ps)) ;

* Calculate and impose the relevant capacity on each step of free reserves.
resv_capacity(paths,y,t,lb,oc,stp)$( nwd(paths) or swd(paths) )..
  RESVCOMPONENTS(paths,y,t,lb,oc,stp) =l= pNFresvcap(paths,stp) ;
*++++++++++++++++++

* Compute the annualised generation plant refurbishment expenditure charge in each year.
calc_refurbcost(PossibleToRefurbish(g),y)$refurbCapCharge(g,y)..
  REFURBCOST(g,y) =e= (1 - ISRETIRED(g)) * i_nameplate(g) * refurbCapCharge(g,y) ;

* Compute the cumulative annualised transmission upgrade capital expenditure charges.
calc_txcapcharges(paths,y)..
  TXCAPCHARGES(paths,y) =e= TXCAPCHARGES(paths,y-1) + sum(validTransitions(paths,pss,ps), txCapCharge(paths,ps,y) * TXUPGRADE(paths,pss,ps,y) ) ;

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
bal_supdem(r,y,t,lb,oc)..
  sum(maps_r(s,r), VOLLGEN(s,y,t,lb,oc)) +
  sum(mapg_r(g,r)$validYrOperate(g,y,t), GEN(g,y,t,lb,oc)) +
* Transmission and losses with transportation formulation
 (sum(rr$paths(rr,r), ( ( TX(rr,r,y,t,lb,oc) - LOSS(rr,r,y,t,lb,oc) ) * hoursPerBlock(t,lb) * 0.001 ) ) -
  sum(rr$paths(r,rr),   ( TX(r,rr,y,t,lb,oc) * hoursPerBlock(t,lb) * 0.001 ) ) )$( DCloadFlow = 0 ) +
* Transmission and losses with DC load flow formulation
 (sum(rr$paths(rr,r), ( ( TX(rr,r,y,t,lb,oc) - 0.5 * LOSS(rr,r,y,t,lb,oc) ) * hoursPerBlock(t,lb) * 0.001 ) ) )$( DCloadFlow = 1 )
  =g=
  ldcMW(r,y,t,lb,oc) * hoursPerBlock(t,lb) * 0.001 +
  sum(g$( mapg_r(g,r) * pumpedHydroPlant(g) * validYrOperate(g,y,t) ), PUMPEDGEN(g,y,t,lb,oc)) ;

* Ensure enough capacity to meet peak demand and the winter capacity margin in NZ.
peak_NZ(y,oc)..
  PEAK_NZ_PENALTY(y,oc) +
  sum(g, CAPACITY(g,y) * peakConPlant(g,y) ) - i_winterCapacityMargin(y)
  =g= peakLoadNZ(y,oc) ;

* Ensure enough capacity to meet peak demand in NI subject to contingencies.
peak_NI(y,oc)..
  PEAK_NI_PENALTY(y,oc) +
  sum(nigen(g), CAPACITY(g,y) * peakConPlant(g,y) ) + i_largestGenerator(y) + i_smallestPole(y) - i_winterCapacityMargin(y)
  =g= peakLoadNI(y,oc) ;

* Ensure enough capacity to meet peak demand in NI  subject to contingencies when wind is low.
noWindPeak_NI(y,oc)..
  NOWINDPEAK_NI_PENALTY(y,oc) +
  sum(mapg_k(g,k)$( nigen(g) and (not wind(k)) ), CAPACITY(g,y) * NWpeakConPlant(g,y) ) - i_fkNI(y) + i_smallestPole(y)
  =g= peakLoadNI(y,oc) ;

* Ensure generation is less than capacity times max capacity factor in each block.
limit_maxgen(validYrOperate(g,y,t),lb,oc)$( ( exist(g) or possibleToBuild(g) ) * ( not useReserves ) )..
  GEN(g,y,t,lb,oc) =l= 1e-3 * CAPACITY(g,y) * maxCapFactPlant(g,t,lb) * hoursPerBlock(t,lb) ;

* Ensure generation is greater than capacity times min capacity factor in each block.
limit_mingen(validYrOperate(g,y,t),lb,oc)$minCapFactPlant(g,y,t)..
  GEN(g,y,t,lb,oc) =g= 1e-3 * CAPACITY(g,y) * minCapFactPlant(g,y,t) * hoursPerBlock(t,lb) ;

* Minimum ultilisation of plant by technology.
minutil(g,k,y,oc)$( i_minUtilisation(g) * i_minUtilByTech(y,k) * mapg_k(g,k) )..
  sum((t,lb)$validYrOperate(g,y,t), GEN(g,y,t,lb,oc)) + MINUTILSLACK(y) =g= i_minUtilByTech(y,k) * 8.76 * CAPACITY(g,y) * (1 - i_fof(g)) ;

* Thermal fuel limits.
limit_fueluse(thermalfuel(f),y,oc)$( ( gas(f) * (i_fuelQuantities(f,y) > 0) * (i_fuelQuantities(f,y) < 999) ) or ( diesel(f) * (i_fuelQuantities(f,y) > 0) ) )..
  1e-6 * sum((g,t,lb)$( mapg_f(g,f) * validYrOperate(g,y,t) ), i_heatrate(g) * GEN(g,y,t,lb,oc) ) =l= i_fuelQuantities(f,y) + FUELSLACK(y) ;

* Impose a limit on total energy generated from any one fuel type.
limit_Nrg(f,y,oc)$i_maxNrgByFuel(f)..
  sum((g,t,lb)$( mapg_f(g,f) * validYrOperate(g,y,t) ), GEN(g,y,t,lb,oc)) =l= i_maxNrgByFuel(f) * sum((g,t,lb)$validYrOperate(g,y,t), GEN(g,y,t,lb,oc)) ;

* Impose a minimum requirement on total energy generated from all renewable sources.
minReq_RenNrg(y,oc)$renNrgShrOn..
  i_renewNrgShare(y) * ( sum((g,t,lb)$validYrOperate(g,y,t), GEN(g,y,t,lb,oc)) + i_distdGenRenew(y) + i_distdGenFossil(y) ) =l=
  sum((g,k,t,lb)$( mapg_k(g,k) * renew(k) * validYrOperate(g,y,t)), GEN(g,y,t,lb,oc)) + i_distdGenRenew(y) +
  RENNRGPENALTY(y) ;

* Impose a minimum requirement on installed renewable capacity.
minReq_RenCap(y)$i_renewCapShare(y)..
  i_renewCapShare(y) * sum(possibleToBuild(g), 8.76 * CAPACITY(g,y) * (1 - i_fof(g)) ) =l=
  sum((g,k)$( possibleToBuild(g) * mapg_k(g,k) * renew(k) ), 8.76 * CAPACITY(g,y) * (1 - i_fof(g)) ) +
  RENCAPSLACK(y) ;

* Limit hydro according to energy available in inflows.
limit_hydro(validYrOperate(g,y,t),oc)$schedHydroPlant(g)..
  sum(lb, GEN(g,y,t,lb,oc)) =l= modelledHydroOutput(g,y,t,oc) + HYDROSLACK(y) ;

* Over the period, ensure that generation from pumped hydro is less than the energy pumped.
limit_pumpgen1(validYrOperate(g,y,t),oc)$pumpedHydroPlant(g)..
  sum(lb, GEN(g,y,t,lb,oc)) =l= i_PumpedHydroEffic(g) * sum(lb, PUMPEDGEN(g,y,t,lb,oc) ) ;

* Over the period, ensure that the energy pumped is less than the storage capacity.
limit_pumpgen2(validYrOperate(g,y,t),oc)$pumpedHydroPlant(g)..
  i_PumpedHydroEffic(g) * sum(lb, PUMPEDGEN(g,y,t,lb,oc) ) =l= sum(mapm_t(m,t), 1) * i_PumpedHydroMonth(g) ;

* The MW pumped can be no greater than the capacity of the project.
limit_pumpgen3(validYrOperate(g,y,t),lb,oc)$pumpedHydroPlant(g)..
  PUMPEDGEN(g,y,t,lb,oc) =l= 0.001 * CAPACITY(g,y) * maxCapFactPlant(g,t,lb) * hoursPerBlock(t,lb) ;

* Piecewise linear transmission losses.
boundTxloss(paths(r,rr),ps,y,t,lb,nsegment(n),oc)$( allowedStates(paths,ps) * bigloss(paths,ps) )..
  LOSS(paths,y,t,lb,oc) =g=
  intercept(paths,ps,n) + slope(paths,ps,n) * TX(paths,y,t,lb,oc) - bigloss(paths,ps) * ( 1 - BTX(paths,ps,y) ) ;

* Calculate the relevant transmission capacity and impose it.
tx_capacity(paths,y,t,lb,oc)..
  TX(paths,y,t,lb,oc) =l= sum(allowedStates(paths,ps), i_txCapacity(paths,ps) * BTX(paths,ps,y)) ;

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
tx_dcflow(r,rr,y,t,lb,oc)$( DCloadFlow * susceptanceYr(r,rr,y) * regLower(r,rr) )..
  TX(r,rr,y,t,lb,oc) =e= susceptanceYr(r,rr,y) * ( THETA(r,y,t,lb,oc) - THETA(rr,y,t,lb,oc) ) ;

* Ensure that for flow on links without reactance the flow from r to rr = - flow from rr to r
tx_dcflow0(r,rr,y,t,lb,oc)$( DCloadFlow * paths(r,rr) * regLower(r,rr) )..
  TX(r,rr,y,t,lb,oc) + TX(rr,r,y,t,lb,oc) =e= 0 ;

* Ensure equality of losses in both directions for the DC load flow representation
* NB: No need for this constraint if the maximum losses on a link = 0 since then the loss variable is fixed in GEMsolve
equatetxloss(r,rr,y,t,lb,oc)$( DCloadFlow * paths(r,rr) * regLower(r,rr) * sum(ps, bigloss(r,rr,ps)) )..
  LOSS(r,rr,y,t,lb,oc) =e= LOSS(rr,r,y,t,lb,oc) ;

* Transmission group constraints, i.e. in addition to individual branch limits. Use to cater for contingencies, stability limits, etc.
***txGrpConstraint(validTGC,y,t,lb,oc)$txconstraintactive(y,t,validTGC)..
txGrpConstraint(validTGC,y,t,lb,oc)$DCloadFlow..
  sum((p,paths(r,rr))$( (bbincidence(p,r) = 1) * (bbincidence(p,rr) = -1) ), i_txGrpConstraintsLHS(validTGC,p) * TX(paths,y,t,lb,oc) )
  =l= i_txGrpConstraintsRHS(validTGC) ;

* Meet the single reserve requirement.
resvsinglereq1(rc,ild,y,t,lb,oc)$( useReserves * singleReservesReqF(rc) )..
  sum(g, RESV(g,rc,y,t,lb,oc)) + RESVVIOL(rc,ild,y,t,lb,oc) =g= RESVREQINT(rc,ild,y,t,lb,oc) ;

* Generator energy constraint - substitute for limit_maxgen when reserves are used.
genmaxresv1(validYrOperate(g,y,t),lb,oc)$( useReserves * ( exist(g) or possibleToBuild(g) ) )..
  1000 * GEN(g,y,t,lb,oc) + sum(rc, RESV(g,rc,y,t,lb,oc)) =l= CAPACITY(g,y) * maxCapFactPlant(g,t,lb) * hoursPerBlock(t,lb) ;

* Reserve transfers - Constraint 1.
resvtrfr1(ild1,ild,y,t,lb,oc)$( useReserves * interIsland(ild1,ild) )..
  sum( rc, RESVTRFR(rc,ild1,ild,y,t,lb,oc) ) +
  hoursPerBlock(t,lb) * sum((r,rr)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr)), TX(r,rr,y,t,lb,oc) )
  =l= hoursPerBlock(t,lb) * sum((r,rr,ps)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacity(r,rr,ps) * BTX(r,rr,ps,y) ) ;

* Reserve transfers - Constraint 2.
resvtrfr2(rc,ild1,ild,y,t,lb,oc)$( useReserves * interIsland(ild1,ild) * ( not singleReservesReqF(rc) ) )..
  RESVTRFR(rc,ild1,ild,y,t,lb,oc)
  =l= hoursPerBlock(t,lb) * sum((r,rr,ps)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) ), i_maxReservesTrnsfr(r,rr,ps,rc) * BTX(r,rr,ps,y) ) ;

* Reserve transfers - Constraint 3.
resvtrfr3(rc,ild1,ild,y,t,lb,oc)$( useReserves * interIsland(ild1,ild) * ( not singleReservesReqF(rc) ) )..
  RESVTRFR(rc,ild1,ild,y,t,lb,oc) =l= sum(mapg_ild(g,ild1), RESV(g,rc,y,t,lb,oc) ) ;

* Internal reserve requirement determined by the largest dispatched unit during each period.
resvrequnit(g,rc,ild,y,t,lb,oc)$( validYrOperate(g,y,t) * useReserves * ( exist(g) or possibleToBuild(g) ) * mapg_ild(g,ild) *
                                  ( (i_reserveReqMW(y,ild,rc) = -1) or (i_reserveReqMW(y,ild,rc) = -3) )  )..
  RESVREQINT(rc,ild,y,t,lb,oc) =g= 1000 * GEN(g,y,t,lb,oc) * i_UnitLargestProp(g) ;

* Internal island reserve requirement.
resvreq2(rc,ild,y,t,lb,oc)$( useReserves * ( not singleReservesReqF(rc) ) )..
  sum(mapg_ild(g,ild), RESV(g,rc,y,t,lb,oc) ) + sum(interIsland(ild1,ild), RESVTRFR(rc,ild1,ild,y,t,lb,oc) ) +
  RESVVIOL(rc,ild,y,t,lb,oc) =g= RESVREQINT(rc,ild,y,t,lb,oc) ;

* Internal reserve requirement determined by the HVDC transfer taking into account self-cover.
resvreqhvdc(rc,ild,y,t,lb,oc)$( useReserves * ( not singleReservesReqF(rc) ) )..
  RESVREQINT(rc,ild,y,t,lb,oc) =g=
  hoursPerBlock(t,lb) * sum((r,rr,ild1)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) * interIsland(ild,ild1) ), TX(r,rr,y,t,lb,oc) ) -
  hoursPerBlock(t,lb) * sum((r,rr,ps,ild1)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) * interIsland(ild,ild1) ), i_txCapacityPO(r,rr,ps) * BTX(r,rr,ps,y) ) ;

* Reserve energy transfer - Constraint 4.
resvtrfr4(interIsland(ild1,ild),y,t,lb,oc)$useReserves..
  sum(rc, RESVTRFR(rc,ild1,ild,y,t,lb,oc) )
  =l= hoursPerBlock(t,lb) * sum((r,rr,ps)$(paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr)) , i_txCapacity(r,rr,ps)) * ( 1 - NORESVTRFR(ild1,ild,y,t,lb,oc) ) ;

* Constraint that defines the reserve transfer capability.
resvtrfrdef(interIsland(ild1,ild),y,t,lb,oc)$useReserves..
  sum((r,rr)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) ), TX(r,rr,y,t,lb,oc) ) -
  sum((r,rr,ps)$( paths(r,rr) * mapild_r(ild1,r) * mapild_r(ild,rr) ), i_txCapacityPO(r,rr,ps) * BTX(r,rr,ps,y) )
  =l= NORESVTRFR(ild1,ild,y,t,lb,oc) * bigm(ild1,ild) ;

* Constraint to define the offline reserve capability.
resvoffcap(validYrOperate(g,y,t),lb,oc)$( useReserves * ( exist(g) or possibleToBuild(g) ) * (sum(rc, reservesCapability(g,rc))) * ( not i_offlineReserve(g) ) )..
  sum(rc, RESV(g,rc,y,t,lb,oc)) =l= 1000 * GEN(g,y,t,lb,oc) ;

* Constraint to ensure that reserves cover a certain proportion of wind generation.
resvreqwind(rc,ild,y,t,lb,oc)$( useReserves * ( (i_reserveReqMW(y,ild,rc) = -2) or (i_reserveReqMW(y,ild,rc) = -3) ) * windCoverPropn(rc) )..
  RESVREQINT(rc,ild,y,t,lb,oc)
  =g= windCoverPropn(rc) * sum(mapg_k(g,k)$( wind(k) * mapg_ild(g,ild) * validYrOperate(g,y,t) ), 1000 * GEN(g,y,t,lb,oc) ) ;

Model DISP Dispatch model with build forced and timing fixed  /
  objectivefn, calc_outcomeCosts, calc_refurbcost, calc_txcapcharges,
  balance_capacity, bal_supdem, peak_nz, peak_ni, noWindPeak_ni
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

* Model GEM is just model DISP with 6 additional constraints added:
Model GEM Generation expansion model / DISP, bldGenOnce, buildCapInt, buildCapCont, annNewMWcap, endogpltretire, endogretonce / ;


*===============================================================================================
* 5. Declare the 's' parameters and specify the statements used to collect up results after each solve.
*    NB: The 's' prefix denotes 'solution' to model.
*        Multiply $m/GWh by 1000 to get $/MWh.
*        Divide $m/GWh by 100 to get cents per kWh.
*        Units not yet verified in all cases and some descriptions could be made more meaningful.

Parameters
*+++++++++++++++++++++++++
* More non-free reserves code.
* Positive Variables
  s_RESVCOMPONENTS(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes,stp)  'Non-free reserve components, MW'
* Equations
  s_calc_nfreserves(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes)     'Calculate non-free reserve components' 
  s_resv_capacity(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes,stp)   'Calculate and impose the relevant capacity on each step of free reserves'
*+++++++++++++++++++++++++
* Free Variables
  s_TOTALCOST(experiments,steps,outcomeSets)                                'Discounted total system costs over all modelled years, $m (objective function value)'
  s_OUTCOME_COSTS(experiments,steps,outcomeSets,outcomes)                   'Discounted costs that might vary by outcome, $m (a component of objective function value)'
  s_TX(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes)                  'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
  s_THETA(experiments,steps,outcomeSets,r,y,t,lb,outcomes)                  'Bus voltage angle'
* Binary Variables
  s_BGEN(experiments,steps,outcomeSets,g,y)                                 'Binary variable to identify build year for new generation plant'
  s_BRET(experiments,steps,outcomeSets,g,y)                                 'Binary variable to identify endogenous retirement year for the eligble generation plant'
  s_ISRETIRED(experiments,steps,outcomeSets,g)                              'Binary variable to identify if the plant has actually been endogenously retired (0 = not retired, 1 = retired)'
  s_BTX(experiments,steps,outcomeSets,r,rr,ps,y)                            'Binary variable indicating the current state of a transmission path'
  s_NORESVTRFR(experiments,steps,outcomeSets,ild,ild1,y,t,lb,outcomes)      'Is there available capacity on the HVDC link to transfer energy reserves (0 = Yes, 1 = No)'
* Positive Variables
  s_REFURBCOST(experiments,steps,outcomeSets,g,y)                           'Annualised generation plant refurbishment expenditure charge, $'
  s_GENBLDCONT(experiments,steps,outcomeSets,g,y)                           'Continuous variable to identify build year for new scalable generation plant - for plant in linearPlantBuild set'
  s_CGEN(experiments,steps,outcomeSets,g,y)                                 'Continuous variable to identify build year for new scalable generation plant - for plant in integerPlantBuild set (CGEN or BGEN = 0 in any year)'
  s_BUILD(experiments,steps,outcomeSets,g,y)                                'New capacity installed by generating plant and year, MW'
  s_RETIRE(experiments,steps,outcomeSets,g,y)                               'Capacity endogenously retired by generating plant and year, MW'
  s_CAPACITY(experiments,steps,outcomeSets,g,y)                             'Cumulative nameplate capacity at each generating plant in each year, MW'
  s_TXCAPCHARGES(experiments,steps,outcomeSets,r,rr,y)                      'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  s_GEN(experiments,steps,outcomeSets,g,y,t,lb,outcomes)                    'Generation by generating plant and block, GWh'
  s_VOLLGEN(experiments,steps,outcomeSets,s,y,t,lb,outcomes)                'Generation by VOLL plant and block, GWh'
  s_PUMPEDGEN(experiments,steps,outcomeSets,g,y,t,lb,outcomes)              'Energy from pumped hydro (treated like demand), GWh'
  s_LOSS(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes)                'Transmission losses along each path, MW'
  s_TXPROJVAR(experiments,steps,outcomeSets,tupg,y)                         'Continuous 0-1 variable indicating whether an upgrade project is applied'
  s_TXUPGRADE(experiments,steps,outcomeSets,r,rr,ps,pss,y)                  'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
* Reserve variables
  s_RESV(experiments,steps,outcomeSets,g,rc,y,t,lb,outcomes)                'Reserve energy supplied, MWh'
  s_RESVVIOL(experiments,steps,outcomeSets,rc,ild,y,t,lb,outcomes)          'Reserve energy supply violations, MWh'
  s_RESVTRFR(experiments,steps,outcomeSets,rc,ild,ild1,y,t,lb,outcomes)     'Reserve energy transferred from one island to another, MWh'
  s_RESVREQINT(experiments,steps,outcomeSets,rc,ild,y,t,lb,outcomes)        'Internally determined energy reserve requirement, MWh'
* Penalty variables
  s_RENNRGPENALTY(experiments,steps,outcomeSets,y)                          'Penalty with cost of penaltyViolateRenNrg - used to make renewable energy constraint feasible, GWh'
  s_PEAK_NZ_PENALTY(experiments,steps,outcomeSets,y,outcomes)               'Penalty with cost of penaltyLostPeak - used to make NZ security constraint feasible, MW'
  s_PEAK_NI_PENALTY(experiments,steps,outcomeSets,y,outcomes)               'Penalty with cost of penaltyLostPeak - used to make NI security constraint feasible, MW'
  s_NOWINDPEAK_NI_PENALTY(experiments,steps,outcomeSets,y,outcomes)         'Penalty with cost of penaltyLostPeak - used to make NI no wind constraint feasible, MW'
* Slack variables
  s_ANNMWSLACK(experiments,steps,outcomeSets,y)                             'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  s_RENCAPSLACK(experiments,steps,outcomeSets,y)                            'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  s_HYDROSLACK(experiments,steps,outcomeSets,y)                             'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  s_MINUTILSLACK(experiments,steps,outcomeSets,y)                           'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  s_FUELSLACK(experiments,steps,outcomeSets,y)                              'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'
* Equations (ignore the objective function)
  s_calc_outcomeCosts(experiments,steps,outcomeSets,outcomes)               'Calculate discounted costs that might vary by outcome'
  s_calc_refurbcost(experiments,steps,outcomeSets,g,y)                      'Calculate the annualised generation plant refurbishment expenditure charge in each year, $'
  s_calc_txcapcharges(experiments,steps,outcomeSets,r,rr,y)                 'Calculate cumulative annualised transmission capital charges in each modelled year, $m'
  s_bldgenonce(experiments,steps,outcomeSets,g)                             'If new generating plant is to be built, ensure it is built only once'
  s_buildcapint(experiments,steps,outcomeSets,g,y)                          'If new integer plant is built, ensure built capacity is equal to nameplate capacity'
  s_buildcapcont(experiments,steps,outcomeSets,g,y)                         'If new scalable plant is built, ensure built capacity does not exceed nameplate capacity'
  s_annnewmwcap(experiments,steps,outcomeSets,y)                            'Restrict aggregate new capacity built in a single year to be less than a specified MW'
  s_endogpltretire(experiments,steps,outcomeSets,g,y)                       'Calculate the MW to endogenously retire'
  s_endogretonce(experiments,steps,outcomeSets,g)                           'Can only endogenously retire a plant once'
  s_balance_capacity(experiments,steps,outcomeSets,g,y)                     'Year to year capacity balance relationship for all plant, MW'
  s_bal_supdem(experiments,steps,outcomeSets,r,y,t,lb,outcomes)             'Balance supply and demand in each region, year, time period and load block'
  s_peak_nz(experiments,steps,outcomeSets,y,outcomes)                       'Ensure enough capacity to meet peak demand and the winter capacity margin in NZ'
  s_peak_ni(experiments,steps,outcomeSets,y,outcomes)                       'Ensure enough capacity to meet peak demand in NI subject to contingencies'
  s_noWindPeak_ni(experiments,steps,outcomeSets,y,outcomes)                 'Ensure enough capacity to meet peak demand in NI  subject to contingencies when wind is low'
  s_limit_maxgen(experiments,steps,outcomeSets,g,y,t,lb,outcomes)           'Ensure generation in each block does not exceed capacity implied by max capacity factors'
  s_limit_mingen(experiments,steps,outcomeSets,g,y,t,lb,outcomes)           'Ensure generation in each block exceeds capacity implied by min capacity factors'
  s_minutil(experiments,steps,outcomeSets,g,k,y,outcomes)                   'Ensure generation by certain technology type meets a minimum utilisation'
  s_limit_fueluse(experiments,steps,outcomeSets,f,y,outcomes)               'Quantum of each fuel used and possibly constrained, PJ'
  s_limit_nrg(experiments,steps,outcomeSets,f,y,outcomes)                   'Impose a limit on total energy generated by any one fuel type'
  s_minreq_rennrg(experiments,steps,outcomeSets,y,outcomes)                 'Impose a minimum requirement on total energy generated from all renewable sources'
  s_minreq_rencap(experiments,steps,outcomeSets,y)                          'Impose a minimum requirement on installed renewable capacity'
  s_limit_hydro(experiments,steps,outcomeSets,g,y,t,outcomes)               'Limit hydro generation to according to inflows'
  s_limit_pumpgen1(experiments,steps,outcomeSets,g,y,t,outcomes)            'Limit output from pumped hydro in a period to the quantity pumped'
  s_limit_pumpgen2(experiments,steps,outcomeSets,g,y,t,outcomes)            'Limit output from pumped hydro in a period to the assumed storage'
  s_limit_pumpgen3(experiments,steps,outcomeSets,g,y,t,lb,outcomes)         "Pumped MW can be no more than the scheme's installed MW"
  s_boundtxloss(experiments,steps,outcomeSets,r,rr,ps,y,t,lb,n,outcomes)    'Sort out which segment of the loss function to operate on'
  s_tx_capacity(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes)         'Calculate the relevant transmission capacity'
  s_tx_projectdef(experiments,steps,outcomeSets,tupg,r,rr,ps,pss,y)         'Associate projects to individual upgrades'
  s_tx_onestate(experiments,steps,outcomeSets,r,rr,y)                       'A link must be in exactly one state in any given year'
  s_tx_upgrade(experiments,steps,outcomeSets,r,rr,ps,y)                     'Make sure the upgrade of a link corresponds to a legitimate state-to-state transition'
  s_tx_oneupgrade(experiments,steps,outcomeSets,r,rr,y)                     'Only one upgrade per path in a single year'
  s_tx_dcflow(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes)           'DC load flow equation'
  s_tx_dcflow0(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes)          'DC load flow equation'
  s_equatetxloss(experiments,steps,outcomeSets,r,rr,y,t,lb,outcomes)        'Ensure that losses in both directions are equal'
  s_txGrpConstraint(experiments,steps,outcomeSets,tgc,y,t,lb,outcomes)      'Group transmission constraints'
  s_resvsinglereq1(experiments,steps,outcomeSets,rc,ild,y,t,lb,outcomes)    'Single reserve energy requirement constraint 1'
  s_genmaxresv1(experiments,steps,outcomeSets,g,y,t,lb,outcomes)            'Limit the amount of energy reserves per generator'
  s_resvtrfr1(experiments,steps,outcomeSets,ild,ild1,y,t,lb,outcomes)       'Limit on the amount of reserve energy transfer - constraint 1'
  s_resvtrfr2(experiments,steps,outcomeSets,rc,ild,ild1,y,t,lb,outcomes)    'Limit on the amount of reserve energy transfer - constraint 2'
  s_resvtrfr3(experiments,steps,outcomeSets,rc,ild,ild1,y,t,lb,outcomes)    'Limit on the amount of reserve energy transfer - constraint 3'
  s_resvrequnit(experiments,steps,outcomeSets,g,rc,ild,y,t,lb,outcomes)     'Reserve energy requirement based on the largest dispatched unit'
  s_resvreq2(experiments,steps,outcomeSets,rc,ild,y,t,lb,outcomes)          'Island reserve energy requirement - constraint 2'
  s_resvreqhvdc(experiments,steps,outcomeSets,rc,ild,y,t,lb,outcomes)       'Reserve energy requirement based on the HVDC transfer taking into account self-cover'
  s_resvtrfr4(experiments,steps,outcomeSets,ild1,ild,y,t,lb,outcomes)       'Limit on the amount of reserve energy transfer - constraint 4'
  s_resvtrfrdef(experiments,steps,outcomeSets,ild,ild1,y,t,lb,outcomes)     'Constraint that defines if reserve energy transfer is available'
  s_resvoffcap(experiments,steps,outcomeSets,g,y,t,lb,outcomes)             'Offline energy reserve capability'
  s_resvreqwind(experiments,steps,outcomeSets,rc,ild,y,t,lb,outcomes)       'Reserve energy requirement based on a specified proportion of dispatched wind generation'
  ;

* Now push the statements that collect up results into a file called CollectResults.txt. This file gets $include'd into GEMsolve.gms
$onecho > CollectResults.txt
*+++++++++++++++++++++++++
* More non-free reserves code.
* Positive Variables
  s_RESVCOMPONENTS(experiments,steps,outcomeSets,r,rr,y,t,lb,oc,stp)    = RESVCOMPONENTS.l(r,rr,y,t,lb,oc,stp) ;
* Equations
  s_calc_nfreserves(experiments,steps,outcomeSets,r,rr,y,t,lb,oc)       = calc_nfreserves.m(r,rr,y,t,lb,oc) ;
  s_resv_capacity(experiments,steps,outcomeSets,r,rr,y,t,lb,oc,stp)     = resv_capacity.m(r,rr,y,t,lb,oc,stp) ;
*+++++++++++++++++++++++++
* Free Variables
  s_TOTALCOST(experiments,steps,outcomeSets)                            = TOTALCOST.l ;
  s_OUTCOME_COSTS(experiments,steps,outcomeSets,oc)                     = OUTCOME_COSTS.l(oc) ;
  if(DCloadFlow = 1,
    s_TX(experiments,steps,outcomeSets,r,rr,y,t,lb,oc)$( TX.l(r,rr,y,t,lb,oc) > 0 ) = TX.l(r,rr,y,t,lb,oc) ;
    else
    s_TX(experiments,steps,outcomeSets,r,rr,y,t,lb,oc)                  = TX.l(r,rr,y,t,lb,oc) ;
  ) ;
  s_THETA(experiments,steps,outcomeSets,r,y,t,lb,oc)                    = THETA.l(r,y,t,lb,oc) ;
* Binary Variables
  s_BRET(experiments,steps,outcomeSets,g,y)                             = BRET.l(g,y) ;
  s_ISRETIRED(experiments,steps,outcomeSets,g)                          = ISRETIRED.l(g) ;
  s_BTX(experiments,steps,outcomeSets,r,rr,ps,y)                        = BTX.l(r,rr,ps,y) ;
  s_NORESVTRFR(experiments,steps,outcomeSets,ild,ild1,y,t,lb,oc)        = NORESVTRFR.l(ild,ild1,y,t,lb,oc) ;
* Positive Variables
  s_REFURBCOST(experiments,steps,outcomeSets,g,y)                       = REFURBCOST.l(g,y) ;
  s_BUILD(experiments,steps,outcomeSets,g,y)                            = BUILD.l(g,y) ;
  s_RETIRE(experiments,steps,outcomeSets,g,y)                           = RETIRE.l(g,y) ;
  s_CAPACITY(experiments,steps,outcomeSets,g,y)                         = CAPACITY.l(g,y) ;
  s_TXCAPCHARGES(experiments,steps,outcomeSets,paths,y)                 = TXCAPCHARGES.l(paths,y) ;
  s_GEN(experiments,steps,outcomeSets,g,y,t,lb,oc)                      = GEN.l(g,y,t,lb,oc) ;
  s_VOLLGEN(experiments,steps,outcomeSets,s,y,t,lb,oc)                  = VOLLGEN.l(s,y,t,lb,oc) ;
  s_PUMPEDGEN(experiments,steps,outcomeSets,g,y,t,lb,oc)                = PUMPEDGEN.l(g,y,t,lb,oc) ;
  s_LOSS(experiments,steps,outcomeSets,r,rr,y,t,lb,oc)                  = LOSS.l(r,rr,y,t,lb,oc) ;
  s_TXPROJVAR(experiments,steps,outcomeSets,tupg,y)                     = TXPROJVAR.l(tupg,y) ;
  s_TXUPGRADE(experiments,steps,outcomeSets,r,rr,ps,pss,y)              = TXUPGRADE.l(r,rr,ps,pss,y) ;
* Reserve variables
  s_RESV(experiments,steps,outcomeSets,g,rc,y,t,lb,oc)                  = RESV.l(g,rc,y,t,lb,oc) ;
  s_RESVVIOL(experiments,steps,outcomeSets,rc,ild,y,t,lb,oc)            = RESVVIOL.l(RC,ILD,y,t,lb,oc) ;
  s_RESVTRFR(experiments,steps,outcomeSets,rc,ild,ild1,y,t,lb,oc)       = RESVTRFR.l(rc,ild1,ild,y,t,lb,oc) ;
  s_RESVREQINT(experiments,steps,outcomeSets,rc,ild,y,t,lb,oc)          = RESVREQINT.l(rc,ild,y,t,lb,oc) ;
* Penalty variables
  s_RENNRGPENALTY(experiments,steps,outcomeSets,y)                      = RENNRGPENALTY.l(y) ;
  s_PEAK_NZ_PENALTY(experiments,steps,outcomeSets,y,oc)                 = PEAK_NZ_PENALTY.l(y,oc) ;
  s_PEAK_NI_PENALTY(experiments,steps,outcomeSets,y,oc)                 = PEAK_NI_PENALTY.l(y,oc) ;
  s_NOWINDPEAK_NI_PENALTY(experiments,steps,outcomeSets,y,oc)           = NOWINDPEAK_NI_PENALTY.l(y,oc) ;
* Slack variables
  s_ANNMWSLACK(experiments,steps,outcomeSets,y)                         = ANNMWSLACK.l(y) ;
  s_RENCAPSLACK(experiments,steps,outcomeSets,y)                        = RENCAPSLACK.l(y) ;
  s_HYDROSLACK(experiments,steps,outcomeSets,y)                         = HYDROSLACK.l(y) ;
  s_MINUTILSLACK(experiments,steps,outcomeSets,y)                       = MINUTILSLACK.l(y) ;
  s_FUELSLACK(experiments,steps,outcomeSets,y)                          = FUELSLACK.l(y) ;
* Equations, i.e. marginal values. (ignore the objective function)
  s_calc_outcomeCosts(experiments,steps,outcomeSets,oc)                 = calc_outcomeCosts.m(oc) ;
  s_calc_refurbcost(experiments,steps,outcomeSets,g,y)                  = calc_refurbcost.m(g,y) ;
  s_calc_txcapcharges(experiments,steps,outcomeSets,paths,y)            = calc_txcapcharges.m(paths,y) ;
  s_balance_capacity(experiments,steps,outcomeSets,g,y)                 = balance_capacity.m(g,y) ;
  s_bal_supdem(experiments,steps,outcomeSets,r,y,t,lb,oc)               = bal_supdem.m(r,y,t,lb,oc) ;
  s_peak_nz(experiments,steps,outcomeSets,y,oc)                         = peak_NZ.m(y,oc) ;
  s_peak_ni(experiments,steps,outcomeSets,y,oc)                         = peak_NI.m(y,oc) ;
  s_noWindPeak_ni(experiments,steps,outcomeSets,y,oc)                   = noWindPeak_NI.m(y,oc) ;
  s_limit_maxgen(experiments,steps,outcomeSets,g,y,t,lb,oc)             = limit_maxgen.m(g,y,t,lb,oc) ;
  s_limit_mingen(experiments,steps,outcomeSets,g,y,t,lb,oc)             = limit_mingen.m(g,y,t,lb,oc) ;
  s_minutil(experiments,steps,outcomeSets,g,k,y,oc)                     = minutil.m(g,k,y,oc) ;
  s_limit_fueluse(experiments,steps,outcomeSets,f,y,oc)                 = limit_fueluse.m(f,y,oc) ;
  s_limit_nrg(experiments,steps,outcomeSets,f,y,oc)                     = limit_nrg.m(f,y,oc) ;
  s_minreq_rennrg(experiments,steps,outcomeSets,y,oc)                   = minReq_renNrg.m(y,oc) ;
  s_minreq_rencap(experiments,steps,outcomeSets,y)                      = minReq_renCap.m(y) ;
  s_limit_hydro(experiments,steps,outcomeSets,g,y,t,oc)                 = limit_hydro.m(g,y,t,oc) ;
  s_limit_pumpgen1(experiments,steps,outcomeSets,g,y,t,oc)              = limit_pumpgen1.m(g,y,t,oc) ;
  s_limit_pumpgen2(experiments,steps,outcomeSets,g,y,t,oc)              = limit_pumpgen2.m(g,y,t,oc) ;
  s_limit_pumpgen3(experiments,steps,outcomeSets,g,y,t,lb,oc)           = limit_pumpgen3.m(g,y,t,lb,oc) ;
  s_boundtxloss(experiments,steps,outcomeSets,r,rr,ps,y,t,lb,n,oc)      = boundtxloss.m(r,rr,ps,y,t,lb,n,oc) ;
  s_tx_capacity(experiments,steps,outcomeSets,r,rr,y,t,lb,oc)           = tx_capacity.m(r,rr,y,t,lb,oc) ;
  s_tx_projectdef(experiments,steps,outcomeSets,tupg,r,rr,ps,pss,y)     = tx_projectdef.m(tupg,r,rr,ps,pss,y) ;
  s_tx_onestate(experiments,steps,outcomeSets,r,rr,y)                   = tx_onestate.m(r,rr,y) ;
  s_tx_upgrade(experiments,steps,outcomeSets,r,rr,ps,y)                 = tx_upgrade.m(r,rr,ps,y) ;
  s_tx_oneupgrade(experiments,steps,outcomeSets,r,rr,y)                 = tx_oneupgrade.m(r,rr,y) ;
  s_tx_dcflow(experiments,steps,outcomeSets,r,rr,y,t,lb,oc)             = tx_dcflow.m(r,rr,y,t,lb,oc) ;
  s_tx_dcflow0(experiments,steps,outcomeSets,r,rr,y,t,lb,oc)            = tx_dcflow0.m(r,rr,y,t,lb,oc) ;
  s_equatetxloss(experiments,steps,outcomeSets,r,rr,y,t,lb,oc)          = equatetxloss.m(r,rr,y,t,lb,oc) ;
  s_txGrpConstraint(experiments,steps,outcomeSets,tgc,y,t,lb,oc)        = txGrpConstraint.m(tgc,y,t,lb,oc) ;
  s_resvsinglereq1(experiments,steps,outcomeSets,rc,ild,y,t,lb,oc)      = resvsinglereq1.m(rc,ild,y,t,lb,oc) ;
  s_genmaxresv1(experiments,steps,outcomeSets,g,y,t,lb,oc)              = genmaxresv1.m(g,y,t,lb,oc) ;
  s_resvtrfr1(experiments,steps,outcomeSets,ild,ild1,y,t,lb,oc)         = resvtrfr1.m(ild,ild1,y,t,lb,oc) ;
  s_resvtrfr2(experiments,steps,outcomeSets,rc,ild,ild1,y,t,lb,oc)      = resvtrfr2.m(rc,ild,ild1,y,t,lb,oc) ;
  s_resvtrfr3(experiments,steps,outcomeSets,rc,ild,ild1,y,t,lb,oc)      = resvtrfr3.m(rc,ild,ild1,y,t,lb,oc) ;
  s_resvrequnit(experiments,steps,outcomeSets,g,rc,ild,y,t,lb,oc)       = resvrequnit.m(g,rc,ild,y,t,lb,oc) ;
  s_resvreq2(experiments,steps,outcomeSets,rc,ild,y,t,lb,oc)            = resvreq2.m(rc,ild,y,t,lb,oc) ;
  s_resvreqhvdc(experiments,steps,outcomeSets,rc,ild,y,t,lb,oc)         = resvreqhvdc.m(rc,ild,y,t,lb,oc) ;
  s_resvtrfr4(experiments,steps,outcomeSets,ild1,ild,y,t,lb,oc)         = resvtrfr4.m(ild1,ild,y,t,lb,oc) ;
  s_resvtrfrdef(experiments,steps,outcomeSets,ild,ild1,y,t,lb,oc)       = resvtrfrdef.m(ild,ild1,y,t,lb,oc) ;
  s_resvoffcap(experiments,steps,outcomeSets,g,y,t,lb,oc)               = resvoffcap.m(g,y,t,lb,oc) ;
  s_resvreqwind(experiments,steps,outcomeSets,rc,ild,y,t,lb,oc)         = resvreqwind.m(rc,ild,y,t,lb,oc) ;
* Now write the statements that are contingent on the model type being solved.
* NB: these statements will not be executed when included in GEMsolve if RunType = 2.
$if %RunType%==2 $goto skip
* Variables
  s_BGEN(experiments,steps,outcomeSets,g,y)                             = BGEN.l(g,y) ;
  s_GENBLDCONT(experiments,steps,outcomeSets,g,y)                       = GENBLDCONT.l(g,y) ;
  s_CGEN(experiments,steps,outcomeSets,g,y)                             = CGEN.l(g,y) ;
* Equations
  s_bldgenonce(experiments,steps,outcomeSets,g)                         = bldGenOnce.m(g) ;
  s_buildcapint(experiments,steps,outcomeSets,g,y)                      = buildCapInt.m(g,y) ;
  s_buildcapcont(experiments,steps,outcomeSets,g,y)                     = buildCapCont.m(g,y) ;
  s_annnewmwcap(experiments,steps,outcomeSets,y)                        = annNewMWcap.m(y) ;
  s_endogpltretire(experiments,steps,outcomeSets,g,y)                   = endogpltretire.m(g,y) ;
  s_endogretonce(experiments,steps,outcomeSets,g)                       = endogretonce.m(g) ;
$label skip
$offecho



*===============================================================================================
* 6. Declare the 's2' parameters for use in GEMreports.

* NB: The 's2' parameters are initialised towards the end of GEMsolve, dumped into a GDX file, and passed along to GEMreports.
*     The 'outcomeSets' index is removed on the s2 parameters, i.e. results are averaged over all outcomeSets in an experiment.

**    This averaging in the s2 parameters implies that we carry along outcome (c.f. outcomeSet) results to GEMreports.

Parameters
* Free variables
  s2_TOTALCOST(experiments,steps)                               'Discounted total system costs over all modelled years, $m (objective function value)'
  s2_OUTCOME_COSTS(experiments,steps,outcomes)                  'Discounted costs that might vary by outcome, $m (a component of objective function value)'
  s2_TX(experiments,steps,r,rr,y,t,lb,outcomes)                 'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
* Binary Variables
  s2_BRET(experiments,steps,g,y)                                'Binary variable to identify endogenous retirement year for the eligble generation plant'
  s2_ISRETIRED(experiments,steps,g)                             'Binary variable to identify if the plant has actually been endogenously retired (0 = not retired, 1 = retired)'
  s2_BTX(experiments,steps,r,rr,ps,y)                           'Binary variable indicating the current state of a transmission path'
* Positive Variables
  s2_REFURBCOST(experiments,steps,g,y)                          'Annualised generation plant refurbishment expenditure charge, $'
  s2_BUILD(experiments,steps,g,y)                               'New capacity installed by generating plant and year, MW'
  s2_RETIRE(experiments,steps,g,y)                              'Capacity endogenously retired by generating plant and year, MW'
  s2_CAPACITY(experiments,steps,g,y)                            'Cumulative nameplate capacity at each generating plant in each year, MW'
  s2_TXCAPCHARGES(experiments,steps,r,rr,y)                     'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  s2_GEN(experiments,steps,g,y,t,lb,outcomes)                   'Generation by generating plant and block, GWh'
  s2_VOLLGEN(experiments,steps,s,y,t,lb,outcomes)               'Generation by VOLL plant and block, GWh'
  s2_PUMPEDGEN(experiments,steps,g,y,t,lb,outcomes)             'Energy from pumped hydro (treated like demand), GWh'
  s2_LOSS(experiments,steps,r,rr,y,t,lb,outcomes)               'Transmission losses along each path, MW'
  s2_TXPROJVAR(experiments,steps,tupg,y)                        'Continuous 0-1 variable indicating whether an upgrade project is applied'
  s2_TXUPGRADE(experiments,steps,r,rr,ps,pss,y)                 'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
  s2_RESV(experiments,steps,g,rc,y,t,lb,outcomes)               'Reserve energy supplied, MWh'
  s2_RESVVIOL(experiments,steps,rc,ild,y,t,lb,outcomes)         'Reserve energy supply violations, MWh'
  s2_RESVTRFR(experiments,steps,rc,ild,ild1,y,t,lb,outcomes)    'Reserve energy transferred from one island to another, MWh'
* Penalty variables
  s2_RENNRGPENALTY(experiments,steps,y)                         'Penalty with cost of penaltyViolateRenNrg - used to make renewable energy constraint feasible, GWh'
  s2_PEAK_NZ_PENALTY(experiments,steps,y,outcomes)              'Penalty with cost of penaltyLostPeak - used to make NZ security constraint feasible, MW'
  s2_PEAK_NI_PENALTY(experiments,steps,y,outcomes)              'Penalty with cost of penaltyLostPeak - used to make NI security constraint feasible, MW'
  s2_NOWINDPEAK_NI_PENALTY(experiments,steps,y,outcomes)        'Penalty with cost of penaltyLostPeak - used to make NI no wind constraint feasible, MW'
* Slack variables
  s2_ANNMWSLACK(experiments,steps,y)                            'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  s2_RENCAPSLACK(experiments,steps,y)                           'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  s2_HYDROSLACK(experiments,steps,y)                            'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  s2_MINUTILSLACK(experiments,steps,y)                          'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  s2_FUELSLACK(experiments,steps,y)                             'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'
* Equations, i.e. marginal values.
  s2_bal_supdem(experiments,steps,r,y,t,lb,outcomes)            'Balance supply and demand in each region, year, time period and load block'
  s2_peak_nz(experiments,steps,y,outcomes)                      'Ensure enough capacity to meet peak demand and the winter capacity margin in NZ'
  s2_peak_ni(experiments,steps,y,outcomes)                      'Ensure enough capacity to meet peak demand in NI subject to contingencies'
  s2_noWindPeak_ni(experiments,steps,y,outcomes)                'Ensure enough capacity to meet peak demand in NI  subject to contingencies when wind is low'

*++++++++++
* More non-free reserves code.
  s2_RESVCOMPONENTS(experiments,steps,r,rr,y,t,lb,outcomes,stp) 'Non-free reserve components, MW'
*++++++++++
  ;




* End of file.
