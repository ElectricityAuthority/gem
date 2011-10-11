* GEMreports.gms


* Last modified by Dr Phil Bishop, 11/10/2011 (imm@ea.govt.nz)


$ontext
 This program generates GEM reports - human-readable files, files to be read by other applications for further processing,
 or pictures. It is to be invoked subsequent to GEMsolve. It does "not" start from GEMdeclarations.g00. All symbols required
 in this program are declared here. Set membership and data values are imported from the default (or base case) run version
 input GDX file or merged GDX files.

 Code sections:
  1. Declare required symbols and load data.
  2. Perform the calculations to be reported.
  3. Write summary results to a csv file (for reportDomain only).
  4. Generate the remaining external files.
     a) Write results to be plotted to a single csv file.
     b) Write an ordered (by year) summary of generation capacity expansion.
     c) Write out capacity report (capacityPlant) (is this redundant given expandSchedule?).
     d) Write out generation report (genPlant and genPlantYear).
     e) Write out annual report (variousAnnual).
$offtext

option seed = 101 ;
$include GEMsettings.inc
$include GEMpathsAndFiles.inc
$offupper offsymxref offsymlist offuellist offuelxref onempty inlinecom { } eolcom !

* Declare output files to be created by GEMreports.
Files
  plotBat        / "%OutPath%\%runName%\Archive\GEMplots.bat" /
  plotResults    / "%OutPath%\%runName%\Processed files\Results to be plotted - %runName%.csv" /
  summaryResults / "%OutPath%\%runName%\Summary results - %runName%.csv" /
  expandSchedule / "%OutPath%\%runName%\Capacity expansion by year - %runName%.csv" /
  capacityPlant  / "%OutPath%\%runName%\Processed files\Capacity by plant and year (net of retirements) - %runName%.csv" /
  genPlant       / "%OutPath%\%runName%\Processed files\Generation and utilisation by plant - %runName%.csv" /
  genPlantYear   / "%OutPath%\%runName%\Processed files\Generation and utilisation by plant (annually) - %runName%.csv" /
  variousAnnual  / "%OutPath%\%runName%\Processed files\Various annual results - %runName%.csv" /
  ;

plotBat.lw = 0 ;
plotResults.pc = 5 ;     plotResults.pw = 999 ;
summaryResults.pc = 5 ;  summaryResults.pw = 999 ;
expandSchedule.pc = 5 ;  expandSchedule.pw = 999 ;
capacityPlant.pc = 5 ;   capacityPlant.pw = 999 ;
genPlant.pc = 5 ;        genPlant.pw = 999 ;
genPlantYear.pc = 5 ;    genPlantYear.pw = 999 ;
variousAnnual.pc = 5 ;   variousAnnual.pw = 999 ;



*===============================================================================================
* 1. Declare required symbols and load data.

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
  ;

* Initialise set y with values from GEMsettings.inc.
Set y 'Modelled calendar years' / %firstYear% * %lastYear% / ;

* Declare the fundamental sets required for reporting.
Sets
  k                 'Generation technologies'
  f                 'Fuels'
  g                 'Generation plant'
  s                 'Shortage or VOLL plants'
  o                 'Owners of generating plant'
  i                 'Substations'
  r                 'Regions'
  e                 'Zones'
  t                 'Time periods (within a year)'
  lb                'Load blocks'
  rc                'Reserve classes'
  hY                'Hydrology output years' ;

Alias (i,ii), (r,rr), (col,red,green,blue) ;

* Declare the selected subsets and mapping sets required for reporting.
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

* Load set membership from the GDX file containing the default or base case run version.
$gdxin "%OutPath%\%runName%\Input data checks\Selected prepared input data - %runName%_%baseRunVersion%.gdx"
$loaddc k f g s o i r e t lb rc hY
$loaddc firstYr firstPeriod thermalFuel nwd swd paths mapg_k mapg_f mapg_o mapg_r mapg_e mapAggR_r isIldEqReg demandGen exist sigen
$loaddc techColor
* fuelColor fuelGrpColor

* Need steps for the non-free reserves stuff - this may yet get deleted!
Set stp 'Steps'  / stp1 * stp5 / ;

* Include GEMstochastic - can't do this until hY and hydroSeqTypes are loaded 
$include GEMstochastic.inc
Alias(scenarios,scen), (scenarioSets,scenSet) ;

