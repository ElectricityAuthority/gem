* GEMreports.gms


* Last modified by Dr Phil Bishop, 17/10/2010 (imm@ea.govt.nz)


$ontext
 This program generates GEM reports - human-readable files, pictures, or files to be read by other
 applications for further processing.
 This program is to be run after GEMsolve. It does "not" start from GEMdeclarations.g00. All symbols
 required in this program are declared here and/or are imported from GDX files.

 Code sections:
  1. Declare fundamental sets and load the required data (from the 'base case' input GDX file).
  2. Declare the sets and parameters:
     a) Re-declare sets and parameters that are to be obtained from the scenario-specific input GDX files (excluding the 26 fundamental sets).
     b) Re-declare sets and parameters that are to be obtained from the scenario-specific GEMdata GDX files.
     c) Re-declare sets and parameters that are to be obtained from the prepared output GDX files.
     d) Declare sets and parameters local to GEMreports, i.e. declared here for the first time.
  3. Declare output files and set their attributes.
  4. Perform the various calculations/assignments necessary to generate reports.
     a) Objective function components - value by year and total value
     b) Various counts
  5. Write out the generation and transmission investment schedules in various formats.
     a) Build, refurbishment and retirement data and outcomes in .csv format suitable for importing into Excel.
     b) Write out generation and transmission investment schedules in a formatted text file (i.e. human-readable)
     c) Write out the build and retirement schedule - in SOO-ready format.
     d) Write out the forced builds by scenario - in SOO-ready format (in the same file as SOO build schedules).
     e) Write out a file to create maps of generation plant builds/retirements.
     f) Write out a file to create maps of transmission upgrades.
  x. Write the solve summary report.
  x. Dump certain parameters into GDX files.

$offtext

option seed = 101 ;
$include GEMsettings.inc
$offupper offsymxref offsymlist offuellist offuelxref onempty inlinecom { } eolcom !

* NB: Set sc 'Scenarios' comes from GEMsettings.inc (set sc is not used before GEMreports).


*===============================================================================================
* 1. Declare fundamental sets and load the required data (from the 'base case' input GDX file).

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
  outcomes     'Hydrology domain for multiple hydro years'
  m            '12 months'
  geo          'Geographic co-ordinate types'
  col          'RGB color codes'
  ;

Alias (sc,scc), (i,ii), (r,rr), (ild,ild1), (ps,pss), (hY,hY1), (col,red,green,blue) ;

* Re-initialise set y with the modelled years from GEMsettings.inc (the set y in the GDX input file contains all data years).
Set y / %firstYear% * %lastYear% / ;

* Get the other 25 of the 26 fundamental sets from the first scenario's input GDX file.
$gdxin "%DataPath%%firstScenario%"
$loaddc k f fg g s o fc i r e ild p ps tupg tgc t prf lb rc hY v outcomes=hd m geo col

* Re-declare and initialise a few miscellaneous sets with fixed membership.
Sets
  rt                      'Model run types'                     / tmg      'Run model GEM to determine optimal timing of new builds'
                                                                  reo      'Run model GEM to re-optimise timing while allowing specified plants to move'
                                                                  dis      'Run model DISP with build forced and timing fixed'   /
  goal                    'Goals for MIP solution procedure'    / QDsol    'Find a quick and dirty solution using a user-specified optcr'
                                                                  VGsol    'Find a very good solution reasonably quickly'
                                                                  MinGap   'Minimize the gap between best possible and best found'  /
  tmg(rt)                 'Run type TMG - determine timing'     / tmg /
  reo(rt)                 'Run type REO - re-optimise timing'   / reo /
  dis(rt)                 'Run type DIS - dispatch'             / dis /
*++++++++++
* More non-free reserves code.
  stp                     'Steps'                               / stp1 * stp5 /
*++++++++++
  ;



*===============================================================================================
* 2. Declare the sets and parameters:
*    a) Re-declare sets and parameters that are to be obtained from the scenario-specific input GDX files (excluding the 26 fundamental sets).
*    b) Re-declare sets and parameters that are to be obtained from the scenario-specific GEMdata GDX files.
*    c) Re-declare sets and parameters that are to be obtained from the prepared output GDX files.
*    d) Declare sets and parameters local to GEMreports, i.e. declared here for the first time.

* NB: The following symbols from input data file may have been changed in GEMdata. So procure from
*     GEMdataGDX rather than from GDXinputFile, or make commensurate change.
*     Sets: y, exist, commit, new, neverBuild
*     Parameters: i_txCapacity, i_txCapacityPO

* a) Sets and parameters from input GDX file - now with an extra dimension, i.e. set sc.
Sets
  mapf_fg(sc,f,fg)                              'Map fuel groups to fuel types'
  techColor(sc,k,red,green,blue)                'RGB color mix for technologies - to pass to plotting applications'
  fuelColor(sc,f,red,green,blue)                'RGB color mix for fuels - to pass to plotting applications'
  fuelGrpcolor(sc,fg,red,green,blue)            'RGB color mix for fuel groups - to pass to plotting applications'
  peaker(sc,k)                                  'Peaking plant technologies'
  demandGen(sc,k)                               'Demand side technologies modelled as generation'
  regionCentroid(sc,i,r)                        'Identify the centroid of each region with a substation'
Parameters
  i_nameplate(sc,g)                             'Nameplate capacity of generating plant, MW'
  i_fixedOM(sc,g)                               'Fixed O&M costs by plant, $/kW/year'
  i_refurbDecisionYear(sc,g)                    'Decision year for endogenous "refurbish or retire" decision for eligble generation plant'
  i_plantReservesCost(sc,g,rc)                  'Plant-specific cost per reserve class, $/MWh'
  i_VOLLcost(sc,s)                              'Value of lost load by VOLL plant (1 VOLL plant/region), $/MWh'
  i_HVDCshr(sc,o)                               'Share of HVDC charge to be incurred by plant owner'
  i_HVDClevy(sc,y)                              'HVDC charge levied on new South Island plant by year, $/kW'
  i_hydroWeight(sc,outcomes)                    'Weights on hydro outflows when multiple hydro outputs is used'
  i_txCapacity(sc,r,rr,ps)                      'Transmission path capacities (bi-directional), MW'
  i_substnCoordinates(sc,i,geo)                 'Geographic coordinates for substations'
  ;

$gdxin 'all_input.gdx'
$loaddc mapf_fg techColor fuelColor fuelGrpcolor peaker demandGen regionCentroid
$load   i_nameplate i_fixedOM i_refurbDecisionYear i_plantReservesCost i_VOLLcost i_HVDCshr i_HVDClevy i_hydroWeight i_txCapacity
$loaddc i_substnCoordinates
* Make sure intraregional transmission capacities are zero.
i_txCapacity(sc,r,r,ps) = 0 ;



* b) Sets and parameters from GEMdata GDX file - now with an extra dimension, i.e. set sc.
Sets
  firstPeriod(sc,t)                             'First time period (i.e. period within the modelled year)'
  exist(sc,g)                                   'Generation plant that are presently operating'
  commit(sc,g)                                  'Generation plant that are assumed to be committed'
  new(sc,g)                                     'Potential generation plant that are neither existing nor committed'
  neverBuild(sc,g)                              'Generation plant that are determined a priori by user never to be built'
  schedHydroPlant(sc,g)                         'Schedulable hydro generation plant'
  mapg_k(sc,g,k)                                'Map technology types to generating plant'
  mapg_f(sc,g,f)                                'Map fuel types to generating plant'
  mapg_o(sc,g,o)                                'Map plant owners to generating plant'
  mapg_i(sc,g,i)                                'Map substations to generating plant'
  mapg_r(sc,g,r)                                'Map regions to generating plant'
  mapg_e(sc,g,e)                                'Map zones to generating plant'
  mapg_ild(sc,g,ild)                            'Map islands to generating plant'
  mapild_r(sc,ild,r)                            'Map the regions to islands'
  sigen(sc,g)                                   'South Island generation plant'
  possibleToBuild(sc,g)                         'Generating plant that may possibly be built in any valid build year'
  possibleToRefurbish(sc,g)                     'Generating plant that may possibly be refurbished in any valid modelled year'
  possibleToEndogRetire(sc,g)                   'Generating plant that may possibly be endogenously retired'
  possibleToRetire(sc,g)                        'Generating plant that may possibly be retired (exogenously or endogenously)'
  validYrBuild(sc,g,y)                          'Valid years in which new generation plant may be built'
  nwd(sc,r,rr)                                  'Northward direction of flow on Benmore-Haywards HVDC'
  swd(sc,r,rr)                                  'Southward direction of flow on Benmore-Haywards HVDC'
  paths(sc,r,rr)                                'All valid transmission paths'
  transitions(sc,tupg,r,rr,ps,pss)              'For all transmission paths, define the allowable transitions from one upgrade state to another'
  allowedStates(sc,r,rr,ps)                     'All of the allowed states (initial and upgraded) for each active path'
Parameters
  yearNum(sc,y)                                 'Real number associated with each year'
  hoursPerBlock(sc,t,lb)                        'Hours per load block by time period'
  PVfacG(sc,y,t)                                'Generation investor's present value factor by period'
  PVfacT(sc,y,t)                                'Transmission investor's present value factor by period'
  capCharge(sc,g,y)                             'Annualised or levelised capital charge for new generation plant, $/MW/yr'
  refurbCapCharge(sc,g,y)                       'Annualised or levelised capital charge for refurbishing existing generation plant, $/MW/yr'
  exogMWretired(sc,g,y)                         'Exogenously retired MW by plant and year, MW'
  SRMC(sc,g,y)                                  'Short run marginal cost of each generation project by year, $/MWh'
  locFac_Recip(sc,e)                            'Reciprocal of zonally-based location factors'
  AClossFactors(sc,ild)                         'Upwards adjustment to load to account for AC (or intraregional) losses'
  NrgDemand(sc,r,y,t,lb)                        'Load (or energy demand) by region, year, time period and load block for selected growth profile, GWh (used to create ldcMW)'
  txEarlyComYr(sc,tupg,r,rr,ps,pss)             'Earliest year that a transmission upgrade can occur (a parameter, not a set)'
  txFixedComYr(sc,tupg,r,rr,ps,pss)             'Fixed year in which a transmission upgrade must occur (a parameter, not a set)'
  reserveViolationPenalty(sc,ild,rc)            'Reserve violation penalty, $/MWh'
*++++++++++
* More non-free reserves code.
  pNFresvCost(sc,r,rr,stp)                      'Constant cost of each non-free piece (or step) of function, $/MWh'
*++++++++++
  ;

$gdxin 'all_gemdata.gdx'
$loaddc firstPeriod exist commit new neverBuild schedHydroPlant mapg_k mapg_f mapg_o mapg_i mapg_r mapg_e mapg_ild mapild_r sigen
$loaddc possibleToBuild possibleToRefurbish possibleToEndogRetire possibleToRetire validYrBuild
$loaddc nwd swd paths transitions allowedStates
$loaddc yearNum hoursPerBlock PVfacG PVfacT capCharge refurbCapCharge exogMWretired SRMC locFac_Recip AClossFactors NrgDemand txEarlyComYr txFixedComYr
$loaddc reserveViolationPenalty pNFresvCost



* c) Sets and parameters from prepared output GDX file - now with an extra dimension, i.e. set sc.
Sets
  h(sc,outcomes)                                'Selected elements of outcomes - used to control multiple versus single hydro years to determine build timing'
  activeSolve(sc,rt,hY)                         'Collect the rt-hY index used for each solve' 
  activeHD(sc,rt,hY,outcomes)                   'Collect the rt-hY-outcomes index used for each solve'
  activeRT(sc,rt)                               'Identify the run types actually employed in this model run'
  solveGoal(sc,goal)                            'User-selected solve goal'
Parameters
* Miscellaneous parameters
  solveReport(sc,rt,hY,*,*)                     'Collect various details about each solve of the models (both GEM and DISP)'
* Free variables
  s2_TOTALCOST(sc,rt)                           'Discounted total system costs over all modelled years, $m (objective function value)'
  s2_TX(sc,rt,r,rr,y,t,lb,outcomes)             'Transmission from region to region in each time period, MW (-ve reduced cost equals s_TXprice???)'
* Binary Variables
  s2_BRET(sc,rt,g,y)                            'Binary variable to identify endogenous retirement year for the eligble generation plant'
  s2_ISRETIRED(sc,rt,g)                         'Binary variable to identify if the plant has actually been endogenously retired (0 = not retired, 1 = retired)'
  s2_BTX(sc,rt,r,rr,ps,y)                       'Binary variable indicating the current state of a transmission path'
* Positive Variables
  s2_REFURBCOST(sc,rt,g,y)                      'Annualised generation plant refurbishment expenditure charge, $'
  s2_BUILD(sc,rt,g,y)                           'New capacity installed by generating plant and year, MW'
  s2_RETIRE(sc,rt,g,y)                          'Capacity endogenously retired by generating plant and year, MW'
  s2_CAPACITY(sc,rt,g,y)                        'Cumulative nameplate capacity at each generating plant in each year, MW'
  s2_TXCAPCHARGES(sc,rt,r,rr,y)                 'Cumulative annualised capital charges to upgrade transmission paths in each modelled year, $m'
  s2_GEN(sc,rt,g,y,t,lb,outcomes)               'Generation by generating plant and block, GWh'
  s2_VOLLGEN(sc,rt,s,y,t,lb,outcomes)           'Generation by VOLL plant and block, GWh'
  s2_PUMPEDGEN(sc,rt,g,y,t,lb,outcomes)         'Energy from pumped hydro (treated like demand), GWh'
  s2_LOSS(sc,rt,r,rr,y,t,lb,outcomes)           'Transmission losses along each path, MW'
  s2_TXPROJVAR(sc,rt,tupg,y)                    'Continuous 0-1 variable indicating whether an upgrade project is applied'
  s2_TXUPGRADE(sc,rt,r,rr,ps,pss,y)             'Continuous 0-1 variable indicating whether a transmission upgrade is applied'
  s2_RESV(sc,rt,g,rc,y,t,lb,outcomes)           'Reserve energy supplied, MWh'
  s2_RESVVIOL(sc,rt,rc,ild,y,t,lb,outcomes)     'Reserve energy supply violations, MWh'
  s2_RESVTRFR(sc,rt,rc,ild,ild1,y,t,lb,outcomes)'Reserve energy transferred from one island to another, MWh'
* Penalty variables
  s2_RENNRGPENALTY(sc,rt,y)                     'Penalty used to make renewable energy constraint feasible, GWh'
* Slack variables
  s2_ANNMWSLACK(sc,rt,y)                        'Slack with arbitrarily high cost - used to make annual MW built constraint feasible, MW'
  s2_SEC_NZSLACK(sc,rt,y)                       'Slack with arbitrarily high cost - used to make NZ security constraint feasible, MW'
  s2_SEC_NI1SLACK(sc,rt,y)                      'Slack with arbitrarily high cost - used to make NI1 security constraint feasible, MW'
  s2_SEC_NI2SLACK(sc,rt,y)                      'Slack with arbitrarily high cost - used to make NI2 security constraint feasible, MW'
  s2_NOWIND_NZSLACK(sc,rt,y)                    'Slack with arbitrarily high cost - used to make NZ no wind constraint feasible, MW'
  s2_NOWIND_NISLACK(sc,rt,y)                    'Slack with arbitrarily high cost - used to make NI no wind constraint feasible, MW'
  s2_RENCAPSLACK(sc,rt,y)                       'Slack with arbitrarily high cost - used to make renewable capacity constraint feasible, MW'
  s2_HYDROSLACK(sc,rt,y)                        'Slack with arbitrarily high cost - used to make limit_hydro constraint feasible, GWh'
  s2_MINUTILSLACK(sc,rt,y)                      'Slack with arbitrarily high cost - used to make minutil constraint feasible, GWh'
  s2_FUELSLACK(sc,rt,y)                         'Slack with arbitrarily high cost - used to make limit_fueluse constraint feasible, PJ'
* Equations, i.e. marginal values. (ignore the objective function)
  s2_bal_supdem(sc,rt,r,y,t,lb,outcomes)        'Balance supply and demand in each region, year, time period and load block'
*++++++++++
* More non-free reserves code.
  s2_RESVCOMPONENTS(sc,rt,r,rr,y,t,lb,outcomes,stp) 'Non-free reserve components, MW'
*++++++++++
  ;

$gdxin 'all_prepout.gdx'
* Sets
$loaddc h activeSolve activeHD activeRT solveGoal
* Parameters
* Miscellaneous parameters
$loaddc solveReport s2_TOTALCOST s2_TX s2_BRET s2_ISRETIRED s2_BTX
$loaddc s2_REFURBCOST s2_BUILD s2_RETIRE s2_CAPACITY  s2_TXCAPCHARGES s2_GEN s2_VOLLGEN s2_LOSS s2_TXPROJVAR s2_TXUPGRADE s2_RESV s2_RESVVIOL
$loaddc s2_RENNRGPENALTY s2_ANNMWSLACK s2_SEC_NZSLACK s2_SEC_NI1SLACK s2_SEC_NI2SLACK s2_NOWIND_NZSLACK s2_NOWIND_NISLACK
$loaddc s2_RENCAPSLACK s2_HYDROSLACK s2_MINUTILSLACK s2_FUELSLACK s2_bal_supdem
*++++++++++
* More non-free reserves code.
$loaddc s2_RESVCOMPONENTS
*++++++++++

*  declared but not loaded yet - follows s2_VOLLGEN
*  s2_PUMPEDGEN(sc,rt,g,y,t,lb,outcomes)        'Energy from pumped hydro (treated like demand), GWh'
*  s2_RESV(sc,rt,g,rc,y,t,lb,outcomes)          'Reserve energy supplied, MWh'
*  s2_RESVVIOL(sc,rt,rc,ild,y,t,lb,outcomes)    'Reserve energy supply violations, MWh'
*  s2_RESVTRFR(sc,rt,rc,ild,ild1,y,t,lb,outcomes)   'Reserve energy transferred from one island to another, MWh'



* d) Sets and parameters declared for the first time (local to GEMreports).
Sets
  a                                             'Activity related to generation investment'
                                                  /  blt   'Potential and actual built capacity by technology (gross of retirements)'
                                                    rfb   'Potential and actual refurbished capacity by technology'
                                                    rtd   'Potential and actual retired capacity by technology'   /
  buildSoln(rt)                                 'Determine which run type element to use for reporting results related to building generation or transmission'
  activeRTHD(sc,rt,outcomes)                    'Determine the sc-rt-outcome index used for each solve'
  activeCapacity(sc,g,y)                        'Identify all plant that are active in any given year, i.e. existing or built but never retired'
* Components of objective function
  objc                                          'Objective function components'
                                                  / obj_total       'Objective function value'
                                                    obj_gencapex    'Discounted levelised generation plant capital costs'
                                                    obj_refurb      'Discounted levelised refurbishment capital costs'
                                                    obj_txcapex     'Discounted levelised transmission capital costs'
                                                    obj_fixOM       'After tax discounted fixed costs at generation plant'
                                                    obj_hvdc        'After tax discounted HVDC charges'
                                                    obj_varOM       'After tax discounted variable costs at generation plant'
                                                    VOLLcost        'After tax discounted value of lost load'
                                                    obj_rescosts    'After tax discounted reserve costs at generation plant'
                                                    obj_nfrcosts    'After tax discounted cost of non-free reserve cover for HVDC'
                                                    obj_renNrg      'Penalty cost of failing to meet renewables target'
                                                    obj_resvviol    'Penalty cost of failing to meet reserves'
                                                    slk_rstrctMW    'Slack on restriction on annual MW built'
                                                    slk_nzsec       'Slack on NZ security constraint'
                                                    slk_ni1sec      'Slack on NI1 security constraint'
                                                    slk_ni2sec      'Slack on NI2 security constraint'
                                                    slk_nzNoWnd     'Slack on NZ no wind security constraint'
                                                    slk_niNoWnd     'Slack on NI no wind security constraint'
                                                    slk_renCap      'Slack on renewable capacity constraint'
                                                    slk_limHyd      'Slack on limit hydro output constraint'
                                                    slk_minutil     'Slack on minimum utilisation constraint'
                                                    slk_limFuel     'Slack on limit fuel use constraint'  /
  pen(objc)                                     'Penalty components of objective function'
                                                  / obj_renNrg, obj_resvviol /
  slk(objc)                                     'Slack components of objective function'
                                                  / slk_rstrctMW, slk_nzsec, slk_ni1sec, slk_ni2sec, slk_nzNoWnd, slk_niNoWnd, slk_renCap, slk_limHyd, slk_minutil, slk_limFuel /
  ;

