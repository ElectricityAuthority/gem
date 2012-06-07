* GEMreports.gms


* Last modified by Dr Phil Bishop, 08/06/2012 (imm@ea.govt.nz)


$ontext
  This program generates GEM reports - human-readable files or files to be read by other applications for further processing.
  It is to be invoked subsequent to the solving of all runs and run versions that are to be reported on. Note that GEMreports
  effectively starts afresh as a standalone program. It does "not" start from any previously created GAMS work files (.g00), and
  it imports or loads all of the data it requires from GDX files containing output from previously solved GEM runs. All symbols
  required in this program are declared here. Set membership and data values are imported from the designated base case input GDX
  file and/or the various merged GDX files.

  Notes:
  1. ...

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
     a) Objective function value breakdown
     b) Plant built by technology
     c) Plant built by region
     d) Generation capacity by plant and year
     e) Generation capacity expansion - ordered by year and including retirements.


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
$include "%OutPath%\rep%reportName%\repData\Configuration info.inc"
$offupper offsymxref offsymlist offuellist offuelxref onempty inlinecom { } eolcom !

Alias(runVersions,rv), (experiments,expts), (scenarioSets,scenSet), (scenarios,scen) ;

* Declare output files to be created by GEMreports.
Files
  objBrkDown     / "%OutPath%\rep%reportName%\Objective function value breakdown - %reportName%.csv" /
  plantTech      / "%OutPath%\rep%reportName%\Plant built by technology - %reportName%.csv" /
  plantReg       / "%OutPath%\rep%reportName%\Plant built by region - %reportName%.csv" /
  capacityPlant  / "%OutPath%\rep%reportName%\Capacity by plant and year (net of retirements) - %reportName%.csv" /
  expandSchedule / "%OutPath%\rep%reportName%\Capacity expansion by year - %reportName%.csv" /

  keyResults     / "%OutPath%\rep%reportName%\A collection of key results - %reportName%.csv" /
  plotResults    / "%OutPath%\rep%reportName%\Results to be plotted - %reportName%.csv" /
  genPlant       / "%OutPath%\rep%reportName%\Generation and utilisation by plant - %reportName%.csv" /
  tempTX         / "%OutPath%\rep%reportName%\Transmission build - %reportName%.csv" /
  genPlantYear   / "%OutPath%\rep%reportName%\Generation and utilisation by plant (annually) - %reportName%.csv" /
  variousAnnual  / "%OutPath%\rep%reportName%\Various annual results - %reportName%.csv" /  ;

objBrkDown.pc = 5 ;      objBrkDown.pw = 999 ;
plantTech.pc = 5 ;       plantTech.pw = 999 ;
plantReg.pc = 5 ;        plantReg.pw = 999 ;
capacityPlant.pc = 5 ;   capacityPlant.pw = 999 ;
expandSchedule.pc = 5 ;  expandSchedule.pw = 999 ;


keyResults.pc = 5 ;      keyResults.pw = 999 ;
plotResults.pc = 5 ;     plotResults.pw = 999 ;
genPlant.pc = 5 ;        genPlant.pw = 999 ;
tempTX.pc = 5 ;          tempTX.pw = 999 ;
genPlantYear.pc = 5 ;    genPlantYear.pw = 999 ;
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
  nwd(r,rr)                        'Northward direction of flow on Benmore-Haywards HVDC'
  swd(r,rr)                        'Southward direction of flow on Benmore-Haywards HVDC'
  paths(r,rr)                      'All valid transmission paths'
  mapg_k(g,k)                      'Map technology types to generating plant'
  mapg_f(g,f)                      'Map fuel types to generating plant'
  mapg_o(g,o)                      'Map plant owners to generating plant'
  mapg_r(g,r)                      'Map regions to generating plant'
  mapg_e(g,e)                      'Map zones to generating plant'
  mapAggR_r(aggR,r)                'Map the regions to the aggregated regional entities (this is primarily to facilitate reporting)'
  isIldEqReg(ild,r)                'Figure out if the region labels are identical to the North and South island labels (a reporting facilitation device)' ;


