* GEMreports.gms


* Last modified by Dr Phil Bishop, 23/04/2016 (emi@ea.govt.nz)


$ontext
  This program generates GEM reports - human-readable files or files to be read by other applications for further processing.
  It is to be invoked subsequent to the solving of all runs and run versions that are to be reported on. Note that GEMreports
  effectively starts afresh as a standalone program. It does "not" start from any previously created GAMS work files (.g00), and
  it imports or loads all of the data it requires from GDX files containing output from previously solved GEM runs. All symbols
  required in this program are declared here. Set membership and data values are imported from the designated base case input GDX
  file and/or the various merged GDX files.

  Notes:
  1. The sets scenarios, defaultScenario, scenarioSets, experiments, and mapScenarios; and parameters weightScenariosBySet, taxRate,
     VOLLcost, penaltyViolatePeakLoad, penaltyViolateRenNrg, and slackCost; and $setglobals firstYear and lastYear all come from the
     base case version of "Configuration info for use in GEMreports - XXX.inc". This can cause problems of non-base case run versions
     are not consistent. When GEM is put back into EMI, there needs to be some check of consistency across run versions to be reported
     on.

 Code sections:
  1. Take care of preliminaries and declare output file names.
  2. Declare required symbols and load data.
     a) Declare and initialise hard-coded sets - cut and paste from GEMdeclarations.
     b) Declare the required fundamental sets - cut and paste from GEMdeclarations.
     c) Declare the required subsets and mapping sets - cut and paste from GEMdeclarations.
     d) Load set membership, i.e. fundamental, subsets, and mapping sets, from the designated base case GDX file.
     e) Declare and load sets and parameters from the merged 'selectedInputData' GDX file.
     f) Declare and load the parameters (variable levels and marginals) to be found in the merged 'reportOutput' GDX file.
  3. Collapse dispatch solves to a single average result in cases where variable hydrology was simulated.
  4. Undertake the declarations and calculations necessary to prepare all that is to be reported.
  5. Write selected results to CSV files.
     a) Set descriptions
     b) Objective function value breakdown
     c) Plant built by technology
     d) Plant built by region
     e) Summary of plant build, refurbishment and retirement by island and New Zealand
     f) Generation capacity by plant and year
     g) Generation capacity expansion - ordered by year and including retirements.
     h) Time-weighted energy price by region and year, $/MWh.


  x. Write key results to a CSV file.
  x. Write results to be plotted to a single csv file.

  x. Generate the remaining external files.
     a) Write an ordered (by year) summary of generation capacity expansion.
     b) Write out capacity report (capacityPlant) (is this redundant given expandSchedule?).
     c) Write out generation report (genPlant and genPlantYear).
     d) Write out annual report (variousAnnual).
  x. Do the John Culy report for TPR work - delete all of this once TPR is over.
$offtext



*===============================================================================================
* 1. Take care of preliminaries and declare output file names.

option seed = 101 ;

$include GEMreportSettings.inc
$include "%primaryOutput%\rep%reportName%\repData\Configuration info.inc"
$offupper offsymxref offsymlist offuellist offuelxref onempty inlinecom { } eolcom !

Alias(runVersions,rv), (experiments,expts), (scenarioSets,scenSet), (scenarios,scen) ;

* Declare output files to be created by GEMreports.
Files
  setDescriptions / "%primaryOutput%\rep%reportName%\Set descriptions - %reportName%.csv" /
  objBrkDown      / "%primaryOutput%\rep%reportName%\Objective function value breakdown - %reportName%.csv" /
  plantBuilt      / "%primaryOutput%\rep%reportName%\Plant built (MW) - %reportName%.csv" /
  txCapex         / "%primaryOutput%\rep%reportName%\Tx capital expenditure ($m) - %reportName%.csv" /
  genOutput       / "%primaryOutput%\rep%reportName%\Generation (GWh) - %reportName%.csv" /
  txFlows         / "%primaryOutput%\rep%reportName%\Transmission flows (GWh) - %reportName%.csv" /
  txLosses        / "%primaryOutput%\rep%reportName%\Transmission losses (GWh) - %reportName%.csv" /
  energyPrices    / "%primaryOutput%\rep%reportName%\Time-weighted energy price by region and year - %reportName%.csv" /


  buildAgg        / "%primaryOutput%\rep%reportName%\Summary of plant build, refurbishment and retirement by island - %reportName%.csv" /
  capacityPlant   / "%primaryOutput%\rep%reportName%\Capacity by plant and year (net of retirements) - %reportName%.csv" /
  expandSchedule  / "%primaryOutput%\rep%reportName%\Capacity expansion by year - %reportName%.csv" /
  keyResults      / "%primaryOutput%\rep%reportName%\A collection of key results - %reportName%.csv" /
  plotResults     / "%primaryOutput%\rep%reportName%\Results to be plotted - %reportName%.csv" /
  variousAnnual   / "%primaryOutput%\rep%reportName%\Various annual results - %reportName%.csv" /  ;

setDescriptions.pc = 5 ; setDescriptions.pw = 999 ;
objBrkDown.pc = 5 ;      objBrkDown.pw = 999 ;
plantBuilt.pc = 5 ;      plantBuilt.pw = 999 ;
txCapex.pc = 5 ;         txCapex.pw = 999 ;
genOutput.pc = 5 ;       genOutput.pw = 999 ;
txFlows.pc = 5 ;         txFlows.pw = 999 ;
txLosses.pc = 5 ;        txLosses.pw = 999 ;
energyPrices.pc = 5 ;    energyPrices.pw = 999 ;


buildAgg.pc = 5 ;        buildAgg.pw = 999 ;
capacityPlant.pc = 5 ;   capacityPlant.pw = 999 ;
expandSchedule.pc = 5 ;  expandSchedule.pw = 999 ;
keyResults.pc = 5 ;      keyResults.pw = 999 ;
plotResults.pc = 5 ;     plotResults.pw = 999 ;
variousAnnual.pc = 5 ;   variousAnnual.pw = 999 ;



*===============================================================================================
* 2. Declare required symbols and load data.

* a) Declare and initialise hard-coded sets - cut and paste from GEMdeclarations.
Sets
  steps             'Steps in an experiment'              / timing      'Solve the timing problem, i.e. timing of new generation/or transmission investment'
                                                            reopt       'Solve the re-optimised timing problem (generally with a drier hydro sequence) while allowing peakers to move'
                                                            dispatch    'Solve for the dispatch only with investment timing fixed'  /
  repSteps          '"Reporting" steps in an experiment'  / timing      'Solve the timing problem, i.e. timing of new generation/or transmission investment'
                                                            reopt       'Solve the re-optimised timing problem (generally with a drier hydro sequence) while allowing peakers to move'
                                                            dispatch    'Solve for the dispatch only with investment timing fixed'
                                                            avgDispatch 'Average over all dispatch solves for a given experiment' /
  hydroSeqTypes     'Types of hydro sequences to use'     / Same        'Use the same sequence of hydro years to be used in every modelled year'
                                                            Sequential  'Use a sequentially developed mapping of hydro years to modelled years' /
  ild               'Islands'                             / ni          'North Island'
                                                            si          'South Island' /
  aggR              'Aggregate regional entities'         / ni          'North Island'
                                                            si          'South Island'
                                                            nz          'New Zealand' /
  col               'RGB color codes'                     / 0 * 256 /
  lvl               'Levels of non-free reserves'         / lvl1 * lvl5 / ;

* Initialise set y with values read from 'Configuration info.txt'.
Set y 'Modelled calendar years' / %firstYear% * %lastYear% / ;


* b) Declare the required fundamental sets - cut and paste from GEMdeclarations.
Sets
  k                 'Generation technologies'
  f                 'Fuels'
  fg                'Fuel groups'
  g                 'Generation plant'
  s                 'Shortage or VOLL plants'
  o                 'Owners of generating plant'
  i                 'Substations'
  r                 'Regions'
  e                 'Zones'
  ps                'Transmission path states (state of upgrade)'
  tupg              'Transmission upgrade projects'
  t                 'Time periods (within a year)'
  lb                'Load blocks'
  rc                'Reserve classes'
  hY                'Hydrology output years' ;

Alias (repSteps,rs), (i,ii), (r,rr), (ps,pss), (col,red,green,blue) ;


* c) Declare the required subsets and mapping sets - cut and paste from GEMdeclarations.
Sets
  techColor(k,red,green,blue)      'RGB color mix for technologies - to pass to plotting applications'
* fuelColor(f,red,green,blue)      'RGB color mix for fuels - to pass to plotting applications'
* fuelGrpcolor(fg,red,green,blue)  'RGB color mix for fuel groups - to pass to plotting applications'
  firstYr(y)                       'First modelled year - as a set, not a scalar'
  firstPeriod(t)                   'First time period (i.e. period within the modelled year)'
  thermalFuel(f)                   'Thermal fuels'
  wind(k)                          'Wind technologies'
  nigen(g)                         'North Island generation plant'
  nwd(r,rr)                        'Northward direction of flow on Benmore-Haywards HVDC'
  swd(r,rr)                        'Southward direction of flow on Benmore-Haywards HVDC'
  paths(r,rr)                      'All valid transmission paths'
  mapg_k(g,k)                      'Map technology types to generating plant'
  mapg_f(g,f)                      'Map fuel types to generating plant'
  mapf_fg(f,fg)                    'Map fuel groups to fuel types'
  mapg_o(g,o)                      'Map plant owners to generating plant'
  mapg_r(g,r)                      'Map regions to generating plant'
  mapg_e(g,e)                      'Map zones to generating plant'
  mapAggR_r(aggR,r)                'Map the regions to the aggregated regional entities (this is primarily to facilitate reporting)'
  isIldEqReg(ild,r)                'Figure out if the region labels are identical to the North and South island labels (a reporting facilitation device)' ;


* d) Load set membership, i.e. fundamental, subsets, and mapping sets, from the designated base case GDX file.
$gdxin "%primaryOutput%\rep%reportName%\repData\Base case input data.gdx"
$loaddc k f fg g s o i r e ps tupg t lb rc hY
$loaddc firstYr firstPeriod thermalFuel wind nigen nwd swd paths mapg_k mapg_f mapf_fg mapg_o mapg_r mapg_e mapAggR_r isIldEqReg
$loaddc techColor


* e) Declare and load sets and parameters from the merged 'selectedInputData' GDX file.
Sets
  demandGen(rv,k)                             'Demand side technologies modelled as generation'
  exist(rv,g)                                 'Generation plant that are presently operating'
  sigen(rv,g)                                 'South Island generation plant'
  possibleToBuild(rv,g)                       'Generating plant that may possibly be built in any valid build year'
  possibleToRefurbish(rv,g)                   'Generating plant that may possibly be refurbished in any valid modelled year'
  possibleToEndogRetire(rv,g)                 'Generating plant that may possibly be endogenously retired'
  possibleToRetire(rv,g)                      'Generating plant that may possibly be retired (exogenously or endogenously)'
  validYrOperate(rv,g,y)                      'Valid years in which an existing, committed or new plant can generate. Use to fix GEN to zero in invalid years'
  transitions(rv,tupg,r,rr,ps,pss)            'For all transmission paths, define the allowable transitions from one upgrade state to another'
  allowedStates(rv,r,rr,ps)                   'All of the allowed states (initial and upgraded) for each active path'
  allAvgDispatchSolves(rv,expts,steps,scenSet)             'All solves for which the dispatch simulations are to be averaged over all scenarios mapped to each scenario set'
  allNotAvgDispatchSolves(rv,expts,steps,scenSet)          'All solves for which the dispatch simulations are not to be averaged over all scenarios mapped to each scenario set'
  avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen) 'Map average dispatch step to (old) dispatch step for an experiment' ;

Parameters
  i_fuelQuantities(rv,f,y)                    'Quantitative limit on availability of various fuels by year, PJ'
  i_namePlate(rv,g)                           'Nameplate capacity of generating plant, MW'
  i_heatrate(rv,g)                            'Heat rate of generating plant, GJ/GWh (default = 3600)'
  i_txCapacity(rv,r,rr,ps)                    'Transmission path capacities (bi-directional), MW'
  i_txCapacityPO(rv,r,rr,ps)                  'Transmission path capacities with largest pole out (bi-directional, HVDC link only), MW'
  txCapitalCost(rv,r,rr,ps)                   'Capital cost of transmission upgrades by path and state, $m'
  totalFuelCost(rv,g,y,scen)                  'Total fuel cost - price plus fuel production and delivery charges all times heatrate - by plant, year and scenario, $/MWh'
  CO2taxByPlant(rv,g,y,scen)                  'CO2 tax by plant, year and scenario, $/MWh'
  SRMC(rv,g,y,scen)                           'Short run marginal cost of each generation project by year and scenario, $/MWh'
  i_fixedOM(rv,g)                             'Fixed O&M costs by plant, $/kW/year'
  ensembleFactor(rv,g)                        'Collection of total cost adjustment factors by plant (e.g. location factors and hydro peaking factors)'
  i_HVDCshr(rv,o)                             'Share of HVDC charge to be incurred by plant owner'
  i_HVDClevy(rv,y)                            'HVDC charge levied on new South Island plant by year, $/kW'
  i_plantReservesCost(rv,g,rc)                'Plant-specific cost per reserve class, $/MWh'
  hoursPerBlock(rv,t,lb)                      'Hours per load block by time period'
  NrgDemand(rv,r,y,t,lb,scen)                 'Load (or energy demand) by region, year, time period and load block, GWh (used to create ldcMW)'
  peakLoadNZ(rv,y,scen)                       'Peak load for New Zealand by year, MW'
  peakLoadNI(rv,y,scen)                       'Peak load for North Island by year, MW'
  peakConPlant(rv,g,y)                        'Contribution to peak of each generating plant by year'
  NWpeakConPlant(rv,g,y)                      'Contribution to peak when there is no wind of each generating plant by year'
  i_winterCapacityMargin(rv,y)                'Required winter capacity margin, MW'
  i_SIACrisk(rv,y)                            'Required cover for South Island AC risk by year, MW'
  i_fkSI(rv,y)                                'Required frequency keeping in South Island by year, MW'
  i_fkNI(rv,y)                                'Required frequency keeping in North Island by year, MW'
  i_HVDClossesAtMaxXfer(rv,y)                 'Required cover for HVDC (bi-pole) losses at maximum transfer by year, MW'
  i_largestGenerator(rv,y)                    'Largest generation plant by year, MW'
  i_P200ratioNZ(rv,y)                         'Desired ratio of peak demand MW to average demand MW (derived from forecast GWh energy demand), New Zealand'
  i_P200ratioNI(rv,y)                         'Desired ratio of peak demand MW to average demand MW (derived from forecast GWh energy demand), North Island'
  yearNum(rv,y)                               'Real number associated with each year'
  PVfacG(rv,y,t)                              "Generation investor's present value factor by period"
  PVfacT(rv,y,t)                              "Transmission investor's present value factor by period"
  capCharge(rv,g,y)                           'Annualised or levelised capital charge for new generation plant, $/MW/yr'
  refurbCapCharge(rv,g,y)                     'Annualised or levelised capital charge for refurbishing existing generation plant, $/MW/yr'
  MWtoBuild(rv,k,aggR)                        'MW available for installation by technology, island and NZ'
  penaltyViolateReserves(rv,ild,rc)           'Penalty for failing to meet certain reserve classes, $/MW'
  pNFresvCost(rv,r,rr,lvl)                    'Constant cost of each non-free piece (or level) of function, $/MWh'
  exogMWretired(rv,g,y)                       'Exogenously retired MW by plant and year, MW' ;