* Declare and load the parameters (variable levels and marginals) to be found in the merged 'all_ReportOutput' GDX file.
Parameters
  s_TOTALCOST(runVersions,experiments,steps,scenSet)                           'Discounted total system costs over all modelled years, $m (objective function value)'
  s_TX(runVersions,experiments,steps,scenSet,r,rr,y,t,lb,scen)                 'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
  s_REFURBCOST(runVersions,experiments,steps,scenSet,g,y)                      'Annualised generation plant refurbishment expenditure charge, $'
  s_BUILD(runVersions,experiments,steps,scenSet,g,y)                           'New capacity installed by generating plant and year, MW'
  s_RETIRE(runVersions,experiments,steps,scenSet,g,y)                          'Capacity endogenously retired by generating plant and year, MW'
  s_CAPACITY(runVersions,experiments,steps,scenSet,g,y)                        'Cumulative nameplate capacity at each generating plant in each year, MW'
  s_TXCAPCHARGES(runVersions,experiments,steps,scenSet,r,rr,y)                 'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  s_GEN(runVersions,experiments,steps,scenSet,g,y,t,lb,scen)                   'Generation by generating plant and block, GWh'
  s_VOLLGEN(runVersions,experiments,steps,scenSet,s,y,t,lb,scen)               'Generation by VOLL plant and block, GWh'
  s_RESV(runVersions,experiments,steps,scenSet,g,rc,y,t,lb,scen)               'Reserve energy supplied, MWh'
  s_RESVVIOL(runVersions,experiments,steps,scenSet,rc,ild,y,t,lb,scen)         'Reserve energy supply violations, MWh'
  s_RESVCOMPONENTS(runVersions,experiments,steps,scenSet,r,rr,y,t,lb,scen,stp) 'Non-free reserve components, MW'
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
  s_noWindPeak_ni(runVersions,experiments,steps,scenSet,y,scen)                'Ensure enough capacity to meet peak demand in NI  subject to contingencies when wind is low' ;

$gdxin "%OutPath%\%runName%\GDX\allRV_ReportOutput.gdx"
$loaddc s_TOTALCOST s_TX s_REFURBCOST s_BUILD s_RETIRE s_CAPACITY s_TXCAPCHARGES s_GEN s_VOLLGEN s_RESV s_RESVVIOL s_RESVCOMPONENTS
$loaddc s_RENNRGPENALTY s_PEAK_NZ_PENALTY s_PEAK_NI_PENALTY s_NOWINDPEAK_NI_PENALTY
$loaddc s_ANNMWSLACK s_RENCAPSLACK s_HYDROSLACK s_MINUTILSLACK s_FUELSLACK
$loaddc s_bal_supdem s_peak_nz s_peak_ni s_noWindPeak_ni

* Declare and load sets and parameters from the merged 'all_SelectedInputData' GDX file.
Sets
  possibleToBuild(runVersions,g)                       'Generating plant that may possibly be built in any valid build year'
  possibleToRefurbish(runVersions,g)                   'Generating plant that may possibly be refurbished in any valid modelled year'
  possibleToEndogRetire(runVersions,g)                 'Generating plant that may possibly be endogenously retired'
  possibleToRetire(runVersions,g)                      'Generating plant that may possibly be retired (exogenously or endogenously)'
  validYrOperate(runVersions,g,y)                      'Valid years in which an existing, committed or new plant can generate. Use to fix GEN to zero in invalid years' ;

Parameters
  i_fuelQuantities(runVersions,f,y)                    'Quantitative limit on availability of various fuels by year, PJ'
  i_namePlate(runVersions,g)                           'Nameplate capacity of generating plant, MW'
  i_heatrate(runVersions,g)                            'Heat rate of generating plant, GJ/GWh (default = 3600)'
  totalFuelCost(runVersions,g,y,scen)                  'Total fuel cost - price plus fuel production and delivery charges all times heatrate - by plant, year and scenario, $/MWh'
  CO2taxByPlant(runVersions,g,y,scen)                  'CO2 tax by plant, year and scenario, $/MWh'
  SRMC(runVersions,g,y,scen)                           'Short run marginal cost of each generation project by year and scenario, $/MWh'
  i_fixedOM(runVersions,g)                             'Fixed O&M costs by plant, $/kW/year'
  i_VOLLcost(runVersions,s)                            'Value of lost load by VOLL plant (1 VOLL plant/region), $/MWh'
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
  locFac_Recip(runVersions,e)                          'Reciprocal of zonally-based location factors'
  penaltyViolateReserves(runVersions,ild,rc)           'Penalty for failing to meet certain reserve classes, $/MW'
  pNFresvCost(runVersions,r,rr,stp)                    'Constant cost of each non-free piece (or step) of function, $/MWh'
  exogMWretired(runVersions,g,y)                       'Exogenously retired MW by plant and year, MW' ;

$gdxin "%OutPath%\%runName%\Input data checks\allRV_SelectedInputData.gdx"
$loaddc possibleToBuild possibleToRefurbish possibleToEndogRetire possibleToRetire validYrOperate
$loaddc i_fuelQuantities i_namePlate i_heatrate totalFuelCost CO2taxByPlant SRMC i_fixedOM i_VOLLcost i_HVDCshr i_HVDClevy i_plantReservesCost
$loaddc hoursPerBlock NrgDemand yearNum PVfacG PVfacT capCharge refurbCapCharge MWtoBuild locFac_recip penaltyViolateReserves pNFresvCost exogMWretired



*===============================================================================================
* 2. Perform the calculations to be reported.