* d) Load set membership, i.e. fundamental, subsets, and mapping sets, from the designated base case GDX file.
$gdxin "%OutPath%\rep%reportName%\repData\Base case input data.gdx"
$loaddc k f g s o i r e ps tupg t lb rc hY
$loaddc firstYr firstPeriod thermalFuel nwd swd paths mapg_k mapg_f mapg_o mapg_r mapg_e mapAggR_r isIldEqReg
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
  allAvgDispatchSolves(rv,expts,steps,scenSet)             'All solves for which the dispatch simulations are to be averaged over all scenarios mapped to each scenario set'
  allNotAvgDispatchSolves(rv,expts,steps,scenSet)          'All solves for which the dispatch simulations are not to be averaged over all scenarios mapped to each scenario set'
  avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen) 'Map average dispatch step to (old) dispatch step for an experiment' ;

Parameters
  i_fuelQuantities(rv,f,y)                    'Quantitative limit on availability of various fuels by year, PJ'
  i_namePlate(rv,g)                           'Nameplate capacity of generating plant, MW'
  i_heatrate(rv,g)                            'Heat rate of generating plant, GJ/GWh (default = 3600)'
  i_txCapacity(rv,r,rr,ps)                    'Transmission path capacities (bi-directional), MW'
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
  yearNum(rv,y)                               'Real number associated with each year'
  PVfacG(rv,y,t)                              "Generation investor's present value factor by period"
  PVfacT(rv,y,t)                              "Transmission investor's present value factor by period"
  capCharge(rv,g,y)                           'Annualised or levelised capital charge for new generation plant, $/MW/yr'
  refurbCapCharge(rv,g,y)                     'Annualised or levelised capital charge for refurbishing existing generation plant, $/MW/yr'
  MWtoBuild(rv,k,aggR)                        'MW available for installation by technology, island and NZ'
  penaltyViolateReserves(rv,ild,rc)           'Penalty for failing to meet certain reserve classes, $/MW'
  pNFresvCost(rv,r,rr,lvl)                    'Constant cost of each non-free piece (or level) of function, $/MWh'
  exogMWretired(rv,g,y)                       'Exogenously retired MW by plant and year, MW' ;

$gdxin "%OutPath%\rep%reportName%\repData\selectedInputData.gdx"
$loaddc demandGen exist sigen possibleToBuild possibleToRefurbish possibleToEndogRetire possibleToRetire validYrOperate transitions allAvgDispatchSolves allNotAvgDispatchSolves avgDispatchSteptoRepStep  
$loaddc i_fuelQuantities i_namePlate i_heatrate i_txCapacity txCapitalCost totalFuelCost CO2taxByPlant SRMC i_fixedOM ensembleFactor i_HVDCshr i_HVDClevy
$loaddc i_plantReservesCost hoursPerBlock NrgDemand yearNum PVfacG PVfacT capCharge refurbCapCharge MWtoBuild penaltyViolateReserves pNFresvCost exogMWretired


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

