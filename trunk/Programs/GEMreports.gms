* GEMreports.gms


* Last modified by Dr Phil Bishop, 21/05/2012 (imm@ea.govt.nz)


$ontext
  This program generates GEM reports - human-readable files or files to be read by other applications for further processing.
  It is to be invoked subsequent to the solving of all runs and run versions that are to be reported on. Note that GEMreports
  effectively starts afresh as a standalone program - it does "not" start from any previously created GAMS work files, and it
  imports or loads all of the data it requires. All symbols required in this program are declared here. Set membership and data
  values are imported from the default (or base case) run version input GDX file or merged GDX files.

  Notes:
  1. ...

 Code sections:
  1. Take care of preliminaries and declare output file names.
  2. Declare required symbols and load data.
  3. Undertake the declarations and calculations necesary to prepare all that is to be reported.
  4. Write key results to a CSV file.
  5. Write results to be plotted to a single csv file.

  x. Generate the remaining external files.
     a) Write an ordered (by year) summary of generation capacity expansion.
     b) Write out capacity report (capacityPlant) (is this redundant given expandSchedule?).
     c) Write out generation report (genPlant and genPlantYear).
     d) Write out annual report (variousAnnual).
  x. Do the John Culy report for TPR work - delete all of this once TPR is over.
$offtext


*** For now, the order of elements in set 'runVersions' in GEMreportSettings.inc must be consistent
*** with the order of the elements specified below in set rep (circa line 293).



*===============================================================================================
* 1. Take care of preliminaries and declare output file names.

option seed = 101 ;

$include GEMreportSettings.inc
$include "%OutPath%\%runName%\Input data checks\Configuration info for GEMreports - %runName%_%baseRunVersion%.inc"
$offupper offsymxref offsymlist offuellist offuelxref onempty inlinecom { } eolcom !

* Declare output files to be created by GEMreports.
Files
  keyResults     / "%OutPath%\%runName%\A collection of key results - %runName%.csv" /
  plotResults    / "%OutPath%\%runName%\Processed files\Results to be plotted - %runName%.csv" /
  expandSchedule / "%OutPath%\%runName%\Capacity expansion by year - %runName%.csv" /
  capacityPlant  / "%OutPath%\%runName%\Processed files\Capacity by plant and year (net of retirements) - %runName%.csv" /
  genPlant       / "%OutPath%\%runName%\Processed files\Generation and utilisation by plant - %runName%.csv" /
  tempTX         / "%OutPath%\%runName%\Processed files\Transmission build - %runName%.csv" /
  genPlantYear   / "%OutPath%\%runName%\Processed files\Generation and utilisation by plant (annually) - %runName%.csv" /
  variousAnnual  / "%OutPath%\%runName%\Processed files\Various annual results - %runName%.csv" /  ;

keyResults.pc = 5 ;      keyResults.pw = 999 ;
plotResults.pc = 5 ;     plotResults.pw = 999 ;
expandSchedule.pc = 5 ;  expandSchedule.pw = 999 ;
capacityPlant.pc = 5 ;   capacityPlant.pw = 999 ;
genPlant.pc = 5 ;        genPlant.pw = 999 ;
tempTX.pc = 5 ;          tempTX.pw = 999 ;
genPlantYear.pc = 5 ;    genPlantYear.pw = 999 ;
variousAnnual.pc = 5 ;   variousAnnual.pw = 999 ;



*===============================================================================================
* 2. Declare required symbols and load data.

* Declare and initialise hard-coded sets - copied from GEMdeclarations.
Sets
  steps             'Steps in an experiment'              / timing     'Solve the timing problem, i.e. timing of new generation/or transmission investment'
                                                            reopt      'Solve the re-optimised timing problem (generally with a drier hydro sequence) while allowing peakers to move'
                                                            dispatch   'Solve for the dispatch only with investment timing fixed'  /
  hydroSeqTypes     'Types of hydro sequences to use'     / Same       'Use the same sequence of hydro years to be used in every modelled year'
                                                            Sequential 'Use a sequentially developed mapping of hydro years to modelled years' /
  ild               'Islands'                             / ni         'North Island'
                                                            si         'South Island' /
  aggR              'Aggregate regional entities'         / ni         'North Island'
                                                            si         'South Island'
                                                            nz         'New Zealand' /
  col               'RGB color codes'                     / 0 * 256 /
  lvl               'Levels of non-free reserves'         / lvl1 * lvl5 / ;