Parameters
* Parameters declared for the first time (local to GEMreports).
  counter                                       'A recyclable counter'
  problems                                      'A flag indicating problems with some solutions - other than the presence of slacks or penalties'
  warnings                                      'A flag indicating warnings - warnings are much less serious than problems (problems ought not be ignored)'
  objComponentsYr(sc,rt,y,*)                    'Components of objective function value by year (tmg, reo and average over all hydrology for the dispatch solves)'
  objComponents(sc,rt,objc)                     'Components of objective function value (tmg, reo and average over all hydrology for the dispatch solves)'
  numGenPlant(sc)                               'Number of generating plant in data file'
  numVOLLplant(sc)                              'Number of shortage generating plant in data file'
  numExist(sc)                                  'Number of generating plant that are presently operating'
  numCommit(sc)                                 'Number of generating plant that are assumed to be committed'
  numNew(sc)                                    'Number of potential generating plant that are neither existing nor committed'
  numNeverBuild(sc)                             'Number of generating plant that are determined a priori by user never to be built'
  numZeroMWplt(sc)                              'Number of generating plant that are specified in input data to have a nameplate capacity of zero MW'
  numSchedHydroPlant(sc)                        'Number of schedulable hydro generation plant'
* Capacity and dispatch
  potentialCap(sc,k,a)                          'Potential capacity able to be built/refurbished/retired by technology, MW'
  actualCap(sc,rt,k,a)                          'Actual capacity built/refurbished/retired by technology, MW'
  actualCapPC(sc,rt,k,a)                        'Actual capacity built/refurbished/retired as a percentage of potential by technology'
  partialMWbuilt(sc,g)                          'The MW actually built in the case of plant not fully constructed'
  numYrsToBuildPlant(sc,g,y)                    'Identify the number of years taken to build a generating plant (-1 indicates plant is retired)'
  buildOrRetireMW(sc,g,y)                       'Collect up both build (positive) and retirement (negative), MW'
  buildYr(sc,g)                                 'Year in which new generating plant is built, or first built if built over multiple years'
  retireYr(sc,g)                                'Year in which generating plant is retired'
  buildMW(sc,g)                                 'MW built at each generating plant able to be built'
  retireMW(sc,g)                                'MW retired at each generating plant able to be retired'
  finalMW(sc,g)                                 'Existing plus built less retired MW by plant'
  totalExistMW(sc)                              'Total existing generating capacity, MW'
  totalExistDSM(sc)                             'Total existing DSM and IL capacity, MW'
  totalBuiltMW(sc)                              'Total new generating capacity installed, MW'
  totalBuiltDSM(sc)                             'Total new DSM and IL capacity installed, MW'
  totalRetiredMW(sc)                            'Total retired capacity, MW'
  genYr(sc,rt,outcomes,g,y)                     'Generation by plant and year, GWh'
  genGWh(sc,rt,outcomes)                        'Generation - includes DSM, IL and shortage (deficit) generation, GWh'
  genTWh(sc,rt,outcomes)                        'Generation - includes DSM, IL and shortage (deficit) generation, TWh'
  genDSM(sc,rt,outcomes)                        'DSM and IL dispatched, GWh'
  genPeaker(sc,rt,outcomes)                     'Generation by peakers, GWh'
  deficitGen(sc,rt,outcomes,y,t,lb)             'Aggregate deficit generation (i.e. sum over all shortage generators), GWh'
  xsDeficitGen(sc,rt,outcomes,y,t,lb)           'Excessive deficit generation in any load block, period or year (excessive means it exceeds 3% of total generation), GWh'
* Transmission
  actualTxCap(sc,rt,r,rr,y)                     'Actual transmission capacity for each path in each modelled year (may depend on endogenous decisions)'
  priorTxCap(sc,r,rr,ps)                        'Transmission capacity prior to a state change for all states (silent, though, on when state changes), MW'
  postTxCap(sc,r,rr,ps)                         'Transmission capacity after a state change for all states (silent, though, on when state changes), MW'
  numYrsToBuildTx(sc,tupg,y)                    'Identify the number of years taken to build a particular upgrade of a transmission investment'
  interTxLossYrGWh(sc,rt,outcomes,y)            'Interregional transmission losses by year, GWh'
  interTxLossGWh(sc,rt,outcomes)                'Total interregional transmission losses, GWh'
  intraTxLossYrGWh(sc,y)                        'Intraregional transmission losses by year, GWh'
  intraTxLossGWh(sc)                            'Total intraregional transmission losses, GWh'
  ;



*===============================================================================================
* 3. Declare output files and set their attributes.

* .pc = 5 ==> comma-delimited text file, aka Excel .csv
* .pc = 6 ==> tab-delimited text file, .txt - good for Matlab.
$set delim  5
$set suffix csv
$if %delim%==6 $set suffix txt

Files
* Human-readable or formatted output files.
  ss        Solve summary report                      / "%OutPath%\%runName%\%runName% - A solve summary report.txt" /
  bld       A build and retirement schedule           / "%OutPath%\%runName%\%runName% - Generation plant build and retirement schedule.%suffix%" /
  invest    Investment schedules by year              / "%OutPath%\%runName%\%runName% - Gen and Tx investment schedules by year.txt" /
  sooBld    SOO build and retirement schedule         / "%OutPath%\%runName%\%runName% - SOO plant build and retirement schedule.%suffix%" /
* Machine-readable output files - for use by other applications.
  colors   'Colours for scenarios, techs, fuels etc'  / "%OutPath%\%runName%\Processed files\%runName% - Colours.txt" /
  pltgeo    Generation with geo                       / "%OutPath%\%runName%\Processed files\%runName% - Generation build and retirements by year with georeferencing.txt" /
  txgeo     Transmission upgrades with geo            / "%OutPath%\%runName%\Processed files\%runName% - Transmission grid and upgrades by year with georeferencing.txt" /
  ;

ss.ap = 0 ;          ss.lw = 0 ;
bld.pc = %delim% ;
invest.pw = 1000 ;   invest.lw = 0 ;
sooBld.pc = %delim% ;

colors.lw = 0 ;      colors.pc = 6 ;
pltgeo.pw = 1000 ;   pltgeo.lw = 0 ;         pltgeo.pc = 6 ;
txgeo.pw = 1000 ;    txgeo.lw = 0 ;          txgeo.pc = 6 ;


* Write out the colours for scenarios, technologies and fuels (NB: as they apply to the first scenario).
put colors '// Scenarios' ;
loop(scenarioColor(sc,red,green,blue), put / sc.tl, sc.te(sc), red.tl, green.tl, blue.tl ) ;
put // '// Technologies' ;
loop(k, put / k.tl, k.te(k) loop(techColor(sc,k,red,green,blue)$(ord(sc) = 1), put red.tl, green.tl, blue.tl ) ) ;
put // '// Fuels' ;
loop(f, put / f.tl, f.te(f) loop(fuelColor(sc,f,red,green,blue)$(ord(sc) = 1), put red.tl, green.tl, blue.tl ) ) ;
put // '// Fuel groups' ;
loop(fg, put / fg.tl, fg.te(fg) loop(fuelGrpColor(sc,fg,red,green,blue)$(ord(sc) = 1), put red.tl, green.tl, blue.tl ) ) ;



*===============================================================================================
* 4. Perform the various calculations/assignments necessary to generate reports.

activeRTHD(sc,rt,outcomes) $sum(hY, activeHD(sc,rt,hY,outcomes) ) = yes ;

* a) Objective function components - value by year and total value
* Objective function components - value by year (Note that for run type 'dis', it's the average that gets computed).
objComponentsYr(activeRT(sc,rt),y,'PVfacG_t1')    = sum(firstPeriod(sc,t), PVfacG(sc,y,t)) ;
objComponentsYr(activeRT(sc,rt),y,'PVfacT_t1')    = sum(firstPeriod(sc,t), PVfacT(sc,y,t)) ;
objComponentsYr(activeRT(sc,rt),y,'obj_total')    = s2_TOTALCOST(sc,rt) ;
objComponentsYr(activeRT(sc,rt),y,'obj_gencapex') = 1e-6 * sum(possibleToBuild(sc,g), capCharge(sc,g,y) * s2_CAPACITY(sc,rt,g,y) ) ;
objComponentsYr(activeRT(sc,rt),y,'obj_refurb')   = 1e-6 * sum(possibleToRefurbish(sc,g), s2_REFURBCOST(sc,rt,g,y) ) ;
objComponentsYr(activeRT(sc,rt),y,'obj_txcapex')  = sum(paths(sc,r,rr), s2_TXCAPCHARGES(sc,rt,r,rr,y) ) ;
objComponentsYr(activeRT(sc,rt),y,'obj_fixOM')    = 1e-6 / card(t) * (1 - taxRate) * sum((g,t), PVfacG(sc,y,t) * i_fixedOM(sc,g) * s2_CAPACITY(sc,rt,g,y)) ;
objComponentsYr(activeRT(sc,rt),y,'obj_hvdc')     = 1e-6 / card(t) * (1 - taxRate) *
                                                      sum((g,k,o,t)$( (not demandGen(sc,k)) * sigen(sc,g) * possibleToBuild(sc,g) * mapg_k(sc,g,k) * mapg_o(sc,g,o) ),
                                                        PVfacG(sc,y,t) * i_HVDCshr(sc,o) * i_HVDClevy(sc,y) * s2_CAPACITY(sc,rt,g,y) ) ;
objComponentsYr(activeRT(sc,rt),y,'obj_varOM')    = 1e-6 * (1 - taxRate) * sum((t,outcomes) , PVfacG(sc,y,t) * 1e3 * i_hydroWeight(sc,outcomes)  *
                                                      sum((g,lb), s2_GEN(sc,rt,g,y,t,lb,outcomes)  * SRMC(sc,g,y) * sum(mapg_e(sc,g,e), locFac_Recip(sc,e)) ) ) ;
objComponentsYr(activeRT(sc,rt),y,'VoLLcost')     = 1e-6 * (1 - taxRate) * sum((t,outcomes) , PVfacG(sc,y,t) * 1e3 * i_hydroWeight(sc,outcomes)  *
                                                      sum((s,lb), s2_VOLLGEN(sc,rt,s,y,t,lb,outcomes)  * i_VOLLcost(sc,s) ) ) ;
objComponentsYr(activeRT(sc,rt),y,'obj_rescosts') = 1e-6 * (1 - taxRate) * sum((g,rc,t,lb,outcomes) , PVfacG(sc,y,t) * i_hydroWeight(sc,outcomes)  * s2_RESV(sc,rt,g,rc,y,t,lb,outcomes)  * i_plantReservesCost(sc,g,rc) ) ;
objComponentsYr(activeRT(sc,rt),y,'obj_nfrcosts') = 1e-6 * (1 - taxRate) * sum((r,rr,t,lb,outcomes, stp)$( nwd(sc,r,rr) or swd(sc,r,rr) ),
                                                      PVfacG(sc,y,t) * i_hydroWeight(sc,outcomes)  * (hoursPerBlock(sc,t,lb) * s2_RESVCOMPONENTS(sc,rt,r,rr,y,t,lb,outcomes, stp)) * pNFresvCost(sc,r,rr,stp) ) ;
objComponentsYr(activeRT(sc,rt),y,'obj_renNrg')   = penaltyViolateRenNrg * s2_RENNRGPENALTY(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'obj_resvviol') = 1e-6 * sum((rc,ild,t,lb,outcomes) , i_hydroWeight(sc,outcomes)  * reserveViolationPenalty(sc,ild,rc) * s2_RESVVIOL(sc,rt,rc,ild,y,t,lb,outcomes)  ) ;
objComponentsYr(activeRT(sc,rt),y,'slk_rstrctMW') = 9999 * s2_ANNMWSLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_nzsec')    = 9998 * s2_SEC_NZSLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_ni1sec')   = 9998 * s2_SEC_NI1SLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_ni2sec')   = 9998 * s2_SEC_NI2SLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_nzNoWnd')  = 9997 * s2_NOWIND_NZSLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_niNoWnd')  = 9997 * s2_NOWIND_NISLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_rencap')   = 9996 * s2_RENCAPSLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_limhyd')   = 9995 * s2_HYDROSLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_minutil')  = 9994 * s2_MINUTILSLACK(sc,rt,y) ;
objComponentsYr(activeRT(sc,rt),y,'slk_limfuel')  = 9993 * s2_FUELSLACK(sc,rt,y) ;

* Objective function components - total value (Note that for run type 'dis', it's the average that gets computed).
objComponents(activeRT(sc,rt),'obj_total')    = s2_TOTALCOST(sc,rt) ;
objComponents(activeRT(sc,rt),'obj_gencapex') = 1e-6 * sum((y,firstPeriod(sc,t),possibleToBuild(sc,g)), PVfacG(sc,y,t) * capCharge(sc,g,y) * s2_CAPACITY(sc,rt,g,y) ) ;
objComponents(activeRT(sc,rt),'obj_refurb')   = 1e-6 * sum((y,firstPeriod(sc,t),possibleToRefurbish(sc,g)), PVfacG(sc,y,t) * s2_REFURBCOST(sc,rt,g,y) ) ;
objComponents(activeRT(sc,rt),'obj_txcapex')  = sum((paths(sc,r,rr),y,firstPeriod(sc,t)), PVfacT(sc,y,t) * s2_TXCAPCHARGES(sc,rt,r,rr,y) ) ;
objComponents(activeRT(sc,rt),'obj_fixOM')    = 1e-6 / card(t) * (1 - taxRate) * sum((g,y,t), PVfacG(sc,y,t) * i_fixedOM(sc,g) * s2_CAPACITY(sc,rt,g,y)) ;
objComponents(activeRT(sc,rt),'obj_hvdc')     = 1e-6 / card(t) * (1 - taxRate) *
                                                  sum((g,k,o,y,t)$( (not demandGen(sc,k)) * sigen(sc,g) * possibleToBuild(sc,g) * mapg_k(sc,g,k) * mapg_o(sc,g,o) ),
                                                    PVfacG(sc,y,t) * i_HVDCshr(sc,o) * i_HVDClevy(sc,y) * s2_CAPACITY(sc,rt,g,y) ) ;
objComponents(activeRT(sc,rt),'obj_varOM')    = 1e-6 * (1 - taxRate) * sum((y,t,outcomes) , PVfacG(sc,y,t) * 1e3 * i_hydroWeight(sc,outcomes)  *
                                                  sum((g,lb), s2_GEN(sc,rt,g,y,t,lb,outcomes)  * SRMC(sc,g,y) * sum(mapg_e(sc,g,e), locFac_Recip(sc,e)) ) ) ;
objComponents(activeRT(sc,rt),'VoLLcost')     = 1e-6 * (1 - taxRate) * sum((y,t,outcomes) , PVfacG(sc,y,t) * 1e3 * i_hydroWeight(sc,outcomes)  *
                                                  sum((s,lb), s2_VOLLGEN(sc,rt,s,y,t,lb,outcomes)  * i_VOLLcost(sc,s) ) ) ;
objComponents(activeRT(sc,rt),'obj_rescosts') = 1e-6 * (1 - taxRate) * sum((g,rc,y,t,lb,outcomes) , PVfacG(sc,y,t) * i_hydroWeight(sc,outcomes)  * s2_RESV(sc,rt,g,rc,y,t,lb,outcomes)  * i_plantReservesCost(sc,g,rc) ) ;
objComponents(activeRT(sc,rt),'obj_nfrcosts') = 1e-6 * (1 - taxRate) * sum((r,rr,y,t,lb,outcomes, stp)$( nwd(sc,r,rr) or swd(sc,r,rr) ),
                                                  PVfacG(sc,y,t) * i_hydroWeight(sc,outcomes)  * (hoursPerBlock(sc,t,lb) * s2_RESVCOMPONENTS(sc,rt,r,rr,y,t,lb,outcomes, stp)) * pNFresvCost(sc,r,rr,stp) ) ;
objComponents(activeRT(sc,rt),'obj_renNrg')   = sum(y, penaltyViolateRenNrg * s2_RENNRGPENALTY(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'obj_resvviol') = 1e-6 * sum((rc,ild,y,t,lb,outcomes) , i_hydroWeight(sc,outcomes)  * reserveViolationPenalty(sc,ild,rc) * s2_RESVVIOL(sc,rt,rc,ild,y,t,lb,outcomes)  ) ;
objComponents(activeRT(sc,rt),'slk_rstrctMW') = 9999 * sum(y, s2_ANNMWSLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_nzsec')    = 9998 * sum(y, s2_SEC_NZSLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_ni1sec')   = 9998 * sum(y, s2_SEC_NI1SLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_ni2sec')   = 9998 * sum(y, s2_SEC_NI2SLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_nzNoWnd')  = 9997 * sum(y, s2_NOWIND_NZSLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_niNoWnd')  = 9997 * sum(y, s2_NOWIND_NISLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_rencap')   = 9996 * sum(y, s2_RENCAPSLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_limhyd')   = 9995 * sum(y, s2_HYDROSLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_minutil')  = 9994 * sum(y, s2_MINUTILSLACK(sc,rt,y)) ;
objComponents(activeRT(sc,rt),'slk_limfuel')  = 9993 * sum(y, s2_FUELSLACK(sc,rt,y)) ;



* b) Various counts
numGenPlant(sc)  = card(g) ;
numVOLLplant(sc) = card(s) ;
numExist(sc)     = sum(exist(sc,g), 1 );
numCommit(sc)    = sum(commit(sc,g), 1 );
numNew(sc)       = sum(new(sc,g), 1 );
numNeverBuild(sc) = sum(neverBuild(sc,g), 1 );
numZeroMWplt(sc)  = sum(g$( i_nameplate(sc,g) = 0 ), 1 ) ;
numSchedHydroPlant(sc) = sum(schedHydroPlant(sc,g), 1 ) ;

* Use this to sort out plant status discrepancies
$ontext
File xxx / xxx.txt / ; xxx.lw=0; put xxx @20 'Exist ' 'Comit' '  New' '  Neva' ;
loop((g,sc),
  put / g.tl @15 sc.tl ;
  if(exist(sc,g),      put @24 '1' else put @24 '-' ) ;
  if(commit(sc,g),     put @30 '1' else put @30 '-' ) ;
  if(new(sc,g),        put @35 '1' else put @35 '-' ) ;
  if(neverBuild(sc,g), put @40 '1' else put @40 '-' ) ;
) ;
$offtext

* Initialise the set called 'buildSoln' based on choice of values for Runtype and SuppressReopt.
$if %RunType%%SuppressReopt%==00 buildSoln('reo') = yes ;
$if %RunType%%SuppressReopt%==01 buildSoln('tmg') = yes ;
$if %RunType%%SuppressReopt%==10 buildSoln('reo') = yes ;
$if %RunType%%SuppressReopt%==11 buildSoln('tmg') = yes ;
$if %RunType%==2 buildSoln('dis') = yes ;

buildYr(sc,g) = 0 ;
retireYr(sc,g) = 0 ;
retireMW(sc,g) = 0 ;

loop(activeRT(sc,rt),

* Capacity and dispatch
  potentialCap(sc,k,'blt') = sum(possibleToBuild(sc,g)$mapg_k(sc,g,k), i_nameplate(sc,g)) ;
  potentialCap(sc,k,'rfb') = sum(possibleToRefurbish(sc,g)$mapg_k(sc,g,k), i_nameplate(sc,g)) ;
  potentialCap(sc,k,'rtd') = sum(possibleToRetire(sc,g)$mapg_k(sc,g,k), i_nameplate(sc,g)) ;

* Calculations that relate only to the run type in which capacity expansion/contraction decisions are made.
  if(buildSoln(rt),

    activeCapacity(sc,g,y)$s2_CAPACITY(sc,rt,g,y) = yes ;

    actualCap(sc,rt,k,'blt') = sum(validYrBuild(sc,g,y)$mapg_k(sc,g,k), s2_BUILD(sc,rt,g,y)) ;
    actualCap(sc,rt,k,'rfb') = sum(possibleToRefurbish(sc,g)$mapg_k(sc,g,k), (1 - s2_ISRETIRED(sc,rt,g)) * i_nameplate(sc,g) ) ;
    actualCap(sc,rt,k,'rtd') = sum((possibleToRetire(sc,g),y)$mapg_k(sc,g,k), s2_RETIRE(sc,rt,g,y) + exogMWretired(sc,g,y)) ;

    actualCapPC(sc,rt,k,a)$potentialCap(sc,k,a) = 100 * actualCap(sc,rt,k,a) / potentialCap(sc,k,a) ;

    partialMWbuilt(sc,g)$( (i_nameplate(sc,g) - sum(y, s2_BUILD(sc,rt,g,y)) > 1.0e-9) ) = sum(y, s2_BUILD(sc,rt,g,y)) ;

    counter = 0 ;
    loop(g,
      loop(y$s2_BUILD(sc,rt,g,y),
        counter = counter + 1 ;
        numYrsToBuildPlant(sc,g,y) = counter ;
      ) ;
      counter = 0 ;
    ) ;
    numYrsToBuildPlant(sc,g,y)$( s2_RETIRE(sc,rt,g,y) or exogMWretired(sc,g,y) ) = -1 ;

    buildOrRetireMW(sc,g,y) = s2_BUILD(sc,rt,g,y) - s2_RETIRE(sc,rt,g,y) - exogMWretired(sc,g,y) ;

    loop(y,
      buildYr(sc,g)$(  buildYr(sc,g) = 0  and   s2_BUILD(sc,rt,g,y) ) = yearNum(sc,y) ;
      retireYr(sc,g)$( retireYr(sc,g) = 0 and ( s2_RETIRE(sc,rt,g,y) or exogMWretired(sc,g,y) ) ) = yearNum(sc,y) ;
    ) ;

    buildMW(sc,g)  = sum(y, s2_BUILD(sc,rt,g,y)) ;
    retireMW(sc,g) = sum(y, s2_RETIRE(sc,rt,g,y) + exogMWretired(sc,g,y)) ;
    finalMW(sc,g)  = i_nameplate(sc,g)$exist(sc,g) + buildMW(sc,g) - retireMW(sc,g) ;

    totalExistMW(sc)  = sum((g,f)$( exist(sc,g) * mapg_f(sc,g,f) ), i_nameplate(sc,g) ) ;
    totalExistDSM(sc) = sum((g,k)$( exist(sc,g) * mapg_k(sc,g,k) * demandGen(sc,k) ), i_nameplate(sc,g) ) ;

    totalBuiltMW(sc)  = sum(g, buildMW(sc,g)) ;
    totalBuiltDSM(sc) = sum((g,k)$( mapg_k(sc,g,k) * demandGen(sc,k) ), buildMW(sc,g)) ;

    totalRetiredMW(sc) = sum(g, retireMW(sc,g)) ;

* End of capacity expansion/contraction calculations.
  ) ;

  genYr(activeRTHD(sc,rt,outcomes) ,g,y) = sum((t,lb), s2_GEN(sc,rt,g,y,t,lb,outcomes) ) ;

  genGWh(activeRTHD(sc,rt,outcomes) ) = sum((g,y), genYr(sc,rt,outcomes, g,y)) ;
  genTWh(activeRTHD(sc,rt,outcomes) ) = 1e-3 * genGWh(sc,rt,outcomes)  ;
  genDSM(activeRTHD(sc,rt,outcomes) ) = sum((g,y,k)$( mapg_k(sc,g,k) * demandGen(sc,k) ), genYr(sc,rt,outcomes, g,y)) ;
  genPeaker(activeRTHD(sc,rt,outcomes) ) = sum((g,y,k)$( mapg_k(sc,g,k) * peaker(sc,k) ), genYr(sc,rt,outcomes, g,y)) ;

  deficitGen(activeRTHD(sc,rt,outcomes) ,y,t,lb) = sum(s, s2_VOLLGEN(sc,rt,s,y,t,lb,outcomes) ) ;
  xsDeficitGen(activeRTHD(sc,rt,outcomes) ,y,t,lb)$( deficitGen(sc,rt,outcomes, y,t,lb) > ( .03 * sum(g, s2_GEN(sc,rt,g,y,t,lb,outcomes) ) ) ) = deficitGen(sc,rt,outcomes, y,t,lb) ;

* Transmission
  actualTxCap(sc,rt,r,rr,y)$paths(sc,r,rr) = sum(ps, i_txCapacity(sc,r,rr,ps) * s2_BTX(sc,rt,r,rr,ps,y)) ; 

  loop(ps,
    priorTxCap(sc,r,rr,ps)$allowedStates(sc,r,rr,ps) = i_txCapacity(sc,r,rr,ps) ;
    postTxCap(sc,r,rr,ps+1)$allowedStates(sc,r,rr,ps+1) = i_txCapacity(sc,r,rr,ps+1) ;
  ) ;

  counter = 0 ;
  loop(tupg$buildSoln(rt),
    loop(y$s2_TXPROJVAR(sc,rt,tupg,y),
      counter = counter + 1 ;
      numYrsToBuildTx(sc,tupg,y) = counter ;
    ) ;
    counter = 0 ;
  ) ;

  interTxLossYrGWh(activeRTHD(sc,rt,outcomes) ,y) = 1e-3 * sum((r,rr,t,lb), s2_LOSS(sc,rt,r,rr,y,t,lb,outcomes)  * hoursPerBlock(sc,t,lb) ) ;
  interTxLossGWh(activeRTHD(sc,rt,outcomes) ) = sum(y, interTxLossYrGWh(sc,rt,outcomes, y)) ; 

  intraTxLossYrGWh(sc,y) = sum((ild,r,t,lb)$mapild_r(sc,ild,r), NrgDemand(sc,r,y,t,lb) * AClossFactors(sc,ild) / ( 1 + AClossFactors(sc,ild) ) ) ;
  intraTxLossGWh(sc) = sum(y, intraTxLossYrGWh(sc,y)) ;

) ;


Display
  objComponentsYr, objComponents, numGenPlant, numVOLLplant, numExist, numCommit, numNew, numNeverBuild, numZeroMWplt, numSchedHydroPlant
  potentialCap, actualCap, actualCapPC, partialMWbuilt, numYrsToBuildPlant, buildOrRetireMW, buildYr, retireYr, buildMW, retireMW, finalMW
  totalExistMW, totalExistDSM, totalBuiltMW, totalBuiltDSM, totalRetiredMW, genYr, genGWh, genTWh, genDSM, genPeaker, deficitGen, xsDeficitGen
  actualTxCap, priorTxCap, postTxCap, numYrsToBuildTx, interTxLossYrGWh, interTxLossGWh, intraTxLossYrGWh, intraTxLossGWh
  ;



*===============================================================================================
* 5. Write out the generation and transmission investment schedules in various formats.

* a) Build, refurbishment and retirement data and outcomes in .csv format suitable for importing into Excel.
put bld 'Scenario', 'Plant', 'Plant name', 'Zone', 'Region', 'Island', 'Technology', 'Fuel', 'RetireType', 'NameplateMW'
        'BuildYr', 'BuildMW', 'RefurbYr', 'RetireYr', 'RetireMW' ;