$gdxin "%OutPath%\rep%reportName%\repData\reportOutput.gdx"
$loaddc s_TOTALCOST s_TX s_BTX s_REFURBCOST s_BUILD s_RETIRE s_CAPACITY s_TXCAPCHARGES s_GEN s_VOLLGEN s_LOSS s_TXPROJVAR s_RESV s_RESVVIOL s_RESVCOMPONENTS
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
    r_TOTALCOST(rv,expts,rs,'avg')                             = wtScensToAvg(rv,expts) * sum(scenSet, s_TOTALCOST(rv,expts,steps,scenSet)) ;
    r_TX(rv,expts,rs,'avg',r,rr,y,t,lb,'averageDispatch')      = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_TX(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)) ;
    r_BTX(rv,expts,rs,'avg',r,rr,ps,y)                         = wtScensToAvg(rv,expts) * sum(scenSet, s_BTX(rv,expts,steps,scenSet,r,rr,ps,y)) ;
    r_REFURBCOST(rv,expts,rs,'avg',g,y)                        = wtScensToAvg(rv,expts) * sum(scenSet, s_REFURBCOST(rv,expts,steps,scenSet,g,y)) ;
    r_BUILD(rv,expts,rs,'avg',g,y)                             = wtScensToAvg(rv,expts) * sum(scenSet, s_BUILD(rv,expts,steps,scenSet,g,y)) ;
    r_RETIRE(rv,expts,rs,'avg',g,y)                            = wtScensToAvg(rv,expts) * sum(scenSet, s_RETIRE(rv,expts,steps,scenSet,g,y)) ;
    r_CAPACITY(rv,expts,rs,'avg',g,y)                          = wtScensToAvg(rv,expts) * sum(scenSet, s_CAPACITY(rv,expts,steps,scenSet,g,y)) ; 
    r_TXCAPCHARGES(rv,expts,rs,'avg',r,rr,y)                   = wtScensToAvg(rv,expts) * sum(scenSet, s_TXCAPCHARGES(rv,expts,steps,scenSet,r,rr,y)) ;
    r_GEN(rv,expts,rs,'avg',g,y,t,lb,'averageDispatch')        = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_GEN(rv,expts,steps,scenSet,g,y,t,lb,scen)) ;
    r_VOLLGEN(rv,expts,rs,'avg',s,y,t,lb,'averageDispatch')    = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_VOLLGEN(rv,expts,steps,scenSet,s,y,t,lb,scen)) ;
    r_LOSS(rv,expts,rs,'avg',r,rr,y,t,lb,'averageDispatch')    = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_LOSS(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)) ;
    r_TXPROJVAR(rv,expts,rs,'avg',tupg,y)                      = wtScensToAvg(rv,expts) * sum(scenSet, s_TXPROJVAR(rv,expts,steps,scenSet,tupg,y)) ;
    r_RESV(rv,expts,rs,'avg',g,rc,y,t,lb,'averageDispatch')    = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_RESV(rv,expts,steps,scenSet,g,rc,y,t,lb,scen)) ;
    r_RESVVIOL(rv,expts,rs,'avg',rc,ild,y,t,lb,'averageDispatch') = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_RESVVIOL(rv,expts,steps,scenSet,rc,ild,y,t,lb,scen)) ;
    r_RESVCOMPONENTS(rv,expts,rs,'avg',r,rr,y,t,lb,'averageDispatch',lvl) = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_RESVCOMPONENTS(rv,expts,steps,scenSet,r,rr,y,t,lb,scen,lvl)) ;
    r_RENNRGPENALTY(rv,expts,rs,'avg',y)                       = wtScensToAvg(rv,expts) * sum(scenSet, s_RENNRGPENALTY(rv,expts,steps,scenSet,y)) ;
    r_PEAK_NZ_PENALTY(rv,expts,rs,'avg',y,'averageDispatch')   = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_PEAK_NZ_PENALTY(rv,expts,steps,scenSet,y,scen)) ;
    r_PEAK_NI_PENALTY(rv,expts,rs,'avg',y,'averageDispatch')   = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_PEAK_NI_PENALTY(rv,expts,steps,scenSet,y,scen)) ;
    r_NOWINDPEAK_NI_PENALTY(rv,expts,rs,'avg',y,'averageDispatch') = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * s_NOWINDPEAK_NI_PENALTY(rv,expts,steps,scenSet,y,scen)) ;
    r_ANNMWSLACK(rv,expts,rs,'avg',y)                          = wtScensToAvg(rv,expts) * sum(scenSet, s_ANNMWSLACK(rv,expts,steps,scenSet,y)) ;
    r_RENCAPSLACK(rv,expts,rs,'avg',y)                         = wtScensToAvg(rv,expts) * sum(scenSet, s_RENCAPSLACK(rv,expts,steps,scenSet,y)) ;
    r_HYDROSLACK(rv,expts,rs,'avg',y)                          = wtScensToAvg(rv,expts) * sum(scenSet, s_HYDROSLACK(rv,expts,steps,scenSet,y)) ;
    r_MINUTILSLACK(rv,expts,rs,'avg',y)                        = wtScensToAvg(rv,expts) * sum(scenSet, s_MINUTILSLACK(rv,expts,steps,scenSet,y)) ;
    r_FUELSLACK(rv,expts,rs,'avg',y)                           = wtScensToAvg(rv,expts) * sum(scenSet, s_FUELSLACK(rv,expts,steps,scenSet,y)) ;