* Initialise set y with values from GEMsettings.inc.
Set y 'Modelled calendar years' / %firstYear% * %lastYear% / ;

* Declare the fundamental sets that are required for reports.
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

Alias (i,ii), (r,rr), (ps,pss), (col,red,green,blue) ;

* Declare the selected subsets and mapping sets that are required for reports.
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
  isIldEqReg(ild,r)                'Figure out if the region labels are identical to the North and South island labels (a reporting facilitation device)' 
  demandGen(k)                     'Demand side technologies modelled as generation'
  exist(g)                         'Generation plant that are presently operating'
  sigen(g)                         'South Island generation plant' ;

* Load set membership from the GDX file containing the base case run version (the default GDX).
$gdxin "%OutPath%\%runName%\Input data checks\Selected prepared input data - %runName%_%baseRunVersion%.gdx"
$loaddc k f g s o i r e ps tupg t lb rc hY
$loaddc firstYr firstPeriod thermalFuel nwd swd paths mapg_k mapg_f mapg_o mapg_r mapg_e mapAggR_r isIldEqReg demandGen exist sigen
$loaddc techColor
* fuelColor fuelGrpColor

* Declare and load the parameters (variable levels and marginals) to be found in the merged 'allRV_ReportOutput' GDX file.
Parameters
  s_TOTALCOST(runVersions,experiments,steps,scenSet)                           'Discounted total system costs over all modelled years, $m (objective function value)'
  s_TX(runVersions,experiments,steps,scenSet,r,rr,y,t,lb,scen)                 'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
  s_BTX(runVersions,experiments,steps,scenSet,r,rr,ps,y)                       'Binary variable indicating the current state of a transmission path'
  s_REFURBCOST(runVersions,experiments,steps,scenSet,g,y)                      'Annualised generation plant refurbishment expenditure charge, $'
  s_BUILD(runVersions,experiments,steps,scenSet,g,y)                           'New capacity installed by generating plant and year, MW'
  s_RETIRE(runVersions,experiments,steps,scenSet,g,y)                          'Capacity endogenously retired by generating plant and year, MW'
  s_CAPACITY(runVersions,experiments,steps,scenSet,g,y)                        'Cumulative nameplate capacity at each generating plant in each year, MW'
  s_TXCAPCHARGES(runVersions,experiments,steps,scenSet,r,rr,y)                 'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  s_GEN(runVersions,experiments,steps,scenSet,g,y,t,lb,scen)                   'Generation by generating plant and block, GWh'
  s_VOLLGEN(runVersions,experiments,steps,scenSet,s,y,t,lb,scen)               'Generation by VOLL plant and block, GWh'
  s_LOSS(runVersions,experiments,steps,scenarioSets,r,rr,y,t,lb,scenarios)     'Transmission losses along each path, MW'
  s_TXPROJVAR(runVersions,experiments,steps,scenarioSets,tupg,y)               'Continuous 0-1 variable indicating whether an upgrade project is applied'
  s_RESV(runVersions,experiments,steps,scenSet,g,rc,y,t,lb,scen)               'Reserve energy supplied, MWh'
  s_RESVVIOL(runVersions,experiments,steps,scenSet,rc,ild,y,t,lb,scen)         'Reserve energy supply violations, MWh'
  s_RESVCOMPONENTS(runVersions,experiments,steps,scenSet,r,rr,y,t,lb,scen,lvl) 'Non-free reserve components, MW'
  s_RENNRGPENALTY(runVersions,experiments,steps,scenSet,y)                     'Penalty with cost of penaltyViolateRenNrg - used to make renewable energy constraint feasible, GWh'
  s_PEAK_NZ_PENALTY(runVersions,experiments,steps,scenSet,y,scen)              'Penalty with cost of penaltyViolatePeakLoad - used to make NZ security constraint feasible, MW'
  s_PEAK_NI_PENALTY(runVersions,experiments,steps,scenSet,y,scen)              'Penalty with cost of penaltyViolatePeakLoad - used to make NI security constraint feasible, MW'
  s_NOWINDPEAK_NI_PENALTY(runVersions,experiments,steps,scenSet,y,scen)        'Penalty with cost of penaltyViolatePeakLoad - used to make NI no wind constraint feasible, MW'
  s_ANNMWSLACK(runVersions,experiments,steps,scenSet,y)                        'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  s_RENCAPSLACK(runVersions,experiments,steps,scenSet,y)                       'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  s_HYDROSLACK(runVersions,experiments,steps,scenSet,y)                        'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  s_MINUTILSLACK(runVersions,experiments,steps,scenSet,y)                      'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  s_FUELSLACK(runVersions,experiments,steps,scenSet,y)                         'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'
  s_bal_supdem(runVersions,experiments,steps,scenSet,r,y,t,lb,scen)            'Balance supply and demand in each region, year, time period and load block'
  s_peak_nz(runVersions,experiments,steps,scenSet,y,scen)                      'Ensure enough capacity to meet peak demand and the winter capacity margin in NZ'
  s_peak_ni(runVersions,experiments,steps,scenSet,y,scen)                      'Ensure enough capacity to meet peak demand in NI subject to contingencies'
  s_noWindPeak_ni(runVersions,experiments,steps,scenSet,y,scen)                'Ensure enough capacity to meet peak demand in NI  subject to contingencies when wind is low'
  s_limit_maxgen(runVersions,experiments,steps,scenSet,g,y,t,lb,scen)          'Ensure generation in each block does not exceed capacity implied by max capacity factors'
  s_limit_mingen(runVersions,experiments,steps,scenSet,g,y,t,lb,scen)          'Ensure generation in each block exceeds capacity implied by min capacity factors'
  s_minutil(runVersions,experiments,steps,scenSet,g,y,scen)                    'Ensure certain generation plant meets a minimum utilisation'
  s_limit_fueluse(runVersions,experiments,steps,scenSet,f,y,scen)              'Quantum of each fuel used and possibly constrained, PJ'
  s_limit_nrg(runVersions,experiments,steps,scenSet,f,y,scen)                  'Impose a limit on total energy generated by any one fuel type'
  s_minreq_rennrg(runVersions,experiments,steps,scenSet,y,scen)                'Impose a minimum requirement on total energy generated from all renewable sources'
  s_minreq_rencap(runVersions,experiments,steps,scenSet,y)                     'Impose a minimum requirement on installed renewable capacity'
  s_limit_hydro(runVersions,experiments,steps,scenSet,g,y,t,scen)              'Limit hydro generation according to inflows'
  s_tx_capacity(runVersions,experiments,steps,scenSet,r,rr,y,t,lb,scen)        'Calculate the relevant transmission capacity' ;