loop((sc,rt,g,e,r,ild,k,f,y)$( buildSoln(rt) * mapg_e(sc,g,e) * mapg_r(sc,g,r) * mapg_ild(sc,g,ild) * mapg_k(sc,g,k) * mapg_f(sc,g,f) * buildOrRetireMW(sc,g,y) ),
  put / sc.tl, g.tl, g.te(g), e.te(e), r.te(r), ild.tl, k.te(k), f.te(f) ;
  if(possibleToRetire(sc,g), if(exogMWretired(sc,g,y), put 'Exogenous' else put 'Endogenous' ) else put '' ) ; 
  put i_nameplate(sc,g) ;
  if(s2_BUILD(sc,rt,g,y), put yearNum(sc,y), s2_BUILD(sc,rt,g,y) else put '', '' ) ;
  if(possibleToRefurbish(sc,g) and (s2_ISRETIRED(sc,rt,g) = 0), put i_refurbDecisionYear(sc,g), else put '' ) ;
  if(retireYr(sc,g), put retireYr(sc,g) else put '' ) ;
  if(retireMW(sc,g), put retireMW(sc,g) else put '' ) ;
) ;


* b) Write out generation and transmission investment schedules in a formatted text file (i.e. human-readable)
counter = 0 ;
put invest 'Generation and transmission investment schedules by year' ;
loop(sc,
* Write out transmission investments.
  put /// sc.tl, ': ', sc.te(sc) ;
  put //   'Transmission' / ;
  put @3   'Year' @10 'Project' @25 'From' @40 'To' @55 'FrState' @65 'ToState' @77 'FrmCap' @86 'ToCap' @93 'ActCap' @102 'numBlds' @110 'Free?'
      @116 'ErlyYr' @124 'Project description' ;
  loop((buildSoln(rt),y)$sum(tupg, s2_TXPROJVAR(sc,rt,tupg,y)),
    put / @3 y.tl ;
    loop(transitions(sc,tupg,r,rr,ps,pss)$s2_TXPROJVAR(sc,rt,tupg,y),
      counter = counter + 1 ;
      if(counter = 1, put @10 else put / @10 ) ;
      put tupg.tl @25 r.tl @40 rr.tl @55 ps.tl @65 pss.tl @75 priorTxCap(sc,r,rr,ps):8:1, postTxCap(sc,r,rr,pss):8:1, actualTxCap(sc,rt,r,rr,y):8:1, @100 numYrsToBuildTx(sc,tupg,y):5:0 ;
      if(txFixedComYr(transitions) = 0, put @112 'y' else put @112 'n' ) ;
      if(txFixedComYr(transitions) >= txEarlyComYr(transitions), put @116 txFixedComYr(transitions):6:0 else put @116 txEarlyComYr(transitions):6:0 ) ;
      put @124 tupg.te(tupg) ;
    ) ;
    counter = 0 ;
  ) ;
  counter = 0 ;
* Write out generation investments.
  loop(buildSoln(rt),
    put // 'Generation' / ;
    put @3 'Year' @10 'Plant' @25 'Tech' @40 'SubStn' @55 'Region' @75 'MW' @81 'npMW' @88 'numBlds' @97 'Plant description' ;
    loop(y$sum(g, buildOrRetireMW(sc,g,y)),
      put / @3 y.tl ;
      loop((k,i,r,g)$( mapg_k(sc,g,k) * mapg_i(sc,g,i) * mapg_r(sc,g,r) * buildOrRetireMW(sc,g,y) ),
        counter = counter + 1 ;
        if(counter = 1, put @10 else put / @10 ) ;
        put g.tl @25 k.tl @40 i.tl @55 r.tl @70 buildOrRetireMW(sc,g,y):7:1, i_nameplate(sc,g):8:1 @86 numYrsToBuildPlant(sc,g,y):5:0 @97 g.te(g) ;
      ) ;
      counter = 0 ;
    ) ;
  ) ;
) ;


* c) Write out the build and retirement schedule - in SOO-ready format.
counter = 0 ;
put sooBld ;
loop(sc,
  put sc.te(sc) ;
  loop(activeRT(sc,rt)$buildSoln(rt),
    put / 'Year', 'Plant description', 'Technology description', 'MW', 'Nameplate MW', 'Substation' ;
    loop(y$sum(g, buildOrRetireMW(sc,g,y)),
      put / y.tl ;
      loop((k,g,i)$( mapg_k(sc,g,k) * mapg_i(sc,g,i) * buildOrRetireMW(sc,g,y) ),
        counter = counter + 1 ;
        if(counter = 1,
          put g.te(g), k.te(k), buildOrRetireMW(sc,g,y), i_nameplate(sc,g), i.te(i) ;
          else
          put / '' g.te(g), k.te(k), buildOrRetireMW(sc,g,y), i_nameplate(sc,g), i.te(i) ;
        ) ;
      ) ;
      counter = 0 ;
    ) ;
    put / ;
  ) ;
  put // ;
) ;

* d) Write out the forced builds by scenario - in SOO-ready format (in the same file as SOO build schedules).
counter = 0 ;
soobld.ap = 1 ;
put soobld / 'Summary of forced build dates by SC' /  ;
loop(sc,
  put sc.te(sc) ;
  loop(activeRT(sc,rt)$buildSoln(rt),
    put / 'Year', 'Plant description', 'Technology description', 'MW', 'Nameplate MW', 'Substation' ;
    loop(y$sum(g$( commit(sc,g) * buildOrRetireMW(sc,g,y) ), 1 ),
      put / y.tl ;
      loop((k,g,i)$( mapg_k(sc,g,k) * mapg_i(sc,g,i) * commit(sc,g) * buildOrRetireMW(sc,g,y) ),
        counter = counter + 1 ;
        if(counter = 1,
          put g.te(g), k.te(k), buildOrRetireMW(sc,g,y), i_nameplate(sc,g), i.te(i) ;
          else
          put / '' g.te(g), k.te(k), buildOrRetireMW(sc,g,y), i_nameplate(sc,g), i.te(i) ;
        ) ;
      ) ;
      counter = 0 ;
    ) ;
    put / ;
  ) ;
  put // ;
) ;

* e) Write out a file to create maps of generation plant builds/retirements.
*    NB: In cases of builds over multiple years, the first year is taken as the build year.
put pltgeo ;
put 'sc', 'Plant', 'Substation', 'Tech', 'Fuel', 'FuelGrp', 'subY', 'subX', 'existMW', 'builtMW', 'retiredMW', 'finalMW'
    'BuildYr', 'RetireYr', 'Plant description', 'Tech description', 'Fuel description', 'Fuel group description' ;
loop((sc,g,i,k,f,fg)$( (exist(sc,g) or finalMW(sc,g)) * mapg_i(sc,g,i) * mapg_k(sc,g,k) * mapg_f(sc,g,f) * mapf_fg(sc,f,fg) ),
  put / sc.tl, g.tl, i.tl, k.tl, f.tl, fg.tl, i_substnCoordinates(sc,i,'Northing'), i_substnCoordinates(sc,i,'Easting') ;
  if(exist(sc,g),
    put i_nameplate(sc,g), '', retireMW(sc,g), finalMW(sc,g), '', retireYr(sc,g) ;
    else
    put '', buildMW(sc,g), retireMW(sc,g), finalMW(sc,g), buildYr(sc,g), retireYr(sc,g) ;
  ) ;
  put g.te(g), k.te(k), f.te(f), fg.te(fg) ;
) ;

* f) Write out a file to create maps of transmission upgrades.
put txgeo ;
put 'sc', 'FrReg', 'ToReg', 'FrY', 'ToY', 'FrX', 'ToX', 'priorTxCap', 'postTxCap', 'ActualCap', 'FrSte', 'ToSte', 'Year', 'Project', 'Project description'  ;
* First report the initial network
loop((paths(sc,r,rr),ps)$( sameas(ps,'initial') ),
  put / sc.tl, r.tl, rr.tl ;
  loop((i,ii)$( regionCentroid(sc,i,r) * regionCentroid(sc,ii,rr) ),
    put i_substnCoordinates(sc,i,'Northing'), i_substnCoordinates(sc,ii,'Northing'), i_substnCoordinates(sc,i,'Easting'), i_substnCoordinates(sc,ii,'Easting') ;
  ) ;
  put priorTxCap(paths,ps) ;
) ;
txgeo.ap = 1 ;
* Now add on the upgrades.
loop((sc,buildSoln(rt),tupg,r,rr,ps,pss,y)$( (paths(sc,r,rr) * transitions(sc,tupg,r,rr,ps,pss)) and s2_TXPROJVAR(sc,rt,tupg,y) and txFixedComYr(sc,tupg,r,rr,ps,pss) < 3333 ),
  put / sc.tl, r.tl, rr.tl ;
  loop((i,ii)$( regionCentroid(sc,i,r) * regionCentroid(sc,ii,rr) ),
    put i_substnCoordinates(sc,i,'Northing'), i_substnCoordinates(sc,ii,'Northing'), i_substnCoordinates(sc,i,'Easting'), i_substnCoordinates(sc,ii,'Easting') ;
  ) ;
  put priorTxCap(sc,r,rr,ps), postTxCap(sc,r,rr,pss), actualTxCap(sc,rt,r,rr,y), ps.tl, pss.tl, yearNum(sc,y), tupg.tl, tupg.te(tupg) ;
) ;

$ontext
* g) Build schedule in GAMS-readable format - only write this file if GEM was run (i.e. skip it if RunType = 2).
$if %RunType%==2 $goto CarryOn2
put bld_GR ;
loop(buildSoln(rt),
* Write table of installed MW
  put "TABLE InstallMW(g,y,sc) 'Generation capacity to be installed by plant, year, and SC, MW'" / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop((g,y)$sum(sc_sim(sc), s2_BUILD(sc,rt,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(sc_sim(sc), if(s2_BUILD(sc,rt,g,y), put s2_BUILD(sc,rt,g,y):14:8 else put '              '  ) ) ;
  ) ;
* Write table of exogenously retired MW
  put '  ;' /// "TABLE ExogRetireSched(sc,g,y) 'Exogenous retirement schedule by plant, year, and SC'" / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop((g,y)$sum(sc_sim(sc), exogMWretired(sc,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(sc_sim(sc), if(exogMWretired(sc,g,y), put exogMWretired(sc,g,y):14:8 else put '              ' ) ) ;
  ) ;
* Write table of endogenously retired MW
  put '  ;' /// "TABLE EndogRetireSched(g,y,sc) 'Endogenous retirement schedule by plant, year, and SC'" / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop((g,y)$sum(sc_sim(sc), s2_RETIRE(sc,rt,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(sc_sim(sc), if(s2_RETIRE(sc,rt,g,y), put s2_RETIRE(sc,rt,g,y):14:8 else put '              ' ) ) ;
  ) ;
* Write table of indicator variables for endogenously retired plant
  put '  ;' /// "TABLE BRETFIX(g,y,sc) 'Indicate whether a plant has been endogenously retired'" / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop((g,y)$sum(sc_sim(sc), s2_BRET(sc,rt,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(sc_sim(sc), if(s2_BRET(sc,rt,g,y), put s2_BRET(sc,rt,g,y):14:8 else put '              ' ) ) ;
  ) ;
* Write table of installation year for generation plant
  put '  ;' /// "TABLE BuildSched(g,y,sc) 'Generation build schedule by plant, year, and SC'" / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop((g,y)$sum(sc_sim(sc), s2_BUILD(sc,rt,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(sc_sim(sc), if(s2_BUILD(sc,rt,g,y), put yearNum(sc,y):14:0 else put '              ' ) ) ;
  ) ;
* Write table of installed MW for those cases where plant is partially built
  if(sum((sc,g), partialMWbuilt(sc,g)),
    put '  ;' /// "TABLE PartialMWbuilt(g,sc) 'MW actually built in the case of plant not fully constructed'" / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
    loop(g$sum(sc_sim(sc), partialMWbuilt(sc,g)),
      put / g.tl:>15 @23 ;
      loop(sc_sim(sc), if(partialMWbuilt(sc,g), put partialMWbuilt(sc,g):14:8 else put '              ' ) ) ;
    ) ;
    put '  ;' /// ;
    else
    put /// ;
  ) ;
) ;
* Now write a summary of what happened to peakers if re-optimisation took place.
if(%SuppressReOpt% = 1,
  put '* Generation build schedule was not re-optimised by moving peakers about' /// ;
  else
  put '* Generation build schedule was re-optimised by allowing peakers to move' //
      '$ontext' / 'Summary of re-optimised peakers' / '  -Peakers in initial solution' / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop(movers(k),
    loop((tmg(rt),g,y)$( mapg_k(g,k) * (sum(sc_sim(sc), s2_BUILD(sc,rt,g,y)) > 0) ),
      put / g.tl:>15, '.', y.tl:<6 ;
      loop(sc_sim(sc), if(s2_BUILD(sc,rt,g,y), put yearNum(sc,y):14:0 else put '              ' ) ) ;
    ) ;
  ) ;
  put / '  -Peakers in re-optimised solution' / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop(movers(k),
    loop((reo(rt),g,y)$( mapg_k(g,k) * (sum(sc_sim(sc), s2_BUILD(sc,rt,g,y)) > 0) ),
      put / g.tl:>15, '.', y.tl:<6 ;
      loop(sc_sim(sc), if(s2_BUILD(sc,rt,g,y), put yearNum(sc,y):14:0 else put '              ' ) ) ;
    ) ;
  ) ;
  put / '$offtext' /// ;
) ;
* Finally, write summary tables pertaining to transmission upgrades.
bld_GR.ap = 1 ; put bld_GR ;
loop(buildSoln(rt),
  put "TABLE TXPROJECT(tupg,y,sc) 'Indicate whether an upgrade project is applied'" / @23 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop((tupg,y)$sum(sc_sim(sc), s2_TXPROJVAR(sc,rt,tupg,y)),
    put / tupg.tl:>15, '.', y.tl:<6 ;
    loop(sc_sim(sc), if(s2_TXPROJVAR(sc,rt,tupg,y), put s2_TXPROJVAR(sc,rt,tupg,y):14:8 else put '              ' ) ) ;
  ) ;
  put '  ;' /// "TABLE TXUPGRADES(r,rr,ps,pss,y,sc) 'Indicate whether a transmission upgrade is applied'" / @71 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop((paths(r,rr),ps,pss,y)$sum(sc_sim(sc), s2_TXUPGRADE(sc,rt,paths,ps,pss,y)),
    put / r.tl:>15, '.', rr.tl:>15, '.', ps.tl:>15, '.', pss.tl:>15, '.', y.tl:<6 ;
    loop(sc_sim(sc), if(s2_TXUPGRADE(sc,rt,paths,ps,pss,y), put s2_TXUPGRADE(sc,rt,paths,ps,pss,y):14:8 else put '              ' ) ) ;
  ) ;
  put '  ;' /// "TABLE BTXFIX(r,rr,ps,y,sc) 'Indicate the current state of a transmission path'" / @55 loop(sc_sim(sc), put sc.tl:>14 ) ;
  loop((paths(r,rr),ps,y)$sum(sc_sim(sc), s2_BTX(sc,rt,paths,ps,y)),
    put / r.tl:>15, '.', rr.tl:>15, '.', ps.tl:>15, '.', y.tl:<6 ;
    loop(sc_sim(sc), if(s2_BTX(sc,rt,paths,ps,y), put s2_BTX(sc,rt,paths,ps,y):14:8 else put '              ' ) ) ;
  ) ;
  put '  ;' / ;
) ;
$label CarryOn2
$offtext