$gdxin "%primaryOutput%\rep%reportName%\repData\selectedInputData.gdx"
$loaddc demandGen exist sigen possibleToBuild possibleToRefurbish possibleToEndogRetire possibleToRetire validYrOperate transitions allowedStates
$loaddc allAvgDispatchSolves allNotAvgDispatchSolves avgDispatchSteptoRepStep i_fuelQuantities i_namePlate i_heatrate
$loaddc i_txCapacity i_txCapacityPO txCapitalCost totalFuelCost CO2taxByPlant SRMC i_fixedOM ensembleFactor i_HVDCshr i_HVDClevy
$loaddc i_plantReservesCost hoursPerBlock NrgDemand peakLoadNZ peakLoadNI peakConPlant NWpeakConPlant i_winterCapacityMargin i_SIACrisk
$loaddc i_fkSI i_fkNI i_HVDClossesAtMaxXfer i_largestGenerator i_P200ratioNZ i_P200ratioNI
$loaddc yearNum PVfacG PVfacT capCharge refurbCapCharge MWtoBuild penaltyViolateReserves pNFresvCost exogMWretired


* f) Declare and load the parameters (variable levels and marginals) to be found in the merged 'reportOutput' GDX file.
Parameters
  s_TOTALCOST(rv,expts,steps,scenSet)                           'Discounted total system costs over all modelled years, $m (objective function value)'
  s_TX(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)                 'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
  s_BTX(rv,expts,steps,scenSet,r,rr,ps,y)                       'Binary variable indicating the current state of a transmission path'
  s_REFURBCOST(rv,expts,steps,scenSet,g,y)                      'Annualised generation plant refurbishment expenditure charge, $'
  s_BUILD(rv,expts,steps,scenSet,g,y)                           'New capacity installed by generating plant and year, MW'
  s_RETIRE(rv,expts,steps,scenSet,g,y)                          'Capacity endogenously retired by generating plant and year, MW'
  s_CAPACITY(rv,expts,steps,scenSet,g,y)                        'Cumulative nameplate capacity at each generating plant in each year, MW'
  s_TXCAPCHARGES(rv,expts,steps,scenSet,r,rr,y)                 'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  s_GEN(rv,expts,steps,scenSet,g,y,t,lb,scen)                   'Generation by generating plant and block, GWh'
  s_VOLLGEN(rv,expts,steps,scenSet,s,y,t,lb,scen)               'Generation by VOLL plant and block, GWh'
  s_LOSS(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)               'Transmission losses along each path, MW'
  s_TXPROJVAR(rv,expts,steps,scenSet,tupg,y)                    'Continuous 0-1 variable indicating whether an upgrade project is applied'
  s_TXUPGRADE(rv,expts,steps,scenSet,r,rr,ps,pss,y)             'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
  s_RESV(rv,expts,steps,scenSet,g,rc,y,t,lb,scen)               'Reserve energy supplied, MWh'
  s_RESVVIOL(rv,expts,steps,scenSet,rc,ild,y,t,lb,scen)         'Reserve energy supply violations, MWh'
  s_RESVCOMPONENTS(rv,expts,steps,scenSet,r,rr,y,t,lb,scen,lvl) 'Non-free reserve components, MW'
  s_RENNRGPENALTY(rv,expts,steps,scenSet,y)                     'Penalty with cost of penaltyViolateRenNrg - used to make renewable energy constraint feasible, GWh'
  s_PEAK_NZ_PENALTY(rv,expts,steps,scenSet,y,scen)              'Penalty with cost of penaltyViolatePeakLoad - used to make NZ security constraint feasible, MW'
  s_PEAK_NI_PENALTY(rv,expts,steps,scenSet,y,scen)              'Penalty with cost of penaltyViolatePeakLoad - used to make NI security constraint feasible, MW'
  s_NOWINDPEAK_NI_PENALTY(rv,expts,steps,scenSet,y,scen)        'Penalty with cost of penaltyViolatePeakLoad - used to make NI no wind constraint feasible, MW'
  s_ANNMWSLACK(rv,expts,steps,scenSet,y)                        'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  s_RENCAPSLACK(rv,expts,steps,scenSet,y)                       'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  s_HYDROSLACK(rv,expts,steps,scenSet,y)                        'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  s_MINUTILSLACK(rv,expts,steps,scenSet,y)                      'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  s_FUELSLACK(rv,expts,steps,scenSet,y)                         'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'
  s_bal_supdem(rv,expts,steps,scenSet,r,y,t,lb,scen)            'Balance supply and demand in each region, year, time period and load block'
  s_peak_nz(rv,expts,steps,scenSet,y,scen)                      'Ensure enough capacity to meet peak demand and the winter capacity margin in NZ'
  s_peak_ni(rv,expts,steps,scenSet,y,scen)                      'Ensure enough capacity to meet peak demand in NI subject to contingencies'
  s_noWindPeak_ni(rv,expts,steps,scenSet,y,scen)                'Ensure enough capacity to meet peak demand in NI  subject to contingencies when wind is low'
  s_limit_maxgen(rv,expts,steps,scenSet,g,y,t,lb,scen)          'Ensure generation in each block does not exceed capacity implied by max capacity factors'
  s_limit_mingen(rv,expts,steps,scenSet,g,y,t,lb,scen)          'Ensure generation in each block exceeds capacity implied by min capacity factors'
  s_minutil(rv,expts,steps,scenSet,g,y,scen)                    'Ensure certain generation plant meets a minimum utilisation'
  s_limit_fueluse(rv,expts,steps,scenSet,f,y,scen)              'Quantum of each fuel used and possibly constrained, PJ'
  s_limit_nrg(rv,expts,steps,scenSet,f,y,scen)                  'Impose a limit on total energy generated by any one fuel type'
  s_minreq_rennrg(rv,expts,steps,scenSet,y,scen)                'Impose a minimum requirement on total energy generated from all renewable sources'
  s_minreq_rencap(rv,expts,steps,scenSet,y)                     'Impose a minimum requirement on installed renewable capacity'
  s_limit_hydro(rv,expts,steps,scenSet,g,y,t,scen)              'Limit hydro generation according to inflows'
  s_tx_capacity(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)        'Calculate the relevant transmission capacity' ;

$gdxin "%primaryOutput%\rep%reportName%\repData\reportOutput.gdx"
$loaddc s_TOTALCOST s_TX s_BTX s_REFURBCOST s_BUILD s_RETIRE s_CAPACITY s_TXCAPCHARGES s_GEN s_VOLLGEN s_LOSS s_TXUPGRADE s_TXPROJVAR
$loaddc s_RESV s_RESVVIOL s_RESVCOMPONENTS
$loaddc s_RENNRGPENALTY s_PEAK_NZ_PENALTY s_PEAK_NI_PENALTY s_NOWINDPEAK_NI_PENALTY
$loaddc s_ANNMWSLACK s_RENCAPSLACK s_HYDROSLACK s_MINUTILSLACK s_FUELSLACK
$loaddc s_bal_supdem s_peak_nz s_peak_ni s_noWindPeak_ni s_limit_maxgen s_limit_mingen s_minutil s_limit_fueluse s_limit_Nrg
$loaddc s_minReq_RenNrg s_minReq_RenCap s_limit_hydro s_tx_capacity



*===============================================================================================
* 3. Collapse dispatch solves to a single average result in cases where variable hydrology was simulated.
*    Conditions to be met in order to collapse results to an average:
*    - scenario to scenarioSet mapping is one-to-one and exists solely for the purpose of introducing variability in hydrology;
*    - each scenario has a weight of 1 in it's mapping to scenario sets, i.e. it's a one-to-one mapping!;
*    - step = dispatch;
*    - hydro sequence type = sequential; and
*    - sequential sequences types are mapped to scenarios.

Set mapStepsToRepSteps(rv,expts,rs,steps) 'Figure out the mapping of steps (timing,reopt,dispatch) to repSteps (timing,reopt,dispatch,avgDispatch)' ;

Parameters
* Transfer s_ parameters (levels and marginals) into r_ parameters -- modify domain by replacing steps with repSteps, or rs.
  r_TOTALCOST(rv,expts,rs,scenSet)                              'Discounted total system costs over all modelled years, $m (objective function value)'
  r_TX(rv,expts,rs,scenSet,r,rr,y,t,lb,scen)                    'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
  r_BTX(rv,expts,rs,scenSet,r,rr,ps,y)                          'Binary variable indicating the current state of a transmission path'
  r_REFURBCOST(rv,expts,rs,scenSet,g,y)                         'Annualised generation plant refurbishment expenditure charge, $'
  r_BUILD(rv,expts,rs,scenSet,g,y)                              'New capacity installed by generating plant and year, MW'
  r_RETIRE(rv,expts,rs,scenSet,g,y)                             'Capacity endogenously retired by generating plant and year, MW'
  r_CAPACITY(rv,expts,rs,scenSet,g,y)                           'Cumulative nameplate capacity at each generating plant in each year, MW'
  r_TXCAPCHARGES(rv,expts,rs,scenSet,r,rr,y)                    'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  r_GEN(rv,expts,rs,scenSet,g,y,t,lb,scen)                      'Generation by generating plant and block, GWh'
  r_VOLLGEN(rv,expts,rs,scenSet,s,y,t,lb,scen)                  'Generation by VOLL plant and block, GWh'
  r_LOSS(rv,expts,rs,scenSet,r,rr,y,t,lb,scen)                  'Transmission losses along each path, MW'
  r_TXPROJVAR(rv,expts,rs,scenSet,tupg,y)                       'Continuous 0-1 variable indicating whether an upgrade project is applied'
  r_TXUPGRADE(rv,expts,rs,scenSet,r,rr,ps,pss,y)                'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
  r_RESV(rv,expts,rs,scenSet,g,rc,y,t,lb,scen)                  'Reserve energy supplied, MWh'
  r_RESVVIOL(rv,expts,rs,scenSet,rc,ild,y,t,lb,scen)            'Reserve energy supply violations, MWh'
  r_RESVCOMPONENTS(rv,expts,rs,scenSet,r,rr,y,t,lb,scen,lvl)    'Non-free reserve components, MW'
  r_RENNRGPENALTY(rv,expts,rs,scenSet,y)                        'Penalty with cost of penaltyViolateRenNrg - used to make renewable energy constraint feasible, GWh'
  r_PEAK_NZ_PENALTY(rv,expts,rs,scenSet,y,scen)                 'Penalty with cost of penaltyViolatePeakLoad - used to make NZ security constraint feasible, MW'
  r_PEAK_NI_PENALTY(rv,expts,rs,scenSet,y,scen)                 'Penalty with cost of penaltyViolatePeakLoad - used to make NI security constraint feasible, MW'
  r_NOWINDPEAK_NI_PENALTY(rv,expts,rs,scenSet,y,scen)           'Penalty with cost of penaltyViolatePeakLoad - used to make NI no wind constraint feasible, MW'
  r_ANNMWSLACK(rv,expts,rs,scenSet,y)                           'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  r_RENCAPSLACK(rv,expts,rs,scenSet,y)                          'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  r_HYDROSLACK(rv,expts,rs,scenSet,y)                           'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  r_MINUTILSLACK(rv,expts,rs,scenSet,y)                         'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  r_FUELSLACK(rv,expts,rs,scenSet,y)                            'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'
  r_bal_supdem(rv,expts,rs,scenSet,r,y,t,lb,scen)               'Balance supply and demand in each region, year, time period and load block'
  r_peak_nz(rv,expts,rs,scenSet,y,scen)                         'Ensure enough capacity to meet peak demand and the winter capacity margin in NZ'
  r_peak_ni(rv,expts,rs,scenSet,y,scen)                         'Ensure enough capacity to meet peak demand in NI subject to contingencies'
  r_noWindPeak_ni(rv,expts,rs,scenSet,y,scen)                   'Ensure enough capacity to meet peak demand in NI  subject to contingencies when wind is low'
  r_limit_maxgen(rv,expts,rs,scenSet,g,y,t,lb,scen)             'Ensure generation in each block does not exceed capacity implied by max capacity factors'
  r_limit_mingen(rv,expts,rs,scenSet,g,y,t,lb,scen)             'Ensure generation in each block exceeds capacity implied by min capacity factors'
  r_minutil(rv,expts,rs,scenSet,g,y,scen)                       'Ensure certain generation plant meets a minimum utilisation'
  r_limit_fueluse(rv,expts,rs,scenSet,f,y,scen)                 'Quantum of each fuel used and possibly constrained, PJ'
  r_limit_nrg(rv,expts,rs,scenSet,f,y,scen)                     'Impose a limit on total energy generated by any one fuel type'
  r_minreq_rennrg(rv,expts,rs,scenSet,y,scen)                   'Impose a minimum requirement on total energy generated from all renewable sources'
  r_minreq_rencap(rv,expts,rs,scenSet,y)                        'Impose a minimum requirement on installed renewable capacity'
  r_limit_hydro(rv,expts,rs,scenSet,g,y,t,scen)                 'Limit hydro generation according to inflows'
  r_tx_capacity(rv,expts,rs,scenSet,r,rr,y,t,lb,scen)           'Calculate the relevant transmission capacity'