$gdxin "%OutPath%\%runName%\GDX\allRV_ReportOutput_%runName%.gdx"
$loaddc s_TOTALCOST s_TX s_BTX s_REFURBCOST s_BUILD s_RETIRE s_CAPACITY s_TXCAPCHARGES s_GEN s_VOLLGEN s_LOSS s_TXPROJVAR s_RESV s_RESVVIOL s_RESVCOMPONENTS
$loaddc s_RENNRGPENALTY s_PEAK_NZ_PENALTY s_PEAK_NI_PENALTY s_NOWINDPEAK_NI_PENALTY
$loaddc s_ANNMWSLACK s_RENCAPSLACK s_HYDROSLACK s_MINUTILSLACK s_FUELSLACK
$loaddc s_bal_supdem s_peak_nz s_peak_ni s_noWindPeak_ni s_limit_maxgen s_limit_mingen s_minutil s_limit_fueluse s_limit_Nrg
$loaddc s_minReq_RenNrg s_minReq_RenCap s_limit_hydro s_tx_capacity


* Declare and load sets and parameters from the merged 'allRV_SelectedInputData' GDX file.
Sets
  possibleToBuild(runVersions,g)                       'Generating plant that may possibly be built in any valid build year'
  possibleToRefurbish(runVersions,g)                   'Generating plant that may possibly be refurbished in any valid modelled year'
  possibleToEndogRetire(runVersions,g)                 'Generating plant that may possibly be endogenously retired'
  possibleToRetire(runVersions,g)                      'Generating plant that may possibly be retired (exogenously or endogenously)'
  validYrOperate(runVersions,g,y)                      'Valid years in which an existing, committed or new plant can generate. Use to fix GEN to zero in invalid years'
  transitions(runVersions,tupg,r,rr,ps,pss)            'For all transmission paths, define the allowable transitions from one upgrade state to another' ;