*   Equation marginals
    r_bal_supdem(rv,expts,rs,'avg',r,y,t,lb,scen)              = wtScensToAvg(rv,expts) * sum(scenSet, s_bal_supdem(rv,expts,steps,scenSet,r,y,t,lb,scen)) ;
    r_peak_nz(rv,expts,rs,'avg',y,scen)                        = wtScensToAvg(rv,expts) * sum(scenSet, s_peak_nz(rv,expts,steps,scenSet,y,scen)) ;
    r_peak_ni(rv,expts,rs,'avg',y,scen)                        = wtScensToAvg(rv,expts) * sum(scenSet, s_peak_ni(rv,expts,steps,scenSet,y,scen)) ;
    r_noWindPeak_ni(rv,expts,rs,'avg',y,scen)                  = wtScensToAvg(rv,expts) * sum(scenSet, s_noWindPeak_ni(rv,expts,steps,scenSet,y,scen)) ;
    r_limit_maxgen(rv,expts,rs,'avg',g,y,t,lb,scen)            = wtScensToAvg(rv,expts) * sum(scenSet, s_limit_maxgen(rv,expts,steps,scenSet,g,y,t,lb,scen)) ;
    r_limit_mingen(rv,expts,rs,'avg',g,y,t,lb,scen)            = wtScensToAvg(rv,expts) * sum(scenSet, s_limit_mingen(rv,expts,steps,scenSet,g,y,t,lb,scen)) ;
    r_minutil(rv,expts,rs,'avg',g,y,scen)                      = wtScensToAvg(rv,expts) * sum(scenSet, s_minutil(rv,expts,steps,scenSet,g,y,scen)) ;
    r_limit_fueluse(rv,expts,rs,'avg',f,y,scen)                = wtScensToAvg(rv,expts) * sum(scenSet, s_limit_fueluse(rv,expts,steps,scenSet,f,y,scen)) ;
    r_limit_nrg(rv,expts,rs,'avg',f,y,scen)                    = wtScensToAvg(rv,expts) * sum(scenSet, s_limit_nrg(rv,expts,steps,scenSet,f,y,scen)) ;
    r_minreq_rennrg(rv,expts,rs,'avg',y,scen)                  = wtScensToAvg(rv,expts) * sum(scenSet, s_minreq_rennrg(rv,expts,steps,scenSet,y,scen)) ;
    r_minreq_rencap(rv,expts,rs,'avg',y)                       = wtScensToAvg(rv,expts) * sum(scenSet, s_minreq_rencap(rv,expts,steps,scenSet,y)) ;
    r_limit_hydro(rv,expts,rs,'avg',g,y,t,scen)                = wtScensToAvg(rv,expts) * sum(scenSet, s_limit_hydro(rv,expts,steps,scenSet,g,y,t,scen)) ;
    r_tx_capacity(rv,expts,rs,'avg',r,rr,y,t,lb,scen)          = wtScensToAvg(rv,expts) * sum(scenSet, s_tx_capacity(rv,expts,steps,scenSet,r,rr,y,t,lb,scen)) ;
*   Input parameters defined on scenarios.
    totalFuelCost(rv,g,y,'averageDispatch')                    = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * totalFuelCost(rv,g,y,scen)) ;
    CO2taxByPlant(rv,g,y,'averageDispatch')                    = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * CO2taxByPlant(rv,g,y,scen)) ;
    SRMC(rv,g,y,'averageDispatch')                             = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * SRMC(rv,g,y,scen)) ;
    NrgDemand(rv,r,y,t,lb,'averageDispatch')                   = sum((scenSet,scen)$avgDispatchSteptoRepStep(rv,expts,rs,steps,scenSet,scen), wtScensToAvg(rv,expts) * NrgDemand(rv,r,y,t,lb,scen)) ;
  ) ;
) ;