Sets
  rv(runVersions)                                                   'All runVersions loaded into GEMreports'
  rvExpStepsScenSet(runVersions,experiments,steps,scenSet)          'All run version-experiment-steps-scenarioSets tuples loaded into GEMreports'
  reportDomain(experiments,steps,scenSet)                           'The single experiment-steps-scenarioSets tuple to be used in summmary report'
  rvRD(runVersions)                                                 'The runVersions to be used in summmary report'
  sc(scen)                                                          '(Dynamically) selected elements of scenarios'
  existBuildOrRetire(runVersions,experiments,steps,scenSet,g,y)     'Plant and years in which any plant either exists, is built, is refurbished or is retired'
  objc                                             'Objective function components'
                                                  / obj_Check       'Check that sum of all components including TOTALCOST less TOTALCOST equals TOTALCOST'
                                                    obj_total       'Objective function value'
                                                    obj_gencapex    'Discounted levelised generation plant capital costs'
                                                    obj_refurb      'Discounted levelised refurbishment capital costs'
                                                    obj_txcapex     'Discounted levelised transmission capital costs'
                                                    obj_fixOM       'After tax discounted fixed costs at generation plant'
                                                    obj_varOM       'After tax discounted variable costs at generation plant'
                                                    obj_hvdc        'After tax discounted HVDC charges'
                                                    VOLLcost        'After tax discounted value of lost load'
                                                    obj_rescosts    'After tax discounted reserve costs at generation plant'
                                                    obj_resvviol    'Penalty cost of failing to meet reserves'
                                                    obj_nfrcosts    'After tax discounted cost of non-free reserve cover for HVDC'
                                                    obj_Penalties   'Value of all penalties'
                                                    obj_Slacks      'Value of all slacks' / ;

Parameters
  cntr                                             'A counter'
  unDiscFactor(runVersions,y,t)                    "Factor to adjust or 'un-discount' and 'un-tax' shadow prices and values - by period and year"
  unDiscFactorYr(runVersions,y)                    "Factor to adjust or 'un-discount' and 'un-tax' shadow prices and values - by year (use last period of year)"
  objComponents(*,*,*,*,objc)                      'Components of objective function value'
  scenarioWeight(scen)                             'Individual scenario weights'
  loadByRegionAndYear(*,*,*,*,r,y)                 'Load by region and year, GWh'
  builtByTechRegion(*,*,*,*,k,r)                   'MW built by technology and region/island'
  builtByTech(*,*,*,*,k)                           'MW built by technology'
  builtByRegion(*,*,*,*,r)                         'MW built by region/island'
  capacityByTechRegionYear(*,*,*,*,k,r,y)          'Capacity by technology and region/island and year, MW'
  genByTechRegionYear(*,*,*,*,k,r,y)               'Generation by technology and region/island and year, GWh'
  txByRegionYear(*,*,*,*,r,rr,y)                   'Interregional transmission by year, GWh'
  energyPrice(*,*,*,*,r,y)                         'Time-weighted energy price by region and year, $/MWh (from marginal price off of energy balance constraint)'
  peakNZPrice(*,*,*,*,y)                           'Shadow price off peak NZ constraint, $/kW'
  peakNIPrice(*,*,*,*,y)                           'Shadow price off peak NI constraint, $/kW'
  peaknoWindNIPrice(*,*,*,*,y)                     'Shadow price off peak no wind NI constraint, $/kW'
  ;

rv(runVersions)$sum((experiments,steps,scenSet)$s_TOTALCOST(runVersions,experiments,steps,scenSet), 1) = yes ;
rvExpStepsScenSet(rv,experiments,steps,scenSet)$s_TOTALCOST(rv,experiments,steps,scenSet) = yes ; 

reportDomain(%reportDomain%) = yes ;
rvRD(rv)$sum(reportDomain, s_TOTALCOST(rv,reportDomain)) = yes ;

existBuildOrRetire(rvExpStepsScenSet,g,y)$( exist(g) * firstYr(y) ) = yes ;
existBuildOrRetire(rvExpStepsScenSet(rv,experiments,steps,scenSet),g,y)$( s_BUILD(rvExpStepsScenSet,g,y) or s_RETIRE(rvExpStepsScenSet,g,y) or exogMWretired(rv,g,y) ) = yes ;
 
unDiscFactor(rv,y,t) = 1 / ( (1 - taxRate) * PVfacG(rv,y,t) ) ;
unDiscFactorYr(rv,y) = sum(t$( ord(t) = card(t) ), unDiscFactor(rv,y,t)) ;