* Other parameters
  numScensToAvg(rv,expts)                                       'Count how many scenario sets are to be averaged over for the dispatch simulations'
  wtScensToAvg(rv,expts)                                        'Reciprocal of the count of scenario sets to be averaged over for the dispatch simulations'  ;

mapStepsToRepSteps(rv,expts,rs,steps)$( (ord(rs) = ord(steps))   and sum(scenSet$allNotAvgDispatchSolves(rv,expts,steps,scenSet), 1) ) = yes ;
mapStepsToRepSteps(rv,expts,rs,steps)$( sameas(rs,'avgDispatch') and sum(scenSet$allAvgDispatchSolves(rv,expts,steps,scenSet), 1) ) = yes ;

numScensToAvg(rv,expts) = sum((steps,scenSet)$(sameas(steps,'dispatch') * allAvgDispatchSolves(rv,expts,steps,scenSet)), 1) ;
wtScensToAvg(rv,expts)$numScensToAvg(rv,expts) = 1 / numScensToAvg(rv,expts) ;

loop((rv,expts,rs,steps)$mapStepsToRepSteps(rv,expts,rs,steps),
  if(not sameas(rs,'avgDispatch'),
*   Variable levels
    r_TOTALCOST(rv,expts,rs,scenSet)                           = s_TOTALCOST(rv,expts,steps,scenSet) ;
    r_TX(rv,expts,rs,scenSet,r,rr,y,t,lb,scen)                 = s_TX(rv,expts,steps,scenSet,r,rr,y,t,lb,scen) ;
    r_BTX(rv,expts,rs,scenSet,r,rr,ps,y)                       = s_BTX(rv,expts,steps,scenSet,r,rr,ps,y) ;
    r_REFURBCOST(rv,expts,rs,scenSet,g,y)                      = s_REFURBCOST(rv,expts,steps,scenSet,g,y) ;
    r_BUILD(rv,expts,rs,scenSet,g,y)                           = s_BUILD(rv,expts,steps,scenSet,g,y) ;
    r_RETIRE(rv,expts,rs,scenSet,g,y)                          = s_RETIRE(rv,expts,steps,scenSet,g,y) ;
    r_CAPACITY(rv,expts,rs,scenSet,g,y)                        = s_CAPACITY(rv,expts,steps,scenSet,g,y) ;
    r_TXCAPCHARGES(rv,expts,rs,scenSet,r,rr,y)                 = s_TXCAPCHARGES(rv,expts,steps,scenSet,r,rr,y) ;
    r_GEN(rv,expts,rs,scenSet,g,y,t,lb,scen)                   = s_GEN(rv,expts,steps,scenSet,g,y,t,lb,scen) ;
    r_VOLLGEN(rv,expts,rs,scenSet,s,y,t,lb,scen)               = s_VOLLGEN(rv,expts,steps,scenSet,s,y,t,lb,scen) ;
    r_LOSS(rv,expts,rs,scenSet,r,rr,y,t,lb,scen)               = s_LOSS(rv,expts,steps,scenSet,r,rr,y,t,lb,scen) ;
    r_TXPROJVAR(rv,expts,rs,scenSet,tupg,y)                    = s_TXPROJVAR(rv,expts,steps,scenSet,tupg,y) ;
    r_TXUPGRADE(rv,expts,rs,scenSet,r,rr,ps,pss,y)             = s_TXUPGRADE(rv,expts,steps,scenSet,r,rr,ps,pss,y) ;
    r_RESV(rv,expts,rs,scenSet,g,rc,y,t,lb,scen)               = s_RESV(rv,expts,steps,scenSet,g,rc,y,t,lb,scen) ;
    r_RESVVIOL(rv,expts,rs,scenSet,rc,ild,y,t,lb,scen)         = s_RESVVIOL(rv,expts,steps,scenSet,rc,ild,y,t,lb,scen) ;
    r_RESVCOMPONENTS(rv,expts,rs,scenSet,r,rr,y,t,lb,scen,lvl) = s_RESVCOMPONENTS(rv,expts,steps,scenSet,r,rr,y,t,lb,scen,lvl) ;
    r_RENNRGPENALTY(rv,expts,rs,scenSet,y)                     = s_RENNRGPENALTY(rv,expts,steps,scenSet,y) ;
    r_PEAK_NZ_PENALTY(rv,expts,rs,scenSet,y,scen)              = s_PEAK_NZ_PENALTY(rv,expts,steps,scenSet,y,scen) ;
    r_PEAK_NI_PENALTY(rv,expts,rs,scenSet,y,scen)              = s_PEAK_NI_PENALTY(rv,expts,steps,scenSet,y,scen) ;
    r_NOWINDPEAK_NI_PENALTY(rv,expts,rs,scenSet,y,scen)        = s_NOWINDPEAK_NI_PENALTY(rv,expts,steps,scenSet,y,scen) ;
    r_ANNMWSLACK(rv,expts,rs,scenSet,y)                        = s_ANNMWSLACK(rv,expts,steps,scenSet,y) ;
    r_RENCAPSLACK(rv,expts,rs,scenSet,y)                       = s_RENCAPSLACK(rv,expts,steps,scenSet,y) ;
    r_HYDROSLACK(rv,expts,rs,scenSet,y)                        = s_HYDROSLACK(rv,expts,steps,scenSet,y) ;
    r_MINUTILSLACK(rv,expts,rs,scenSet,y)                      = s_MINUTILSLACK(rv,expts,steps,scenSet,y) ;
    r_FUELSLACK(rv,expts,rs,scenSet,y)                         = s_FUELSLACK(rv,expts,steps,scenSet,y) ;
*   Equation marginals
    r_bal_supdem(rv,expts,rs,scenSet,r,y,t,lb,scen)            = s_bal_supdem(rv,expts,steps,scenSet,r,y,t,lb,scen) ;
    r_peak_nz(rv,expts,rs,scenSet,y,scen)                      = s_peak_nz(rv,expts,steps,scenSet,y,scen) ;
    r_peak_ni(rv,expts,rs,scenSet,y,scen)                      = s_peak_ni(rv,expts,steps,scenSet,y,scen) ;
    r_noWindPeak_ni(rv,expts,rs,scenSet,y,scen)                = s_noWindPeak_ni(rv,expts,steps,scenSet,y,scen) ;
    r_limit_maxgen(rv,expts,rs,scenSet,g,y,t,lb,scen)          = s_limit_maxgen(rv,expts,steps,scenSet,g,y,t,lb,scen) ;
    r_limit_mingen(rv,expts,rs,scenSet,g,y,t,lb,scen)          = s_limit_mingen(rv,expts,steps,scenSet,g,y,t,lb,scen) ;
    r_minutil(rv,expts,rs,scenSet,g,y,scen)                    = s_minutil(rv,expts,steps,scenSet,g,y,scen) ;
    r_limit_fueluse(rv,expts,rs,scenSet,f,y,scen)              = s_limit_fueluse(rv,expts,steps,scenSet,f,y,scen) ;
    r_limit_nrg(rv,expts,rs,scenSet,f,y,scen)                  = s_limit_nrg(rv,expts,steps,scenSet,f,y,scen) ;
    r_minreq_rennrg(rv,expts,rs,scenSet,y,scen)                = s_minreq_rennrg(rv,expts,steps,scenSet,y,scen) ;
    r_minreq_rencap(rv,expts,rs,scenSet,y)                     = s_minreq_rencap(rv,expts,steps,scenSet,y) ;
    r_limit_hydro(rv,expts,rs,scenSet,g,y,t,scen)              = s_limit_hydro(rv,expts,steps,scenSet,g,y,t,scen) ;
    r_tx_capacity(rv,expts,rs,scenSet,r,rr,y,t,lb,scen)        = s_tx_capacity(rv,expts,steps,scenSet,r,rr,y,t,lb,scen) ;
  else
*   Variable levels
    r_TOTALCOST(rv,expts,rs,'avg')                                 = wtScensToAvg(rv,expts) * sum(scenSet, s_TOTALCOST(rv,expts,steps,scenSet)) ;
    r_TX(rv,expts,rs,'avg',r,rr,y,t,lb,'averageDispatch')          = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_TX(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)) ;
    r_BTX(rv,expts,rs,'avg',r,rr,ps,y)                             = wtScensToAvg(rv,expts) * sum(scenSet, s_BTX(rv,expts,steps,scenSet,r,rr,ps,y)) ;
    r_REFURBCOST(rv,expts,rs,'avg',g,y)                            = wtScensToAvg(rv,expts) * sum(scenSet, s_REFURBCOST(rv,expts,steps,scenSet,g,y)) ;
    r_BUILD(rv,expts,rs,'avg',g,y)                                 = wtScensToAvg(rv,expts) * sum(scenSet, s_BUILD(rv,expts,steps,scenSet,g,y)) ;
    r_RETIRE(rv,expts,rs,'avg',g,y)                                = wtScensToAvg(rv,expts) * sum(scenSet, s_RETIRE(rv,expts,steps,scenSet,g,y)) ;
    r_CAPACITY(rv,expts,rs,'avg',g,y)                              = wtScensToAvg(rv,expts) * sum(scenSet, s_CAPACITY(rv,expts,steps,scenSet,g,y)) ;
    r_TXCAPCHARGES(rv,expts,rs,'avg',r,rr,y)                       = wtScensToAvg(rv,expts) * sum(scenSet, s_TXCAPCHARGES(rv,expts,steps,scenSet,r,rr,y)) ;
    r_GEN(rv,expts,rs,'avg',g,y,t,lb,'averageDispatch')            = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_GEN(rv,expts,steps,scenSet,g,y,t,lb,scen)) ;
    r_VOLLGEN(rv,expts,rs,'avg',s,y,t,lb,'averageDispatch')        = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_VOLLGEN(rv,expts,steps,scenSet,s,y,t,lb,scen)) ;
    r_LOSS(rv,expts,rs,'avg',r,rr,y,t,lb,'averageDispatch')        = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_LOSS(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)) ;
    r_TXPROJVAR(rv,expts,rs,'avg',tupg,y)                          = wtScensToAvg(rv,expts) * sum(scenSet, s_TXPROJVAR(rv,expts,steps,scenSet,tupg,y)) ;
    r_TXUPGRADE(rv,expts,rs,'avg',r,rr,ps,pss,y)                   = wtScensToAvg(rv,expts) * sum(scenSet, s_TXUPGRADE(rv,expts,steps,scenSet,r,rr,ps,pss,y)) ;
    r_RESV(rv,expts,rs,'avg',g,rc,y,t,lb,'averageDispatch')        = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_RESV(rv,expts,steps,scenSet,g,rc,y,t,lb,scen)) ;
    r_RESVVIOL(rv,expts,rs,'avg',rc,ild,y,t,lb,'averageDispatch')  = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_RESVVIOL(rv,expts,steps,scenSet,rc,ild,y,t,lb,scen)) ;
    r_RESVCOMPONENTS(rv,expts,rs,'avg',r,rr,y,t,lb,'averageDispatch',lvl) = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_RESVCOMPONENTS(rv,expts,steps,scenSet,r,rr,y,t,lb,scen,lvl)) ;
    r_RENNRGPENALTY(rv,expts,rs,'avg',y)                           = wtScensToAvg(rv,expts) * sum(scenSet, s_RENNRGPENALTY(rv,expts,steps,scenSet,y)) ;
    r_PEAK_NZ_PENALTY(rv,expts,rs,'avg',y,'averageDispatch')       = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_PEAK_NZ_PENALTY(rv,expts,steps,scenSet,y,scen)) ;
    r_PEAK_NI_PENALTY(rv,expts,rs,'avg',y,'averageDispatch')       = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_PEAK_NI_PENALTY(rv,expts,steps,scenSet,y,scen)) ;
    r_NOWINDPEAK_NI_PENALTY(rv,expts,rs,'avg',y,'averageDispatch') = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_NOWINDPEAK_NI_PENALTY(rv,expts,steps,scenSet,y,scen)) ;
    r_ANNMWSLACK(rv,expts,rs,'avg',y)                              = wtScensToAvg(rv,expts) * sum(scenSet, s_ANNMWSLACK(rv,expts,steps,scenSet,y)) ;
    r_RENCAPSLACK(rv,expts,rs,'avg',y)                             = wtScensToAvg(rv,expts) * sum(scenSet, s_RENCAPSLACK(rv,expts,steps,scenSet,y)) ;
    r_HYDROSLACK(rv,expts,rs,'avg',y)                              = wtScensToAvg(rv,expts) * sum(scenSet, s_HYDROSLACK(rv,expts,steps,scenSet,y)) ;
    r_MINUTILSLACK(rv,expts,rs,'avg',y)                            = wtScensToAvg(rv,expts) * sum(scenSet, s_MINUTILSLACK(rv,expts,steps,scenSet,y)) ;
    r_FUELSLACK(rv,expts,rs,'avg',y)                               = wtScensToAvg(rv,expts) * sum(scenSet, s_FUELSLACK(rv,expts,steps,scenSet,y)) ;