*===============================================================================================
* x. Write the solve summary report.

* Message/header strings for use throughout solve summary report: 
$set ModStatx    "++++ Solution is no good - check GEMsolve.lst ++++"
$set ModStat1    "An optimal RMIP solution was obtained"
$set ModStat8    "A valid integer solution was obtained"
$set ModStat18   "An optimal integer solution was obtained"
$set SolveStatx  "++++ The solver exited abnormally - check GEMsolve.lst ++++"
$set SolveStat1  "The solver exited normally"
$set SolveStat3  "The solver exited normally after hitting a resource limit"

$set TmgHeader   " - results pertain to the timing run."
$set ReoHeader   " - results pertain to the re-optimisation run."
$set DisHeader   " - results pertain to the average of the dispatch runs."
$set DisExogHdr  " - decisions were provided to GEM exogenously in the form of a build and retirement schedule."

problems = 0 ; warnings = 0 ;
put ss
  'This report generated at ', system.time, ' on ' system.date  /
  'Search this entire report for 4 plus signs (++++) to identify any important error messages.' ///
  'Scenarios reported on are:' loop(sc, put / @3 sc.tl @15 sc.te(sc) ) ;

** Note - something is wrong with this table (or the calcs that come before) - the numbers don't add up.
put /// 'Generating plant status count' / @37 loop(sc, put sc.tl:>8 ) ; put /
'Total number plants in input file'       @37 loop(sc, put numGenPlant(sc):8:0 ) ; put /
'  Number of existing plant'              @37 loop(sc, put numExist(sc):8:0 ) ; put /
'    - includes scheduable hydro'         @37 loop(sc, put numSchedHydroPlant(sc):8:0 ) ; put /
'  Number of committed plant'             @37 loop(sc, put numCommit(sc):8:0 ) ; put /
'  Number of uncommitted plant'           @37 loop(sc, put numNew(sc):8:0 ) ; put /
'  Number of plant unable to be built'    @37 loop(sc, put numNeverBuild(sc):8:0 ) ; put /
'    - includes some due to zero MW'      @37 loop(sc, put numZeroMWplt(sc):8:0 ) ; put /
'Additionally, number of VOLL plant'      @37 loop(sc, put numVOLLplant(sc):8:0 ) ; put // ;

$ontext
  @3 'Run type:'                       @37 if(%RunType%=0, put 'GEM and DISP' else if(%RunType% = 1, put 'GEM only' else put 'DISP only')) ; put /
  @3 'Modelled time horizon:'          @37 '%FirstYr%', ' - ', '%LastYr%', '   (', numyears:2:0, ' years)' /
  @3 'Terminal benefit years:'         @37 begtermyrs:<4:0, ' - ', '%LastYr%' /
  @3 'Linear gen build years:'         @37 cgenyr:<4:0, ' onwards.' /
  @3 'Hydro sequences:'                @37 '%FirstInflowYr%', ' - ', '%LastInflowYr%' /
  @3 'Hydro year for timing:'          @37 loop(tmnghydyr(hYr),  put hYr.tl:<8:0
                                             if((not sameas(tmnghydyr,'Multiple')), put '- scaled by ', scaleInflows:4:2 ) ;
                                             if(sameas(tmnghydyr,'Multiple'),
                                               put @47 '- ' loop(outcomes$ ( not sameas(outcomes, 'dum')),  put outcomes. tl, ' ' ) ;
                                               put '- weighted by, respectively,' loop(outcomes$ ( not sameas(outcomes, 'dum')), put hydWeight(outcomes) :6:3 ) ) ;
                                           ) ; put /
  @3 'Timing re-optimised?'            @37 if(%RunType%<2 and %SuppressReopt%=0, put 'Yes' else put 'No') ; put /
$                                      if %SuppressReopt%==1 $goto SkipLine
  @3 'Hydro year for re-opt:'          @37 loop(reopthydyr(hYr), put hYr.tl:<8:0 ) ; put /
$                                      label SkipLine
  @3 'DISP hydro years limit:'         @37 (%LimHydYr%):<5:0 /
  @3 'DInflowYr flag:'                 @37 (%DInflowYr%):<5:0 /
  @3 'DInflwYrType flag:'              @37 (%DInflwYrType%):<5:0 /
  @3 'Security criteria:'              @37 if(Security = -1, put 'Security constraints are suppressed'
                                           else if(Security = 0, put 'n' else if(Security = 1, put 'n-1' else put 'n-2' ))) ; put /
  @3 'Reserves modelled?'              @37 if(useresv = 1, put 'Yes' else put 'No' ) ; put /
  @3 'Load growth profile:'            @37 '%GrowthProfile%' /
  @3 'Number load blocks:'             @37 numLBs:<5:0 /
  @3 'VOLL plants unavailable in top'  @37 '%noVOLLblks% load blocks' /
  @3 'Number of technologies:'         @37 numtech:<3:0 /
  @3 'Number of fuels:'                @37 numfuel:<3:0 /
  @3 'Number of owners:'               @37 numowner:<3:0 /
  @3 'Number of substations:'          @37 numsub:<3:0 /
  @3 'Number of regions:'              @37 numreg:<3:0 /
  @3 'Number of zones:'                @37 numzone:<3:0 /
  @3 'Number of Tx paths:'             @37 numpaths:<3:0 /
  @3 'Potential/actual Tx upgrades:'   @37 numupgrades:<3:0 /
  @3 'Network structure:'              @37 if(DCloadflow = 1,   put 'Meshed - solved using DC load flow' ;
                                           else if(numKVLs > 0, put 'Meshed - but forced to be solved as a transportation problem' ;
                                           else                 put 'Radial - solved as a transportation problem' ) ) ;  put /
  @3 'Kirchoff current laws:'          @37 numKCLs:<3:0 /
  @3 'Kirchoff voltage laws:'          @37 numKVLs:<3:0 /
  @3 'Transmission investment?'        @37 if(%RunType%<2 and EndogTx = 1, put 'Endogenous' else put 'Exogenous') ; put /
  @3 'Tx loss function segments:'      @37 (%CtrlPoints% - 1):<3:0 /
  @3 'Depreciation type:'              @37 if(%deptype%=0, put 'Straight line' else put 'Diminishing value' ) ; put /
  @3 'Random capex adjustment:'        @37 'Initial cost +/- ', (100 * %RandomCC%):<4:1, ' percent for technology types: ' loop(randomise(k), put k.tl ', ' ) ; put /
  @3 'Annual MW limit:'                @37 annMW:<5:0 /
  @3 'Partial builds?'                 @37 if(PartGenBld = 1, put 'Yes' else put 'No' ) ; put /
  @3 'Re-opt renew share?'             @37 if(%SprsRenShrReo%=0, put 'Yes' else put 'No' ) ; put /
  @3 'Dispatch renew share?'           @37 if(%SprsRenShrDis%=0, put 'Yes' else put 'No' ) ; put /
  @3 'Market scenarios:'               @37 '%RunMDS%' /
  @3 'LP/MIP/RMIP solver:'             @37 '%Solver%' /
  @3 'GEM solved as a:'                @37 '%GEMtype%' /
  @3 'DISP solved as a:'               @37 '%DISPtype%' /
  @3 'Plotting method:'                @37 if(%MexOrMat%=1, put 'Generate figures using .mex executable'
                                           else put 'Generate figures using Matlab source code' ) ; put /
  @3 'Input plots?'                    @37 if(%PlotInFigures%=1,  put 'Yes' else put 'No' ) ; put /
  @3 'Output plots?'                   @37 if(%PlotOutFigures%=1, put 'Yes' else put 'No' ) ; put /
  @3 'MIPtrace plots?'                 @37 ;
$                                      if %GEMtype%=="rmip" $goto NoTracePlots
                                       if(%PlotMIPtrace%=1, put 'Yes' else put 'No' ) ; put /
$                                      label NoTracePlots
$                                      if not %GEMtype%=="rmip" $goto YesTracePlots
                                       put 'No' ; put /
$                                      label YesTracePlots
  @3 'Restart file name:'              @37 system.rfile /
  @3 'Input file names:'               @37 "%DataPath%%GDXfilename%" ///
$offtext

loop(solveGoal(sc,goal),
  put /// 'Scenario: ' put sc.te(sc), ' (', sc.tl, ') ' / @3
          'Solve goal:' @25 goal.tl:<6, ' - ', goal.te(goal) //

$ if %RunType%==2 $goto NoGEM
* Generate the MIP solve summary information, i.e. timing run and re-optimised run (if it exists).
  loop(activeSolve(sc,rt,hY)$( not sameas(rt,'dis') ),
    if(sameas(rt,'tmg'),  put @3 rt.te(rt) / else put // @3 rt.te(rt) / ) ;
    put @3 'Model status:'  @25 ;
    if(solveReport(sc,rt,hY,goal,'ModStat') = 1, put '%ModStat18%' /
      else if(solveReport(sc,rt,hY,goal,'ModStat') = 8, put '%ModStat8%' /
        else put '%ModStatx%' / ; problems = problems + 1 ;
      ) ;
    ) ;
    put @3 'Solver status:' @25 ;
    if(solveReport(sc,rt,hY,goal,'SolStat') = 1, put '%SolveStat1%' / ;
      else if(solveReport(sc,rt,hY,goal,'SolStat') = 2 or solveReport(sc,rt,hY,goal,'SolStat') = 3, put '%SolveStat3%' / ;
        else put '%SolveStatx%' / ; problems = problems + 1 ;
      ) ;
    ) ; put
    @3 'Number equations:'     @25 solveReport(sc,rt,hY,goal,'Eqns'):<10:0 / 
    @3 'Number variables:'     @25 solveReport(sc,rt,hY,goal,'Vars'):<10:0 / 
    @3 'Number discrete vars:' @25 solveReport(sc,rt,hY,goal,'DVars'):<10:0 / 
    @3 'Number iterations:'    @25 solveReport(sc,rt,hY,goal,'Iter'):<12:0 / 
    @3 'Options file:'         @25 '%Solver%.op', solveReport(sc,rt,hY,goal,'Optfile'):<2:0 /
    @3 'Optcr (%):'            @25 ( 100 * solveReport(sc,rt,hY,goal,'Optcr') ):<6:3 /
    @3 'Gap (%):'              @25 solveReport(sc,rt,hY,goal,'Gap%'):<6:3 /
    @3 'Absolute gap:'         @25 solveReport(sc,rt,hY,goal,'GapAbs'):<10:2 /
    @3 'CPU seconds:'          @25 solveReport(sc,rt,hY,goal,'Time'):<10:0 /
    @3 'Objective fn value:'   @25 s2_TOTALCOST(sc,rt):<10:1 ;
    if(solveReport(sc,rt,hY,goal,'Slacks') = 1, put '  ++++ This solution contains slack variables ++++' / else put / ) ;
    put @9 'Comprised of:' @25 ;
    loop(objc$( ord(objc) > 1 and not (pen(objc) or slk(objc)) ),
      put objComponents(sc,rt,objc):<10:1, @33 '- ', objc.te(objc) / @23 '+ ' ;
    ) ;
    put sum(pen(objc), objComponents(sc,rt,objc)):<10:1, @33 '- Sum of penalty components' / @23 '+ ' ;
    put sum(slk(objc), objComponents(sc,rt,objc)):<10:1, @33 '- Sum of slack components' ;
  ) ;

$ label NoGEM
$ if %RunType%==1 $goto NoDISP
* Generate the RMIP (simulation) solve summary information for each pass around the SC loop.
  counter = 0 ;
  loop(activeSolve(sc,rt,hY)$( sameas(rt,'dis') and counter = 0 ),
    counter = counter + 1 ;
    put /// @3 rt.te(rt) /
    @3 'Number equations:'     @25 solveReport(sc,rt,hY,'','Eqns'):<10:0 / 
    @3 'Number variables:'     @25 solveReport(sc,rt,hY,'','Vars'):<10:0 / 
    @3 'Generation capex'      @25 objComponents(sc,rt,'obj_gencapex'):<10:1 /
    @3 'Refurbishment capex'   @25 objComponents(sc,rt,'obj_refurb'):<10:1 /
    @3 'Transmission capex'    @25 objComponents(sc,rt,'obj_txcapex'):<10:1 /
    @3 'HVDC charges'          @25 objComponents(sc,rt,'obj_hvdc'):<10:1 /
    @3 'Fixed opex'            @25 objComponents(sc,rt,'obj_fixOM'):<10:1 /
    @3 'Objective value in the following simulations (DISP solves) differs only due to after tax discounted' /
    @3 'variable costs, the cost of providing reserves and, possibly, the value of any penalties.' //
  ) ;
  loop(activeSolve(sc,rt,hY)$sameas(rt,'dis'),
    put @3 sc.tl, '. Simulation - ' hY.tl ' hydro year' /
    @3 'Model status:' @25 ;
    if(solveReport(sc,rt,hY,'','ModStat') = 1,  put '%ModStat1%'   / else put '%ModStatx%'   / ; problems = problems + 1 ) ; put @3 'Solver status:' @25 ;
    if(solveReport(sc,rt,hY,'','SolStat') = 1,  put '%SolveStat1%' / else put '%SolveStatx%' / ; problems = problems + 1 ) ; put
    @3 'Number iterations:'    @25 solveReport(sc,rt,hY,'','Iter'):<10:0 / 
    @3 'CPU seconds:'          @25 solveReport(sc,rt,hY,'','Time'):<10:0 / 
    @3 'Objective fn value:'   @25 s2_TOTALCOST(sc,rt):<10:0  ;
    if(solveReport(sc,rt,hY,'','Slacks') = 1, put '  ++++ This solution contains slack variables ++++' / else put / ) ;
    put / ;
  ) ;

$ label NoDisp
* End of writing to solve summary report loop over SC.
) ;


* Write summaries of built, refurbished and retired capacity by technology.
loop(buildSoln(rt),
  loop(a,
    put /// a.te(a) ;
    if( sameas(a,'blt'),
      if(sameas(rt,'tmg'), put '%TmgHeader%' else if(sameas(rt,'reo'), put '%ReoHeader%' else put '%DisExogHdr%' ) ) ;
      else
      if(not sameas(rt,'dis'), put '%TmgHeader%' else put '%DisExogHdr%' ) ;
    ) ;
    loop(activeRT(sc,rt),
      put // @3 sc.te(sc), ' (', sc.tl, ')' /  @58 'Potential MW' @71 'Actual MW' @89 '%' ;
      loop(k$potentialCap(sc,k,a),
        put / @5 k.te(k) @60, potentialCap(sc,k,a):10:0, actualCap(sc,rt,k,a):10:0, actualCapPC(sc,rt,k,a):10:1 ;
      ) ;
    ) ;
  ) ;
) ;


* Write a summary of transmission upgrades.
loop(buildSoln(rt),
  put //// 'Summary of transmission upgrades' ;
  if(not sameas(rt,'dis'), put '%TmgHeader%' else put '%DisHeader%' ) ;
  loop(activeRT(sc,rt),
    put // @3 sc.te(sc), ' (', sc.tl, ')' ;
    put / @5 'Project' @20 'From' @35 'To' @50 'From state' @65 'To state' @80 'Year' @87 'MW Capacity'
    loop((y,transitions(sc,tupg,r,rr,ps,pss))$s2_TXUPGRADE(sc,rt,r,rr,ps,pss,y),
      put / @5 tupg.tl:<15, r.tl:<15, rr.tl:<15, ps.tl:<15, pss.tl:<15, y.tl:<8, actualTxCap(sc,rt,r,rr,y):10:0  ;
    ) ;
  ) ;
) ;


* Write a summary of transmission losses.
loop(buildSoln(rt),
  put //// 'Summary of transmission losses (GWh and as percent of generation)' ;
  if(sameas(rt,'tmg'), put '%TmgHeader%' else if(sameas(rt,'reo'), put '%ReoHeader%' else put '%DisHeader%' ) ) ;
  loop(sc,
    put // @3 sc.te(sc), ' (', sc.tl, ')' ;
    put  / @5 'Generation:'           @28 loop(activeRTHD(sc,rt,outcomes) , put genGWh(sc,rt,outcomes) :10:1 ) ;
    put  / @5 'Intraregional losses:' @28 put intraTxLossGWh(sc):10:1 ; loop(activeRTHD(sc,rt,outcomes) ,  put ( 100 * intraTxLossGWh(sc) / genGWh(sc,rt,outcomes)  ):>7:2, '%  ' ) ;
    put  / @5 'Interregional losses:' @28 loop(activeRTHD(sc,rt,outcomes) , put interTxLossGWh(sc,rt,outcomes) :10:1, ( 100 * interTxLossGWh(sc,rt,outcomes)  / genGWh(sc,rt,outcomes)  ):>7:2, '%  ' ) ;
  ) ;
) ;


* Indicate whether or not there is excessive shortage generation (excessive is assumed to be 3% of generation).
if(sum((activeRTHD(sc,rt,outcomes) ,y,t,lb), xsDeficitGen(sc,rt,outcomes, y,t,lb)) = 0,
  put //// 'There is no excessive use of unserved energy, where excessive is defined to be 3% or more of generation.' ;
  else
  put //// 'Examine "Objective value components and shortage generation.gdx" in the GDX output folder to see' /
           'what years and load blocks had excessive shortage generation (i.e. more than 3% of generation).' ;
) ;


* Write a summary breakdown of objective function values.
loop(buildSoln(rt),
  put //// 'Summary breakdown of objective function values ($m)' ;
  if(sameas(rt,'tmg'), put '%TmgHeader%' else if(sameas(rt,'reo'), put '%ReoHeader%' else put '%DisHeader%' ) ) ;
  loop(activeSolve(sc,rt,hY),
    put // @3 sc.te(sc), ' (', sc.tl, ')' ;
    put /  @5 'Objective function value' @65 s2_TOTALCOST(sc,rt):10:1 ;
    loop(objc$( ord(objc) > 1 and not (pen(objc) or slk(objc)) ),
      put / @5 objc.te(objc), @65 objComponents(sc,rt,objc):10:1 ;
    ) ;
    put / @5 'Sum of penalty components', @65 ( sum(pen(objc), objComponents(sc,rt,objc)) ):10:1 ;
    put / @5 'Sum of slack components',   @65 ( sum(slk(objc), objComponents(sc,rt,objc)) ):10:1 ;
  ) ;
) ;


$ontext
* Probably don't need all this...
$set beginTermYrs  2035 ! Beginning of the sequence of modelled years that are used to represent the period of so-called terminal years.

* Write a note to solve summary report if problems (other than slacks or penalty violations) are present in some solutions, or if warnings are required.
* Figure out the warnings:
* Warning 1
if(%lastYear% - %beginTermYrs% < 3, warnings = warnings + 1 ) ;
* Warning 2
counter = 0 ;
loop((g,sc)$( ( erlyComYr(g,sc) > 1 ) * ( fixComYr(g,sc) > 1 ) * ( fixComYr(g,sc) < erlyComYr(g,sc) ) ),
  counter  = counter + 1 ;
  warnings = warnings + 1 ;
) ;
if(warnings > 0,
  put ss ////
  '  ++++ WARNINGS ++++' // ;
  if(%lastYear% - %beginTermYrs% < 3,
    put '  Terminal years begin in %beginTermYrs% whereas the last modelled year is ', lastYear:<4:0, ' (although GEM changed %beginTermYrs% to '
    begtermyrs:<4:0, ' and just carried on anyway). Check value of beginTermYrs.' / ;
  ) ;
  if(counter > 0,
    put '  Some fixed plant commissioning years precede the earliest commissioning year. Examine badComYr in %BaseOutName%.lst.' / ;
  ) ;
) ;

if(problems > 0,
  put ////
  '  ++++ PROBLEMS OTHER THAN SLACKS OR PENALTIES EXIST WITH SOME SOLUTIONS ++++' /
  '  It could be that a model is infeasible or the solver has not exited        ' /
  '  normally for some reason. Examine this solve summary report (search        ' /
  '  for ++++) or GEMsolve.log for additional information and resolve before    ' /
  '  proceeding.                                                                ' //// ;
) ;
$offtext

*===============================================================================================
* x. Xxx.

Execute_Unload '%OutPath%\%runName%\GDX\%runName% - Objective value components and shortage generation.gdx',
  objComponentsYr, objComponents, deficitGen, xsDeficitGen  ;



* Write a final time stamp in the solve summary report file
ss.ap = 1 ;
putclose ss //// "GEMreports has now finished..." / "Time: " system.time / "Date: " system.date ;



$stop
$ontext
From this point forward is stuff from the old GEMreports.

 Code sections:
  1. Load the data required to generate reports from the GDX files.
  2. Declare the sets and parameters local to GEMreports.
  3. Perform the various calculations required to generate reports.
  4. Write out the summary results report.
  5. Write out the generation and transmission investment schedules in various formats.
     a) Build, refurbishment and retirement data and outcomes in easy to read format suitable for importing into Excel.
     b) Write out generation and transmission investment schedules in a formatted text file (i.e. human-readable)
     c) Write out the build and retirement schedule - in SOO-ready format.
     d) Write out the forced builds by SC - in SOO-ready format (in the same file as SOO build schedules).
     e) Build schedule in GAMS-readable format - only write this file if GEM was run (i.e. skip it if RunType = 2).
     f) Write out a file to create maps of generation plant builds/retirements.
     g) Write out a file to create maps of transmission upgrades.
  6. Write out various summaries of the MW installed net of retirements.
  7. Write out various summaries of activity associated with peaking plant.
  8. Write out the GIT summary results.
  9. Write a report of HVDC charges sliced and diced all different ways.
 10. Write a report of features common to all scenarios.
 11. Write out a file of miscellaneous scalars - to pass to Matlab.
 12. Write out the mapping of inflow years to modelled years.
 13. Collect national generation, transmission, losses and load (GWh) into a single parameter.
 14. Write the solve summary report.
 15. Report the presence of penalty or slack (i.e. violation) variables (if any).
 16. Dump certain parameters into GDX files for use in subsequent programs, e.g. GEMplots and GEMaccess.