loop(rvExpStepsScenSet(rv,experiments,steps,scenSet),

* Initialise the scenarios for this particular solve.
  sc(scen) = no ;
  sc(scen)$mapScenarios(scenSet,scen) = yes ;

* Select the scenario weights for this particular solve.
  scenarioWeight(sc) = 0 ;
  scenarioWeight(sc) = weightScenariosBySet(scenSet,sc) ;

  objComponents(rvExpStepsScenSet,'obj_total')     = s_TOTALCOST(rvExpStepsScenSet) ;
  objComponents(rvExpStepsScenSet,'obj_gencapex')  = 1e-6 * sum((y,firstPeriod(t),possibleToBuild(rv,g)), PVfacG(rv,y,t) * capCharge(rv,g,y) * s_CAPACITY(rvExpStepsScenSet,g,y) ) ;
  objComponents(rvExpStepsScenSet,'obj_refurb')    = 1e-6 * sum((y,firstPeriod(t),possibleToRefurbish(rv,g))$refurbCapCharge(rv,g,y), PVfacG(rv,y,t) * s_REFURBCOST(rvExpStepsScenSet,g,y) ) ;
  objComponents(rvExpStepsScenSet,'obj_txcapex')   = sum((paths,y,firstPeriod(t)), PVfacT(rv,y,t) * s_TXCAPCHARGES(rvExpStepsScenSet,paths,y) ) ;
  objComponents(rvExpStepsScenSet,'obj_fixOM')     = 1e-3 * (1 - taxRate) * sum((g,y,t), PVfacG(rv,y,t) * ( 1/card(t) ) * i_fixedOM(rv,g) * s_CAPACITY(rvExpStepsScenSet,g,y) ) ;
  objComponents(rvExpStepsScenSet,'obj_varOM')     = 1e-3 * (1 - taxRate) * sum((validYrOperate(rv,g,y),t,lb,sc), scenarioWeight(sc) * PVfacG(rv,y,t) * s_GEN(rvExpStepsScenSet,g,y,t,lb,sc) * srmc(rv,g,y,sc) * sum(mapg_e(g,e), locFac_Recip(rv,e)) ) ;
  objComponents(rvExpStepsScenSet,'obj_hvdc')      = 1e-3 * (1 - taxRate) * sum((y,t), PVfacG(rv,y,t) * ( 1/card(t) ) * (
                                                     sum((g,k,o)$((not demandGen(k)) * sigen(g) * possibleToBuild(rv,g) * mapg_k(g,k) * mapg_o(g,o)), i_HVDCshr(rv,o) * i_HVDClevy(rv,y) * s_CAPACITY(rvExpStepsScenSet,g,y)) ) ) ;
  objComponents(rvExpStepsScenSet,'VOLLcost')      = 1e-3 * (1 - taxRate) * sum((s,y,t,lb,sc), scenarioWeight(sc) * PVfacG(rv,y,t) * s_VOLLGEN(rvExpStepsScenSet,s,y,t,lb,sc) * i_VOLLcost(rv,s) ) ;
  objComponents(rvExpStepsScenSet,'obj_rescosts')  = 1e-6 * (1 - taxRate) * sum((g,rc,y,t,lb,sc), PVfacG(rv,y,t) * scenarioWeight(sc) * s_RESV(rvExpStepsScenSet,g,rc,y,t,lb,sc) * i_plantReservesCost(rv,g,rc) ) ;

  objComponents(rvExpStepsScenSet,'obj_resvviol')  = 1e-6 * sum((rc,ild,y,t,lb,sc), scenarioWeight(sc) * s_RESVVIOL(rvExpStepsScenSet,rc,ild,y,t,lb,sc) * penaltyViolateReserves(rv,ild,rc) ) ;
  objComponents(rvExpStepsScenSet,'obj_nfrcosts')  = 1e-6 * (1 - taxRate) * sum((y,t,lb), PVfacG(rv,y,t) * (
                                                     sum((paths,stp,sc)$( nwd(paths) or swd(paths) ), hoursPerBlock(rv,t,lb) * scenarioWeight(sc) * s_RESVCOMPONENTS(rvExpStepsScenSet,paths,y,t,lb,sc,stp) * pNFresvcost(rv,paths,stp) ) ) ) ;
  objComponents(rvExpStepsScenSet,'obj_Penalties') = sum((y,sc), scenarioWeight(sc) * (
                                                       1e-3 * penaltyViolateRenNrg * s_RENNRGPENALTY(rvExpStepsScenSet,y) +
                                                       1e-6 * penaltyViolatePeakLoad * ( s_PEAK_NZ_PENALTY(rvExpStepsScenSet,y,sc) + s_PEAK_NI_PENALTY(rvExpStepsScenSet,y,sc) + s_NOWINDPEAK_NI_PENALTY(rvExpStepsScenSet,y,sc) ) )
                                                     ) ;
  objComponents(rvExpStepsScenSet,'obj_Slacks')    = slackCost * sum(y, s_ANNMWSLACK(rvExpStepsScenSet,y) + s_RENCAPSLACK(rvExpStepsScenSet,y) + s_HYDROSLACK(rvExpStepsScenSet,y) +
                                                                        s_MINUTILSLACK(rvExpStepsScenSet,y) + s_FUELSLACK(rvExpStepsScenSet,y) ) ;

  builtByTechRegion(rvExpStepsScenSet,k,r) = sum((g,y)$( mapg_k(g,k) * mapg_r(g,r) ), s_BUILD(rvExpStepsScenSet,g,y)) ;

  capacityByTechRegionYear(rvExpStepsScenSet,k,r,y)  = sum(g$( mapg_k(g,k) * mapg_r(g,r) ), s_CAPACITY(rvExpStepsScenSet,g,y)) ;

  genByTechRegionYear(rvExpStepsScenSet,k,r,y) = sum((g,t,lb,sc)$( mapg_k(g,k) * mapg_r(g,r) ), scenarioWeight(sc) * s_GEN(rvExpStepsScenSet,g,y,t,lb,sc)) ;

  txByRegionYear(rvExpStepsScenSet,paths,y) = sum((t,lb,sc), 1e-3 * scenarioWeight(sc) * hoursPerBlock(rv,t,lb) * s_TX(rvExpStepsScenSet,paths,y,t,lb,sc)) ;

  energyPrice(rvExpStepsScenSet,r,y) = 1e3 * sum((t,lb,sc), unDiscFactor(rv,y,t) * hoursPerBlock(rv,t,lb) * s_bal_supdem(rvExpStepsScenSet,r,y,t,lb,sc)) / sum((t,lb), hoursPerBlock(rv,t,lb)) ;

  peakNZPrice(rvExpStepsScenSet,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_peak_nz(rvExpStepsScenSet,y,sc) ) ;

  peakNIPrice(rvExpStepsScenSet,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_peak_ni(rvExpStepsScenSet,y,sc) ) ;

  peaknoWindNIPrice(rvExpStepsScenSet,y) = 1e3 * unDiscFactorYr(rv,y) * sum(sc, s_noWindPeak_ni(rvExpStepsScenSet,y,sc) ) ;

  loadByRegionAndYear(rvExpStepsScenSet,r,y) = sum((t,lb,sc), scenarioWeight(sc) * NrgDemand(rv,r,y,t,lb,sc)) ;

) ;