*   Equation marginals
    r_bal_supdem(rv,expts,rs,'avg',r,y,t,lb,'averageDispatch')     = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_bal_supdem(rv,expts,steps,scenSet,r,y,t,lb,scen)) ;
    r_peak_nz(rv,expts,rs,'avg',y,'averageDispatch')               = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_peak_nz(rv,expts,steps,scenSet,y,scen)) ;
    r_peak_ni(rv,expts,rs,'avg',y,'averageDispatch')               = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_peak_ni(rv,expts,steps,scenSet,y,scen)) ;
    r_noWindPeak_ni(rv,expts,rs,'avg',y,'averageDispatch')         = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_noWindPeak_ni(rv,expts,steps,scenSet,y,scen)) ;
    r_limit_maxgen(rv,expts,rs,'avg',g,y,t,lb,'averageDispatch')   = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_limit_maxgen(rv,expts,steps,scenSet,g,y,t,lb,scen)) ;
    r_limit_mingen(rv,expts,rs,'avg',g,y,t,lb,'averageDispatch')   = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_limit_mingen(rv,expts,steps,scenSet,g,y,t,lb,scen)) ;
    r_minutil(rv,expts,rs,'avg',g,y,'averageDispatch')             = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_minutil(rv,expts,steps,scenSet,g,y,scen)) ;
    r_limit_fueluse(rv,expts,rs,'avg',f,y,'averageDispatch')       = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_limit_fueluse(rv,expts,steps,scenSet,f,y,scen)) ;
    r_limit_nrg(rv,expts,rs,'avg',f,y,'averageDispatch')           = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_limit_nrg(rv,expts,steps,scenSet,f,y,scen)) ;
    r_minreq_rennrg(rv,expts,rs,'avg',y,'averageDispatch')         = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_minreq_rennrg(rv,expts,steps,scenSet,y,scen)) ;
    r_minreq_rencap(rv,expts,rs,'avg',y)                           = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_minreq_rencap(rv,expts,steps,scenSet,y)) ;
    r_limit_hydro(rv,expts,rs,'avg',g,y,t,'averageDispatch')       = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_limit_hydro(rv,expts,steps,scenSet,g,y,t,scen)) ;
    r_tx_capacity(rv,expts,rs,'avg',r,rr,y,t,lb,'averageDispatch') = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_tx_capacity(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)) ;
*   Input parameters defined on scenarios.
    totalFuelCost(rv,g,y,'averageDispatch')                        = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * totalFuelCost(rv,g,y,scen)) ;
    CO2taxByPlant(rv,g,y,'averageDispatch')                        = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * CO2taxByPlant(rv,g,y,scen)) ;
    SRMC(rv,g,y,'averageDispatch')                                 = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * SRMC(rv,g,y,scen)) ;
    NrgDemand(rv,r,y,t,lb,'averageDispatch')                       = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * NrgDemand(rv,r,y,t,lb,scen)) ;
    peakLoadNZ(rv,y,'averageDispatch')                             = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * peakLoadNZ(rv,y,scen)) ;
    peakLoadNI(rv,y,'averageDispatch')                             = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * peakLoadNI(rv,y,scen)) ;
  ) ;
) ;

option s_TOTALCOST:3:0:2, r_TOTALCOST:3:0:2, allNotAvgDispatchSolves:0:0:1, allAvgDispatchSolves:0:0:1, mapStepsToRepSteps:0:0:1 ;
Display allNotAvgDispatchSolves, allAvgDispatchSolves, mapStepsToRepSteps, numScensToAvg, wtScensToAvg, s_TOTALCOST, r_TOTALCOST ;
* r_TX, r_BTX, r_REFURBCOST, r_BUILD, r_RETIRE, r_CAPACITY, r_TXCAPCHARGES, r_GEN, r_VOLLGEN
* r_LOSS, r_TXPROJVAR,  r_TXUPGRADE, r_RESV, r_RESVVIOL, r_RESVCOMPONENTS, r_RENNRGPENALTY, r_PEAK_NZ_PENALTY, r_PEAK_NI_PENALTY, r_NOWINDPEAK_NI_PENALTY
* r_ANNMWSLACK, r_RENCAPSLACK, r_HYDROSLACK, r_MINUTILSLACK, r_FUELSLACK
* r_bal_supdem, r_peak_nz, r_peak_ni, r_noWindPeak_ni, r_limit_maxgen, r_limit_mingen, r_minutil
* r_limit_fueluse, r_limit_nrg, r_minreq_rennrg, r_minreq_rencap, r_limit_hydro, r_tx_capacity
* totalFuelCost, CO2taxByPlant, SRMC, NrgDemand



*===============================================================================================
* 4. Undertake the declarations and calculations necessary to prepare all that is to be reported.

Sets
  objc                                                     'Objective function components'
                                                            / obj_Check      'Check that sum of all components including TOTALCOST less TOTALCOST equals TOTALCOST'
                                                              obj_total      'Objective function value'
                                                              obj_gencapex   'Discounted levelised generation plant capital costs'
                                                              obj_refurb     'Discounted levelised refurbishment capital costs'
                                                              obj_txcapex    'Discounted levelised transmission capital costs'
                                                              obj_fixOM      'After tax discounted fixed costs at generation plant'
                                                              obj_varOM      'After tax discounted variable costs at generation plant'
                                                              obj_hvdc       'After tax discounted HVDC charges'
                                                              VOLLcost       'After tax discounted value of lost load'
                                                              obj_rescosts   'After tax discounted reserve costs at generation plant'
                                                              obj_resvviol   'Penalty cost of failing to meet reserves'
                                                              obj_nfrcosts   'After tax discounted cost of non-free reserve cover for HVDC'
                                                              obj_Penalties  'Value of all penalties'
                                                              obj_Slacks     'Value of all slacks' /
  repDom(rv,expts,rs,scenSet)                              'The runVersions-experiments-repSteps-scenarioSets domain to be reported on - key it off of r_TOTALCOST(rv,expts,rs,scenSet)'
  sc(scen)                                                 '(Dynamically) selected subsets of elements of scenarios'
  existBuildOrRetire(rv,expts,rs,scenSet,g,y)              'Plant and years in which any plant either exists, is built, is refurbished, or is retired'
  ;

Parameters
  cntr                                                     'A counter'
  unDiscFactor(rv,y,t)                                     "Factor to adjust or 'un-discount' and 'un-tax' shadow prices or revenues - by period and year"
  unDiscFactorYr(rv,y)                                     "Factor to adjust or 'un-discount' and 'un-tax' shadow prices or revenues - by year (use last period of year)"
  scenarioWeight(scen)                                     'Individual scenario weights'
  objComponents(*,*,*,*,objc)                              'Components of objective function value'
* Capacity and capex
  genBuiltByPlantYear(*,*,*,*,g,y)                         'Generating plant built by plant and year, MW'
  genBuiltByPlantTechFuelRegionYear(*,*,*,*,g,k,f,r,y)     'Generating plant built by plant, technology, fuel, region and year, MW'
  genBuiltByTechRegionYear(*,*,*,*,k,r,y)                  'Generating plant built by technology, region and year, MW'
  genBuiltByTechYear(*,*,*,*,k,y)                          'Generating plant built by technology and year, MW'
  genBuiltByRegionYear(*,*,*,*,r,y)                        'Generating plant built by region and year, MW'
  genBuiltByTechRegion(*,*,*,*,k,r)                        'Generating plant built by technology and region, MW'
  genBuiltByTech(*,*,*,*,k)                                'Generating plant built by technology, MW'
  genBuiltByRegion(*,*,*,*,r)                              'Generating plant built by region, MW'
  genBuiltByYear(*,*,*,*,y)                                'Generating plant built by year, MW'

  capacityByPlantYear(*,*,*,*,g,y)                         'Capacity by plant and year, MW'
  capacityByPlantTechFuelRegionYear(*,*,*,*,g,k,f,r,y)     'Capacity by plant, technology, fuel, region and year, MW'
  capacityByTechRegionYear(*,*,*,*,k,r,y)                  'Capacity by technology, region and year, MW'
  capacityByTechYear(*,*,*,*,k,y)                          'Capacity by technology and year, MW'
  capacityByRegionYear(*,*,*,*,r,y)                        'Capacity by region and year, MW'

  txCapacityByYear(*,*,*,*,r,rr,y)                         'Transmission capacity by path and year, MW'
  txCapexByProjectPathStateYear(*,*,*,*,tupg,r,rr,pss,y)   'Transmission capital expenditure by project, path, state and year, $m'
  txCapexByProjectYear(*,*,*,*,tupg,y)                     'Transmission capital expenditure by project and year, $m'

* Operation
  genByPlantLoadBlockYear(*,*,*,*,g,y,t,lb)                'Generation by plant, load block and year, GWh'
  genByPlantYear(*,*,*,*,g,y)                              'Generation by plant and year, GWh'
  genByPlantTechFuelRegionYear(*,*,*,*,g,k,f,r,y)          'Generation by plant, technology, fuel, region and year, GWh'
  genByTechRegionYear(*,*,*,*,k,r,y)                       'Generation by technology, region and year, GWh'
  genByTechYear(*,*,*,*,k,y)                               'Generation by technology and year, GWh'
  genByRegionYear(*,*,*,*,r,y)                             'Generation by region and year, GWh'
  genByTechRegion(*,*,*,*,k,r)                             'Generation by technology and region, GWh'
  genByTech(*,*,*,*,k)                                     'Generation by technology, GWh'
  genByRegion(*,*,*,*,r)                                   'Generation by region, GWh'
  genByYear(*,*,*,*,y)                                     'Generation by year, GWh'
  genAtTopOfLoadBlockYear(*,*,*,*,g,y,t,lb)                'Generation in top two blocks of LDC by plant and year, GWh'
  genAtTopOfLoadBlockPltTechFuelRegYr(*,*,*,*,g,k,f,r,y,t) 'Generation in top two blocks of LDC by plant, technology, fuel, region and year, GWh'
  peakDemandNZ(*,*,*,*,y,*)                                'Peak load for New Zealand by year, MW'
  peakDemandNI(*,*,*,*,y,*)                                'Peak load for the North Island by year, MW'
  peakDemandNWNI(*,*,*,*,y,*)                              'Peak load with no wind for the North Island by year, MW'
  txByPathLoadBlockYear(*,*,*,*,r,rr,y,t,lb)               'Interregional transmission by load block and year, GWh'
  txByPathYear(*,*,*,*,r,rr,y)                             'Interregional transmission by year, GWh'
  txFromRegionByYear(*,*,*,*,r,y)                          'Transmission from each region by year, GWh'
  txIntoRegionByYear(*,*,*,*,r,y)                          'Transmission to each region by year, GWh'
  txByYear(*,*,*,*,y)                                      'Total transmission by year, GWh'

  txLossesByPathLoadBlockYear(*,*,*,*,r,rr,y,t,lb)         'Interregional transmission losses by load block and year, GWh'
  txLossesByPathYear(*,*,*,*,r,rr,y)                       'Interregional transmission losses by year, GWh'
  txLossesFromRegionByYear(*,*,*,*,r,y)                    'Transmission losses on flows from each region by year, GWh'
  txLossesIntoRegionByYear(*,*,*,*,r,y)                    'Transmission losses on flows to each region by year, GWh'
  txLossesByYear(*,*,*,*,y)                                'Total transmission losses by year, GWh'

  energyPrice(*,*,*,*,r,y)                                 'Time-weighted energy price by region and year, $/MWh'

  loadByRegionLoadBlockYear(*,*,*,*,r,y,t,lb)              'Load by region, load block and year, GWh'
  loadByRegionYear(*,*,*,*,r,y)                            'Load by region and year, GWh'
  loadByYear(*,*,*,*,y)                                    'Load by year, GWh'
  ;

repDom(rv,expts,rs,scenSet)$r_TOTALCOST(rv,expts,rs,scenSet) = yes ;

existBuildOrRetire(rv,expts,rs,scenSet,g,y)$( exist(rv,g) * firstYr(y) ) = yes ;
existBuildOrRetire(rv,expts,rs,scenSet,g,y)$( r_BUILD(rv,expts,rs,scenSet,g,y) or r_RETIRE(rv,expts,rs,scenSet,g,y) or exogMWretired(rv,g,y) ) = yes ;

unDiscFactor(rv,y,t)$PVfacG(rv,y,t) = 1 / ( (1 - taxRate) * PVfacG(rv,y,t) ) ;
unDiscFactorYr(rv,y) = sum(t$( ord(t) = card(t) ), unDiscFactor(rv,y,t)) ;