$offtext

Sets
* Capacity
  pkrs_plus20(sc,rt,outcomes,g)                 'Identify peakers that produce 20% or more energy in a year than they are theoretically capable of'
  noPkr_minus20(sc,rt,outcomes,g)               'Identify non-peakers that produce less than 20% of the energy in a year than they are theoretically capable of'

* GIT analysis
  cy        'Class of years'
             / git            'Years entering the GIT analysis'
               trm            'Terminal years' /
  item      'Item of GIT analysis'
             / itm1           'Capex (generation plant) before depreciation tax credit, $m PV'
               itm2           'Fixed Opex before tax, $m PV'
               itm3           'HVDC charge before tax, $m PV'
               itm4           'Variable Opex before tax, $m PV'
               itm5           'Capex (generation plant) after depreciation tax credit, $m PV'
               itm6           'Fixed Opex after tax, $m PV'
               itm7           'HVDC charge after tax, $m PV'
               itm8           'Variable Opex after tax, $m PV'
               itm9           'Capex (transmission equipment) before depreciation tax credit, $m PV'
               itm10          'Capex (transmission equipment) after depreciation tax credit, $m PV'
               itmA           'Generation fixed benefits (A)'
               itmB           'Generation variable benefits (B)'
               itmC           'Transmission costs (C)'
               itmD           'Terminal benefits (D)'
               itmE           'Expected net markets benefit (A+B-C+D)'  /
  git(cy)   'Years entering the GIT analysis'    / git /
  trm(cy)   'Terminal years'                     / trm /
  gityrs(y) 'GIT analysis years'
  trmyrs(y) 'Terminal period years'
  mapcy_y(cy,y) 'Map modelled years into year classes'

* Analysis of features common to all scenarios solved.
  buildall(g)              'Identify all plant built in all scenarios'
  buildall_sameyr(g)       'Identify all plant built in the same year in all scenarios'
  buildall_notsameyr(g)    'Identify all plant built in all scenarios but in different years in at least two scenarios'
  build_close5(g,sc,scs) 'A step to identifying all plant built within 5 years of each other (but not in the same year) in all scenarios'
  buildclose5(g)           'Identify all plant built within 5 years of each other (but not in the same year) in all scenarios'
  buildplus5(g)            'Identify all plant built in all scenarios where the build year is more than 5 years apart'
  ;

Parameters
  GITresults(item,d,sc,dt,cy)                   'GIT analysis summary'
  Chktotals(sc,rt,*)                            'Calculate national generation, transmission, losses and load, GWh'

* Items common to all SCs (where more than one SC is solved)
  numSC_fact                                    '(NumSC)!'
  numSC_fact2                                   '(NumSC - 2)!'
  numCombos                                     'numSC_fact / 2 * numSC_fact2, i.e. the number of ways of picking k unordered outcomes from n possibilities'
  retiresame(sc,g,y)                            'MW retired and year retired is the same across all SCs'
  refurbsame(sc,g)                              'Refurbishment year is the same across all SCs'
  txupgradesame(sc,tupg,y)                      'Transmission upgrade and upgrade year is the same across all SCs'

* Reserves
  totalresvviol(sc,rt,rc,outcomes)               'Total energy reserves violation, MW (to be written into results summary report)'

* Generation capex
  capchrg_r(sc,rt,g,y)                           'Capex charges (net of depreciation tax credit effects) by built plant by year, $m (real)'
  capchrg_pv(sc,rt,g,y,d)                        'Capex charges (net of depreciation tax credit effects) by built plant by year, $m (present value)'
  capchrgyr_r(sc,rt,y)                           'Capex charges on built plant (net of depreciation tax credit effects) by year, $m (real)'
  capchrgyr_pv(sc,rt,y,d)                        'Capex charges on built plant (net of depreciation tax credit effects) by year, $m (present value)'
  capchrgplt_r(sc,rt,g)                          'Capex charges (net of depreciation tax credit effects) by plant, $m (real)'
  capchrgplt_pv(sc,rt,g,d)                       'Capex charges (net of depreciation tax credit effects) by plant, $m (present value)'
  capchrgtot_r(sc,rt)                            'Total capex charges on built plant (net of depreciation tax credit effects), $m (real)'
  capchrgtot_pv(sc,rt,d)                         'Total capex charges on built plant (net of depreciation tax credit effects), $m (present value)'

  taxcred_r(sc,rt,g,y)                           'Tax credit on depreciation by built plant by year, $m (real)'
  taxcred_pv(sc,rt,g,y,d)                        'Tax credit on depreciation by built plant by year, $m (present value)'
  taxcredyr_r(sc,rt,y)                           'Tax credit on depreciation of built plant by year, $m (real)'
  taxcredyr_pv(sc,rt,y,d)                        'Tax credit on depreciation of built plant by year, $m (present value)'
  taxcredplt_r(sc,rt,g)                          'Tax credit on depreciation by plant, $m (real)'
  taxcredplt_pv(sc,rt,g,d)                       'Tax credit on depreciation by plant, $m (present value)'
  taxcredtot_r(sc,rt)                            'Total tax credit on depreciation of built plant, $m (real)'
  taxcredtot_pv(sc,rt,d)                         'Total tax credit on depreciation of built plant, $m (present value)'

* Generation plant fixed costs
  fopexgross_r(sc,rt,g,y,t)                      'Fixed O&M expenses (before tax benefit) by built plant by year by period, $m (real)'
  fopexgross_pv(sc,rt,g,y,t,d)                   'Fixed O&M expenses (before tax benefit) by built plant by year by period, $m (present value)'
  fopexnet_r(sc,rt,g,y,t)                        'Fixed O&M expenses (after tax benefit) by built plant by year by period, $m (real)'
  fopexnet_pv(sc,rt,g,y,t,d)                     'Fixed O&M expenses (after tax benefit) by built plant by year by period, $m (present value)'
  fopexgrosstot_r(sc,rt)                         'Total fixed O&M expenses (before tax benefit), $m (real)'
  fopexgrosstot_pv(sc,rt,d)                      'Total fixed O&M expenses (before tax benefit), $m (present value)'
  fopexnettot_r(sc,rt)                           'Total fixed O&M expenses (after tax benefit), $m (real)'
  fopexnettot_pv(sc,rt,d)                        'Total fixed O&M expenses (after tax benefit), $m (present value)'

* Generation plant HVDC costs
  hvdcgross_r(sc,rt,g,y,t)                       'HVDC charges (before tax benefit) by built plant by year by period, $m (real)'
  hvdcgross_pv(sc,rt,g,y,t,d)                    'HVDC charges (before tax benefit) by built plant by year by period, $m (present value)'
  hvdcnet_r(sc,rt,g,y,t)                         'HVDC charges (after tax benefit) by built plant by year by period, $m (real)'
  hvdcnet_pv(sc,rt,g,y,t,d)                      'HVDC charges (after tax benefit) by built plant by year by period, $m (present value)'
  hvdcgrosstot_r(sc,rt)                          'Total HVDC charges (before tax benefit), $m (real)'
  hvdcgrosstot_pv(sc,rt,d)                       'Total HVDC charges (before tax benefit), $m (present value)'
  hvdcnettot_r(sc,rt)                            'Total HVDC charges (after tax benefit), $m (real)'
  hvdcnettot_pv(sc,rt,d)                         'Total HVDC charges (after tax benefit), $m (present value)'

* Generation plant total SRMCs
  vopexgross_r(sc,rt,g,y,t,outcomes)             'Variable O&M expenses with LF adjustment (before tax benefit) by built plant by year by period, $m (real)'
  vopexgross_pv(sc,rt,g,y,t,outcomes,d)          'Variable O&M expenses with LF adjustment (before tax benefit) by built plant by year by period, $m (present value)'
  vopexnet_r(sc,rt,g,y,t,outcomes)               'Variable O&M expenses with LF adjustment (after tax benefit) by built plant by year by period, $m (real)'
  vopexnet_pv(sc,rt,g,y,t,outcomes,d)            'Variable O&M expenses with LF adjustment (after tax benefit) by built plant by year by period, $m (present value)'
  vopexgrosstot_r(sc,rt,outcomes)                'Total variable O&M expenses with LF adjustment (before tax benefit), $m (real)'
  vopexgrosstot_pv(sc,rt,outcomes,d)             'Total variable O&M expenses with LF adjustment (before tax benefit), $m (present value)'
  vopexnettot_r(sc,rt,outcomes)                  'Total variable O&M expenses with LF adjustment (after tax benefit), $m (real)'
  vopexnettot_pv(sc,rt,outcomes,d)               'Total variable O&M expenses with LF adjustment (after tax benefit), $m (present value)'

  vopexgrossnolf_r(sc,rt,g,y,t,outcomes)         'Variable O&M expenses without LF adjustment (before tax benefit) by built plant by year by period, $m (real)'
  vopexgrossnolf_pv(sc,rt,g,y,t,outcomes,d)      'Variable O&M expenses without LF adjustment (before tax benefit) by built plant by year by period, $m (present value)'
  vopexnetnolf_r(sc,rt,g,y,t,outcomes)           'Variable O&M expenses without LF adjustment (after tax benefit) by built plant by year by period, $m (real)'
  vopexnetnolf_pv(sc,rt,g,y,t,outcomes,d)        'Variable O&M expenses without LF adjustment (after tax benefit) by built plant by year by period, $m (present value)'
  vopexgrosstotnolf_r(sc,rt,outcomes)            'Total variable O&M expenses without LF adjustment (before tax benefit), $m (real)'
  vopexgrosstotnolf_pv(sc,rt,outcomes,d)         'Total variable O&M expenses without LF adjustment (before tax benefit), $m (present value)'
  vopexnettotnolf_r(sc,rt,outcomes)              'Total variable O&M expenses without LF adjustment (after tax benefit), $m (real)'
  vopexnettotnolf_pv(sc,rt,outcomes,d)           'Total variable O&M expenses without LF adjustment (after tax benefit), $m (present value)'

* Transmission equipment capex
  txcapchrg_r(sc,rt,r,rr,ps,y)                   'Transmission capex charges (net of depreciation tax credit effects) by built equipment by year, $m (real)'
  txcapchrg_pv(sc,rt,r,rr,ps,y,d)                'Transmission capex charges (net of depreciation tax credit effects) by built equipment by year, $m (present value)'
  txcapchrgyr_r(sc,rt,y)                         'Transmission capex charges (net of depreciation tax credit effects) by year, $m (real)'
  txcapchrgyr_pv(sc,rt,y,d)                      'Transmission capex charges (net of depreciation tax credit effects) by year, $m (present value)'
  txcapchrgeqp_r(sc,rt,r,rr,ps)                  'Transmission capex charges (net of depreciation tax credit effects) by equipment, $m (real)'
  txcapchrgeqp_pv(sc,rt,r,rr,ps,d)               'Transmission capex charges (net of depreciation tax credit effects) by equipment, $m (present value)'
  txcapchrgtot_r(sc,rt)                          'Total transmission capex charges (net of depreciation tax credit effects), $m (real)'
  txcapchrgtot_pv(sc,rt,d)                       'Total transmission capex charges (net of depreciation tax credit effects), $m (present value)'

  txtaxcred_r(sc,rt,r,rr,ps,y)                   'Tax credit on depreciation by built transmission equipment by year, $m (real)'
  txtaxcred_pv(sc,rt,r,rr,ps,y,d)                'Tax credit on depreciation by built transmission equipment by year, $m (present value)'
  txtaxcredyr_r(sc,rt,y)                         'Tax credit on depreciation on transmission equipment by year, $m (real)'
  txtaxcredyr_pv(sc,rt,y,d)                      'Tax credit on depreciation on transmission equipment by year, $m (present value)'
  txtaxcredeqp_r(sc,rt,r,rr,ps)                  'Tax credit on depreciation by transmission equipment, $m (real)'
  txtaxcredeqp_pv(sc,rt,r,rr,ps,d)               'Tax credit on depreciation by transmission equipment, $m (present value)'
  txtaxcredtot_r(sc,rt)                          'Total tax credit on depreciation of transmission equipment, $m (real)'
  txtaxcredtot_pv(sc,rt,d)                       'Total tax credit on depreciation of transmission equipment, $m (present value)'   ;



*===============================================================================================
* 3. Perform the various calculations required to generate reports.


loop(activeRT(sc,rt),

* Capacity and dispatch
  blah blah blah

* Calculations that relate only to the run type in which capacity expansion/contraction decisions are made.
    blah blah blah
   
* End of capacity expansion/contraction calculations.
  ) ;

  blah blah blah

* Reserves
  totalresvviol(sc,rt,rc,outcomes) $activeRTHD(sc,rt,outcomes)  = sum((ild,y,t,lb), s2_RESVVIOL(sc,rt,rc,ild,y,t,lb,outcomes)  ) ;

* Generation capex
  capchrg_r(sc,rt,g,y)    = 1e-6 * capchargem(g,y,sc) * s2_capacity(sc,rt,g,y) ;
  capchrg_pv(sc,rt,g,y,d) = sum(firstPeriod(t), PVfacsM(y,t,d) * capchrg_r(sc,rt,g,y)) ;

  capchrgyr_r(sc,rt,y)    = sum(g, capchrg_r(sc,rt,g,y)) ;
  capchrgyr_pv(sc,rt,y,d) = sum(g, capchrg_pv(sc,rt,g,y,d)) ;

  capchrgplt_r(sc,rt,g)    = sum(y, capchrg_r(sc,rt,g,y)) ;
  capchrgplt_pv(sc,rt,g,d) = sum(y, capchrg_pv(sc,rt,g,y,d)) ;

  capchrgtot_r(sc,rt)    = sum((g,y), capchrg_r(sc,rt,g,y)) ;
  capchrgtot_pv(sc,rt,d) = sum((g,y), capchrg_pv(sc,rt,g,y,d)) ;

  taxcred_r(sc,rt,g,y)    = 1e-6 * sum(mapg_k(g,k), deptcrecfac(y,k,'genplt') * capcostm(g,sc) * s2_capacity(sc,rt,g,y)) ;
  taxcred_pv(sc,rt,g,y,d) = sum(firstPeriod(t), PVfacsM(y,t,d) * taxcred_r(sc,rt,g,y)) ;

  taxcredyr_r(sc,rt,y)    = sum(g, taxcred_r(sc,rt,g,y)) ;
  taxcredyr_pv(sc,rt,y,d) = sum(g, taxcred_pv(sc,rt,g,y,d)) ;

  taxcredplt_r(sc,rt,g)    = sum(y, taxcred_r(sc,rt,g,y)) ;
  taxcredplt_pv(sc,rt,g,d) = sum(y, taxcred_pv(sc,rt,g,y,d)) ;

  taxcredtot_r(sc,rt)    = sum((g,y), taxcred_r(sc,rt,g,y)) ;
  taxcredtot_pv(sc,rt,d) = sum((g,y), taxcred_pv(sc,rt,g,y,d)) ;

* Generation plant fixed costs
  fopexgross_r(sc,rt,g,y,t)    = 1e-6 * ( 1/card(t) ) * fixedOM(g) * s2_capacity(sc,rt,g,y) ;
  fopexgross_pv(sc,rt,g,y,t,d) = PVfacsM(y,t,d) * fopexgross_r(sc,rt,g,y,t) ;
  fopexnet_r(sc,rt,g,y,t)      = (1 - i_taxRate)  * fopexgross_r(sc,rt,g,y,t) ;
  fopexnet_pv(sc,rt,g,y,t,d)   = PVfacsM(y,t,d) * fopexnet_r(sc,rt,g,y,t) ;

  fopexgrosstot_r(sc,rt)    = sum((g,y,t), fopexgross_r(sc,rt,g,y,t)) ;
  fopexgrosstot_pv(sc,rt,d) = sum((g,y,t), fopexgross_pv(sc,rt,g,y,t,d)) ;
  fopexnettot_r(sc,rt)      = sum((g,y,t), fopexnet_r(sc,rt,g,y,t)) ;
  fopexnettot_pv(sc,rt,d)   = sum((g,y,t), fopexnet_pv(sc,rt,g,y,t,d)) ; 

* Generation plant HVDC costs
  hvdcgross_r(sc,rt,g,y,t) =  1e-6 *
    ( 1/card(t) ) * sum((k,o)$( ( not demandGen(sc,k) ) * sigen(g) * posbuildm(g,sc) * mapg_k(g,k) * mapg_o(g,o) ), HVDCshr(o) * HVDCchargem(y,sc) * s2_capacity(sc,rt,g,y)) ;
  hvdcgross_pv(sc,rt,g,y,t,d) = PVfacsM(y,t,d) * hvdcgross_r(sc,rt,g,y,t) ;
  hvdcnet_r(sc,rt,g,y,t)      = (1 - i_taxRate)  * hvdcgross_r(sc,rt,g,y,t) ;
  hvdcnet_pv(sc,rt,g,y,t,d)   = PVfacsM(y,t,d) * hvdcnet_r(sc,rt,g,y,t) ;

  hvdcgrosstot_r(sc,rt)    = sum((g,y,t), hvdcgross_r(sc,rt,g,y,t)) ;
  hvdcgrosstot_pv(sc,rt,d) = sum((g,y,t), hvdcgross_pv(sc,rt,g,y,t,d)) ;
  hvdcnettot_r(sc,rt)      = sum((g,y,t), hvdcnet_r(sc,rt,g,y,t)) ;
  hvdcnettot_pv(sc,rt,d)   = sum((g,y,t), hvdcnet_pv(sc,rt,g,y,t,d)) ;