option s_TOTALCOST:3:0:2, r_TOTALCOST:3:0:2, allNotAvgDispatchSolves:0:0:1, allAvgDispatchSolves:0:0:1, mapStepsToRepSteps:0:0:1 ;
Display allNotAvgDispatchSolves, allAvgDispatchSolves, mapStepsToRepSteps, numScensToAvg, wtScensToAvg, s_TOTALCOST, r_TOTALCOST ;
* r_TX, r_BTX, r_REFURBCOST, r_BUILD, r_RETIRE, r_CAPACITY, r_TXCAPCHARGES, r_GEN, r_VOLLGEN
* r_LOSS, r_TXPROJVAR,  r_RESV, r_RESVVIOL, r_RESVCOMPONENTS, r_RENNRGPENALTY, r_PEAK_NZ_PENALTY, r_PEAK_NI_PENALTY, r_NOWINDPEAK_NI_PENALTY
* r_ANNMWSLACK, r_RENCAPSLACK, r_HYDROSLACK, r_MINUTILSLACK, r_FUELSLACK
* r_bal_supdem, r_peak_nz, r_peak_ni, r_noWindPeak_ni, r_limit_maxgen, r_limit_mingen, r_minutil
* r_limit_fueluse, r_limit_nrg, r_minreq_rennrg, r_minreq_rencap, r_limit_hydro, r_tx_capacity
* totalFuelCost, CO2taxByPlant, SRMC, NrgDemand



*===============================================================================================
* 4. Undertake the declarations and calculations necessary to prepare all that is to be reported.

Sets
  objc                                            'Objective function components'
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
  repDom(rv,expts,rs,scenSet)                     'The runVersions-experiments-repSteps-scenarioSets domain to be reported on - key it off of r_TOTALCOST(rv,expts,rs,scenSet)'
  sc(scen)                                        '(Dynamically) selected subsets of elements of scenarios'
  existBuildOrRetire(rv,expts,rs,scenSet,g,y)     'Plant and years in which any plant either exists, is built, is refurbished, or is retired'
  ;

Parameters
  cntr                                             'A counter'
  unDiscFactor(rv,y,t)                             "Factor to adjust or 'un-discount' and 'un-tax' shadow prices or revenues - by period and year"
  unDiscFactorYr(rv,y)                             "Factor to adjust or 'un-discount' and 'un-tax' shadow prices or revenues - by year (use last period of year)"
  scenarioWeight(scen)                             'Individual scenario weights'
  objComponents(*,*,*,*,objc)                      'Components of objective function value'
  builtByTechRegion(*,*,*,*,k,r)                   'Generating plant built by technology and region, MW'
  builtByTech(*,*,*,*,k)                           'Generating plant built by technology, MW'
  builtByRegion(*,*,*,*,r)                         'Generating plant built by region, MW'
  capacityByTechRegionYear(*,*,*,*,k,r,y)          'Generating capacity by technology and region and year, MW'
  capacityByTechYear(*,*,*,*,k,y)                  'Generating capacity by technology and year, MW'
  capacityByRegionYear(*,*,*,*,r,y)                'Generating capacity by region and year, MW'
  txUpgradeYearByProjectAndPath(*,*,*,*,tupg,r,rr) 'Transmission upgrade year by project and transmission path'
  txCapacityByYear(*,*,*,*,r,rr,y)                 'Transmission capacity in each year by transmission path, MW'
  txCapexByProjectYear(*,*,*,*,tupg,y)             'Transmission capital expenditure by project and year, $m'
  loadByRegionAndYear(*,*,*,*,r,y)                 'Load by region and year, GWh'
  genByTechRegionYear(*,*,*,*,k,r,y)               'Generation by technology and region and year, GWh'
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