Parameters
  i_fuelQuantities(runVersions,f,y)                    'Quantitative limit on availability of various fuels by year, PJ'
  i_namePlate(runVersions,g)                           'Nameplate capacity of generating plant, MW'
  i_heatrate(runVersions,g)                            'Heat rate of generating plant, GJ/GWh (default = 3600)'
  i_txCapacity(runVersions,r,rr,ps)                    'Transmission path capacities (bi-directional), MW'
  txCapitalCost(runVersions,r,rr,ps)                   'Capital cost of transmission upgrades by path and state, $m'
  totalFuelCost(runVersions,g,y,scen)                  'Total fuel cost - price plus fuel production and delivery charges all times heatrate - by plant, year and scenario, $/MWh'
  CO2taxByPlant(runVersions,g,y,scen)                  'CO2 tax by plant, year and scenario, $/MWh'
  SRMC(runVersions,g,y,scen)                           'Short run marginal cost of each generation project by year and scenario, $/MWh'
  i_fixedOM(runVersions,g)                             'Fixed O&M costs by plant, $/kW/year'
  ensembleFactor(runVersions,g)                        'Collection of total cost adjustment factors by plant (e.g. location factors and hydro peaking factors)'
  i_HVDCshr(runVersions,o)                             'Share of HVDC charge to be incurred by plant owner'
  i_HVDClevy(runVersions,y)                            'HVDC charge levied on new South Island plant by year, $/kW'
  i_plantReservesCost(runVersions,g,rc)                'Plant-specific cost per reserve class, $/MWh'
  hoursPerBlock(runVersions,t,lb)                      'Hours per load block by time period'
  NrgDemand(runVersions,r,y,t,lb,scen)                 'Load (or energy demand) by region, year, time period and load block, GWh (used to create ldcMW)'
  yearNum(runVersions,y)                               'Real number associated with each year'
  PVfacG(runVersions,y,t)                              "Generation investor's present value factor by period"
  PVfacT(runVersions,y,t)                              "Transmission investor's present value factor by period"
  capCharge(runVersions,g,y)                           'Annualised or levelised capital charge for new generation plant, $/MW/yr'
  refurbCapCharge(runVersions,g,y)                     'Annualised or levelised capital charge for refurbishing existing generation plant, $/MW/yr'
  MWtoBuild(runVersions,k,aggR)                        'MW available for installation by technology, island and NZ'
  penaltyViolateReserves(runVersions,ild,rc)           'Penalty for failing to meet certain reserve classes, $/MW'
  pNFresvCost(runVersions,r,rr,lvl)                    'Constant cost of each non-free piece (or level) of function, $/MWh'
  exogMWretired(runVersions,g,y)                       'Exogenously retired MW by plant and year, MW' ;

$gdxin "%OutPath%\%runName%\Input data checks\allRV_SelectedInputData_%runName%.gdx"
$loaddc possibleToBuild possibleToRefurbish possibleToEndogRetire possibleToRetire validYrOperate transitions
$loaddc i_fuelQuantities i_namePlate i_heatrate i_txCapacity txCapitalCost totalFuelCost CO2taxByPlant SRMC i_fixedOM ensembleFactor i_HVDCshr i_HVDClevy
$loaddc i_plantReservesCost hoursPerBlock NrgDemand yearNum PVfacG PVfacT capCharge refurbCapCharge MWtoBuild penaltyViolateReserves pNFresvCost exogMWretired



*===============================================================================================
* 3. Undertake the declarations and calculations necesary to prepare all that is to be reported.

Sets
  sc(scen)                                                      '(Dynamically) selected subsets of elements of scenarios'
  rv(runVersions)                                               'The runVersions loaded into GEMreports'
  repDomLd(runVersions,experiments,steps,scenSet)               'The runVersions-experiments-steps-scenarioSets tuples loaded into GEMreports'
  repDom(runVersions,experiments,steps,scenSet)                 'The user-specified runVersions-experiments-steps-scenarioSets subset to be reported on'
  existBuildOrRetire(runVersions,experiments,steps,scenSet,g,y) 'Plant and years in which any plant either exists, is built, is refurbished or is retired'
  objc                                                          'Objective function components'
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
                                                                 obj_Slacks     'Value of all slacks' / ;