* Generation plant total SRMCs
  vopexgross_r(sc,rt,g,y,t,outcomes)$activeRTHD(sc,rt,outcomes)   = 1e-3 * sum((mapg_e(g,e),lb), SRMC(g,y) * s2_gen(sc,rt,g,y,t,lb,outcomes)  * locFac_Recip(e) ) ;
  vopexgross_pv(sc,rt,g,y,t,outcomes,d)$activeRTHD(sc,rt,outcomes)       = PVfacsM(y,t,d) * vopexgross_r(sc,rt,g,y,t,outcomes)  ;
  vopexnet_r(sc,rt,g,y,t,outcomes)$activeRTHD(sc,rt,outcomes)     = (1 - i_taxRate)  * vopexgross_r(sc,rt,g,y,t,outcomes)  ;
  vopexnet_pv(sc,rt,g,y,t,outcomes,d)$activeRTHD(sc,rt,outcomes)  = PVfacsM(y,t,d) * vopexnet_r(sc,rt,g,y,t,outcomes)  ;

  vopexgrosstot_r(sc,rt,outcomes)$activeRTHD(sc,rt,outcomes)      = sum((g,y,t), vopexgross_r(sc,rt,g,y,t,outcomes) ) ;
  vopexgrosstot_pv(sc,rt,outcomes,d)$activeRTHD(sc,rt,outcomes)   = sum((g,y,t), vopexgross_pv(sc,rt,g,y,t,outcomes, d)) ;
  vopexnettot_r(sc,rt,outcomes)$activeRTHD(sc,rt,outcomes)        = sum((g,y,t), vopexnet_r(sc,rt,g,y,t,outcomes) ) ;
  vopexnettot_pv(sc,rt,outcomes,d)$activeRTHD(sc,rt,outcomes)     = sum((g,y,t), vopexnet_pv(sc,rt,g,y,t,outcomes, d)) ;

  vopexgrossNoLF_r(sc,rt,g,y,t,outcomes)$activeRTHD(sc,rt,outcomes)      = 1e-3 * SRMC(g,y) * sum(lb, s2_gen(sc,rt,g,y,t,lb,outcomes) ) ;
  vopexgrossNoLF_pv(sc,rt,g,y,t,outcomes,d)$activeRTHD(sc,rt,outcomes)   = PVfacsM(y,t,d) * vopexgrossNoLF_r(sc,rt,g,y,t,outcomes)  ;
  vopexnetNoLF_r(sc,rt,g,y,t,outcomes)$activeRTHD(sc,rt,outcomes) = (1 - i_taxRate)  * vopexgrossNoLF_r(sc,rt,g,y,t,outcomes)  ;
  vopexnetNoLF_pv(sc,rt,g,y,t,outcomes,d)$activeRTHD(sc,rt,outcomes)     = PVfacsM(y,t,d) * vopexnetNoLF_r(sc,rt,g,y,t,outcomes)  ;

  vopexgrosstotNoLF_r(sc,rt,outcomes)$activeRTHD(sc,rt,outcomes)  = sum((g,y,t), vopexgrossNoLF_r(sc,rt,g,y,t,outcomes) ) ;
  vopexgrosstotNoLF_pv(sc,rt,outcomes,d)$activeRTHD(sc,rt,outcomes)      = sum((g,y,t), vopexgrossNoLF_pv(sc,rt,g,y,t,outcomes, d)) ;
  vopexnettotNoLF_r(sc,rt,outcomes)$activeRTHD(sc,rt,outcomes)    = sum((g,y,t), vopexnetNoLF_r(sc,rt,g,y,t,outcomes) ) ;
  vopexnettotNoLF_pv(sc,rt,outcomes,d)$activeRTHD(sc,rt,outcomes) = sum((g,y,t), vopexnetNoLF_pv(sc,rt,g,y,t,outcomes, d)) ;