* Capital expenditure
  builtByTechRegion(repDom,k,r) = sum((g,y)$( mapg_k(g,k) * mapg_r(g,r) ), r_BUILD(repDom,g,y)) ;

  capacityByTechRegionYear(repDom,k,r,y) = sum(g$( mapg_k(g,k) * mapg_r(g,r) ), r_CAPACITY(repDom,g,y)) ;

  txUpgradeYearByProjectAndPath(repDom,tupg,paths) = sum((ps,y)$(r_BTX(repDom,paths,ps,y) * r_TXPROJVAR(repDom,tupg,y)), yearNum(rv,y)) ;

  txCapacityByYear(repDom,paths,y) = sum(ps, i_txCapacity(rv,paths,ps) * r_BTX(repDom,paths,ps,y)) ;

* Operation
  loadByRegionAndYear(repDom,r,y) = sum((t,lb,sc), scenarioWeight(sc) * NrgDemand(rv,r,y,t,lb,sc)) ;

  genByTechRegionYear(repDom,k,r,y) = sum((g,t,lb,sc)$( mapg_k(g,k) * mapg_r(g,r) ), scenarioWeight(sc) * r_GEN(repDom,g,y,t,lb,sc)) ;

) ;

objComponents(repDom,'obj_Check') = sum(objc, objComponents(repDom,objc)) - objComponents(repDom,'obj_total') ;

builtByTech(repDom,k) = sum(r, builtByTechRegion(repDom,k,r)) ;

builtByRegion(repDom,r) = sum(k, builtByTechRegion(repDom,k,r)) ;

capacityByTechYear(repDom,k,y) = sum(r, capacityByTechRegionYear(repDom,k,r,y)) ;

capacityByRegionYear(repDom,r,y) = sum(k, capacityByTechRegionYear(repDom,k,r,y)) ;

txCapexByProjectYear(repDom,tupg,y)$r_TXPROJVAR(repDom,tupg,y) = sum(transitions(rv,tupg,paths,ps,pss), txCapitalCost(rv,paths,pss)) ;

option repDom:0:0:1 ;
Display repDom, weightScenariosBySet, objComponents, builtByTech, builtByRegion
* builtByTechRegion, capacityByTechRegionYear, capacityByTechYear, capacityByRegionYear
* txUpgradeYearByProjectAndPath, txCapacityByYear, txCapexByProjectYear
* loadByRegionAndYear, genByTechRegionYear
 ;

* Put output in a GDX file.
Execute_Unload "%OutPath%\rep%reportName%\All results - %reportName%.gdx", repDom weightScenariosBySet objComponents
 builtByTechRegion builtByTech builtByRegion capacityByTechRegionYear capacityByTechYear capacityByRegionYear txUpgradeYearByProjectAndPath txCapacityByYear txCapexByProjectYear
 loadByRegionAndYear genByTechRegionYear
 ;

$ontext
computations yet to be put in loop above.
Parameters
  txByRegionYear(*,*,*,*,r,rr,y)                    'Interregional transmission by year, GWh'
  txLossesByRegionYear(*,*,*,*,r,rr,y)              'Interregional transmission losses by year, GWh'
  energyPrice(*,*,*,*,r,y)                          'Time-weighted energy price by region and year, $/MWh (from marginal price off of energy balance constraint)'
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

  txByRegionYear(repDomLd,paths,y) = sum((t,lb,sc), 1e-3 * scenarioWeight(sc) * hoursPerBlock(rv,t,lb) * s_TX(repDomLd,paths,y,t,lb,sc)) ;

  txLossesByRegionYear(repDomLd,paths,y) = sum((t,lb,sc), 1e-3 * scenarioWeight(sc) * hoursPerBlock(rv,t,lb) * s_LOSS(repDomLd,paths,y,t,lb,sc)) ;

  energyPrice(repDomLd,r,y) = 1e3 * sum((t,lb,sc), unDiscFactor(rv,y,t) * hoursPerBlock(rv,t,lb) * s_bal_supdem(repDomLd,r,y,t,lb,sc)) / sum((t,lb), hoursPerBlock(rv,t,lb)) ;

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