Parameters
  cntr                                              'A counter'
  unDiscFactor(runVersions,y,t)                     "Factor to adjust or 'un-discount' and 'un-tax' shadow prices or revenues - by period and year"
  unDiscFactorYr(runVersions,y)                     "Factor to adjust or 'un-discount' and 'un-tax' shadow prices or revenues - by year (use last period of year)"
  objComponents(*,*,*,*,objc)                       'Components of objective function value'
  scenarioWeight(scen)                              'Individual scenario weights'
  loadByRegionAndYear(*,*,*,*,r,y)                  'Load by region and year, GWh'
  builtByTechRegion(*,*,*,*,k,r)                    'MW built by technology and region/island'
  builtByTech(*,*,*,*,k)                            'MW built by technology'
  builtByRegion(*,*,*,*,r)                          'MW built by region/island'
  capacityByTechRegionYear(*,*,*,*,k,r,y)           'Capacity by technology and region/island and year, MW'
  genByTechRegionYear(*,*,*,*,k,r,y)                'Generation by technology and region/island and year, GWh'
  txUpgradeYearByProjectAndPath(*,*,*,*,tupg,r,rr)  'Transmission upgrade year by project and transmission path'
  txCapacityByYear(*,*,*,*,r,rr,y)                  'Transmission capacity in each year by transmission path, MW'
  txCapexByProjectYear(*,*,*,*,tupg,y)              'Transmission capital expenditure by project and year, $m'
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

repDomLd(runVersions,expts,steps,scenSet)$s_TOTALCOST(runVersions,expts,steps,scenSet) = yes ; 
rv(runVersions)$sum(repDomLd(runVersions,expts,steps,scenSet), 1) = yes ;


**+++++++++++++++++
* For now, make repDom equal to repDomLd. When GEM gets back into emi, repDom will come from emi.
repDom(runVersions,experiments,steps,scenSet)$repDomLd(runVersions,experiments,steps,scenSet) = yes ;

* Moreover, the mapping of the report domain (repdom <= repdomL) will also come from emi. Each solve to be reported on needs to be given a name - perhaps
* a concatenation of the (runVersions,experiments,steps,scenSet) tuple? In the meantime, use the following code to flatten the 4-dimensional tuple into a
* single-dimensioned set called rep.
Sets
  rep                                               'Individual solutions to be reported on in the key results file' /
                                                     mds1Tmg   'Sustainable path - timing'
                                                     mds2Tmg   'South Island wind - timing'
                                                     mds3Tmg   'Medium renewables - timing'
                                                     mds4Tmg   'Coal - timing'
                                                     mds5Tmg   'High gas discovery - timing'
                                                     rep6 * rep50  /
  activeRep(rep)                                    'The active elements from set rep'
  foldRep(runVersions,expts,steps,scenSet,rep)      'Fold the (rv,expts,steps,scenSet)-tuple into the set rep'
  maprv_rep(runVersions,rep)                        'Map runVersions into rep'
  ;

option foldRep(repDom:rep) ;

activeRep(rep)$sum(foldRep(repDom,rep), 1) = yes ;

maprv_rep(rv,activeRep(rep))$sum(foldRep(rv,expts,steps,scenSet,rep), 1) = yes ;

option foldRep:0:0:1 Display foldRep, activeRep, maprv_rep ;
**+++++++++++++++++


existBuildOrRetire(repDomLd,g,y)$( exist(g) * firstYr(y) ) = yes ;
existBuildOrRetire(repDomLd(rv,expts,steps,scenSet),g,y)$( s_BUILD(repDomLd,g,y) or s_RETIRE(repDomLd,g,y) or exogMWretired(rv,g,y) ) = yes ;
 
unDiscFactor(rv,y,t) = 1 / ( (1 - taxRate) * PVfacG(rv,y,t) ) ;
unDiscFactorYr(rv,y) = sum(t$( ord(t) = card(t) ), unDiscFactor(rv,y,t)) ;