* This loop is on the domain of all that is loaded into GEMreports and is to be reported on.
loop(repDom(rv,expts,rs,scenSet),

* Initialise sc to contain all scenarios in this particular scenario set.
  sc(scen) = no ;
  sc(scen)$mapScenarios(scenSet,scen) = yes ;

* Select the weights for all scenarios in this particular scenario set.
  scenarioWeight(sc) = 0 ;
  scenarioWeight(sc) = weightScenariosBySet(scenSet,sc) ;

* Objective function components
  objComponents(repDom,'obj_total')     = r_TOTALCOST(repDom) ;
  objComponents(repDom,'obj_gencapex')  = 1e-6 * sum((y,firstPeriod(t),possibleToBuild(rv,g)), PVfacG(rv,y,t) * ensembleFactor(rv,g) * capCharge(rv,g,y) * r_CAPACITY(repDom,g,y) ) ;
  objComponents(repDom,'obj_refurb')    = 1e-6 * sum((y,firstPeriod(t),possibleToRefurbish(rv,g))$refurbCapCharge(rv,g,y), PVfacG(rv,y,t) * r_REFURBCOST(repDom,g,y) ) ;
  objComponents(repDom,'obj_txcapex')   = sum((paths,y,firstPeriod(t)), PVfacT(rv,y,t) * r_TXCAPCHARGES(repDom,paths,y) ) ;
  objComponents(repDom,'obj_fixOM')     = 1e-3 * (1 - taxRate) * sum((g,y,t), PVfacG(rv,y,t) * ( 1/card(t) ) * ensembleFactor(rv,g) * i_fixedOM(rv,g) * r_CAPACITY(repDom,g,y) ) ;
  objComponents(repDom,'obj_varOM')     = 1e-3 * (1 - taxRate) * sum((validYrOperate(rv,g,y),t,lb,sc), scenarioWeight(sc) * PVfacG(rv,y,t) * ensembleFactor(rv,g) * srmc(rv,g,y,sc) * r_GEN(repDom,g,y,t,lb,sc) ) ;
  objComponents(repDom,'obj_hvdc')      = 1e-3 * (1 - taxRate) * sum((y,t), PVfacG(rv,y,t) * ( 1/card(t) ) * (
                                               sum((g,k,o)$((not demandGen(rv,k)) * mapg_k(g,k) * sigen(rv,g) * possibleToBuild(rv,g) * mapg_o(g,o)), i_HVDCshr(rv,o) * ensembleFactor(rv,g) * i_HVDClevy(rv,y) * r_CAPACITY(repDom,g,y)) ) ) ;
  objComponents(repDom,'VOLLcost')      = 1e-3 * (1 - taxRate) * VOLLcost * sum((s,y,t,lb,sc), scenarioWeight(sc) * PVfacG(rv,y,t) * r_VOLLGEN(repDom,s,y,t,lb,sc) ) ;
  objComponents(repDom,'obj_rescosts')  = 1e-6 * (1 - taxRate) * sum((g,rc,y,t,lb,sc), PVfacG(rv,y,t) * scenarioWeight(sc) * i_plantReservesCost(rv,g,rc) * ensembleFactor(rv,g) * r_RESV(repDom,g,rc,y,t,lb,sc) ) ;
  objComponents(repDom,'obj_resvviol')  = 1e-6 * sum((rc,ild,y,t,lb,sc), scenarioWeight(sc) * r_RESVVIOL(repDom,rc,ild,y,t,lb,sc) * penaltyViolateReserves(rv,ild,rc) ) ;
  objComponents(repDom,'obj_nfrcosts')  = 1e-6 * (1 - taxRate) * sum((y,t,lb), PVfacG(rv,y,t) * (
                                               sum((paths,lvl,sc)$( nwd(paths) or swd(paths) ), hoursPerBlock(rv,t,lb) * scenarioWeight(sc) * r_RESVCOMPONENTS(repDom,paths,y,t,lb,sc,lvl) * pNFresvcost(rv,paths,lvl) ) ) ) ;
  objComponents(repDom,'obj_Penalties') = sum((y,sc), scenarioWeight(sc) * (
                                              1e-3 * penaltyViolateRenNrg * r_RENNRGPENALTY(repDom,y) +
                                              1e-6 * penaltyViolatePeakLoad * ( r_PEAK_NZ_PENALTY(repDom,y,sc) + r_PEAK_NI_PENALTY(repDom,y,sc) + r_NOWINDPEAK_NI_PENALTY(repDom,y,sc) ) )
                                          ) ;
  objComponents(repDom,'obj_Slacks')    = slackCost * sum(y, r_ANNMWSLACK(repDom,y) + r_RENCAPSLACK(repDom,y) + r_HYDROSLACK(repDom,y) + r_MINUTILSLACK(repDom,y) + r_FUELSLACK(repDom,y) ) ;

  objComponents(repDom,'obj_Check')     = sum(objc, objComponents(repDom,objc)) - objComponents(repDom,'obj_total') ;


* Capacity and capex
  genBuiltByPlantYear(repDom,g,y) = r_BUILD(repDom,g,y) ;

  genBuiltByPlantTechFuelRegionYear(repDom,g,k,f,r,y)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) ) = genBuiltByPlantYear(repDom,g,y) ;

  genBuiltByTechRegionYear(repDom,k,r,y) = sum(g$( mapg_k(g,k) * mapg_r(g,r) ), genBuiltByPlantYear(repDom,g,y)) ;

  genBuiltByTechYear(repDom,k,y) = sum(r, genBuiltByTechRegionYear(repDom,k,r,y)) ;

  genBuiltByRegionYear(repDom,r,y) = sum(k, genBuiltByTechRegionYear(repDom,k,r,y)) ;

  genBuiltByTechRegion(repDom,k,r) = sum(y, genBuiltByTechRegionYear(repDom,k,r,y)) ;

  genBuiltByTech(repDom,k) = sum(y, genBuiltByTechYear(repDom,k,y)) ;

  genBuiltByRegion(repDom,r) = sum(y, genBuiltByRegionYear(repDom,r,y)) ;

  genBuiltByYear(repDom,y) = sum(g, genBuiltByPlantYear(repDom,g,y)) ;

  capacityByPlantYear(repDom,g,y) = r_CAPACITY(repDom,g,y) ;

  capacityByPlantTechFuelRegionYear(repDom,g,k,f,r,y)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) ) = capacityByPlantYear(repDom,g,y) ;

  capacityByTechRegionYear(repDom,k,r,y) = sum(g$( mapg_k(g,k) * mapg_r(g,r) ), capacityByPlantYear(repDom,g,y)) ;

  capacityByTechYear(repDom,k,y) = sum(r, capacityByTechRegionYear(repDom,k,r,y)) ;

  capacityByRegionYear(repDom,r,y) = sum(k, capacityByTechRegionYear(repDom,k,r,y)) ;

  txCapacityByYear(repDom,paths,y) = sum(ps, i_txCapacity(rv,paths,ps) * r_BTX(repDom,paths,ps,y)) ;

  txCapexByProjectPathStateYear(repDom,tupg,paths,pss,y)$( r_TXPROJVAR(repDom,tupg,y) * sum(ps, r_TXUPGRADE(repDom,paths,ps,pss,y)) ) =
    sum(transitions(rv,tupg,paths,ps,pss), r_TXUPGRADE(repDom,paths,ps,pss,y) * txCapitalCost(rv,paths,pss)) ;

  txCapexByProjectYear(repDom,tupg,y)$r_TXPROJVAR(repDom,tupg,y) =
    sum(transitions(rv,tupg,paths,ps,pss), txCapexByProjectPathStateYear(repDom,tupg,paths,pss,y)) ;


* Operation
  genByPlantLoadBlockYear(repDom,g,y,t,lb) = sum(sc, scenarioWeight(sc) * r_GEN(repDom,g,y,t,lb,sc)) ;

  genByPlantYear(repDom,g,y) = sum((t,lb), genByPlantLoadBlockYear(repDom,g,y,t,lb)) ;

  genByPlantTechFuelRegionYear(repDom,g,k,f,r,y)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) ) = genByPlantYear(repDom,g,y) ;

  genByTechRegionYear(repDom,k,r,y) = sum(g$( mapg_k(g,k) * mapg_r(g,r) ), genByPlantYear(repDom,g,y)) ;

  genByTechYear(repDom,k,y) = sum(r, genByTechRegionYear(repDom,k,r,y)) ;

  genByRegionYear(repDom,r,y) = sum(k, genByTechRegionYear(repDom,k,r,y)) ;

  genByTechRegion(repDom,k,r) =  sum(y, genByTechRegionYear(repDom,k,r,y)) ;

  genByTech(repDom,k) =  sum(y, genByTechYear(repDom,k,y)) ;

  genByRegion(repDom,r) = sum(y, genByRegionYear(repDom,r,y)) ;

  genByYear(repDom,y) = sum(g, genByPlantYear(repDom,g,y)) ;

  genAtTopOfLoadBlockYear(repDom,g,y,t,lb)$( ord(lb) < 3 ) = genByPlantLoadBlockYear(repDom,g,y,t,lb) ;

  genAtTopOfLoadBlockPltTechFuelRegYr(repDom,g,k,f,r,y,t)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) ) = sum(lb, genAtTopOfLoadBlockYear(repDom,g,y,t,lb)) ;

  peakDemandNZ(repDom,y,'LHSpenalty') = sum(sc, scenarioWeight(sc) * r_PEAK_NZ_PENALTY(repDom,y,sc)) ;
  peakDemandNZ(repDom,y,'LHS')        = sum(g, peakConPlant(rv,g,y) * r_CAPACITY(repDom,g,y)) - i_winterCapacityMargin(rv,y) - i_SIACrisk(rv,y) -
                                        i_fkSI(rv,y) - i_HVDClossesAtMaxXfer(rv,y) ;
  peakDemandNZ(repDom,y,'RHS')        = sum(sc, scenarioWeight(sc) * peakLoadNZ(rv,y,sc)) ;
  peakDemandNZ(repDom,y,'Surplus%')$peakDemandNZ(repDom,y,'RHS') =
                                        100 * ( peakDemandNZ(repDom,y,'LHSpenalty') + peakDemandNZ(repDom,y,'LHS') - peakDemandNZ(repDom,y,'RHS') ) / peakDemandNZ(repDom,y,'RHS') ;


  peakDemandNI(repDom,y,'LHSpenalty') = sum(sc, scenarioWeight(sc) * r_PEAK_NI_PENALTY(repDom,y,sc)) ;
  peakDemandNI(repDom,y,'LHS')        = sum(nigen(g), peakConPlant(rv,g,y) * r_CAPACITY(repDom,g,y)) + i_largestGenerator(rv,y) - i_winterCapacityMargin(rv,y) +
                                        sum(allowedStates(rv,paths,ps)$nwd(paths), i_txCapacityPO(rv,paths,ps) * r_BTX(repDom,paths,ps,y)) ;
  peakDemandNI(repDom,y,'RHS')        = sum(sc, scenarioWeight(sc) * peakLoadNI(rv,y,sc)) ;
  peakDemandNI(repDom,y,'Surplus%')$peakDemandNI(repDom,y,'RHS') =
                                        100 * ( peakDemandNI(repDom,y,'LHSpenalty') + peakDemandNI(repDom,y,'LHS') - peakDemandNI(repDom,y,'RHS') ) / peakDemandNI(repDom,y,'RHS') ;

  peakDemandNWNI(repDom,y,'LHSpenalty') = sum(sc, scenarioWeight(sc) * r_NOWINDPEAK_NI_PENALTY(repDom,y,sc)) ;
  peakDemandNWNI(repDom,y,'LHS')        = sum(mapg_k(g,k)$( nigen(g) and (not wind(k)) ), NWpeakConPlant(rv,g,y) * r_CAPACITY(repDom,g,y)) - i_fkNI(rv,y) +
                                          sum(allowedStates(rv,paths,ps)$nwd(paths), i_txCapacityPO(rv,paths,ps) * r_BTX(repDom,paths,ps,y)) ;
  peakDemandNWNI(repDom,y,'RHS')        = sum(sc, scenarioWeight(sc) * peakLoadNI(rv,y,sc)) ;
  peakDemandNWNI(repDom,y,'Surplus%')$peakDemandNWNI(repDom,y,'RHS') =
                                          100 * ( peakDemandNWNI(repDom,y,'LHSpenalty') + peakDemandNWNI(repDom,y,'LHS') - peakDemandNWNI(repDom,y,'RHS') ) / peakDemandNWNI(repDom,y,'RHS') ;

  txByPathLoadBlockYear(repDom,paths,y,t,lb) = 1e-3 * sum(sc, scenarioWeight(sc) * hoursPerBlock(rv,t,lb) * r_TX(repDom,paths,y,t,lb,sc)) ;

  txByPathYear(repDom,paths,y) = sum((t,lb), txByPathLoadBlockYear(repDom,paths,y,t,lb)) ;

  txFromRegionByYear(repDom,r,y) = sum(paths(r,rr), txByPathYear(repDom,paths,y)) ;

  txIntoRegionByYear(repDom,r,y) = sum(paths(rr,r), txByPathYear(repDom,paths,y)) ;

  txByYear(repDom,y) = sum(paths, txByPathYear(repDom,paths,y)) ;

  txLossesByPathLoadBlockYear(repDom,paths,y,t,lb) = 1e-3 * sum(sc, scenarioWeight(sc) * hoursPerBlock(rv,t,lb) * r_LOSS(repDom,paths,y,t,lb,sc)) ;

  txLossesByPathYear(repDom,paths,y) = sum((t,lb), txLossesByPathLoadBlockYear(repDom,paths,y,t,lb)) ;

  txLossesFromRegionByYear(repDom,r,y) = sum(paths(r,rr), txLossesByPathYear(repDom,paths,y)) ;

  txLossesIntoRegionByYear(repDom,r,y) = sum(paths(rr,r), txLossesByPathYear(repDom,paths,y)) ;

  txLossesByYear(repDom,y) = sum(paths, txLossesByPathYear(repDom,paths,y)) ;


  energyPrice(repDom,r,y) = 1e3 * sum((t,lb,sc), unDiscFactor(rv,y,t) * hoursPerBlock(rv,t,lb) * r_bal_supdem(repDom,r,y,t,lb,sc)) / sum((t,lb), hoursPerBlock(rv,t,lb)) ;

  loadByRegionLoadBlockYear(repDom,r,y,t,lb) = sum(sc, scenarioWeight(sc) * NrgDemand(rv,r,y,t,lb,sc)) ;

  loadByRegionYear(repDom,r,y) = sum((t,lb), loadByRegionLoadBlockYear(repDom,r,y,t,lb)) ;

  loadByYear(repDom,y) = sum(r, loadByRegionYear(repDom,r,y)) ;

) ;

option repDom:0:0:1 ;
Display repDom, weightScenariosBySet, objComponents, genBuiltByTech, genBuiltByRegion
* genBuiltByTechRegionYear, capacityByTechRegionYear, capacityByTechYear, capacityByRegionYear
* txUpgradeYearByProjectAndPath, txCapacityByYear, txCapexByProjectYear
* loadByRegionAndYear, genByTechRegionYear, txByRegionYear, txLossesByRegionYear, energyPrice
 ;

* Put output in a GDX file.
Execute_Unload "%primaryOutput%\rep%reportName%\All results - %reportName%.gdx",
 rv expts repSteps scenSet scen y t lb r k g tupg ps existBuildOrRetire unDiscFactor
 allNotAvgDispatchSolves allAvgDispatchSolves mapStepsToRepSteps repDom weightScenariosBySet objComponents
 genBuiltByPlantYear genBuiltByPlantTechFuelRegionYear genBuiltByTechRegionYear genBuiltByTechYear genBuiltByRegionYear
 genBuiltByTechRegion  genBuiltByTech genBuiltByRegion genBuiltByYear
 capacityByPlantYear capacityByPlantTechFuelRegionYear capacityByTechRegionYear capacityByTechYear capacityByRegionYear
 txCapacityByYear, txCapexByProjectPathStateYear, txCapexByProjectYear
 genByPlantLoadBlockYear genByPlantYear genByPlantTechFuelRegionYear genByTechRegionYear genByTechYear
 genByRegionYear genByTechRegion genByTech genByRegion genByYear
 genAtTopOfLoadBlockYear, genAtTopOfLoadBlockPltTechFuelRegYr peakDemandNZ peakDemandNI peakDemandNWNI
 txByPathLoadBlockYear txByPathYear txFromRegionByYear txIntoRegionByYear txByYear
 txLossesByPathLoadBlockYear txLossesByPathYear txLossesFromRegionByYear txLossesIntoRegionByYear txLossesByYear
 energyPrice loadByRegionLoadBlockYear loadByRegionYear loadByYear
 ;