objComponents(rvExpStepsScenSet,'obj_Check') = sum(objc, objComponents(rvExpStepsScenSet,objc)) - objComponents(rvExpStepsScenSet,'obj_total') ;

Display rvExpStepsScenSet, rv, reportDomain, rvRD, unDiscFactor, unDiscFactorYr, objComponents, builtByTechRegion ;



*===============================================================================================
* 3. Write summary results to a csv file (for reportDomain only).

* NB: Summary results only get produced for the runVersion elements in rvRD and the experiment-steps-scenarioSets tuples in reportDomain.

put summaryResults 'Objective function value components, $m' / '' ;
loop(rvRD(rv), put rv.tl ) ;
loop(objc,
  put / objc.tl ;
  loop(rvRD(rv), put sum(reportDomain, objComponents(rv,reportDomain,objc)) ) ;
  put objc.te(objc) ;
) ;

put //// 'MW built by technology and region (MW built as percent of MW able to be built shown in 3 columns to the right) ' ;
loop(rvRD(rv),
  put / rv.tl ; loop(r$( card(isIldEqReg) <> 2 ), put r.tl ) loop(aggR, put aggR.tl ) put '' loop(aggR, put aggR.tl ) ;
  loop(k, put / k.tl
    loop(r$( card(isIldEqReg) <> 2 ), put sum(reportDomain, builtByTechRegion(rv,reportDomain,k,r)) ) ;
    loop(aggR, put sum((reportDomain,r)$mapAggR_r(aggR,r), builtByTechRegion(rv,reportDomain,k,r)) ) ;
    put '' ;
    loop(aggR,
    if(MWtoBuild(rv,k,aggR) = 0, put '' else
      put (100 * sum((reportDomain,r)$mapAggR_r(aggR,r), builtByTechRegion(rv,reportDomain,k,r)) / MWtoBuild(rv,k,aggR)) ) ;
    ) ;
    put '' k.te(k) ;
  ) ;
  put / ;
) ;

put /// 'Capacity by technology and region and year, MW (existing plus built less retired)' ;
loop(rvRD(rv), put / rv.tl '' ; loop(y, put y.tl ) ;
  loop((k,r),
    put / k.tl, r.tl ;
    loop(y, put sum(reportDomain, capacityByTechRegionYear(rv,reportDomain,k,r,y)) ) ;
  ) ;
  put / ;
) ;

cntr = 0 ;
put /// 'Generation by technology, region and year, GWh' ;
loop(rvRD(rv), put / rv.tl '' ; loop(y, put y.tl ) ; put / ;
  if(card(isIldEqReg) <> 2,
    loop(k,
      put k.tl ;
      loop(r,
        put$(cntr = 0) r.tl ; put$(cntr > 0) '' r.tl ; cntr = cntr + 1 ;
        loop(y, put sum(reportDomain, genByTechRegionYear(rv,reportDomain,k,r,y)) ) put / ;
      ) ;
      loop(aggR,
        put '' aggR.tl ;
        loop(y, put sum((reportDomain,r)$mapAggR_r(aggR,r), genByTechRegionYear(rv,reportDomain,k,r,y)) ) put / ;
      ) ;
    cntr = 0 ;
    ) ;
    else
    loop(k,
      put k.tl ;
      loop(aggR,
        put$(cntr = 0) aggR.tl ; put$(cntr > 0) '' aggR.tl ; cntr = cntr + 1 ;
        loop(y, put sum((reportDomain,r)$mapAggR_r(aggR,r), genByTechRegionYear(rv,reportDomain,k,r,y)) ) put / ;
      ) ;
      cntr = 0 ;
    ) ;
  ) ;
) ;