* a) Objective function value breakdown
put objBrkDown 'Objective function value breakdown, all values are $million' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' loop(objc, put objc.tl ) ;
loop(repDom(rv,expts,rs,scenSet)$sum(objc, objComponents(repDom,objc)),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl loop(objc, put objComponents(repDom,objc)) ;
) ;
put // 'Descriptions' ;
put  / 'Objective function components' loop(objc, put / objc.tl, objc.te(objc)) ;
put // 'Run versions'  loop(rv, put / rv.tl, rv.te(rv)) ;
put // 'Experiments'   loop(expts, put / expts.tl, expts.te(expts)) ;
put // 'Steps'         loop(rs, put / rs.tl, rs.te(rs)) ;
put // 'Scenario sets' loop(scenSet, put / scenSet.tl, scenSet.te(scenSet)) ;

* b) Plant built by technology
put plantTech 'Plant built by technology, MW' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Technology' 'MW' ;
loop((repDom(rv,expts,rs,scenSet),k)$builtByTech(repDom,k),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, k.tl, builtByTech(repDom,k) ;
) ;

* c) Plant built by region
put plantReg 'Plant built by region, MW' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Region' 'MW' ;
loop((repDom(rv,expts,rs,scenSet),r)$builtByRegion(repDom,r),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, r.tl, builtByRegion(repDom,r) ;
) ;

* d) Generation capacity by plant and year
put capacityPlant 'Capacity by plant and year (net of retirements), MW' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Technology' 'Region' 'Plant' 'Year' 'MW' ;
loop((repDom(rv,expts,rs,scenSet),k,r,g,y)$( mapg_k(g,k) * mapg_r(g,r) * r_CAPACITY(repDom,g,y) ),
  put / rv.tl, expts.tl, rs.tl, scenSet.tl, k.tl, r.tl, g.tl, y.tl, r_CAPACITY(repDom,g,y) ;
) ;

* e) Generation capacity expansion - ordered by year and including retirements.
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
  loop(k$sum((foldRep(repDom,rep),r), builtByTechRegion(repDom,k,r)),
    put / k.tl
    loop(r$( card(isIldEqReg) <> 2 ), put sum(foldRep(repDom,rep), builtByTechRegion(repDom,k,r)) ) ;
    loop(aggR, put sum((foldRep(repDom,rep),r)$mapAggR_r(aggR,r), builtByTechRegion(repDom,k,r)) ) ;
    put '' ;
    loop(aggR,
      if(sum(maprv_rep(rv,rep), MWtoBuild(rv,k,aggR)) = 0, put '' else
        put (100 * sum((foldRep(repDom,rep),r)$mapAggR_r(aggR,r), builtByTechRegion(repDom,k,r)) / sum(maprv_rep(rv,rep), MWtoBuild(rv,k,aggR)) ) ;
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
  summaryResults    / "%OutPath%\%runName%\JC summary results - %runName%.csv" /
  summaryResultsJC  / "%OutPath%\%runName%\JC results - %runName%.csv" /
  blockResults      / "%OutPath%\%runName%\JC Blocks - %runName%.csv" / ;

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
    loop(r$( card(isIldEqReg) <> 2 ), put sum(singleDomain, builtByTechRegion(rv,singleDomain,k,r)) ) ;
    loop(aggR, put sum((singleDomain,r)$mapAggR_r(aggR,r), builtByTechRegion(rv,singleDomain,k,r)) ) ;
    put '' ;
    loop(aggR,
    if(MWtoBuild(rv,k,aggR) = 0, put '' else
      put (100 * sum((singleDomain,r)$mapAggR_r(aggR,r), builtByTechRegion(rv,singleDomain,k,r)) / MWtoBuild(rv,k,aggR)) ) ;
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
File PeakResults / "%OutPath%\%runName%\%runName% - %scenarioName% - PeakResults.txt" / ; PeakResults.lw = 0 ; PeakResults.pw = 999 ;
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