$ontext
computations yet to be put in loop above.
Parameters
  minEnergyPrice(*,*,*,*,g,y)                       'Shadow price off minimum scedulable hydro generation constraint, $/MWh [need to check units and test that this works]'
  minUtilEnergyPrice(*,*,*,*,g,y)                   'Shadow price off minimum utilisation constraint, $/MWh [need to check units and test that this works]'
  peakNZPrice(*,*,*,*,y)                            'Shadow price off peak NZ constraint, $/kW'
  peakNIPrice(*,*,*,*,y)                            'Shadow price off peak NI constraint, $/kW'
  peaknoWindNIPrice(*,*,*,*,y)                      'Shadow price off peak no wind NI constraint, $/kW'
  renewEnergyShrPrice(*,*,*,*,y)                    'Shadow price off the minimum renewable energy share constraint, $/GWh [need to check units and test that this works]'
  renewCapacityShrPrice(*,*,*,*,y)                  'Shadow price off the minimum renewable capacity share constraint, $/kW [need to check units and test that this works]'
  fuelPrice(*,*,*,*,f,y)                            'Shadow price off limit on fuel use constraint, $/GJ [need to check units and test that this works]'
  energyLimitPrice(*,*,*,*,f,y)                     'Shadow price off limit on total energy from any one fuel constraint, $/MWh  [need to check units and test that this works]'
*  s_limit_maxgen(runVersions,experiments,steps,scenSet,g,y,t,lb,scen)          'Ensure generation in each block does not exceed capacity implied by max capacity factors'
*  s_limit_hydro(runVersions,experiments,steps,scenSet,g,y,t,scen)              'Limit hydro generation according to inflows'
*  s_tx_capacity(runVersions,experiments,steps,scenSet,r,rr,y,t,lb,scen)        'Calculate the relevant transmission capacity' ;
  ;

loop(repDomLd(rv,expts,steps,scenSet),

  minEnergyPrice(repDomLd,g,y) = 1e3 * sum((t,lb,sc), unDiscFactor(rv,y,t) * hoursPerBlock(rv,t,lb) * s_limit_mingen(repDomLd,g,y,t,lb,sc)) / sum((t,lb), hoursPerBlock(rv,t,lb)) ;

  minUtilEnergyPrice(repDomLd,g,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_minutil(repDomLd,g,y,sc)) ;

  peakNZPrice(repDomLd,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_peak_nz(repDomLd,y,sc) ) ;

  peakNIPrice(repDomLd,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_peak_ni(repDomLd,y,sc) ) ;

  peaknoWindNIPrice(repDomLd,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_noWindPeak_ni(repDomLd,y,sc) ) ;

  renewEnergyShrPrice(repDomLd,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_minreq_rennrg(repDomLd,y,sc)) ;

  renewCapacityShrPrice(repDomLd,y) = 1e3 * unDiscFactorYr(rv,y) * s_minreq_rencap(repDomLd,y) ;

  fuelPrice(repDomLd,f,y) = -1 * unDiscFactorYr(rv,y) * sum(sc, s_limit_fueluse(repDomLd,f,y,sc) ) ;

  energyLimitPrice(repDomLd,f,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_limit_nrg(repDomLd,f,y,sc) ) ;

) ;
$offtext



*===============================================================================================
* 5. Write selected results to CSV files.

* a) Set descriptions
put setDescriptions 'Set descriptions (and RGB codes where applicable)' ;
put // 'Run versions'      loop(rv,    put / rv.tl, rv.te(rv) loop((red,green,blue)$runVersionColor(rv,red,green,blue), put red.tl:3:0, green.tl:3:0, blue.tl:3:0 ) ) ;
put // 'Experiments'       loop(expts, put / expts.tl, expts.te(expts)) ;
put // 'Solve steps'       loop(rs,    put / rs.tl, rs.te(rs)) ;
put // 'Technologies'      loop(k,     put / k.tl, k.te(k) loop((red,green,blue)$techColor(k,red,green,blue), put red.tl:3:0, green.tl:3:0, blue.tl:3:0 ) ) ;
put // 'Regions'           loop(r,     put / r.tl, r.te(r)) ;
put // 'Aggregate regions' loop(aggR,  put / aggR.tl, aggR.te(aggR)) ;
put // 'Scenario sets'     loop(scenSet, put / scenSet.tl, scenSet.te(scenSet)) ;


* b) Objective function value breakdown
put objBrkDown 'Objective function value breakdown, all values are $million' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' loop(objc, put objc.tl ) ;
loop(repDom(rv,expts,rs,scenSet)$sum(objc, objComponents(repDom,objc)),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl loop(objc, put objComponents(repDom,objc)) ;
) ;
put // 'Descriptions of objective function components' loop(objc, put / objc.tl, objc.te(objc)) ;


* c) Plant built by plant, technology, fuel, region and year (MW)
put plantBuilt 'Plant built by plant, technology, fuel, region and year (MW)' /
               'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Plant' 'Technology' 'Fuel' 'Region' loop(y, put y.tl ) ;
loop((repDom(rv,expts,rs,scenSet),g,k,f,r)$sum(y, genBuiltByPlantTechFuelRegionYear(repDom,g,k,f,r,y)),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, g.tl, k.tl, f.tl, r.tl ;
  loop(y,
    if(genBuiltByPlantTechFuelRegionYear(repDom,g,k,f,r,y) > 0,
      put genBuiltByPlantTechFuelRegionYear(repDom,g,k,f,r,y) ;
    else
      put '' ;
    ) ;
  ) ;
) ;



* x) Transmission capital expenditure by project, path, state and year, $m
put txCapex 'Transmission capital expenditure by project, path, state and year ($m)' /
            'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Project' 'From region' 'To region' 'Upgrade state' loop(y, put y.tl ) ;
loop((repDom(rv,expts,rs,scenSet),tupg,r,rr,ps)$sum(y, txCapexByProjectPathStateYear(repDom,tupg,r,rr,ps,y)),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, tupg.tl, r.tl, rr.tl, ps.tl ;
  loop(y,
    if(txCapexByProjectPathStateYear(repDom,tupg,r,rr,ps,y) > 0,
      put txCapexByProjectPathStateYear(repDom,tupg,r,rr,ps,y) ;
    else
      put '' ;
    ) ;
  ) ;
) ;



* x) Generation (GWh)
put genOutput 'Generation by plant, technology, fuel, region and year (GWh)' /
            'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Plant' 'Technology' 'Fuel' 'Region' loop(y, put y.tl ) ;
loop((repDom(rv,expts,rs,scenSet),g,k,f,r)$( mapg_k(g,k) * mapg_f(g,f) and sum(y, genByPlantTechFuelRegionYear(rv,expts,rs,scenSet,g,k,f,r,y)) ),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, g.tl, k.tl, f.tl, r.tl ;
  loop(y,
    if(genByPlantTechFuelRegionYear(rv,expts,rs,scenSet,g,k,f,r,y) > 0,
      put genByPlantTechFuelRegionYear(rv,expts,rs,scenSet,g,k,f,r,y) ;
    else
      put '' ;
    ) ;
  ) ;
) ;


* x) Transmission flows (GWh)
put txFlows 'Transmission flows (GWh)' /
            'runVersion' 'Experiment' 'Step' 'scenarioSet' 'From region' 'To region' loop(y, put y.tl ) ;
loop((repDom(rv,expts,rs,scenSet),r,rr)$sum(y, txByPathYear(repDom,r,rr,y)),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, r.tl, rr.tl ;
  loop(y,
    if(txByPathYear(repDom,r,rr,y) > 0,
      put txByPathYear(repDom,r,rr,y) ;
    else
      put '' ;
    ) ;
  ) ;
) ;


* x) Transmission losses (GWh)
put txLosses 'Transmission losses (GWh)' /
            'runVersion' 'Experiment' 'Step' 'scenarioSet' 'To region' loop(y, put y.tl ) ;
loop((repDom(rv,expts,rs,scenSet),r)$sum(y, txLossesIntoRegionByYear(repDom,r,y)),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, r.tl ;
  loop(y,
    if(txLossesIntoRegionByYear(repDom,r,y) > 0,
      put txLossesIntoRegionByYear(repDom,r,y) ;
    else
      put '' ;
    ) ;
  ) ;
) ;


* x) Time-weighted energy price by region and year, $/MWh.
put energyPrices 'Time-weighted energy price by region and year, $/MWh' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Region' loop(y, put y.tl ) ;
loop((repDom(rv,expts,rs,scenSet),r)$sum(y, energyPrice(repDom,r,y)),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, r.tl ;
  loop(y,
    if(energyPrice(repDom,r,y) > 0,
      put energyPrice(repDom,r,y) ;
    else
      put '' ;
    ) ;
  ) ;
) ;






$stop

* e) Aggregate summary of plant build, refurbishment and retirement by island and New Zealand
put buildAgg 'Summary of plant built, refurbished and retired' / 'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Island/NZ' 'Existing MW' 'Built MW' 'Refurbished MW' 'Retired MW' ;
loop((repDom(rv,expts,rs,scenSet),aggR),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, aggR.tl ;
  put sum((r,g)$( mapAggR_r(aggR,r) * mapg_r(g,r) * exist(rv,g) ), i_namePlate(rv,g)) ;
  put sum(r$mapAggR_r(aggR,r), builtByRegion(repDom,r)) ;
*  put sum((r,g)$( mapAggR_r(aggR,r) * mapg_r(g,r) * possibleToRefurbish(rv,g) * ( sum(y, r_REFURBCOST(repDom,g,y)) = 0) ), i_namePlate(rv,g)) ;
*  put sum((r,g)$( mapAggR_r(aggR,r) * mapg_r(g,r) * possibleToRetire(rv,g) ),  sum(y, r_RETIRE(repDom,g,y) + exogMWretired(rv,g,y)) ) ;
) ;

** I don't believe retirement and refurbishment is working


* f) Generation capacity by plant and year
put capacityPlant 'Capacity by plant and year (net of retirements), MW' / 'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Technology' 'Region' 'Plant' loop(y, put y.tl ) ;
loop((repDom(rv,expts,rs,scenSet),k,r,g)$( mapg_k(g,k) * mapg_r(g,r) * sum(y, r_CAPACITY(repDom,g,y)) ),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, k.tl, r.tl, g.tl loop(y, put r_CAPACITY(repDom,g,y)) ;
) ;

* g) Generation capacity expansion - ordered by year and including retirements.
put expandSchedule 'Generation capacity expansion ordered by year' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Technology' 'Plant' 'NameplateMW' 'ExistMW' 'BuildYr', 'BuildMW' 'RetireType' 'RetireYr' 'RetireMW' 'Capacity' ;
loop((repDom(rv,expts,rs,scenSet),y,k,g)$( mapg_k(g,k) * existBuildOrRetire(repDom,g,y) ),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, k.tl, g.tl, i_namePlate(rv,g) ;
  if(exist(rv,g), put i_namePlate(rv,g) else put '' ) ;
  if(r_BUILD(repDom,g,y), put yearNum(rv,y), r_BUILD(repDom,g,y) else put '' '' ) ;
  if(possibleToRetire(rv,g) * ( r_RETIRE(repDom,g,y) or exogMWretired(rv,g,y) ),
    if( ( possibleToEndogRetire(rv,g) * r_RETIRE(repDom,g,y) ),
      put 'Endogenous', yearNum(rv,y), r_RETIRE(repDom,g,y) else put 'Exogenous', yearNum(rv,y), exogMWretired(rv,g,y) ;
    ) else  put '' '' '' ;
  ) ;
) ;



* Up to here with rebuild of GEMreports to accomodate reporting on many solutions.
$stop








*===============================================================================================
* 5. Write key results to a CSV file.

* Write a report config file - a bit like run config, i.e. what runs, experiments, obj fn value etc. Put the solveReport in it?

put keyResults 'Key results' ;

put // 'Objective function value components, $m' / '' loop(activeRep(rep), put rep.tl ) ;
loop(objc,
  put / objc.tl loop(activeRep(rep), put sum(foldRep(repDom,rep), objComponents(repDom,objc)) ) put '' objc.te(objc) ;
) ;

put /// 'MW built by technology and region (MW built as percent of MW able to be built shown in 3 columns to the right) ' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / ' ' ;
  loop(r$( card(isIldEqReg) <> 2 ), put r.tl ) loop(aggR, put aggR.tl ) put '' loop(aggR, put aggR.tl ) ;
  loop(k$sum((foldRep(repDom,rep),r), genBuiltByTechRegionYear(repDom,k,r)),
    put / k.tl
    loop(r$( card(isIldEqReg) <> 2 ), put sum(foldRep(repDom,rep), genBuiltByTechRegionYear(repDom,k,r)) ) ;
    loop(aggR, put sum((foldRep(repDom,rep),r)$mapAggR_r(aggR,r), genBuiltByTechRegionYear(repDom,k,r)) ) ;
    put '' ;
    loop(aggR,
      if(sum(maprv_rep(rv,rep), MWtoBuild(rv,k,aggR)) = 0, put '' else
        put (100 * sum((foldRep(repDom,rep),r)$mapAggR_r(aggR,r), genBuiltByTechRegionYear(repDom,k,r)) / sum(maprv_rep(rv,rep), MWtoBuild(rv,k,aggR)) ) ;
      ) ;
    ) ;
    put '' k.te(k) ;
  ) put / ;
) ;