put /// 'Interregional transmission by year, GWh' ;
loop(rvRD(rv), put / rv.tl '' ; loop(y, put y.tl ) ;
  loop((paths(r,rr)),
    put / r.tl, rr.tl ;
    loop(y, put sum(reportDomain, txByRegionYear(rv,reportDomain,paths,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Load by region and year, GWh' ;
loop(rvRD(rv), put / rv.tl ; loop(y, put y.tl ) ;
  loop(r, put / r.tl
    loop(y, put sum(reportDomain, loadByRegionAndYear(rv,reportDomain,r,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Time-weighted energy price by region and year, $/MWh' ;
loop(rvRD(rv), put / rv.tl ; loop(y, put y.tl ) ;
  loop(r, put / r.tl
    loop(y, put sum(reportDomain, energyPrice(rv,reportDomain,r,y)) ) ;
  ) ;
  put / ;
) ;

put /// 'Peak constraint shadow prices, $/kW' ;
loop(rvRD(rv), put / rv.tl ; loop(y, put y.tl ) ;
  put / 'PeakNZ'       loop(y, put sum(reportDomain, peakNZPrice(rv,reportDomain,y)) ) ;
  put / 'PeakNI'       loop(y, put sum(reportDomain, peakNIPrice(rv,reportDomain,y)) ) ;
  put / 'noWindPeakNI' loop(y, put sum(reportDomain, peaknoWindNIPrice(rv,reportDomain,y)) ) ;
  put / ;
) ;



*===============================================================================================
* 4. Generate the remaining external files.

* a) Write results to be plotted to a single csv file.

** Note that Results to be plotted is currently conditioned such that only the reportDomain results are written to the file
** that gets plotted. Consider whether you want to write out all elements of rvExpStepsScenSet(rv,experiments,steps,scenSet)?

* First create a batch file in the archive folder to be used to invoke the plotting executable.
putclose plotBat '"%MatCodePath%\GEMplots.exe" "%OutPath%\%runName%\Processed files\Results to be plotted - %runName%.csv"' / ;

put plotResults "%runName%" "%FigureTitles%", card(y) ; ! card(y) needs to indicate the number of columns of data (the first 2 cols are not data.
put // 'Technologies' ;
loop(k,
  put / k.tl, k.te(k) loop(techColor(k,red,green,blue), put red.tl, green.tl, blue.tl ) ; 
) ;

put // 'Run versions' ;
loop(rv(runVersions),
  put / runVersions.tl, runVersions.te(runVersions) loop(runVersionColor(runVersions,red,green,blue), put red.tl, green.tl, blue.tl ) ; 
) ;

put // 'Time-weighted energy price by region and year, $/MWh' / '' '' loop(y, put y.tl ) ;
loop(rv, put / rv.tl ;
  loop(r,
    put / r.tl '' ;
    loop(y, put sum(reportDomain, energyPrice(rv,reportDomain,r,y)) ) ;
  ) ;
) ;

put // 'Capacity by technology and year (existing plus built less retired), MW' / '' '' loop(y, put y.tl ) ;
loop(rv, put / rv.tl ;
  loop(k$sum((reportDomain,r,y), capacityByTechRegionYear(rv,reportDomain,k,r,y)),
    put / k.tl '' ;
    loop(y, put sum((reportDomain,r), capacityByTechRegionYear(rv,reportDomain,k,r,y)) ) ;
  ) ;
  put / 'Total' '' loop(y, put sum((reportDomain,k,r), capacityByTechRegionYear(rv,reportDomain,k,r,y)) ) ;
) ;

put // 'Generation by technology and region and year, GWh' / '' '' loop(y, put y.tl ) ;
loop(rv, put / rv.tl ;
  loop(k$sum((reportDomain,r,y), genByTechRegionYear(rv,reportDomain,k,r,y)),
    put / k.tl '' ;
    loop(y, put sum((reportDomain,r), genByTechRegionYear(rv,reportDomain,k,r,y)) ) ;
  ) ;
  put / 'Total' '' loop(y, put sum((reportDomain,k,r), genByTechRegionYear(rv,reportDomain,k,r,y)) ) ;
) ;


* b) Write an ordered (by year) summary of generation capacity expansion.
put expandSchedule 'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Technology' 'Plant' 'NameplateMW' 'ExistMW' 'BuildYr', 'BuildMW'
  'RetireType' 'RetireYr' 'RetireMW' 'Capacity' ;
loop((rvExpStepsScenSet(rv,experiments,steps,scenSet),y,k,g)$( mapg_k(g,k) * existBuildOrRetire(rvExpStepsScenSet,g,y) ),
  put / rv.tl, experiments.tl, steps.tl, scenSet.tl, k.tl, g.tl, i_namePlate(rv,g) ;
  if(exist(g), put i_namePlate(rv,g) else put '' ) ;
  if(s_BUILD(rvExpStepsScenSet,g,y), put yearNum(rv,y), s_BUILD(rvExpStepsScenSet,g,y) else put '' '' ) ;
  if(possibleToRetire(rv,g) * ( s_RETIRE(rvExpStepsScenSet,g,y) or exogMWretired(rv,g,y) ),
    if( ( possibleToEndogRetire(rv,g) * s_RETIRE(rvExpStepsScenSet,g,y) ),
      put 'Endogenous', yearNum(rv,y), s_RETIRE(rvExpStepsScenSet,g,y) else put 'Exogenous', yearNum(rv,y), exogMWretired(rv,g,y) ;
    ) else  put '' '' '' ;
  ) ;
) ;


* c) Write out capacity report (capacityPlant) (is this redundant given expandSchedule?).
put capacityPlant 'Capacity by plant and year (net of retirements), MW' / 'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Plant' 'Year' 'MW' ;
loop((rvExpStepsScenSet(rv,experiments,steps,scenSet),g,y)$s_CAPACITY(rvExpStepsScenSet,g,y),
  put / rv.tl, experiments.tl, steps.tl, scenSet.tl, g.tl, y.tl, s_CAPACITY(rvExpStepsScenSet,g,y) ;
) ;


* d) Write out generation report (genPlant and genPlantYear).
put genPlant 'Generation (GWh) and utilisation (percent) by plant and year' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Plant' 'Year' 'Period' 'Block' 'Scenario' 'GWh' 'Percent' ;
loop((rvExpStepsScenSet(rv,experiments,steps,scenSet),g,y,t,lb,scen)$s_GEN(rvExpStepsScenSet,g,y,t,lb,scen),
  put / rv.tl, experiments.tl, steps.tl, scenSet.tl, g.tl, y.tl, t.tl, lb.tl, scen.tl, s_GEN(rvExpStepsScenSet,g,y,t,lb,scen) ;
  put (100 * s_GEN(rvExpStepsScenSet,g,y,t,lb,scen) / ( 1e-3 * hoursPerBlock(rv,t,lb) * i_namePlate(rv,g) )) ;
) ;

put genPlantYear 'Annual generation (GWh) and utilisation (percent) by plant' /
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Plant' 'Year' 'Scenario' 'GWh' 'Percent' ;
loop((rvExpStepsScenSet(rv,experiments,steps,scenSet),g,y,scen)$sum((t,lb), s_GEN(rvExpStepsScenSet,g,y,t,lb,scen)),
  put / rv.tl, experiments.tl, steps.tl, scenSet.tl, g.tl, y.tl, scen.tl, sum((t,lb), s_GEN(rvExpStepsScenSet,g,y,t,lb,scen)) ;
  put ( 100 * sum((t,lb), s_GEN(rvExpStepsScenSet,g,y,t,lb,scen)) / ( 8.76 * i_namePlate(rv,g) ) ) ;
) ;


* e) Write out annual report (variousAnnual).
Set ryr 'Labels for results by year' /
  FuelPJ   'Fuel burn, PJ'
  / ;

put variousAnnual 'Various results reported by year' / ''
  'runVersion' 'Experiment' 'Step' 'scenarioSet' 'Scenario' 'Fuel' loop(y, put y.tl) ;
loop((ryr,rvExpStepsScenSet(rv,experiments,steps,scenSet),scen,thermalfuel(f))$sum((mapg_f(g,f),y,t,lb), s_GEN(rvExpStepsScenSet,g,y,t,lb,scen)),
  put / ryr.te(ryr), rv.tl, experiments.tl, steps.tl, scenSet.tl, scen.tl, f.tl ;
  loop(y, put sum((mapg_f(g,f),t,lb), 1e-6 * i_heatrate(rv,g) * s_GEN(rvExpStepsScenSet,g,y,t,lb,scen)) ) ;
) ;

* Need to check units are correct on Fuel burn, PJ?
* Create a parameter to calculate this stuff and move it into a loop where it all gets done at once.

*CO2taxByPlant(g,y,scen) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_co2tax(y) * scenarioCO2TaxFactor(scen) * i_emissionFactors(f) ) ;




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




* JC reports....
Files
  summaryResultsJC  / "%OutPath%\%runName%\JC results - %runName%.csv" /
  blockResults      / "%OutPath%\%runName%\JC Blocks - %runName%.csv" / ;

summaryResultsJC.pc = 5 ; summaryResultsJC.pw = 999 ;
blockResults.pc = 5 ;     blockResults.pw = 999 ;

Sets
  block                  'Load Block group'      /  peak 'PeakLd',  offpk 'OffpeakLd', mid 'MidLd' /
  maplb_block(lb,block)  'Load Block Group map'  / (b1l,b1w).peak
                                                   (b5,b6).offpk
                                                   (b2l,b2w,b3l,b3w,b4).mid / ;

Parameters
  hoursYearBlock(runVersions,block)                           'Hours by block'
  genByTechRegionYearBlock(*,*,*,*,k,r,y,block)               'Generation by technology and region/island/Block and year, GWh'
  energyPriceBlock(*,*,*,*,r,y,block)                         'Time-weighted energy price by region/Block and year, $/MWh (from marginal price off of energy balance constraint)'
  txByRegionYearBlock(*,*,*,*,r,rr,y,block)                   'Interregional transmission by year/Block, GWh'
  genRevByTechRegionYear(*,*,*,*,k,r,y)                       'Generation rev by technology and region/island and year, $k'
  loadByRegionAndYearBlock(*,*,*,*,r,y,block)                 'Load by region and year,Block GWh'
  ;

hoursYearBlock(rv,block) = sum((t,lb)$maplb_block(lb,block), hoursPerBlock(rv,t,lb) ) ;

* Generation Revenue excluding contribution to security constraints, you can add contribution to security constriants from outputs
genRevByTechRegionYear(rv,reportDomain,k,r,y) = sum((g,t,lb,sc)$( mapg_k(g,k) * mapg_r(g,r) ), 1e3 * unDiscFactor(rv,y,t) * s_GEN(rv,reportDomain,g,y,t,lb,sc)* s_bal_supdem(rv,reportDomain,r,y,t,lb,sc)) ;

genByTechRegionYearBlock(rvRD,reportDomain,k,r,y,block) = sum((g,t,lb,sc)$( mapg_k(g,k) * mapg_r(g,r) * maplb_block(lb,block) ), scenarioWeight(sc) * s_GEN(rvRD,reportDomain,g,y,t,lb,sc)) ;

energyPriceBlock(rvRD,reportDomain,r,y,block) = 1e3 * sum((t,lb,sc)$ maplb_block(lb,block), unDiscFactor(rvRD,y,t) * hoursPerBlock(rvRD,t,lb) * s_bal_supdem(rvRD,reportDomain,r,y,t,lb,sc))  ;

txByRegionYearBlock(rvRD,reportDomain,paths,y,block) = sum((t,lb,sc)$ maplb_block(lb,block), 1e-3 * scenarioWeight(sc) * hoursPerBlock(rvRD,t,lb) * s_TX(rvRD,reportDomain,paths,y,t,lb,sc)) ;

loadByRegionAndYearBlock(rvRD,reportDomain,r,y,block) = sum((t,lb,sc)$(maplb_block(lb,block)), scenarioWeight(sc) * NrgDemand(rvRD,r,y,t,lb,sc)) ;


* Derive results for generation by type
put summaryResultsJC 'JC Report ', ' %runName% '  ;
put / 'Generation by run, type, region and year, MW, GWh ' ;
put / 'Run', 'Type', 'Region', 'Year','MW', 'GWh', 'Price', 'Rev';
  loop((rvRD(rv),k,r,y),
    put / rv.tl, k.tl, r.tl, y.tl,
         sum(reportDomain, capacityByTechRegionYear(rv,reportDomain,k,r,y)),
         sum(reportDomain, genByTechRegionYear(rv,reportDomain,k,r,y)),
         sum(reportDomain, (genRevByTechRegionYear(rv,reportDomain,k,r,y)/genByTechRegionYear(rv,reportDomain,k,r,y))$genByTechRegionYear(rv,reportDomain,k,r,y)),
         sum(reportDomain, genRevByTechRegionYear(rv,reportDomain,k,r,y)),
  ) ;

*put / 'Results by run, region and year, MW, GWh, Price ' ;
*put / 'Run', 'Type','Region', 'Year', 'MW', 'GWh', 'Price';
   loop((rvRD(rv),r,y),
    put / rv.tl, 'Area', r.tl, y.tl,
         sum(reportDomain, loadByRegionAndYear(rv,reportDomain,r,y)/8.76),
         sum(reportDomain, loadByRegionAndYear(rv,reportDomain,r,y)),
         sum(reportDomain, energyPrice(rv,reportDomain,r,y))
  ) ;

*put / 'Peak Constraint by run, Region, year, $/kW/yr ' ;
*put / 'Run', 'PkConstraint','Region', 'Year','MW', 'GWh', 'Price';
   loop((rvRD(rv),y),
         put / rv.tl, 'Security', 'ni', y.tl, 0, sum(reportDomain,loadByRegionAndYear(rv,reportDomain,'ni',y)),
              sum(reportDomain, (peakNZPrice(rv,reportDomain,y)+peakNIPrice(rv,reportDomain,y)+peaknoWindNIPrice(rv,reportDomain,y))/8.76) ;
         put / rv.tl, 'Security', 'ni_LowWind', y.tl, 0, 0,
              sum(reportDomain, (peaknoWindNIPrice(rv,reportDomain,y))/8.76) ;
         put / rv.tl, 'Security', 'nz', y.tl, 0, 0,
              sum(reportDomain, (peakNZPrice(rv,reportDomain,y))/8.76) ;
         put / rv.tl, 'Security', 'si', y.tl, 0, sum(reportDomain,loadByRegionAndYear(rv,reportDomain,'si',y)),
              sum(reportDomain, peakNZPrice(rv,reportDomain,y)/8.76) ;
    ) ;

*put / 'Link Flow by run, FromRegion, Toregion and year, MW, GWh ' ;
*put / 'Run', 'FromRegion', 'ToRegion', 'Year','MW', 'GWh', 'Price';
   loop((rvRD(rv),r,y),
         put / rv.tl, loop((paths(r,rr)), put r.tl, rr.tl, y.tl, sum(reportDomain, txByRegionYear(rv,reportDomain,paths,y)/8.76), sum(reportDomain, txByRegionYear(rv,reportDomain,paths,y)),0 );
  ) ;
  put / ;

* code Below if you want results by Block
put blockResults 'JC Report ', ' %runName% ' ;
put / 'Run', 'Type', 'Region', 'Year','Block', 'MW', 'GWh', 'Price';
  loop((rvRD(rv),k,r,y,block),
    put / rv.tl, k.tl, r.tl, y.tl, block.tl,
         sum(reportDomain, genByTechRegionYearBlock(rv,reportDomain,k,r,y,block)/hoursYearBlock(rv,block)*1000), sum(reportDomain, genByTechRegionYearBlock(rv,reportDomain,k,r,y,block)), 0,
  ) ;
   loop((rvRD(rv),r,y,block),
    put / rv.tl, 'Area', r.tl, y.tl, block.tl, sum(reportDomain, loadByRegionAndYearBlock(rv,reportDomain,r,y,block)/hoursYearBlock(rv,block)*1000), sum(reportDomain, loadByRegionAndYearBlock(rv,reportDomain,r,y,block)),  sum(reportDomain, energyPriceBlock(rv,reportDomain,r,y,block)/hoursYearBlock(rv,block))
  ) ;
    loop((rvRD(rv),r,y,block),
         put / rv.tl, loop((paths(r,rr)), put r.tl, rr.tl, y.tl, block.tl, sum(reportDomain, txByRegionYearBlock(rv,reportDomain,paths,y,block)/hoursYearBlock(rv,block)*1000), sum(reportDomain, txByRegionYearBlock(rv,reportDomain,paths,y,block)), 0 );
  ) ;




* End of file