* This loop is on the domain of all that is loaded into GEMreports. It may be the case that only a subset of this is actually reported in output files.
loop(repDomLd(rv,expts,steps,scenSet),

* Initialise the scenarios for this particular solve (or loaded domain).
  sc(scen) = no ;
  sc(scen)$mapScenarios(scenSet,scen) = yes ;

* Select the scenario weights for this particular solve.
  scenarioWeight(sc) = 0 ;
  scenarioWeight(sc) = weightScenariosBySet(scenSet,sc) ;

  objComponents(repDomLd,'obj_total')     = s_TOTALCOST(repDomLd) ;
  objComponents(repDomLd,'obj_gencapex')  = 1e-6 * sum((y,firstPeriod(t),possibleToBuild(rv,g)), PVfacG(rv,y,t) * ensembleFactor(rv,g) * capCharge(rv,g,y) * s_CAPACITY(repDomLd,g,y) ) ;
  objComponents(repDomLd,'obj_refurb')    = 1e-6 * sum((y,firstPeriod(t),possibleToRefurbish(rv,g))$refurbCapCharge(rv,g,y), PVfacG(rv,y,t) * s_REFURBCOST(repDomLd,g,y) ) ;
  objComponents(repDomLd,'obj_txcapex')   = sum((paths,y,firstPeriod(t)), PVfacT(rv,y,t) * s_TXCAPCHARGES(repDomLd,paths,y) ) ;
  objComponents(repDomLd,'obj_fixOM')     = 1e-3 * (1 - taxRate) * sum((g,y,t), PVfacG(rv,y,t) * ( 1/card(t) ) * ensembleFactor(rv,g) * i_fixedOM(rv,g) * s_CAPACITY(repDomLd,g,y) ) ;
  objComponents(repDomLd,'obj_varOM')     = 1e-3 * (1 - taxRate) * sum((validYrOperate(rv,g,y),t,lb,sc), scenarioWeight(sc) * PVfacG(rv,y,t) * ensembleFactor(rv,g) * srmc(rv,g,y,sc) * s_GEN(repDomLd,g,y,t,lb,sc) ) ;
  objComponents(repDomLd,'obj_hvdc')      = 1e-3 * (1 - taxRate) * sum((y,t), PVfacG(rv,y,t) * ( 1/card(t) ) * (
                                              sum((g,k,o)$((not demandGen(k)) * mapg_k(g,k) * sigen(g) * possibleToBuild(rv,g) * mapg_o(g,o)), i_HVDCshr(rv,o) * ensembleFactor(rv,g) * i_HVDClevy(rv,y) * s_CAPACITY(repDomLd,g,y)) ) ) ;
  objComponents(repDomLd,'VOLLcost')      = 1e-3 * (1 - taxRate) * VOLLcost * sum((s,y,t,lb,sc), scenarioWeight(sc) * PVfacG(rv,y,t) * s_VOLLGEN(repDomLd,s,y,t,lb,sc) ) ;
  objComponents(repDomLd,'obj_rescosts')  = 1e-6 * (1 - taxRate) * sum((g,rc,y,t,lb,sc), PVfacG(rv,y,t) * scenarioWeight(sc) * i_plantReservesCost(rv,g,rc) * ensembleFactor(rv,g) * s_RESV(repDomLd,g,rc,y,t,lb,sc) ) ;
  objComponents(repDomLd,'obj_resvviol')  = 1e-6 * sum((rc,ild,y,t,lb,sc), scenarioWeight(sc) * s_RESVVIOL(repDomLd,rc,ild,y,t,lb,sc) * penaltyViolateReserves(rv,ild,rc) ) ;
  objComponents(repDomLd,'obj_nfrcosts')  = 1e-6 * (1 - taxRate) * sum((y,t,lb), PVfacG(rv,y,t) * (
                                                   sum((paths,lvl,sc)$( nwd(paths) or swd(paths) ), hoursPerBlock(rv,t,lb) * scenarioWeight(sc) * s_RESVCOMPONENTS(repDomLd,paths,y,t,lb,sc,lvl) * pNFresvcost(rv,paths,lvl) ) ) ) ;
  objComponents(repDomLd,'obj_Penalties') = sum((y,sc), scenarioWeight(sc) * (
                                              1e-3 * penaltyViolateRenNrg * s_RENNRGPENALTY(repDomLd,y) +
                                              1e-6 * penaltyViolatePeakLoad * ( s_PEAK_NZ_PENALTY(repDomLd,y,sc) + s_PEAK_NI_PENALTY(repDomLd,y,sc) + s_NOWINDPEAK_NI_PENALTY(repDomLd,y,sc) ) )
                                            ) ;
  objComponents(repDomLd,'obj_Slacks')    = slackCost * sum(y, s_ANNMWSLACK(repDomLd,y) + s_RENCAPSLACK(repDomLd,y) + s_HYDROSLACK(repDomLd,y) +
                                                               s_MINUTILSLACK(repDomLd,y) + s_FUELSLACK(repDomLd,y) ) ;

  builtByTechRegion(repDomLd,k,r) = sum((g,y)$( mapg_k(g,k) * mapg_r(g,r) ), s_BUILD(repDomLd,g,y)) ;

  capacityByTechRegionYear(repDomLd,k,r,y) = sum(g$( mapg_k(g,k) * mapg_r(g,r) ), s_CAPACITY(repDomLd,g,y)) ;

  genByTechRegionYear(repDomLd,k,r,y) = sum((g,t,lb,sc)$( mapg_k(g,k) * mapg_r(g,r) ), scenarioWeight(sc) * s_GEN(repDomLd,g,y,t,lb,sc)) ;

  txUpgradeYearByProjectAndPath(repDomLd,tupg,paths) = sum((ps,y)$(s_BTX(repDomLd,paths,ps,y) * s_TXPROJVAR(repDomLd,tupg,y)), yearNum(rv,y)) ;

  txCapacityByYear(repDomLd,paths,y) = sum(ps, i_txCapacity(rv,paths,ps) * s_BTX(repDomLd,paths,ps,y)) ;

  txCapexByProjectYear(repDomLd,tupg,y)$s_TXPROJVAR(repDomLd,tupg,y) = sum(transitions(rv,tupg,paths,ps,pss), txCapitalCost(rv,paths,pss)) ;

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

  loadByRegionAndYear(repDomLd,r,y) = sum((t,lb,sc), scenarioWeight(sc) * NrgDemand(rv,r,y,t,lb,sc)) ;

) ;