cntr = 0 ;
put /// 'Generation by technology, region and year, GWh' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' '' loop(y, put y.tl ) put / ;
  if(card(isIldEqReg) <> 2,
    loop(k$sum((foldRep(repDom,rep),r,y), genByTechRegionYear(repDom,k,r,y)),
      put k.tl ;
      loop(r$sum((foldRep(repDom,rep),y), genByTechRegionYear(repDom,k,r,y)),
        put$(cntr = 0) r.tl ; put$(cntr > 0) '' r.tl ; cntr = cntr + 1 ;
        loop(y, put sum(foldRep(repDom,rep), genByTechRegionYear(repDom,k,r,y)) ) put / ;
      ) ;
      loop(aggR$sum((foldRep(repDom,rep),r,y)$mapAggR_r(aggR,r), genByTechRegionYear(repDom,k,r,y)),
        put '' aggR.tl ;
        loop(y, put sum((foldRep(repDom,rep),r)$mapAggR_r(aggR,r), genByTechRegionYear(repDom,k,r,y)) ) put / ;
      ) ;
      cntr = 0 ;
    ) ;
    else
    loop(k$sum((foldRep(repDom,rep),r,y), genByTechRegionYear(repDom,k,r,y)),
      put k.tl ;
      loop(aggR$sum((foldRep(repDom,rep),r,y)$mapAggR_r(aggR,r), genByTechRegionYear(repDom,k,r,y)),
        put$(cntr = 0) aggR.tl ; put$(cntr > 0) '' aggR.tl ; cntr = cntr + 1 ;
        loop(y, put sum((foldRep(repDom,rep),r)$mapAggR_r(aggR,r), genByTechRegionYear(repDom,k,r,y)) ) put / ;
      ) ;
      cntr = 0 ;
    ) ;
  ) ;
) ;

put /// 'Interregional transmission by year, GWh' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' '' loop(y, put y.tl ) ;
  loop(paths(r,rr)$sum((foldRep(repDom,rep),y), txByRegionYear(repDom,paths,y)),
    put / r.tl, rr.tl ;
    loop(y, put sum(foldRep(repDom,rep), txByRegionYear(repDom,paths,y)) ) ;
  ) put / ;
) ;

put /// 'Interregional transmission losses by year, GWh' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' '' loop(y, put y.tl ) ;
  loop(paths(r,rr)$sum((foldRep(repDom,rep),y), txLossesByRegionYear(repDom,paths,y)),
    put / r.tl, rr.tl ;
    loop(y, put sum(foldRep(repDom,rep), txLossesByRegionYear(repDom,paths,y)) ) ;
  ) put / ;
) ;

put /// 'Load by region and year, GWh' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' loop(y, put y.tl ) ;
  loop(r$sum((foldRep(repDom,rep),y), loadByRegionAndYear(repDom,r,y)),
    put / r.tl loop(y, put sum(foldRep(repDom,rep), loadByRegionAndYear(repDom,r,y)) ) ;
  ) put / ;
) ;

put /// 'Time-weighted energy price by region and year, $/MWh' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' loop(y, put y.tl ) ;
  loop(r$sum((foldRep(repDom,rep),y), energyPrice(repDom,r,y)),
    put / r.tl loop(y, put sum(foldRep(repDom,rep), energyPrice(repDom,r,y)) ) ;
  ) put / ;
) ;

put /// 'Shadow prices by year' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' loop(y, put y.tl ) ;
  put / 'PeakNZ, $/kW'                loop(y, put sum(foldRep(repDom,rep), peakNZPrice(repDom,y)) ) ;
  put / 'PeakNI, $/kW'                loop(y, put sum(foldRep(repDom,rep), peakNIPrice(repDom,y)) ) ;
  put / 'noWindPeakNI, $/kW'          loop(y, put sum(foldRep(repDom,rep), peaknoWindNIPrice(repDom,y)) ) ;
  put / 'renewEnergyShrPrice, $/GWh'  loop(y, put sum(foldRep(repDom,rep), renewEnergyShrPrice(repDom,y)) ) ;
  put / 'renewCapacityShrPrice, $/kW' loop(y, put sum(foldRep(repDom,rep), renewCapacityShrPrice(repDom,y)) ) put / ;
) ;

put /// 'Shadow prices on fuel-related constraints' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' loop(y, put y.tl ) ;
  loop(f$sum((foldRep(repDom,rep),y), fuelPrice(repDom,f,y) + energyLimitPrice(repDom,f,y)),
    put / f.tl ;
    put / 'Limit on fuel use, $/GJ'    loop(y, put sum(foldRep(repDom,rep), fuelPrice(repDom,f,y)) ) ;
    put / 'Limit on energy use, $/MWh' loop(y, put sum(foldRep(repDom,rep), energyLimitPrice(repDom,f,y)) ) ;
  ) put / ;
) ;

put /// 'Time-weighted energy price from minimum schedulable hydro generation constraint by plant and year, $/MWh' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' loop(y, put y.tl ) ;
  loop(g$sum((foldRep(repDom,rep),y), minEnergyPrice(repDom,g,y)),
    put / g.tl loop(y, put sum(foldRep(repDom,rep), minEnergyPrice(repDom,g,y)) ) ;
  ) put / ;
) ;

put /// 'Energy price from minimum utilisation constraint by plant and year, $/MWh' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' loop(y, put y.tl ) ;
  loop(g$sum((foldRep(repDom,rep),y), minUtilEnergyPrice(repDom,g,y)),
    put / g.tl loop(y, put sum(foldRep(repDom,rep), minUtilEnergyPrice(repDom,g,y)) ) ;
  ) put / ;
) ;



*===============================================================================================
* 5. Write results to be plotted to a single CSV file.

* Write to the plotting csv file
put plotResults "%runName%" "%FigureTitles%", card(y) ; ! card(y) needs to indicate the number of columns of data - i.e. after the first 2 cols, which are not data.
put // 'Technologies' ;
loop(k, put / k.tl, k.te(k) loop(techColor(k,red,green,blue), put red.tl, green.tl, blue.tl ) ) ;

put // 'Run versions' ;
loop(rv(runVersions), put / runVersions.tl, runVersions.te(runVersions) loop(runVersionColor(runVersions,red,green,blue), put red.tl, green.tl, blue.tl ) ) ;

put // 'Time-weighted energy price by region and year, $/MWh' / '' '' loop(y, put y.tl ) ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) ;
  loop(r$sum((foldRep(repDom,rep),y), energyPrice(repDom,r,y)),
    put / r.tl '' loop(y, put sum(foldRep(repDom,rep), energyPrice(repDom,r,y)) ) ;
  ) ;
) ;

put // 'Capacity by technology and year (existing plus built less retired), MW' / '' '' loop(y, put y.tl ) ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) ;
  loop(k$sum((foldRep(repDom,rep),r,y), capacityByTechRegionYear(repDom,k,r,y)),
    put / k.tl '' ;
    loop(y, put sum((foldRep(repDom,rep),r), capacityByTechRegionYear(repDom,k,r,y)) ) ;
  ) ;
  put / 'Total' '' loop(y, put sum((foldRep(repDom,rep),k,r), capacityByTechRegionYear(repDom,k,r,y)) ) ;
) ;

put // 'Generation by technology and region and year, GWh' / '' '' loop(y, put y.tl ) ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) ;
  loop(k$sum((foldRep(repDom,rep),r,y), genByTechRegionYear(repDom,k,r,y)),
    put / k.tl '' ;
    loop(y, put sum((foldRep(repDom,rep),r), genByTechRegionYear(repDom,k,r,y)) ) ;
  ) ;
  put / 'Total' '' loop(y, put sum((foldRep(repDom,rep),k,r), genByTechRegionYear(repDom,k,r,y)) ) ;
) ;

put // 'Transmission investment by project and year, $m' ;
put / '' '' loop(tupg$sum((rep,foldRep(repDom,rep),y), s_TXPROJVAR(repDom,tupg,y)), put tupg.tl ) ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) ;
  loop(y$sum((foldRep(repDom,rep),tupg), s_TXPROJVAR(repDom,tupg,y)),
    put / y.tl '' loop(tupg$( not sameas(tupg,'Exist') ), put sum(foldRep(repDom,rep), txCapexByProjectYear(repDom,tupg,y)) ) ;
  ) ;
) ;

put // 'Transmission capacity by path and year, MW' / '' '' loop(y, put y.tl ) ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) ;
  loop(paths(r,rr),
    put / r.tl, rr.tl loop(y, put sum(foldRep(repDom,rep), txCapacityByYear(repDom,paths,y)) ) ;
  ) ;
) ;

put // 'Transmission investments' ;
loop(tupg$sum((rep,foldRep(repDom,rep),y), s_TXPROJVAR(repDom,tupg,y)), put / tupg.tl, tupg.te(tupg) ) ;

put / 'EOF' ;






*===============================================================================================
* x. Generate the remaining external files.

** Note that this section writes all that is loaded - it has not been edited to write only that which is in repDom.


* c) Write out generation report (genPlant and genPlantYear).
put genPlant 'Generation (GWh) and utilisation (percent) by plant and year' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Plant' 'Year' 'Period' 'Block' 'Scenario' 'GWh' 'Percent' ;
loop((repDomLd(rv,expts,steps,scenSet),g,y,t,lb,scen)$s_GEN(repDomLd,g,y,t,lb,scen),
  put / rv.tl, expts.tl, steps.tl, scenSet.tl, g.tl, y.tl, t.tl, lb.tl, scen.tl, s_GEN(repDomLd,g,y,t,lb,scen) ;
  put (100 * s_GEN(repDomLd,g,y,t,lb,scen) / ( 1e-3 * hoursPerBlock(rv,t,lb) * i_namePlate(rv,g) )) ;
) ;

put genPlantYear 'Annual generation (GWh) and utilisation (percent) by plant' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Plant' 'Year' 'Scenario' 'GWh' 'Percent' ;
loop((repDomLd(rv,expts,steps,scenSet),g,y,scen)$sum((t,lb), s_GEN(repDomLd,g,y,t,lb,scen)),
  put / rv.tl, expts.tl, steps.tl, scenSet.tl, g.tl, y.tl, scen.tl, sum((t,lb), s_GEN(repDomLd,g,y,t,lb,scen)) ;
  put ( 100 * sum((t,lb), s_GEN(repDomLd,g,y,t,lb,scen)) / ( 8.76 * i_namePlate(rv,g) ) ) ;
) ;


** Temporary TX
put tempTX 'Transmission build' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'FromReg' 'ToReg' 'UpgState' 'Year' ;
loop((repDomLd(rv,expts,steps,scenSet),r,rr,ps,y)$s_BTX(repDomLd,r,rr,ps,y),
  put / rv.tl, expts.tl, steps.tl, scenSet.tl, r.tl, rr.tl, ps.tl, y.tl, s_BTX(repDomLd,r,rr,ps,y) ;
) ;


* e) Write out annual report (variousAnnual).
Set ryr 'Labels for results by year' /
  FuelPJ   'Fuel burn, PJ'
  / ;

put variousAnnual 'Various results reported by year' / ''
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Scenario' 'Fuel' loop(y, put y.tl) ;
loop((ryr,repDomLd(rv,expts,steps,scenSet),scen,thermalfuel(f))$sum((mapg_f(g,f),y,t,lb), s_GEN(repDomLd,g,y,t,lb,scen)),
  put / ryr.te(ryr), rv.tl, expts.tl, steps.tl, scenSet.tl, scen.tl, f.tl ;
  loop(y, put sum((mapg_f(g,f),t,lb), 1e-6 * i_heatrate(rv,g) * s_GEN(repDomLd,g,y,t,lb,scen)) ) ;
) ;

* Need to check units are correct on Fuel burn, PJ?
* Create a parameter to calculate this stuff and move it into a loop where it all gets done at once.

*CO2taxByPlant(g,y,scen) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_co2tax(y) * scenarioCO2TaxFactor(scen) * i_emissionFactors(f) ) ;



*===============================================================================================
* x. Do the John Culy report for TPR work - delete all of this once TPR is over.

Files
  summaryResults    / "%primaryOutput%\%runName%\JC summary results - %runName%.csv" /
  summaryResultsJC  / "%primaryOutput%\%runName%\JC results - %runName%.csv" /
  blockResults      / "%primaryOutput%\%runName%\JC Blocks - %runName%.csv" / ;

summaryResults.pc = 5 ;   summaryResults.pw = 999 ;
summaryResultsJC.pc = 5 ; summaryResultsJC.pw = 999 ;
blockResults.pc = 5 ;     blockResults.pw = 999 ;

Sets
  singleDomain(experiments,steps,scenSet)       'The single experiment-steps-scenarioSets tuple to be used in summmary report'
  block                                         'Load Block group'      /  peak 'PeakLd',  offpk 'OffpeakLd', mid 'MidLd' /
  maplb_block(lb,block)                         'Load Block Group map'  / (b1l,b1w).peak
                                                                          (b5,b6).offpk
                                                                          (b2l,b2w,b3l,b3w,b4).mid / ;
Parameters
  hoursYearBlock(runVersions,block)             'Hours by block'
  genByTechRegionYearBlock(*,*,*,*,k,r,y,block) 'Generation by technology and region/island/Block and year, GWh'
  energyPriceBlock(*,*,*,*,r,y,block)           'Time-weighted energy price by region/Block and year, $/MWh (from marginal price off of energy balance constraint)'
  txByRegionYearBlock(*,*,*,*,r,rr,y,block)     'Interregional transmission by year/Block, GWh'
  genRevByTechRegionYear(*,*,*,*,k,r,y)         'Generation rev by technology and region/island and year, $k'
  loadByRegionAndYearBlock(*,*,*,*,r,y,block)   'Load by region and year,Block GWh'  ;

singleDomain(%singleDomain%) = yes ;

hoursYearBlock(rv,block) = sum((t,lb)$maplb_block(lb,block), hoursPerBlock(rv,t,lb) ) ;

* Generation Revenue excluding contribution to security constraints, you can add contribution to security constriants from outputs
genRevByTechRegionYear(rv,singleDomain,k,r,y) = sum((g,t,lb,sc)$( mapg_k(g,k) * mapg_r(g,r) ), 1e3 * unDiscFactor(rv,y,t) * s_GEN(rv,singleDomain,g,y,t,lb,sc)* s_bal_supdem(rv,singleDomain,r,y,t,lb,sc)) ;

genByTechRegionYearBlock(rv,singleDomain,k,r,y,block) = sum((g,t,lb,sc)$( mapg_k(g,k) * mapg_r(g,r) * maplb_block(lb,block) ), scenarioWeight(sc) * s_GEN(rv,singleDomain,g,y,t,lb,sc)) ;