* Transmission equipment capex
  txcapchrg_r(sc,rt,allowedStates(sc,r,rr,ps),y) = 0 ;
  loop(y,
    txcapchrg_r(sc,rt,paths,ps,y) = txcapchrg_r(sc,rt,paths,ps,y-1) + sum(trntxps(paths,pss,ps), txcapcharge(paths,ps,y) * s2_txupgrade(sc,rt,paths,pss,ps,y) ) ;
  ) ;
  txcapchrg_pv(sc,rt,allowedStates(sc,r,rr,ps),y,d) = sum(firstPeriod(t), PVfacsM(y,t,d) * txcapchrg_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ;

  txcapchrgyr_r(sc,rt,y)    = sum(allowedStates(sc,r,rr,ps), txcapchrg_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ;
  txcapchrgyr_pv(sc,rt,y,d) = sum(allowedStates(sc,r,rr,ps), txcapchrg_pv(sc,rt,allowedStates(sc,r,rr,ps),y,d)) ;

  txcapchrgeqp_r(sc,rt,allowedStates(sc,r,rr,ps))    = sum(y, txcapchrg_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ;
  txcapchrgeqp_pv(sc,rt,allowedStates(sc,r,rr,ps),d) = sum(y, txcapchrg_pv(sc,rt,allowedStates(sc,r,rr,ps),y,d)) ;

  txcapchrgtot_r(sc,rt)    = sum((allowedStates(sc,r,rr,ps),y), txcapchrg_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ;
  txcapchrgtot_pv(sc,rt,d) = sum((allowedStates(sc,r,rr,ps),y), txcapchrg_pv(sc,rt,allowedStates(sc,r,rr,ps),y,d)) ;

  txtaxcred_r(sc,rt,allowedStates(sc,r,rr,ps),y)    = txdeptcrecfac(y) * txcapcost(allowedStates(sc,r,rr,ps)) * s2_btx(sc,rt,allowedStates(sc,r,rr,ps),y) ;
  txtaxcred_pv(sc,rt,allowedStates(sc,r,rr,ps),y,d) = sum(firstPeriod(t), PVfacsM(y,t,d) * txtaxcred_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ;

  txtaxcredyr_r(sc,rt,y)    = sum(allowedStates(sc,r,rr,ps), txtaxcred_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ;
  txtaxcredyr_pv(sc,rt,y,d) = sum(allowedStates(sc,r,rr,ps), txtaxcred_pv(sc,rt,allowedStates(sc,r,rr,ps),y,d)) ;

  txtaxcredeqp_r(sc,rt,allowedStates(sc,r,rr,ps))    = sum(y, txtaxcred_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ;
  txtaxcredeqp_pv(sc,rt,allowedStates(sc,r,rr,ps),d) = sum(y, txtaxcred_pv(sc,rt,allowedStates(sc,r,rr,ps),y,d)) ;

  txtaxcredtot_r(sc,rt)    = sum((allowedStates(sc,r,rr,ps),y), txtaxcred_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ;
  txtaxcredtot_pv(sc,rt,d) = sum((allowedStates(sc,r,rr,ps),y), txtaxcred_pv(sc,rt,allowedStates(sc,r,rr,ps),y,d)) ;

) ;


*===============================================================================================
* 4. Write out the summary results report.

put rep "Results summary for '" system.title "' generated on " system.date ' at ' system.time / ;

put //  'Existing capacity (includes DSM and IL, and excludes shortage), MW' / @30 ;
loop(sc_sim(sc), put sc.tl:>12 ) put / @30 loop(sc_sim(sc), put totalExistMW(sc):12:1 ) ;

put /// 'Existing DSM and IL capacity, MW' / @30 loop(sc_sim(sc), put sc.tl:>12 ) put / @30 ;
loop(sc_sim(sc), put totalExistDSM(sc):12:1 ) ;

put /// 'Installed new capacity (includes DSM and IL), MW' / @30 loop(sc_sim(sc), put sc.tl:>12 ) put / @30 ;
loop(sc_sim(sc), put totalBuiltMW(sc):12:1 ) ;

put /// 'Installed new DSM and IL capacity, MW' / @30 loop(sc_sim(sc), put sc.tl:>12 ) put / @30 ;
loop(sc_sim(sc), put totalBuiltDSM(sc):12:1 ) ;

put /// 'Retired capacity, MW' / @30 loop(sc_sim(sc), put sc.tl:>12 ) put / @30 ;
loop(sc_sim(sc), put totalRetiredMW(sc):12:1 ) ;

put /// 'Generation (includes DSM, IL, and Shortage), TWh' / @30 loop(sc_sim(sc), put sc.tl:>12 ) ;
loop((rt,outcomes) $sum(sc, genTWh(sc,rt,outcomes) ),
  put / rt.tl @18 if(sameas(outcomes, 'dum'), put @30 else put outcomes. tl, (100 * i_hydroWeight(outcomes) ):8:2, @30 ) ;
  loop(sc_sim(sc), put genTWh(sc,rt,outcomes) :12:1 ) ;
) ;

put /// "'Generation' by DSM and IL, GWh" / @30 loop(sc_sim(sc), put sc.tl:>12 ) ;
loop((rt,outcomes) $sum(sc, genDSM(sc,rt,outcomes) ),
  put / rt.tl @18 if(sameas(outcomes, 'dum'), put @30 else put outcomes. tl, (100 * i_hydroWeight(outcomes) ):8:2, @30 ) ;
  loop(sc_sim(sc), put genDSM(sc,rt,outcomes) :12:1 ) ;
) ;

put /// 'Unserved energy (shortage generation), GWh' / @30 loop(sc_sim(sc), put sc.tl:>12 ) ;
loop((rt,outcomes) $sum((sc,y), defgenYr(sc,rt,outcomes, y)),
  put / rt.tl @18 if(sameas(outcomes, 'dum'), put @30 else put outcomes. tl, (100 * i_hydroWeight(outcomes) ):8:2, @30 ) ;
  loop(sc_sim(sc), put (sum(y, defgenYr(sc,rt,outcomes, y))):12:1 ) ;
) ;

put /// 'Generation by peakers, GWh' / @30 loop(sc_sim(sc), put sc.tl:>12 ) ;
loop((rt,outcomes) $sum(sc, genPeaker(sc,rt,outcomes) ),
  put / rt.tl @18 if(sameas(outcomes, 'dum'), put @30 else put outcomes. tl, (100 * i_hydroWeight(outcomes) ):8:2, @30 ) ;
  loop(sc_sim(sc), put  genPeaker(sc,rt,outcomes) :12:1 ) ;
) ;

put /// 'Transmission losses, GWh' / @30 loop(sc_sim(sc), put sc.tl:>12 ) ;
loop((rt,outcomes) $sum(sc, interTxLossGWh(sc,rt,outcomes) ),
  put / rt.tl @18 if(sameas(outcomes, 'dum'), put @30 else put outcomes. tl, (100 * i_hydroWeight(outcomes) ):8:2, @30 ) ;
  loop(sc_sim(sc), put  interTxLossGWh(sc,rt,outcomes) :12:1 ) ;
) ;

put /// 'Total energy reserve violation, MWh' / @30 ; loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @17 'Reserve class' ;
  loop((rc,outcomes) $(sum(sc, sc_rt(sc,rt)) and sum(sc, totalresvviol(sc,rt,rc,outcomes) )),
    put / @27 rc.tl if(sameas(outcomes, 'dum'), put @30 else put outcomes. tl, (100 * i_hydroWeight(outcomes) ):8:2, @30 ) ;
    loop(sc_sim(sc), put totalresvviol(sc,rt,rc,outcomes) :12:1 ) ;
  ) ;
) ;

put /// 'Total capex charges - before deducting depreciation tax credit effects, $m (present value)' / @30 ;
loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(sc_sim(sc), put ( capchrgtot_pv(sc,rt,d) + taxcredtot_pv(sc,rt,d) ):12:1 ) ;
  ) ;
) ;

put /// 'Total capex charges - net of depreciation tax credit effects, $m (present value)' / @30 ;
loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(sc_sim(sc), put capchrgtot_pv(sc,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total fixed O&M expenses - before deducting tax, $m (present value)' / @30 ; loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(sc_sim(sc), put fopexgrosstot_pv(sc,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total fixed O&M expenses - net of tax, $m (present value)' / @30 ; loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(sc_sim(sc), put fopexnettot_pv(sc,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total HVDC charges - before deducting tax, $m (present value)' / @30 ; loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(sc_sim(sc), put hvdcgrosstot_pv(sc,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total HVDC charges - net of tax, $m (present value)' / @30 ; loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(sc_sim(sc), put hvdcnettot_pv(sc,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total variable O&M expenses with LF adjustment - before deducting tax, $m (present value)' / @30 ;
loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop((outcomes, d)$sum(sc, vopexgrosstot_pv(sc,rt,outcomes, d)),
    put / @14
    if(sameas(outcomes, 'dum'),
      put @26 (100 * GITdisc(d)):4:1 @30 ;
      else
      put outcomes. tl, (100 * i_hydroWeight(outcomes) ):6:2, (100 * GITdisc(d)):6:1 @30 ;
    ) ;
    loop(sc_sim(sc), put vopexgrosstot_pv(sc,rt,outcomes, d):12:1 ) ;
  ) ;
) ;

put /// 'Total variable O&M expenses with LF adjustment - net of tax, $m (present value)' / @30 ;
loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop((outcomes, d)$sum(sc, vopexgrosstot_pv(sc,rt,outcomes, d)),
    put / @14
    if(sameas(outcomes, 'dum'),
      put @26 (100 * GITdisc(d)):4:1 @30 ;
      else
      put outcomes. tl, (100 * i_hydroWeight(outcomes) ):6:2, (100 * GITdisc(d)):6:1 @30 ;
    ) ;
    loop(sc_sim(sc), put vopexnettot_pv(sc,rt,outcomes, d):12:1 ) ;
  ) ;
) ;

put /// 'Total variable O&M expenses without LF adjustment - before deducting tax, $m (present value)' / @30 ;
loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop((outcomes, d)$sum(sc, vopexgrosstot_pv(sc,rt,outcomes, d)),
    put / @14
    if(sameas(outcomes, 'dum'),
      put @26 (100 * GITdisc(d)):4:1 @30 ;
      else
      put outcomes. tl, (100 * i_hydroWeight(outcomes) ):6:2, (100 * GITdisc(d)):6:1 @30 ;
    ) ;
    loop(sc_sim(sc), put vopexgrosstotNoLF_pv(sc,rt,outcomes, d):12:1 ) ;
  ) ;
) ;

put /// 'Total variable O&M expenses without LF adjustment - net of tax, $m (present value)' / @29 ;
loop(sc_sim(sc), put sc.tl:>12 ) ;
loop(rt$sum(sc, sc_rt(sc,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop((outcomes, d)$sum(sc, vopexgrosstot_pv(sc,rt,outcomes, d)),
    put / @14
    if(sameas(outcomes, 'dum'),
      put @26 (100 * GITdisc(d)):4:1 @30 ;
      else
      put outcomes. tl, (100 * i_hydroWeight(outcomes) ):6:2, (100 * GITdisc(d)):6:1 @30 ;
    ) ;
    loop(sc_sim(sc), put vopexnettotNoLF_pv(sc,rt,outcomes, d):12:1 ) ;
  ) ;
) ;


**
** Yet to write out the 16 transmission capex related parameters... but do we even want to?
** txcapchrg_r(sc,rt,r,rr,ps,y)                 'Transmission capex charges (net of depreciation tax credit effects) by built equipment by year, $m (real)'
** txcapchrg_pv(sc,rt,r,rr,ps,y,d)              'Transmission capex charges (net of depreciation tax credit effects) by built equipment by year, $m (present value)'
** txcapchrgyr_r(sc,rt,y)                       'Transmission capex charges (net of depreciation tax credit effects) by year, $m (real)'
** txcapchrgyr_pv(sc,rt,y,d)                    'Transmission capex charges (net of depreciation tax credit effects) by year, $m (present value)'
** txcapchrgeqp_r(sc,rt,r,rr,ps)                'Transmission capex charges (net of depreciation tax credit effects) by equipment, $m (real)'
** txcapchrgeqp_pv(sc,rt,r,rr,ps,d)             'Transmission capex charges (net of depreciation tax credit effects) by equipment, $m (present value)'
** txcapchrgtot_r(sc,rt)                        'Total transmission capex charges (net of depreciation tax credit effects), $m (real)'
** txcapchrgtot_pv(sc,rt,d)                     'Total transmission capex charges (net of depreciation tax credit effects), $m (present value)'
** txtaxcred_r(sc,rt,r,rr,ps,y)                 'Tax credit on depreciation by built transmission equipment by year, $m (real)'
** txtaxcred_pv(sc,rt,r,rr,ps,y,d)              'Tax credit on depreciation by built transmission equipment by year, $m (present value)'
** txtaxcredyr_r(sc,rt,y)                       'Tax credit on depreciation on transmission equipment by year, $m (real)'
** txtaxcredyr_pv(sc,rt,y,d)                    'Tax credit on depreciation on transmission equipment by year, $m (present value)'
** txtaxcredeqp_r(sc,rt,r,rr,ps)                'Tax credit on depreciation by transmission equipment, $m (real)'
** txtaxcredeqp_pv(sc,rt,r,rr,ps,d)             'Tax credit on depreciation by transmission equipment, $m (present value)'
** txtaxcredtot_r(sc,rt)                        'Total tax credit on depreciation of transmission equipment, $m (real)'
** txtaxcredtot_pv(sc,rt,d)                     'Total tax credit on depreciation of transmission equipment, $m (present value)'   ;
**



*===============================================================================================
* 5. Write out the generation and transmission investment schedules in various formats.

* Done already



*===============================================================================================
* 6. Write out various summaries of the MW installed net of retirements.

Parameters
  TechIldMW(sc,k,ild)  'Built megawatts less retired megawatts by technology and island'
  TechZoneMW(sc,k,e)   'Built megawatts less retired megawatts by technology and zone'
  TechRegMW(sc,k,r)    'Built megawatts less retired megawatts by technology and region'
  TechYearMW(sc,k,y)   'Built megawatts less retired megawatts by technology and year'
  SCyearMW(sc,y)       'Built megawatts less retired megawatts by SC and year'
  ;

if(%RunType%=2,
  TechIldMW(sc,k,ild) = sum((dis(rt),mapg_k(g,k),mapg_ild(g,ild),y), s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
  TechZoneMW(sc,k,e)  = sum((dis(rt),mapg_k(g,k),mapg_e(g,e),y),     s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
  TechRegMW(sc,k,r)   = sum((dis(rt),mapg_k(g,k),mapg_r(g,r),y),     s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
  TechYearMW(sc,k,y)  = sum((dis(rt),mapg_k(g,k)),                   s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
  else
  if(%SuppressReopt%=1,
    TechIldMW(sc,k,ild) = sum((tmg(rt),mapg_k(g,k),mapg_ild(g,ild),y), s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
    TechZoneMW(sc,k,e)  = sum((tmg(rt),mapg_k(g,k),mapg_e(g,e),y),     s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
    TechRegMW(sc,k,r)   = sum((tmg(rt),mapg_k(g,k),mapg_r(g,r),y),     s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
    TechYearMW(sc,k,y)  = sum((tmg(rt),mapg_k(g,k)),                   s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
    else
    TechIldMW(sc,k,ild) = sum((reo(rt),mapg_k(g,k),mapg_ild(g,ild),y), s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
    TechZoneMW(sc,k,e)  = sum((reo(rt),mapg_k(g,k),mapg_e(g,e),y),     s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
    TechRegMW(sc,k,r)   = sum((reo(rt),mapg_k(g,k),mapg_r(g,r),y),     s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
    TechYearMW(sc,k,y)  = sum((reo(rt),mapg_k(g,k)),                   s2_build(sc,rt,g,y) - s2_retire(sc,rt,g,y) - exogMWretired(sc,g,y)) ;
  ) ;
) ;

SCyearMW(sc,y) = sum(k, TechYearMW(sc,k,y)) ;

put bldsum 'Various summaries of newly installed generation plant net of retirements, MW' / ;

put // 'Installed less retired MW by technology and island'
loop(sc_sim(sc)$sum((k,ild), TechIldMW(sc,k,ild)),
  put // sc.tl, ': ', sc.te(sc) @58 ; loop(ild, put ild.tl:>15 ) ; put '          Total' ;
  loop(k$sum(ild, TechIldMW(sc,k,ild)),
    put / @3 k.te(k) @58 ; loop(ild, put TechIldMW(sc,k,ild):15:1 ) ; put (sum(ild, TechIldMW(sc,k,ild))):15:1 ;
  ) ;
  put / @3 'Total' @58 ; loop(ild, put (sum(k, TechIldMW(sc,k,ild))):15:1 ) ; put (sum((k,ild), TechIldMW(sc,k,ild))):15:1 ;
) ;

put // 'Installed less retired MW by technology and zone'
loop(sc_sim(sc)$sum((k,e), TechZoneMW(sc,k,e)),
  put // sc.tl, ': ', sc.te(sc) @58 ; loop(e, put e.tl:>15 ) ; put '          Total' ;
  loop(k$sum(e, TechZoneMW(sc,k,e)),
    put / @3 k.te(k) @58 ; loop(e, put TechZoneMW(sc,k,e):15:1 ) ; put (sum(e, TechZoneMW(sc,k,e))):15:1 ;
  ) ;
  put / @3 'Total' @58 ; loop(e, put (sum(k, TechZoneMW(sc,k,e))):15:1 ) ; put (sum((k,e), TechZoneMW(sc,k,e))):15:1 ;
) ;

put /// 'Installed less retired MW by technology and region'
loop(sc_sim(sc)$sum((k,r), TechRegMW(sc,k,r)),
  put // sc.tl, ': ', sc.te(sc) @58 ; loop(r, put r.tl:>15 ) ; put '          Total' ;
  loop(k$sum(r, TechRegMW(sc,k,r)),
    put / @3 k.te(k) @58 ; loop(r, put TechRegMW(sc,k,r):15:1 ) ; put (sum(r, TechRegMW(sc,k,r))):15:1 ;
  ) ;
  put / @3 'Total' @58 ; loop(r, put (sum(k, TechRegMW(sc,k,r))):15:1 ) ; put (sum((k,r), TechRegMW(sc,k,r))):15:1 ;
) ;

put /// 'Installed less retired MW by technology and year'
loop(sc_sim(sc)$sum((k,y), TechYearMW(sc,k,y)),
  put // sc.tl, ': ', sc.te(sc) @58 ; loop(y, put y.tl:>8 ) ; put '    Total' ;
  loop(k$sum(y, TechYearMW(sc,k,y)),
    put / @3 k.te(k) @58 ; loop(y, put TechYearMW(sc,k,y):8:1 ) ; put (sum(y, TechYearMW(sc,k,y))):9:1 ;
  ) ;
  put / @3 'Total' @58 ; loop(y, put (sum(k, TechYearMW(sc,k,y))):8:1 ) ;
) ;

put /// 'Installed less retired MW by SC and year' / @58 ; loop(y, put y.tl:>8 ) ; put '    Total' ;
loop(sc_sim(sc), put / @3 sc.te(sc) @58 ; loop(y, put SCyearMW(sc,y):8:1 ) ; put (sum(y, SCyearMW(sc,y))):9:1 ) ;

put /// 'Zone descriptions' ;
loop(e, put / e.tl @15 e.te(e) ) ;

put /// 'Region descriptions' ;
loop(r, put / r.tl @15 r.te(r) ) ;

put /// 'SC descriptions' ;
loop(sc_sim(sc), put / sc.tl @15 sc.te(sc) ) ;



*===============================================================================================
* 7. Write out various summaries of activity associated with peaking plant.

* Figure out which peakers produce more than 20% energy in any year.
counter = 0 ;
loop((activeRTHD(sc,rt,outcomes) ,mapg_k(g,k))$( peaker(k) * sum(y$activeCapacity(sc,g,y), 1) ),
  loop(y$( counter < 0.2 ),
    counter = genYr(sc,rt,outcomes, g,y) / (1e-3 * i_nameplate(sc,g) * sum((t,lb), maxcapfact(g,t,lb) * hoursPerBlock(t,lb)) ) ;
    pkrs_plus20(sc,rt,outcomes, g)$( counter >= 0.2 ) = yes ;
  ) ;
  counter = 0 ;
) ;

* Figure out which non-peakers produce less than 20% energy in any year.
counter = 1 ;
loop((activeRTHD(sc,rt,outcomes) ,mapg_k(g,k))$( not peaker(k) ),
  loop(y$( counter > 0.2 ),
    counter$( i_nameplate(sc,g) * sum((t,lb), maxcapfact(g,t,lb) * hoursPerBlock(t,lb)) ) =
      genYr(sc,rt,outcomes, g,y) / (1e-3 * i_nameplate(sc,g) * sum((t,lb), maxcapfact(g,t,lb) * hoursPerBlock(t,lb)) ) ;
    nopkr_minus20(sc,rt,outcomes, g)$( counter > 0 and counter <= 0.2 ) = yes ;
  ) ;
  counter = 1 ;
) ;

put pksum 'Peaking plant and VOLL activity' / 'Run name:', '%OutPrefix%' /
 'First modelled year:', '%FirstYr%' /
 'Number of modelled years:', numyears:2:0  /
 'Technologies specified by user to be peaking:' loop(peaker(k), put k.tl ) ;

put /// 'Peaking capacity by technology, MW' / 'Technology' '' loop(sc_sim(sc), put sc.tl ) ;
loop(peaker(k),
  put / k.te(k) ;
  put 'Existing capacity'              loop(sc_sim(sc), put sum(mapg_k(g,k), initCap(g)) ) ; 
  put / '' 'Capacity able to be built' loop(sc_sim(sc), put potentialCap(sc,k,'blt') ) ; 
  put / '' 'Capacity actually built'   loop(sc_sim(sc), put sum(buildSoln(rt), actualCap(sc,rt,k,'blt')) ) ; 
) ;

put /// 'Peaking capacity installed by region, MW' / 'Region' loop(sc_sim(sc), put sc.tl ) ;
loop(r,
  put / r.te(r) ; loop(sc_sim(sc), put sum((g,k)$( peaker(k) * mapg_k(g,k) * mapg_r(g,r) ), buildMW(sc,g)) ) ;
) ;

put /// 'Peaking capacity installed by zone, MW' / 'Zone' loop(sc_sim(sc), put sc.tl ) ;
loop(e,
  put / e.te(e) ; loop(sc_sim(sc), put sum((g,k)$( peaker(k) * mapg_k(g,k) * mapg_e(g,e) ), buildMW(sc,g)) ) ;
) ;

put /// 'Peakers exceeding 20% utilisation in any year' / 'Plant' 'Run type' 'Hydro domain' loop(sc_sim(sc), put sc.tl ) ;
loop((g,rt,outcomes) $sum(sc, pkrs_plus20(sc,rt,outcomes, g)),
  put / g.te(g), rt.tl, outcomes. tl ;
  loop(sc_sim(sc),
    if(pkrs_plus20(sc,rt,outcomes, g), put 'y' else put '' ) ;
  ) ;
) ;

put /// 'Non-peakers at less than 20% utilisation in any year' / 'Plant' 'Run type' 'Hydro domain' loop(sc_sim(sc), put sc.tl ) ;
loop((g,rt,outcomes) $sum(sc, nopkr_minus20(sc,rt,outcomes, g)),
  put / g.te(g), rt.tl, outcomes. tl ;
  loop(sc_sim(sc),
    if(nopkr_minus20(sc,rt,outcomes, g), put 'y' else put '' ) ;
  ) ;
) ;

put /// 'Energy produced by peakers, GWh' / 'SC' 'Run type' 'Hydro domain' 'Plant' 'Tech' 'Substn' 'MaxPotGWh' loop(y, put y.tl ) ; put '' 'Technology' ;
loop((activeRTHD(sc,rt,outcomes) ,g,peaker(k),i)$( mapg_k(g,k) * mapg_i(g,i) * sum(y$activeCapacity(sc,g,y), 1) ),
  put / sc.tl, rt.tl, outcomes. tl, g.te(g), k.tl, i.tl, (1e-3 * i_nameplate(sc,g) * sum((t,lb), maxcapfact(g,t,lb) * hoursPerBlock(t,lb)) )
  loop(y, put genYr(sc,rt,outcomes, g,y) ) ;
  put k.te(k) ;
) ;

put /// 'Energy produced by peakers as a proportion of potential' / 'SC' 'Run type' 'Hydro domain' 'Plant' 'Tech' 'Substn' 'MaxPotGWh' loop(y, put y.tl ) ; put '' 'Technology' ;
loop((activeRTHD(sc,rt,outcomes) ,g,peaker(k),i)$( mapg_k(g,k) * mapg_i(g,i) * sum(y$activeCapacity(sc,g,y), 1) ),
  put / sc.tl, rt.tl, outcomes. tl, g.te(g), k.tl, i.tl, (1e-3 * i_nameplate(sc,g) * sum((t,lb), maxcapfact(g,t,lb) * hoursPerBlock(t,lb)) )
  loop(y, put ( genYr(sc,rt,outcomes, g,y) / (1e-3 * i_nameplate(sc,g) * sum((t,lb), maxcapfact(g,t,lb) * hoursPerBlock(t,lb)) ) )  ) ;
  put k.te(k) ;
) ;

put /// 'VOLL by load block, period and year, GWh' / 'SC' 'Run type' 'Hydro domain' 'Plant' 'Period' 'Load block' loop(y, put y.tl ) ;
loop((activeRTHD(sc,rt,outcomes) ,s,t,lb)$sum(y$s2_vollgen(sc,rt,s,y,t,lb,outcomes) , 1),
  put / sc.tl, rt.tl, outcomes. tl, s.te(s), t.tl, lb.tl ;
  loop(y, put s2_vollgen(sc,rt,s,y,t,lb,outcomes)  ) ;
) ;

put /// 'Energy produced by peakers by load block, period and year, GWh' / 'SC' 'Run type' 'Hydro domain' 'Plant' 'Period' 'Load block' loop(y, put y.tl ) ;
loop((activeRTHD(sc,rt,outcomes) ,g,peaker(k),t,lb)$( mapg_k(g,k) * sum(y$s2_gen(sc,rt,g,y,t,lb,outcomes) , 1) ),
  put / sc.tl, rt.tl, outcomes. tl, g.te(g), t.tl, lb.tl ;
  loop(y, put s2_gen(sc,rt,g,y,t,lb,outcomes)  ) ;
) ;

*Display pkrs_plus20, nopkr_minus20 ;



*===============================================================================================
* 8. Write out the GIT summary results.

gityrs(y)$( yearNum(sc,y) <  begtermyrs ) = yes ;
trmyrs(y)$( yearNum(sc,y) >= begtermyrs ) = yes ;
mapcy_y(git,gityrs) = yes ;
mapcy_y(trm,trmyrs) = yes ;

GITresults('itm1',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),firstPeriod(t)), PVfacs(y,t,gitd,dt) * ( capchrg_r(sc,rt,g,y) + taxcred_r(sc,rt,g,y)) ) ;

GITresults('itm2',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t), PVfacs(y,t,gitd,dt) * fopexgross_r(sc,rt,g,y,t) ) ;

GITresults('itm3',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t), PVfacs(y,t,gitd,dt) * hvdcgross_r(sc,rt,g,y,t) ) ;

GITresults('itm4',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t,outcomes) , PVfacs(y,t,gitd,dt) * ( 1 / numhd ) * vopexgrossnolf_r(sc,rt,g,y,t,outcomes)  ) ;

GITresults('itm5',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),firstPeriod(t)), PVfacs(y,t,gitd,dt) * capchrg_r(sc,rt,g,y) ) ;

GITresults('itm6',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t), PVfacs(y,t,gitd,dt) * ( 1 - i_taxRate ) * fopexgross_r(sc,rt,g,y,t) ) ;

GITresults('itm7',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t), PVfacs(y,t,gitd,dt) * ( 1 - i_taxRate ) * hvdcgross_r(sc,rt,g,y,t) ) ;

GITresults('itm8',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t,outcomes) , PVfacs(y,t,gitd,dt) * ( 1 / numhd ) * ( 1 - i_taxRate ) * vopexgrossnolf_r(sc,rt,g,y,t,outcomes)  ) ;

GITresults('itm9',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),allowedStates(sc,r,rr,ps),mapcy_y(cy,y),firstPeriod(t)), PVfacs(y,t,gitd,dt) * ( txcapchrg_r(sc,rt,allowedStates(sc,r,rr,ps),y) + txtaxcred_r(sc,rt,allowedStates(sc,r,rr,ps),y)) ) ;

GITresults('itm10',gitd,sc_sim(sc),dt,cy) = sum((dis(rt),allowedStates(sc,r,rr,ps),mapcy_y(cy,y),firstPeriod(t)), PVfacs(y,t,gitd,dt) * txcapchrg_r(sc,rt,allowedStates(sc,r,rr,ps),y) ) ;

GITresults('itmA',gitd,sc_sim(sc),dt,cy) = GITresults('itm1',gitd,sc,dt,cy) + GITresults('itm2',gitd,sc,dt,cy) + GITresults('itm3',gitd,sc,dt,cy) ;

GITresults('itmB',gitd,sc_sim(sc),dt,cy) = GITresults('itm4',gitd,sc,dt,cy) ;

GITresults('itmC',gitd,sc_sim(sc),dt,cy) = GITresults('itm9',gitd,sc,dt,cy) ;

GITresults('itmD',gitd,sc_sim(sc),dt,cy) = GITresults('itm1',gitd,sc,dt,'trm') + GITresults('itm2',gitd,sc,dt,'trm') + GITresults('itm3',gitd,sc,dt,'trm') + GITresults('itm4',gitd,sc,dt,'trm') ;
 
GITresults('itmE',gitd,sc_sim(sc),dt,cy) = GITresults('itmA',gitd,sc,dt,cy) + GITresults('itmB',gitd,sc,dt,cy) - GITresults('itmC',gitd,sc,dt,cy) + GITresults('itmD',gitd,sc,dt,cy) ;

*Display cy, item, git, trm, mapcy_y, gityrs, trmyrs, GITresults ;

put gits
  'GIT analysis' /
  'Run name:', '%OutPrefix%' /
  'All results in millions of %FirstYr% dollars' /
  'All results are averages over the hydro sequences simulated (i.e. model DISP)' /
  'Number of inflow sequences simulated:' ;
loop(sc_sim(sc), put / '', sc.tl, numdisyrs(sc):0 ) ;

put // 'Summary GIT results - mid-period discounting (absolute, not change from base)', 'Discount rate' ;
loop(sc_sim(sc), put sc.tl ) ;
loop(item$( ord(item) > 10 ),
  put / item.te(item) ;
  counter = 0 ;
  loop(gitd(d),
    counter = counter + 1 ;
    if(counter = 1, put d.te(d) else put / '', d.te(d) ) ;
    loop(sc_sim(sc), put GITresults(item,gitd,sc,'mid','git') ) ;
  ) ;
) ;

put /// 'Summary GIT results - end-of-year discounting (absolute, not change from base)', 'Discount rate' ;
loop(sc_sim(sc), put sc.tl ) ;
loop(item$( ord(item) > 10 ),
  put / item.te(item) ;
  counter = 0 ;
  loop(gitd(d),
    counter = counter + 1 ;
    if(counter = 1, put d.te(d) else put / '', d.te(d) ) ;
    loop(sc_sim(sc), put GITresults(item,gitd,sc,'eoy','git') ) ;
  ) ;
) ;

put /// 'Components of GIT analysis - mid-period discounting', 'Discount rate' ;
loop(sc_sim(sc), put sc.tl ) ;
loop(item$( ord(item) < 11 ),
  put / item.te(item) ;
  counter = 0 ;
  loop(gitd(d),
    counter = counter + 1 ;
    if(counter = 1, put d.te(d) else put / '', d.te(d) ) ;
    loop(sc_sim(sc), put GITresults(item,gitd,sc,'mid','git') ) ;
  ) ;
) ;

put /// 'Components of GIT analysis - end-of-year discounting', 'Discount rate' ;
loop(sc_sim(sc), put sc.tl ) ;
loop(item$( ord(item) < 11 ),
  put / item.te(item) ;
  counter = 0 ;
  loop(gitd(d),
    counter = counter + 1 ;
    if(counter = 1, put d.te(d) else put / '', d.te(d) ) ;
    loop(sc_sim(sc), put GITresults(item,gitd,sc,'eoy','git') ) ;
  ) ;
) ;



*===============================================================================================
* 9. Write a report of HVDC charges sliced and diced all different ways.

put HVDCsum 'HVDC charges by year - before deducting tax, $m (real)' / 'SC' ; loop(y, put y.tl ) ;
loop((buildSoln(rt),sc_sim(sc))$sum((g,y,t), hvdcgross_r(sc,rt,g,y,t)),
  put / sc.tl ;
  loop(y, put ( sum((g,t), hvdcgross_r(sc,rt,g,y,t)) ) ) ;
) ;

put /// 'HVDC charges by year - after deducting tax, $m (real)' / 'SC' ; loop(y, put y.tl ) ;
loop((buildSoln(rt),sc_sim(sc))$sum((g,y,t), hvdcnet_r(sc,rt,g,y,t)),
  put / sc.tl ;
  loop(y, put ( sum((g,t), hvdcnet_r(sc,rt,g,y,t)) ) ) ;
) ;

put /// 'HVDC charges by plant - before deducting tax, $m (real)' / 'Plant' 'Tech' 'Fuel' 'Region' 'Zone' 'Owner' 'Share' 'Nameplate' ;
loop(sc_sim(sc), put sc.tl ) ;
loop((buildSoln(rt),g,k,f,r,e,o)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) * mapg_e(g,e) * mapg_o(g,o) * sum((sc,y,t), hvdcgross_r(sc,rt,g,y,t)) ),
  put / g.tl, k.tl, f.tl, r.tl, e.tl, o.tl, HVDCshr(o), i_nameplate(sc,g) ;
  loop(sc_sim(sc), put ( sum((y,t), hvdcgross_r(sc,rt,g,y,t)) ) ) ;
) ;

put /// 'HVDC charges by plant - after deducting tax, $m (real)' / 'Plant' 'Tech' 'Fuel' 'Region' 'Zone' 'Owner' 'Share' 'Nameplate' ;
loop(sc_sim(sc), put sc.tl ) ;
loop((buildSoln(rt),g,k,f,r,e,o)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) * mapg_e(g,e) * mapg_o(g,o) * sum((sc,y,t), hvdcnet_r(sc,rt,g,y,t)) ),
  put / g.tl, k.tl, f.tl, r.tl, e.tl, o.tl, HVDCshr(o), i_nameplate(sc,g) ;
  loop(sc_sim(sc), put ( sum((y,t), hvdcnet_r(sc,rt,g,y,t)) ) ) ;
) ;



$ontext
This chunk of code needs to be finished, i.e. it is to see if the revenue collected from HVDC charges is sufficient, and if it ain't,
you can reset the level of $/kw charge in the input data. 

Parameter ImpliedHVDC(sc,y) 'Implied HVDC charge, $/kW' ;
ImpliedHVDC(sc,y)$sum((buildSoln(rt),g)$( sigen(g) * posbuildm(g,sc) ), s2_capacity(sc,rt,g,y)) =
  sum((buildSoln(rt),g,t), hvdcgross_r(sc,rt,g,y,t)) / sum((buildSoln(rt),k,g)$(( not demandGen(sc,k) ) * sigen(g) * posbuildm(g,sc) * mapg_k(g,k)), s2_capacity(sc,rt,g,y)) ;

Display ImpliedHVDC, i_HVDCrevenue ;

*put /// 'Implied HVDC charges by plant, $/kW (real)' / 'Plant' 'Tech' 'Fuel' 'Region' 'Zone' 'Owner' 'Share' 'Nameplate' ;
*loop(sc_sim(sc), put sc.tl ) ;
*loop((g,k,f,r,e,o)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) * mapg_e(g,e) * mapg_o(g,o) * sum((sc,y,t), ImpliedHVDC(sc,g,y,t)) ),
*  put / g.tl, k.tl, f.tl, r.tl, e.tl, o.tl, HVDCshr(o), i_nameplate(sc,g) ;
*  loop(sc_sim(sc), put ( sum((y,t), ImpliedHVDC(sc,g,y,t)) ) ) ;
*) ;


* NB: The HVDC charge applies only to committed and new SI projects.
  1e-6 * sum((y,t), PVfacG(y,t) * (1 - i_taxRate) * (
           ( 1/card(t) ) * (
           sum((g,k,o)$((not demandGen(sc,k)) * sigen(g) * posbuild(g) * mapg_k(g,k) * mapg_o(g,o)), HVDCshr(o) * HVDCcharge(y) * CAPACITY(g,y))
           )
         ) )

* Generation plant HVDC costs
  hvdcgross_r(sc,rt,g,y,t) =  1e-6 *
    ( 1/card(t) ) * sum((k,o)$( ( not demandGen(sc,k) ) * sigen(g) * posbuildm(g,sc) * mapg_k(g,k) * mapg_o(g,o) ), HVDCshr(o) * HVDCchargem(y,sc) * s2_capacity(sc,rt,g,y)) ;
  hvdcgross_pv(sc,rt,g,y,t,d) = PVfacsM(y,t,d) * hvdcgross_r(sc,rt,g,y,t) ;
  hvdcnet_r(sc,rt,g,y,t)      = (1 - i_taxRate)  * hvdcgross_r(sc,rt,g,y,t) ;
  hvdcnet_pv(sc,rt,g,y,t,d)   = PVfacsM(y,t,d) * hvdcnet_r(sc,rt,g,y,t) ;
HVDCchargem(y,sc) = 1e3 * i_HVDCcharge(y,sc) ;
$offtext





*===============================================================================================
* 10. Write a report of features common to all scenarios.

* Skip this entire section if numSC = 1.
if(NumSC > 1,

* Figure out the number of combinations - used in counting all SC pairs where build year is within 5 years.
  numSC_fact = numSC ;      counter = numSC_fact ;
  numSC_fact2 = numSC - 2 ; counter2 = numSC_fact2 ;
  loop(sc_sim(sc),
    if(counter > 1,  numSC_fact  = numSC_fact *  ( counter - 1 ) ) ;
    if(counter2 > 1, numSC_fact2 = numSC_fact2 * ( counter2 - 1 ) ) ;
    counter =  counter  - 1 ;
    counter2 = counter2 - 1 ;
  ) ;

* numCombos equals 1 if numSC = 2, otherwise it equals numSC - 2 
  numCombos = 1 ;
  numCombos$( numSC > 2 ) = numSC_fact / ( 2 * numSC_fact2 ) ;

* Figure out which plants get built in all scenarios.
  buildall(g)$( ( sum(sc_sim(sc), buildYr(sc,g)) >= numSC * firstyear ) and
                ( sum(sc_sim(sc), buildYr(sc,g)) <= numSC * lastyear ) ) = yes ;

* Of the plants built in all scenarios, identify which ones get built in the same year.
  loop(sc_sim(sc),
    buildall_sameyr(buildall(g))$( sum(scs, buildYr(scs,g)) = numSC * buildYr(sc,g) ) = yes ;
  ) ;

* Of the plants built in all scenarios, identify which ones don't get built in the same year.
  buildall_notsameyr(buildall(g))$( not buildall_sameyr(g) ) = yes ; 

* Of the plants built in all scenarios but not all in the same year, identify those that get built within 5 years of each other.
  loop((g,sc,scs)$( buildall_notsameyr(g) * sc_sim(sc) * sc_sim(scs) * ( ord(sc) > ord(scs) ) ),
    build_close5(g,sc,scs)$( ( buildYr(sc,g) - buildYr(scs,g) > -6 ) and ( buildYr(sc,g) - buildYr(scs,g) < 6 ) ) = yes ;
  ) ;
  buildclose5(buildall_notsameyr(g))$( sum((sc,scs)$build_close5(g,sc,scs), 1 ) = numCombos ) = yes ;

* Of the plants built in all scenarios but not all in the same year, identify those that get built within 5 years of each other.
  buildplus5(buildall_notsameyr(g))$( not buildclose5(g) ) = yes ;

* Figure out retirements, refurbishments and transmission upgrades that happen in exactly the same year in each sc.
  loop(buildSoln(rt),
    retiresame(sc,g,y)$( sum(scs, s2_retire(scs,rt,g,y) + exogMWretired(scc,g,y)) = numSC * ( s2_retire(sc,rt,g,y) + exogMWretired(sc,g,y)) ) = s2_retire(sc,rt,g,y) + exogMWretired(sc,g,y) ;
    refurbsame(sc,g)$( sum(scs, s2_isretired(scs,rt,g)) = numSC ) = i_refurbDecisionYear(sc,g) ;
    txupgradesame(sc,tupg,y)$( sum(scs, s2_txprojvar(scs,rt,tupg,y)) = numSC ) = yearNum(sc,y) ;
  ) ;

  Display numSC_fact, numSC_fact2, numCombos, buildall, buildall_sameyr, buildall_notsameyr, buildclose5, buildplus5, retiresame, refurbsame, txupgradesame ;

* Write common features report.
  put common 'Common features across all scenarios' /// 'Scenarios in this model run: ' loop(sc_sim(sc), put sc.tl ', ' ) ;
  put /  'NB: Build year refers to the year the first increment of plant is built in case of builds over multiple years.' / ;

  put // 'Year and MW for all plant built in the same year in all scenarios' / 'Plant' @18 'Year' @23 ; loop(sc_sim(sc), put sc.tl:>6 ) ;
  loop((y,buildall_sameyr(g))$( numSC * yearNum(sc,y) = sum(sc_sim(sc), buildYr(sc,g)) ),
    put / g.tl @18 y.tl @23 loop(sc_sim(sc), put buildMW(sc,g):>6:0 ) ;
  ) ;

  put // 'MW and year built for all plant built in all scenarios, not in same year, but within 5 years of each other' /
         'Plant' @23 loop(sc_sim(sc), put sc.tl:>6 ) put '      ' loop(sc_sim(sc), put sc.tl:>6 ) ;
  if(sum(buildclose5(g), 1) > 0,
    loop(buildclose5(g),
      put / g.tl @23 loop(sc_sim(sc), put buildMW(sc,g):>6:0 ) put '      ' loop(sc_sim(sc), put buildYr(sc,g):>6:0 ) ;
    ) ;
    else put / 'There are none' ) ;

  put // 'MW and year built for all plant built in all scenarios, not in same year, but more than 5 years apart' /
         'Plant' @23 loop(sc_sim(sc), put sc.tl:>6 ) put '      ' loop(sc_sim(sc), put sc.tl:>6 ) ;
  if(sum(buildplus5(g), 1) > 0,
    loop(buildplus5(g),
      put / g.tl @23 loop(sc_sim(sc), put buildMW(sc,g):>6:0 ) put '      ' loop(sc_sim(sc), put buildYr(sc,g):>6:0 ) ;
    ) ;
    else put / 'There are none' ) ;

  put // 'MW retired' / 'Year' @7 'Plant' @23 ; loop(sc_sim(sc), put sc.tl:>6 ) ;
  if(sum((sc,g,y)$retiresame(sc,g,y), 1) > 0,
    loop((y,g)$sum(sc_sim(sc), retiresame(sc,g,y)),
      put / y.tl @7 g.tl @23 loop(sc_sim(sc), put retiresame(sc,g,y):>6:0 ) ;
    ) ;
    else put / 'There are none' ) ;

  put // 'Plant for which the refurbishment decision year is the same in all scenarios' / 'Plant' @23 ; loop(sc_sim(sc), put sc.tl:>6 ) ;
  if(sum((sc,g)$refurbsame(sc,g), 1) > 0,
    loop(g$sum(sc_sim(sc), refurbsame(sc,g)),
      put / g.tl @23 loop(sc_sim(sc), put refurbsame(sc,g):>6:0 )
    ) ;
    else put / 'There are none' ) ;

  put // 'Transmission upgrade year' / 'Year' @7 'Upgrade' @23 ; loop(sc_sim(sc), put sc.tl:>6 ) ;
  if(sum((sc,tupg,y)$txupgradesame(sc,tupg,y), 1) > 0,
    loop((y,tupg)$sum(sc_sim(sc), txupgradesame(sc,tupg,y)),
      put / y.tl @7 tupg.tl @23 ;
      loop(sc_sim(sc), put txupgradesame(sc,tupg,y):>6:0 )
    ) ;
    else put / 'There are none' ) ;

  put // 'Build years for all plant not built in all scenarios' / 'Plant' @23 loop(sc_sim(sc), put sc.tl:>6 ) ;
  loop(noexist(sc,g)$( not buildall(g) and sum(sc$buildYr(sc,g), 1) > 0 ),
    put / g.tl @23 loop(sc_sim(sc), put buildYr(sc,g):>6:0 )
  ) ;

) ;



*===============================================================================================
* 11. Write out a file of miscellaneous scalars - to pass to Matlab.
*     NB: It is not necessary to put every scalar known to GEM in this file.

Put miscs ;
put 'LossValue|%LossValue%|A user-specified value of the LRMC of generation plant' / ;
put 'partGenBld|', partGenBld:2:0, '|1 to enable some new plants to be partially and/or incrementally built; 0 otherwise' / ;
put 'annMW|', annMW:5:0, '|Annual MW upper bound on aggregate new generation plant builds' / ;
put 'i_taxRate|', i_taxRate:5:3, '|Corporate tax rate' / ;
put 'penaltyViolateRenNrg|', penaltyViolateRenNrg:5:3, '|Penalty used to make renewable energy constraint feasible, $m/GWh' / ;
put 'security|', security:2:0, '|Switch to control usage of (N, N-1, N-2) security constraints' / ;
put 'useresv|',  useresv:2:0, '|Global reserve formulation activation flag (1 = use reserves, 0 = no reserves are modelled)' / ;



*===============================================================================================
* 12. Write out the mapping of inflow years to modelled years.

put HydYrs 'SC', 'Run Type', 'hY' loop(y, put y.tl ) ;
loop((sc,rt,hY)$( sum(y, s_inflowyr(sc,rt,hY,y)) ),
  put / sc.tl, rt.tl, hY.tl ;
  loop(y,
    if(ahy(hY), put 'Average' else put s_inflowyr(sc,rt,hY,y) ) ;
  ) ;
) ;



*===============================================================================================
* 13. Collect national generation, transmission, losses and load (GWh) into a single parameter.

chktotals(sc_rt(sc,rt),'Gen')  = sum((r,g,y,t,lb,outcomes) $( activeRTHD(sc,rt,outcomes)  and mapg_r(g,r) ), s2_gen(sc,rt,g,y,t,lb,outcomes) ) ;
chktotals(sc_rt(sc,rt),'Tx')   = sum((r,rr,y,t,lb,outcomes) $activeRTHD(sc,rt,outcomes) , hoursPerBlock(t,lb) * 1e-3 * s2_tx(sc,rt,r,rr,y,t,lb,outcomes) ) ;
chktotals(sc_rt(sc,rt),'Loss') = sum((r,rr,y,t,lb,outcomes) $activeRTHD(sc,rt,outcomes) , hoursPerBlock(t,lb) * 1e-3 * s2_loss(sc,rt,r,rr,y,t,lb,outcomes) ) ;
chktotals(sc_rt(sc,rt),'Dem')  =
  sum((r,t,lb,y,outcomes) $activeRTHD(sc,rt,outcomes) , ldcMWm(sc,r,t,lb,y) * hoursPerBlock(t,lb) * 1e-3 + sum(g$( mapg_r(g,r) * pdhydro(g) ), s2_pumpedgen(sc,rt,g,y,t,lb,outcomes) ) ) ;

chktotals(sc,rt,'Bal')$sc_rt(sc,rt) = chktotals(sc,rt,'Gen') - chktotals(sc,rt,'Dem') - chktotals(sc,rt,'Loss') ;

Display chktotals ;





*===============================================================================================
* 15. Report the presence of penalty or slack (i.e. violation) variables (if any).

slacks = 0 ;
slacks = sum((sc_rt,slk), objComponents(sc_rt,slk)) + sum((sc_rt,pen), objComponents(sc_rt,pen)) ; 

Option slacks:0 ; Display slacks ;

if(slacks > 0,

  Display 'Slack or penalty variables have been used in at least one solution', %List_10_s3slacks%, s2_renNrgPenalty, s2_resvviol ;
  Execute_Unload '%OutPath%\%Outprefix%\GDX\S3 Slacks and penalties.gdx',       %List_10_s3slacks%, s2_renNrgPenalty, s2_resvviol ;

  put ss //// '++++ Slack or penalty variables are present in some solutions. Examine'    /
              '     %RepName%.lst and/or "Slacks and penalties.gdx" in the GDX directory' /
              '     for a detailed list of all slack and penalty variables.'              // ;
) ;



*===============================================================================================
* 16. Dump certain parameters into GDX files for use in subsequent programs, e.g. GEMplots and GEMaccess.

Execute_Unload '%OutPath%\%Outprefix%\GDX\%Outprefix% - ReportsData.gdx',
  GEMexecVer, GEMprepoutVer, GEMreportsVer
  activeCapacity, problems, warnings, slacks, numdisyrs, genYr, buildYr, capchrg_r, capchrg_pv, capchrgyr_r, capchrgyr_pv
  taxcred_r, taxcred_pv, fopexgross_r, fopexnet_r, hvdcgross_r, hvdcnet_r, txcapchrgyr_r, txcapchrgyr_pv
  ;




* End of file

$ontext

** LRMC code still under development. Use the stuff in GEMbaseOut as a template to create estimates of LRMC by plant
** given the actual GEM solution.

Sets
  z                                             'A sequence of years'            / z1 * z100  /
  mc                                            'Index for LRMC values'          / c1 * c2000 /
  checkmap(sc,g,y,z)

Parameter
*  mwh(sc,g,y)                                  'MWh per year per plant actually generated'
  mwh(sc,g)                                     'MWh per year per plant actually generated'
  plantyrs(g)                                   'Plant life, years'
  depreciation(sc,g,z)                          'Depreciation in each year of plant life, $m'
  undepcapital(sc,g,z)                          'Undepreciated capital in each year of plant life, $m'
  cndte_lrmc(mc)                                'Candidate lrmc's, $/MWh'
  dcf(sc,g,mc)                                  'Post-tax discounted cashflows by plant at each candidate LRMC level, $m'
  lrmc(sc,g)                                    'LRMC of each plant, $/MWh'
  totcosts(sc,g,z)                              'Total costs, $m'
  lrmc_offset                                   'Constant to add to 1 to kick off the candidate LRMC series'     / 0 /
  ycount
  zcount(sc,g)
  ;

* h is dum only for rt=dis - need to do mwh for tmg and/or reo too 
*mwh(sc,noexist(sc,g),y)$numdisyrs(sc) = 1e3 * sum((dis(rt),hY,outcomes) $( s_hdindex(sc,rt,hY,outcomes)  * ( not (ahy(hY) or mhy(hY)) ) ), s2_genYr(sc,rt,hY,g,y,outcomes) ) / numdisyrs(sc) ;
mwh(sc,noexist(sc,g)) = i_nameplate(sc,g) * 8760 * (1 - fof(g)) ;


* Convert plant life by technology to plant life by plant.
plantyrs(noexist(sc,g)) = sum(mapg_k(g,k), plantlife(k)) ;

zcount(sc_sim(sc),noexist(sc,g)) = plantyrs(g) + lastyear - firstyear ;

loop((sc_sim(sc),noexist(sc,g),y,z)$( ord(z) = ord(y) and buildYr(sc,'dis','1932',g) ),
  totcosts(sc,g,z) = 1e-6 * mwh(sc,g) * SRMC(g,y) + 1e-9 * gendata(g,'fOM') * nameplate(g) ;
) ;

* Complete the series for sequential years up to the number of modelled years plus plant life years.
loop((sc_sim(sc),noexist(sc,g),z)$( zcount(sc,g) and (ord(z) > 1) and (ord(z) <= zcount(sc,g)) ),
  totcosts(sc,g,z)$( not totcosts(sc,g,z) ) = totcosts(sc,g,z-1) ; 
) ;

* Zero out totcosts for all years prior to build year.
totcosts(sc,g,z)$( ord(z) < ( buildYr(sc,'dis','1932',g) - firstyear + 1 ) ) = 0 ;

* Compute depreciation and undepreciated capital for each relevant 'z' year. 
loop((sc_sim(sc),noexist(sc,g),z)$totcosts(sc,g,z),
  undepcapital(sc,g,z)$( ord(z) = buildYr(sc,'dis','1932',g) - firstyear + 1 ) = 1e-6 * nameplate(g) * capandconcost(g) ;
  depreciation(sc,g,z)$( ord(z) > buildYr(sc,'dis','1932',g) - firstyear + 1 ) = sum(mapg_k(g,k), deprate(k) * undepcapital(sc,g,z-1) ) ;
  undepcapital(sc,g,z)$( ord(z) > buildYr(sc,'dis','1932',g) - firstyear + 1 ) = undepcapital(sc,g,z-1) - depreciation(sc,g,z) ;
) ;

* Add depreciation to totcosts.
totcosts(sc,g,z) = totcosts(sc,g,z) + depreciation(sc,g,z) ;

Parameter capex(sc,g,z) ;
capex(sc,g,z)$( zcount(sc,g) and (ord(z) = buildYr(sc,'dis','1932',g) - firstyear + 1) ) = -1e-6 * nameplate(g) * capandconcost(g) ;

counter = 0 ;
lrmc(sc,g) = 0 ;
loop((sc,noexist(sc,g),mc)$( zcount(sc,g) and lrmc(sc,g) = 0 ),

  cndte_lrmc(mc) = ord(mc) + lrmc_offset ;

  dcf(sc,g,mc)$sum(z, capex(sc,g,z)) = 
                                sum(z$( ord(z) <= zcount(sc,g) ),
                                  capex(sc,g,z) / ( ( 1 + WACCg) ** ( ord(z) ) ) +
                                  ( ( 1 - i_taxRate ) * ( 1e-6 * mwh(sc,g) * cndte_lrmc(mc) - totcosts(sc,g,z) ) + depreciation(sc,g,z) ) /
                                  ( ( 1 + WACCg) ** ( ord(z) ) )
                                ) ;

  if(dcf(sc,g,mc) > 0 and counter = 0,
    counter = 1 ;
    lrmc(sc,g) = cndte_lrmc(mc) ;
  ) ;

  counter = 0 ;

) ;

Execute_Unload 'test.gdx', mwh, srmcm, buildYr, totcosts, zcount, undepcapital, depreciation, lrmc, capex ;

*$ontext

zcount = 0 ; counter = 0 ; lrmc(sc,g) = 0 ;
loop((sc_sim(sc),noexist(sc,g),y)$( buildYr(sc,'dis','1932',g) = yearNum(sc,y) ),

  loop(z$( ord(z) <= plantyrs(g) ),

    checkmap(sc,g,y,z) = yes ;

    zcount = zcount + 1 ;

    undepcapital(sc,g,z)$( ord(z) = 1 ) = 1e-6 * nameplate(g) * capandconcost(g) ;
    depreciation(sc,g,z)$( ord(z) > 1 ) = sum(mapg_k(g,k), deprate(k) * undepcapital(sc,g,z-1) ) ;
    undepcapital(sc,g,z)$( ord(z) > 1 ) = undepcapital(sc,g,z-1) - depreciation(sc,g,z) ;

    totcosts(sc,g,z) = 1e-6 * mwh(sc,g,y) * srmcm(g,y+zcount,sc) +
                        1e-9 * gendata(g,'fOM') * nameplate(g) ;
    ) ;

  zcount = 0 ;

* Complete the series for sequential years up to the number of plant life years.
  loop(z$( ord(z) > 1  and ord(z) <= plantyrs(g) ),
    totcosts(sc,g,z)$( not totcosts(sc,g,z) ) = totcosts(sc,g,z-1) ; 
  ) ;

* Add depreciation to totcosts.
  totcosts(sc,g,z) = totcosts(sc,g,z) + depreciation(sc,g,z) ;

  loop(mc$( lrmc(sc,g) = 0 ),
    cndte_lrmc(mc) = ord(mc) + lrmc_offset ;
    dcf(sc,g,mc)$mwh(sc,g,y) = -capandconcost(g) * nameplate(g) * 1e-6 +
                                 sum(z$( ord(z) <= plantyrs(g) ),
                                   ( ( 1 - i_taxRate ) * ( 1e-6 * mwh(sc,g,y) * cndte_lrmc(mc) - totcosts(sc,g,z) ) + depreciation(sc,g,z) ) /
                                   ( ( 1 + WACCg) ** ( ord(z) ) )
                                 ) ;
    if(dcf(sc,g,mc) > 0 and counter = 0,
      counter = 1 ;
      lrmc(sc,g) = cndte_lrmc(mc) ;
    ) ;

    counter = 0 ;

  ) ;

) ;


Execute_Unload 'test.gdx', mwh, srmcm, totcosts, checkmap, buildYr, undepcapital, depreciation, lrmc, dcf ;


file lrmc_sc  LRMCs based on GEM solution  / "LRMC estimates by SC.csv" / ; lrmc_sc.pc = 5 ;

put lrmc_sc 'Plant', 'Technology', 'MW' ; loop(sc_sim(sc), put sc.tl ); loop(sc_sim(sc), put sc.tl ) ;
*loop((k,noexist(sc,g))$( sum(sc, lrmc(sc,g)) * mapg_k(g,k) ),
loop((k,noexist(sc,g))$( sum(sc, buildYr(sc,'dis','1932',g)) * mapg_k(g,k) ),
  put / g.tl, k.tl, nameplate(g) ;
  loop(sc_sim(sc), put lrmc(sc,g) ) ;
  loop(sc_sim(sc), put buildYr(sc,'dis','1932',g) ) ;
) ;



  tmg(rt)                'Run type TMG - determine timing'   / tmg /
  reo(rt)                'Run type REO - re-optimise timing' / reo /
  dis(rt)                'Run type DIS - dispatch'           / dis /

  loop((tmg(rt),tmnghydyr(hY)),
  loop((reo(rt),reopthydyr(hY)),

$ if %SuppressReopt%==1 $goto NoReOpt

    loop(dis(rt),

*   Capture the elements of the run type - SC - hydro year tuple, i.e. the 3 looping sets:
    activeSolve(sc,rt,hY) = yes ;

*   Capture the hydro domain index.
     = yes ;

* Compute depreciation and undepreciated capital by sequential year. 
undepcapital(noexist(sc,g),z)$( ord(z) = 1 ) = 1e-6 * nameplate(g) * capandconcost(g) ;

loop((noexist(sc,g),z)$( ( ord(z) > 1 ) and ( ord(z) <= plantyrs(g) ) ),
  depreciation(g,z) = sum(mapg_k(g,k), deprate(k) * undepcapital(g,z-1) ) ;
  undepcapital(g,z) = undepcapital(g,z-1) - depreciation(g,z) ;
) ;

* Convert costs from modelled years (y) to sequential years (z), from $/MWh to $m, and collect into a parameter called totcosts.
loop((noexist(sc,g),z,y)$( ( ord(z) <= plantyrs(g) ) and ( ord(z) = ord(y) ) ),
  totcosts(g,z,sc) = 1e-6 * mwh(g) * varomm(g,y,sc) +             ! Variable O&M costs, $m
                      1e-9 * gendata(g,'fOM') * nameplate(g) +      ! Fixed O&M costs, $m
                      1e-6 * mwh(g) * fuelcostm(g,y,sc) +          ! Fuel costs, $m
                      1e-6 * mwh(g) * co2taxm(g,y,sc)   ;          ! CO2 taxes, $m
) ;

$offtext