objComponents(repDomLd,'obj_Check') = sum(objc, objComponents(repDomLd,objc)) - objComponents(repDomLd,'obj_total') ;

option transitions:0:0:1, txCapacityByYear:0:0:1 ;

Display
  repDomLd, rv, existBuildOrRetire, unDiscFactor, unDiscFactorYr, objComponents
* builtByTechRegion, capacityByTechRegionYear, genByTechRegionYear, txUpgradeYearByProjectAndPath, txCapacityByYear, txCapexByProjectYear, txByRegionYear, txLossesByRegionYear
* energyPrice, minEnergyPrice, minUtilEnergyPrice, peakNZPrice, peakNIPrice, peaknoWindNIPrice, renewEnergyShrPrice, renewCapacityShrPrice, fuelPrice, energyLimitPrice
  loadByRegionAndYear ;



*===============================================================================================
* 4. Write key results to a CSV file.

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

put /// 'Capacity by technology and region and year, MW (existing plus built less retired)' ;
loop(activeRep(rep),
  put / rep.tl, rep.te(rep) / '' '' loop(y, put y.tl ) ;
  loop((k,r)$sum((foldRep(repDom,rep),y), capacityByTechRegionYear(repDom,k,r,y)),
    put / k.tl, r.tl loop(y, put sum(foldRep(repDom,rep), capacityByTechRegionYear(repDom,k,r,y)) ) ;
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

* a) Write an ordered (by year) summary of generation capacity expansion.
put expandSchedule 'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Technology' 'Plant' 'NameplateMW' 'ExistMW' 'BuildYr', 'BuildMW'
  'RetireType' 'RetireYr' 'RetireMW' 'Capacity' ;
loop((repDomLd(rv,expts,steps,scenSet),y,k,g)$( mapg_k(g,k) * existBuildOrRetire(repDomLd,g,y) ),
  put / rv.tl, expts.tl, steps.tl, scenSet.tl, k.tl, g.tl, i_namePlate(rv,g) ;
  if(exist(g), put i_namePlate(rv,g) else put '' ) ;
  if(s_BUILD(repDomLd,g,y), put yearNum(rv,y), s_BUILD(repDomLd,g,y) else put '' '' ) ;
  if(possibleToRetire(rv,g) * ( s_RETIRE(repDomLd,g,y) or exogMWretired(rv,g,y) ),
    if( ( possibleToEndogRetire(rv,g) * s_RETIRE(repDomLd,g,y) ),
      put 'Endogenous', yearNum(rv,y), s_RETIRE(repDomLd,g,y) else put 'Exogenous', yearNum(rv,y), exogMWretired(rv,g,y) ;
    ) else  put '' '' '' ;
  ) ;
) ;


* b) Write out capacity report (capacityPlant) (is this redundant given expandSchedule?).
put capacityPlant 'Capacity by plant and year (net of retirements), MW' / 'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Plant' 'Year' 'MW' ;
loop((repDomLd(rv,expts,steps,scenSet),g,y)$s_CAPACITY(repDomLd,g,y),
  put / rv.tl, expts.tl, steps.tl, scenSet.tl, g.tl, y.tl, s_CAPACITY(repDomLd,g,y) ;
) ;


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