energyPriceBlock(rv,singleDomain,r,y,block) = 1e3 * sum((t,lb,sc)$ maplb_block(lb,block), unDiscFactor(rv,y,t) * hoursPerBlock(rv,t,lb) * s_bal_supdem(rv,singleDomain,r,y,t,lb,sc))  ;

txByRegionYearBlock(rv,singleDomain,paths,y,block) = sum((t,lb,sc)$ maplb_block(lb,block), 1e-3 * scenarioWeight(sc) * hoursPerBlock(rv,t,lb) * s_TX(rv,singleDomain,paths,y,t,lb,sc)) ;

loadByRegionAndYearBlock(rv,singleDomain,r,y,block) = sum((t,lb,sc)$(maplb_block(lb,block)), scenarioWeight(sc) * NrgDemand(rv,r,y,t,lb,sc)) ;

* Write summary results to a csv file.
put summaryResults 'Objective function value components, $m' / '' ;
loop(rv, put rv.tl ) ;
loop(objc,
  put / objc.tl ;
  loop(rv, put sum(singleDomain, objComponents(rv,singleDomain,objc)) ) ;
  put objc.te(objc) ;
) ;

put //// 'MW built by technology and region (MW built as percent of MW able to be built shown in 3 columns to the right) ' ;
loop(rv,
  put / rv.tl ; loop(r$( card(isIldEqReg) <> 2 ), put r.tl ) loop(aggR, put aggR.tl ) put '' loop(aggR, put aggR.tl ) ;
  loop(k, put / k.tl
    loop(r$( card(isIldEqReg) <> 2 ), put sum(singleDomain, genBuiltByTechRegionYear(rv,singleDomain,k,r)) ) ;
    loop(aggR, put sum((singleDomain,r)$mapAggR_r(aggR,r), genBuiltByTechRegionYear(rv,singleDomain,k,r)) ) ;
    put '' ;
    loop(aggR,
    if(MWtoBuild(rv,k,aggR) = 0, put '' else
      put (100 * sum((singleDomain,r)$mapAggR_r(aggR,r), genBuiltByTechRegionYear(rv,singleDomain,k,r)) / MWtoBuild(rv,k,aggR)) ) ;
    ) ;
    put '' k.te(k) ;
  ) ;
  put / ;
) ;

put /// 'Capacity by technology and region and year, MW (existing plus built less retired)' ;
loop(rv, put / rv.tl '' ; loop(y, put y.tl ) ;
  loop((k,r),
    put / k.tl, r.tl ;
    loop(y, put sum(singleDomain, capacityByTechRegionYear(rv,singleDomain,k,r,y)) ) ;
  ) ;
  put / ;
) ;

cntr = 0 ;
put /// 'Generation by technology, region and year, GWh' ;
loop(rv, put / rv.tl '' ; loop(y, put y.tl ) ; put / ;
  if(card(isIldEqReg) <> 2,
    loop(k,
      put k.tl ;
      loop(r,
        put$(cntr = 0) r.tl ; put$(cntr > 0) '' r.tl ; cntr = cntr + 1 ;
        loop(y, put sum(singleDomain, genByTechRegionYear(rv,singleDomain,k,r,y)) ) put / ;
      ) ;
      loop(aggR,
        put '' aggR.tl ;
        loop(y, put sum((singleDomain,r)$mapAggR_r(aggR,r), genByTechRegionYear(rv,singleDomain,k,r,y)) ) put / ;
      ) ;
    cntr = 0 ;
    ) ;
    else
    loop(k,
      put k.tl ;
      loop(aggR,
        put$(cntr = 0) aggR.tl ; put$(cntr > 0) '' aggR.tl ; cntr = cntr + 1 ;
        loop(y, put sum((singleDomain,r)$mapAggR_r(aggR,r), genByTechRegionYear(rv,singleDomain,k,r,y)) ) put / ;
      ) ;
      cntr = 0 ;
    ) ;
  ) ;
) ;

put /// 'Interregional transmission by year, GWh' ;
loop(rv, put / rv.tl '' ; loop(y, put y.tl ) ;
  loop((paths(r,rr)),
    put / r.tl, rr.tl ;
    loop(y, put sum(singleDomain, txByRegionYear(rv,singleDomain,paths,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Interregional transmission losses by year, GWh' ;
loop(rv, put / rv.tl '' ; loop(y, put y.tl ) ;
  loop((paths(r,rr)),
    put / r.tl, rr.tl ;
    loop(y, put sum(singleDomain, txLossesByRegionYear(rv,singleDomain,paths,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Load by region and year, GWh' ;
loop(rv, put / rv.tl ; loop(y, put y.tl ) ;
  loop(r, put / r.tl
    loop(y, put sum(singleDomain, loadByRegionAndYear(rv,singleDomain,r,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Time-weighted energy price by region and year, $/MWh' ;
loop(rv, put / rv.tl ; loop(y, put y.tl ) ;
  loop(r, put / r.tl
    loop(y, put sum(singleDomain, energyPrice(rv,singleDomain,r,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Shadow prices by year' ;
loop(rv, put / rv.tl ; loop(y, put y.tl ) ;
  put / 'PeakNZ, $/kW'                loop(y, put sum(singleDomain, peakNZPrice(rv,singleDomain,y)) ) ;
  put / 'PeakNI, $/kW'                loop(y, put sum(singleDomain, peakNIPrice(rv,singleDomain,y)) ) ;
  put / 'noWindPeakNI, $/kW'          loop(y, put sum(singleDomain, peaknoWindNIPrice(rv,singleDomain,y)) ) ;
  put / 'renewEnergyShrPrice, $/GWh'  loop(y, put sum(singleDomain, renewEnergyShrPrice(rv,singleDomain,y)) ) ;
  put / 'renewCapacityShrPrice, $/kW' loop(y, put sum(singleDomain, renewCapacityShrPrice(rv,singleDomain,y)) ) ;
  put / ;
) ;

put /// 'Shadow prices on fuel-related constraints' ;
loop(rv, put / rv.tl ; loop(y, put y.tl ) ;
  loop(f$sum((singleDomain,y), fuelPrice(rv,singleDomain,f,y) + energyLimitPrice(rv,singleDomain,f,y)),
  put / f.tl ;
  put / 'Limit on fuel use, $/GJ'    loop(y, put sum(singleDomain, fuelPrice(rv,singleDomain,f,y)) ) ;
  put / 'Limit on energy use, $/MWh' loop(y, put sum(singleDomain, energyLimitPrice(rv,singleDomain,f,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Time-weighted energy price from minimum schedulable hydro generation constraint by plant and year, $/MWh' ;
loop(rv, put / rv.tl ; loop(y, put y.tl ) ;
  loop(g$sum((singleDomain,y), minEnergyPrice(rv,singleDomain,g,y)), put / g.tl
    loop(y, put sum(singleDomain, minEnergyPrice(rv,singleDomain,g,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Energy price from minimum utilisation constraint by plant and year, $/MWh' ;
loop(rv, put / rv.tl ; loop(y, put y.tl ) ;
  loop(g$sum((singleDomain,y), minUtilEnergyPrice(rv,singleDomain,g,y)), put / g.tl
    loop(y, put sum(singleDomain, minUtilEnergyPrice(rv,singleDomain,g,y)) ) ;
  ) ;
  put / ;
) ;

* Derive results for generation by type
put summaryResultsJC 'JC Report ', ' %runName% '  ;
put / 'Generation by run, type, region and year, MW, GWh ' ;
put / 'Run', 'Type', 'Region', 'Year','MW', 'GWh', 'Price', 'Rev';
  loop((rv,k,r,y),
    put / rv.tl, k.tl, r.tl, y.tl,
         sum(singleDomain, capacityByTechRegionYear(rv,singleDomain,k,r,y)),
         sum(singleDomain, genByTechRegionYear(rv,singleDomain,k,r,y)),
         sum(singleDomain, (genRevByTechRegionYear(rv,singleDomain,k,r,y)/genByTechRegionYear(rv,singleDomain,k,r,y))$genByTechRegionYear(rv,singleDomain,k,r,y)),
         sum(singleDomain, genRevByTechRegionYear(rv,singleDomain,k,r,y)),
  ) ;

*put / 'Results by run, region and year, MW, GWh, Price ' ;
*put / 'Run', 'Type','Region', 'Year', 'MW', 'GWh', 'Price';
   loop((rv,r,y),
    put / rv.tl, 'Area', r.tl, y.tl,
         sum(singleDomain, loadByRegionAndYear(rv,singleDomain,r,y)/8.76),
         sum(singleDomain, loadByRegionAndYear(rv,singleDomain,r,y)),
         sum(singleDomain, energyPrice(rv,singleDomain,r,y))
  ) ;

*put / 'Peak Constraint by run, Region, year, $/kW/yr ' ;
*put / 'Run', 'PkConstraint','Region', 'Year','MW', 'GWh', 'Price';
$ontext
   loop((rv,y),
         put / rv.tl, 'Security', 'ni', y.tl, 0, sum(singleDomain,loadByRegionAndYear(rv,singleDomain,'ni',y)),
              sum(singleDomain, (peakNZPrice(rv,singleDomain,y)+peakNIPrice(rv,singleDomain,y)+peaknoWindNIPrice(rv,singleDomain,y))/8.76) ;
         put / rv.tl, 'Security', 'ni_LowWind', y.tl, 0, 0,
              sum(singleDomain, (peaknoWindNIPrice(rv,singleDomain,y))/8.76) ;
         put / rv.tl, 'Security', 'nz', y.tl, 0, 0,
              sum(singleDomain, (peakNZPrice(rv,singleDomain,y))/8.76) ;
         put / rv.tl, 'Security', 'si', y.tl, 0, sum(singleDomain,loadByRegionAndYear(rv,singleDomain,'si',y)),
              sum(singleDomain, peakNZPrice(rv,singleDomain,y)/8.76) ;
    ) ;
$offtext

*put / 'Link Flow by run, FromRegion, Toregion and year, MW, GWh ' ;
*put / 'Run', 'FromRegion', 'ToRegion', 'Year','MW', 'GWh', 'Price';
   loop((rv,r,y),
         put / rv.tl, loop((paths(r,rr)), put r.tl, rr.tl, y.tl, sum(singleDomain, txByRegionYear(rv,singleDomain,paths,y)/8.76), sum(singleDomain, txByRegionYear(rv,singleDomain,paths,y)),0 );
  ) ;
  put / ;

* code Below if you want results by Block
put blockResults 'JC Report ', ' %runName% ' ;
put / 'Run', 'Type', 'Region', 'Year','Block', 'MW', 'GWh', 'Price';
  loop((rv,k,r,y,block),
    put / rv.tl, k.tl, r.tl, y.tl, block.tl,
         sum(singleDomain, genByTechRegionYearBlock(rv,singleDomain,k,r,y,block)/hoursYearBlock(rv,block)*1000), sum(singleDomain, genByTechRegionYearBlock(rv,singleDomain,k,r,y,block)), 0,
  ) ;
   loop((rv,r,y,block),
    put / rv.tl, 'Area', r.tl, y.tl, block.tl, sum(singleDomain, loadByRegionAndYearBlock(rv,singleDomain,r,y,block)/hoursYearBlock(rv,block)*1000), sum(singleDomain, loadByRegionAndYearBlock(rv,singleDomain,r,y,block)),  sum(singleDomain, energyPriceBlock(rv,singleDomain,r,y,block)/hoursYearBlock(rv,block))
  ) ;
    loop((rv,r,y,block),
         put / rv.tl, loop((paths(r,rr)), put r.tl, rr.tl, y.tl, block.tl, sum(singleDomain, txByRegionYearBlock(rv,singleDomain,paths,y,block)/hoursYearBlock(rv,block)*1000), sum(singleDomain, txByRegionYearBlock(rv,singleDomain,paths,y,block)), 0 );
  ) ;

** End of John Culy results **



$ontext
* Write Peak constraint info to a txt file.
File PeakResults / "%primaryOutput%\%runName%\%runName% - %scenarioName% - PeakResults.txt" / ; PeakResults.lw = 0 ; PeakResults.pw = 999 ;
put PeakResults '1. Peak NZ' / @6 'Capacity' '  RestLHS', '      RHS', '  MargVal' ;
loop(y,
  put / y.tl:<4:0, (sum((activeExpSteps,g), peakConPlant(g,y) * s2_CAPACITY(activeExpSteps,g,y))):>9:1,
    ( -i_winterCapacityMargin(y)):>9:1,
    ( sum(sc, scenarioWeight(sc) * peakLoadNZ(y,sc)) ):>9:1
    ( sum(sc, 1000 * scenarioWeight(sc) * peak_NZ.m(y,sc)) ):>9:1
) ;

put /// '2. Peak NI' / @6 'Capacity' '  RestLHS', '      RHS', '  MargVal' ;
loop(y,
  put / y.tl:<4:0, (sum((activeExpSteps,nigen(g)), peakConPlant(g,y) * s2_CAPACITY(activeExpSteps,g,y))):>9:1,
    ( i_largestGenerator(y) + i_smallestPole(y) - i_winterCapacityMargin(y) ):>9:1,
    ( sum(sc, scenarioWeight(sc) * peakLoadNI(y,sc)) ):>9:1
    ( sum(sc, 1000 * scenarioWeight(sc) * peak_NI.m(y,sc)) ):>9:1
) ;

put /// '3. Low wind peak NI' / @6 'Capacity' '  RestLHS', '      RHS', '  MargVal' ;
loop(y,
  put / y.tl:<4:0, (sum((activeExpSteps,mapg_k(g,k))$( nigen(g) and (not wind(k)) ), NWpeakConPlant(g,y) * s2_CAPACITY(activeExpSteps,g,y))):>9:1,
    ( -i_fkNI(y) + i_smallestPole(y) ):>9:1,
    ( sum(sc, scenarioWeight(sc) * peakLoadNI(y,sc)) ):>9:1
    ( sum(sc, 1000 * scenarioWeight(sc) * noWindPeak_NI.m(y,sc)) ):>9:1
) ;
$offtext





* End of file
