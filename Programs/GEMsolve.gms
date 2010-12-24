* GEMsolve.gms


* Last modified by Dr Phil Bishop, 17/10/2010 (imm@ea.govt.nz)


$ontext
 This program continues sequentially from GEMdata. The GEMdeclarations work file must be
 called at invocation. This program is followed by GEMreports.

 Code sections:
  1. Take care of preliminaries.
  2. Read in required data from GDX files.
  3. Re-declare and/or initialise sets and parameters.
  4. Set bounds, initial levels and fixes.
  5. Enter the rt-hY loop, solve the model, and collect results.
  6. Prepare results to pass along to report codes in the form of a GDX file. 
  7. Dump results out to GDX files and rename/relocate certain output files.


  x. Move MIPtrace files to output directory and generate miptrace.bat.
  x. Create an awk script, which when executed, will produce a file containing the number of integer solutions per MIP model.
$offtext

$include GEMpaths.inc
$include GEMsettings.inc
$offupper onempty inlinecom { } eolcom !
option seed = 101 ;
File bat "A recyclable batch file" / "%ProgPath%temp.bat" / ;   bat.lw = 0 ; bat.ap = 0 ;
File rep "Write to a report"       / "%ProgPath%Report.txt" / ; rep.lw = 0 ; rep.ap = 1 ;
File con "Write to the console"    / con / ;                    con.lw = 0 ;

putclose rep 'Run: "%runName%"' / 'Scenario: "%scenarioName%"' / '  - started at ', system.time, ' on ' system.date ;

* Turn the following maps on/off as desired.
$offuelxref offuellist	
*$onuelxref  onuellist	

$offsymxref offsymlist
*$onsymxref  onsymlist

* Track memory usage.
* Higher numbers are for more detailed information inside loops. Alternatively, on the command line, type: gams xxx profile=1
*option profile = 1 ;
*option profile = 2 ;
*option profile = 3 ;



*===============================================================================================
* 1. Take care of preliminaries.

* Specify various .lst file and solver-related options.
option limcol = 0, limrow = 0, reslim = 500, iterlim = 10000000 ;
option sysout = off, solprint = on ;

* Select the solver and include the relevant solver options files:
option LP = %Solver%, MIP = %Solver%, RMIP = %Solver% ;
$include 'GEM%Solver%.gms'

* Use the 'xxx.OptFile = 1 ;' command to call the options file. Use the 'xxx.OptFile = 0 ;' or simply
* comment out the 'xxx.OptFile = 1 ;' command if you don't want to call a solver options file.
GEM.OptFile = 1 ;
DISP.OptFile = 0 ;

*option MIP=GAMSCHK ;



*===============================================================================================
* 2. Read in required data from GDX files.

* NB: The following symbols from input data file may have been changed in GEMdata. So procure from
*     GEMdataGDX rather than from GDXinputFile, or make commensurate change.
*     Sets: y, exist, commit, new, neverBuild
*     Parameters: i_txCapacity, i_txCapacityPO

* Get set y from %GEMdataGDX% rather than %GDXinputFile% (years to solve for may be less than years data was prepared for).
$gdxin '%ProgPath%%GEMdataGDX%'
$loaddc y

$gdxin "%DataPath%%GDXinputFile%"
* Load sets from input GDX file.
$loaddc k f g s o r e ild p ps tupg tgc t lb rc hY v outcomes=hd m
$loaddc maps_r mapm_t maphd_hY movers wind renew minUtilTechs demandGen gas diesel
* Load parameters from input GDX file.
$load i_minUtilByTech i_maxNrgByFuel i_fuelQuantities
$load i_UnitLargestProp i_offlineReserve i_nameplate i_baseload i_minUtilisation i_refurbDecisionYear
$load i_fof i_heatrate i_PumpedHydroMonth i_PumpedHydroEffic i_fixedOM i_HVDCshr i_HVDClevy i_plantReservesCost
$load i_distdGenRenew i_distdGenFossil i_VOLLcap i_VOLLcost i_renewNrgShare i_renewCapShare
$load i_firstHydroYear i_hydroWeight i_hydroOutputAdj i_bigSIgen i_fkNI i_fkSI i_HVDClosses i_HVDClossesPO
$load i_txGrpConstraintsRHS i_txGrpConstraintsLHS i_maxReservesTrnsfr i_reserveReqMW i_txCapacity i_txCapacityPO

* Make sure intraregional transmission capacities are zero.
i_txCapacity(r,r,ps) = 0 ; i_txCapacityPO(r,r,ps) = 0 ;

$gdxin '%ProgPath%%GEMdataGDX%'
* Load sets created in GEMdata.
$loaddc n firstYr allButFirstYr firstPeriod mapg_k mapg_f mapg_o mapg_r mapg_e mapg_ild mapild_r mapv_g thermalFuel
$loaddc exist commit new noExist nigen sigen schedHydroPlant pumpedHydroPlant moverExceptions validYrBuild integerPlantBuild linearPlantBuild possibleToBuild
$loaddc possibleToRefurbish possibleToEndogRetire endogenousRetireDecisnYrs endogenousRetireYrs validYrOperate
$loaddc slackBus regLower interIsland nwd swd paths transitions validTransitions allowedStates notAllowedStates upgradedStates
$loaddc txEarlyComYrSet txFixedComYrSet vtgc nSegment
* Load parameters created in GEMdata.
$loaddc yearNum averageHydroYear hydroYearNum lastHydroYear hoursPerBlock PVfacG PVfacT SRMC initialCapacity capCharge refurbCapCharge txCapCharge exogMWretired continueAftaEndogRetire
$loaddc peakConPlant NWpeakConPlant reservesCapability maxCapFactPlant minCapFactPlant ldcMW peakLoadNZ peakLoadNI bigNIgen nxtbigNIgen
$loaddc locFac_Recip susceptanceYr BBincidence bigLoss slope intercept reserveViolationPenalty windCoverPropn bigM
$loaddc singleReservesReqF hydroOutput
*+++++++++++++++++++++++++
* More code to do the non-free reserves stuff. 
$loaddc freeReserves pNFresvCap pNFresvCost
*+++++++++++++++++++++++++



*===============================================================================================
* 3. Re-declare and/or initialise sets and parameters.

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
* Initialise selected subsets (NB: values come from GEMsettings).
  solveGoal(goal)         'User-selected solve goal'                                                                               / %solveGoal% /
  hydroYrForTiming(hY)    'Hydro year used to determine investment timing. Choices are Multiple, Average, 1932, 1933, ... 2007'    / %hydroYrForTiming% /
  hydroYrForReopt(hY)     'Hydro year used to re-optimise investment timing. Choices are Multiple, Average, 1932, 1933, ... 2007'  / %hydroYrForReopt% /
  ;

timeAllowed('QDsol')  = %QDsolSecs% ;
timeAllowed('VGsol')  = %VGsolSecs% ;
timeAllowed('MinGap') = %MinGapSecs% ;



*===============================================================================================
* 4. Set bounds, initial levels and fixes.

* Variables that are to be fixed, first need to be unfixed - this is probably redundant now that we're not going around the old MDS loop.
BUILD.lo(g,y) = 0 ;                                  BUILD.up(g,y) = i_nameplate(g) ;
REFURBCOST.lo(g,y) = 0 ;                             REFURBCOST.up(g,y) = +inf ;
ISRETIRED.lo(g) = 0 ;                                ISRETIRED.up(g) = 1 ;
BRET.lo(g,y) = 0 ;                                   BRET.up(g,y) = 1 ;
RETIRE.lo(g,y) = 0 ;                                 RETIRE.up(g,y) = +inf ;
GEN.lo(g,y,t,lb,outcomes) = 0 ;                      GEN.up(g,y,t,lb,outcomes) = +inf ;
VOLLGEN.lo(s,y,t,lb,outcomes) = 0 ;                  VOLLGEN.up(s,y,t,lb,outcomes) = +inf ;
TX.lo(paths,y,t,lb,outcomes) = -inf ;                TX.up(paths,y,t,lb,outcomes) = +inf ;
CGEN.lo(g,y) = 0 ;                                   CGEN.up(g,y) = 1 ;
BGEN.lo(g,y) = 0 ;                                   BGEN.up(g,y) = 1 ;
TXUPGRADE.lo(validTransitions(paths,ps,pss),y) = 0 ; TXUPGRADE.up(validTransitions(paths,ps,pss),y) = 1 ;
TXPROJVAR.lo(tupg,y) = 0 ;                           TXPROJVAR.up(tupg,y) = 1 ;
BTX.lo(paths,ps,y) = 0 ;                             BTX.up(paths,ps,y) = 1 ;
THETA.lo(r,y,t,lb,outcomes) = -inf ;                 THETA.up(r,y,t,lb,outcomes) = +inf ;
RESV.lo(g,rc,y,t,lb,outcomes) = 0 ;                  RESV.up(g,rc,y,t,lb,outcomes) = +inf ;
RESVVIOL.lo(rc,ild,y,t,lb,outcomes) = 0 ;            RESVVIOL.up(rc,ild,y,t,lb,outcomes) = +inf ;
RESVTRFR.lo(rc,ild1,ild,y,t,lb,outcomes) = 0 ;       RESVTRFR.up(rc,ild1,ild,y,t,lb,outcomes) = +inf ;
RESVREQINT.lo(rc,ild,y,t,lb,outcomes) = 0 ;          RESVREQINT.up(rc,ild,y,t,lb,outcomes) = +inf ;
NORESVTRFR.lo(ild,ild,y,t,lb,outcomes) = 0 ;         NORESVTRFR.up(ild,ild,y,t,lb,outcomes) = 1 ;

* Restrict the build variable (i.e. MW) to be zero depending on input assumptions:
* a) Don't allow capacity to be built in years outside the valid range of build years.
BUILD.fx(g,y)$( not validYrBuild(g,y) ) = 0 ;

* b) For committed plant, fix the build year regardless of any other settings.
BUILD.fx(g,y)$( commit(g) * validYrBuild(g,y) ) = i_nameplate(g) ;

* c) Fix CGEN to zero for all years less than cGenYr and fix BGEN to zero for all years greater than or equal to cGenYr.
CGEN.fx(g,y)$( yearNum(y) <  cGenYr ) = 0 ;
BGEN.fx(g,y)$( yearNum(y) >= cGenYr ) = 0 ;

* Restrict refurbishment cost to be zero in years prior to refurbishment.
REFURBCOST.fx(g,y)$( yearNum(y) < i_refurbDecisionYear(g) ) = 0 ;

* Fix retired MW by year and generating plant to zero if not able to be endogenously retired.
RETIRE.fx(g,y)$( not endogenousRetireYrs(g,y) ) = 0 ;

* Fix the endogenous retirement binaries at zero for all cases where it's not required.
BRET.l(g,y) = 0 ; ISRETIRED.l(g) = 0 ;
BRET.fx(g,y)$( not endogenousRetireDecisnYrs(g,y) ) = 0 ;
ISRETIRED.fx(g)$( not possibleToEndogRetire(g) ) = 0 ;

* Restrict generation:
* a) Don't allow generation from units prior to committed date or earliest allowable operation or if plant is retired.
*    NB: 'validYrOperate embodies the appropriate date for existing, committed, and new units - i.e., all units.
GEN.fx(g,y,t,lb,outcomes)$( not validYrOperate(g,y,t) ) = 0 ;

* b) Force generation from the 'must run' (i.e base load) plant.
*    Convert MW capacity to GWh in the load block, as in the lim_maxgen constraint. 
GEN.fx(g,y,t,lb,outcomes)$( ( exist(g) or commit(g) ) * i_baseload(g) * validYrOperate(g,y,t) ) =  1e-3 * hoursPerBlock(t,lb) * i_nameplate(g) * maxCapFactPlant(g,t,lb) ;

* Place restrictions on VOLL plants:
* a) Respect the capacity of VOLL plants 
VOLLGEN.up(s,y,t,lb,outcomes) = 1e-3 * hoursPerBlock(t,lb) * i_VOLLcap(s) ;

* b) Don't allow VOLL in user-specified top load blocks 
VOLLGEN.fx(s,y,t,lb,outcomes)$( ord(lb) <= noVOLLblks ) = 0 ;

* Fix lower bound on TX to zero if transportation formulation is being used. Reset level to zero each time too.
TX.l(paths,y,t,lb,outcomes) = 0 ;
TX.lo(paths,y,t,lb,outcomes)$(DCloadFlow = 0) = 0 ;
 
* Impose upper bound of 1 on continuous 0-1 transmission-related variables.
TXUPGRADE.up(validTransitions(paths,ps,pss),y) = 1 ;
TXPROJVAR.up(tupg,y) = 1 ;

* Force transmission upgrades in user-specified year (in either endog or exog tx investment mode).
loop((transitions(tupg,r,rr,ps,pss),y)$txFixedComYrSet(tupg,r,rr,ps,pss,y),
  TXUPGRADE.fx(r,rr,ps,pss,y) = 1 ;
) ;

* Fix years prior to earliest year at zero for either exogenous or endogenous transmission investment.
loop((transitions(tupg,r,rr,ps,pss),y)$txEarlyComYrSet(tupg,r,rr,ps,pss,y),
  TXUPGRADE.fx(r,rr,ps,pss,y) = 0 ;
) ;

* Fix transmission binaries to zero if they're not needed.
BTX.fx(notAllowedStates,y) = 0 ;

* Fix the reference bus angle to zero.
THETA.fx(slackBus(r),y,t,lb,outcomes) = 0 ;

* Fix reserve variables to zero if they are not needed.
RESV.fx(g,rc,y,t,lb,outcomes)$(            ( not useReserves ) or ( not reservesCapability(g,rc) ) ) = 0 ;
RESVVIOL.fx(rc,ild,y,t,lb,outcomes)$(        not useReserves ) = 0 ;
RESVTRFR.fx(rc,ild,ild1,y,t,lb,outcomes)$( ( not useReserves ) or singleReservesReqF(rc) ) = 0 ;
RESVREQINT.fx(rc,ild,y,t,lb,outcomes)$(      not useReserves ) = 0 ;
NORESVTRFR.fx(ild,ild1,y,t,lb,outcomes)$(    not useReserves ) = 0 ;

* Fix to zero the intra-island reserve variables.
RESVTRFR.fx(rc,ild,ild,y,t,lb,outcomes) = 0 ;
NORESVTRFR.fx(ild,ild,y,t,lb,outcomes)  = 0 ;

* Set the lower bound on the reserve requirement if there is an external requirement specified.
RESVREQINT.lo(rc,ild,y,t,lb,outcomes)$( i_reserveReqMW(y,ild,rc) > 0 ) = i_reserveReqMW(y,ild,rc) * hoursPerBlock(t,lb) ;

* Reserve contribution cannot exceed the specified capability during peak or other periods.
RESV.up(g,rc,y,t,lb,outcomes)$( useReserves and reservesCapability(g,rc) ) = reservesCapability(g,rc) * hoursPerBlock(t,lb) ;

* Don't allow reserves from units prior to committed date or earliest allowable operation or if plant is retired.
* NB: 'validYrOperate' embodies the appropriate date for existing, committed, and new units - i.e., all units.
RESV.fx(g,rc,y,t,lb,outcomes)$( not validYrOperate(g,y,t) ) = 0 ;

* Reset all slacks and penalties/violations to zero.
ANNMWSLACK.l(y) = 0 ;         SEC_NZSLACK.l(y) = 0 ;      SEC_NI1SLACK.l(y) = 0 ;  SEC_NI2SLACK.l(y) = 0 ;
NOWIND_NZSLACK.l(y) = 0 ;     NOWIND_NISLACK.l(y) = 0 ;   RENCAPSLACK.l(y) = 0 ;
HYDROSLACK.l(y) = 0 ;         MINUTILSLACK.l(y) = 0 ;     FUELSLACK.l(y) = 0 ;
RENNRGPENALTY.l(y) = 0 ;
RESVVIOL.l(rc,ild,y,t,lb,outcomes) = 0 ;

$set AddUp10Slacks "sum(y, ANNMWSLACK.l(y) + SEC_NZSLACK.l(y) + SEC_NI1SLACK.l(y) + SEC_NI2SLACK.l(y) + NOWIND_NZSLACK.l(y) + NOWIND_NISLACK.l(y) + RENCAPSLACK.l(y) + HYDROSLACK.l(y) + MINUTILSLACK.l(y) + FUELSLACK.l(y) )"



*===============================================================================================
* 5. Enter the rt-hY loop, solve the model, and collect results.

$if %RunType%==2 $goto NoGEM

** Solve the MIP to determine investment timing.
* Open loop on run type TMG.
loop((tmg(rt),hydroYrForTiming(hY)),

* Capture the current elements of the run type-hydro year tuple.
  activeSolve(rt,hY) = yes ;

* Select appropriate hydro year(s) in order to do the timing solve.
  h(outcomes) = no ;
  hydOutput(g,y,t,h) = 0 ;
  if(sameas(hydroYrForTiming,'Multiple'),
    h(outcomes)$( not sameas(outcomes,'dum') ) = yes ;
    hydOutput(g,y,t,h) = hydroOutputScalar * sum((mapv_g(v,g),hY1,mapm_t(m,t))$maphd_hY(h,hY1), hydroOutput(v,hY1,m)) ;
    else
    h(outcomes)$( sameas(outcomes,'dum') ) = yes ;
    hydOutput(g,y,t,h) = hydroOutputScalar * i_hydroOutputAdj(y) * sum((mapv_g(v,g),mapm_t(m,t)), hydroOutput(v,hY,m)) ;
  ) ;

* Capture the hydro domain index and the hydro year number.
  activeHD(rt,hY,h) = yes ;
  indexhY(rt,hY,y) = hydroYearNum(hY) ;

* Make sure renewable energy share constraint is not suppressed unless i_renewNrgShare(y) = 0 for all y.
  renNrgShrOn$( sum(y, i_renewNrgShare(y)) = 0 ) = 0 ;

* Apply the selected solve goal for the investment timing solve.
  loop(solveGoal(goal),
    gem.reslim = timeAllowed(solveGoal) ;
    gem.optcr = 0.00001 ;
    gem.optca = 0 ;
    if(sameas(solveGoal,'QDsol'),  gem.optfile = 2 ; gem.optcr = %QDoptCr% ) ;
    if(sameas(solveGoal,'VGsol'),  gem.optfile = 3 ) ;
    if(sameas(solveGoal,'MinGap'), gem.optfile = 4 ) ;

    if(%LimitOutput% = 1, option limcol = 0, limrow = 0, sysout = off, solprint = off ;) ; 
    Solve GEM using %GEMtype% minimizing TOTALCOST ;

*   Figure out if run is to be aborted and report that fact before aborting.
    slacks = %AddUp10Slacks% ;
    counter = 0 ;
    counter$( ( GEM.modelstat = 10 ) or ( GEM.modelstat <> 1 and GEM.modelstat <> 8 ) ) = 1 ;

*   Post a progress message to report for use by GUI and to the console.
    if(counter = 1,
      putclose rep // 'The ' rt.tl '-' hY.tl ' solve finished with some sort of problem and the job is now going to abort.' /
                      'Examine GEMsolve.lst and/or GEMsolve.log to see what went wrong.' ;
      else
      putclose rep // 'The ' rt.tl '-' hY.tl ' solve finished at ', system.time / 'Objective function value: ' TOTALCOST.l:<12:1 / ;
    ) ;
    putclose con // '    The ' rt.tl '-' hY.tl ' solve for "%runName% -- %scenarioName% has just finished' /
                    '    Objective function value: ' TOTALCOST.l:<12:1 // ;

    abort$( GEM.modelstat = 10 ) "GEM is infeasible - check out GEMsolve.log to see what you've done wrong in configuring a model that is infeasible" ;
    abort$( GEM.modelstat <> 1 and GEM.modelstat <> 8 ) "Problem encountered solving GEM..." ;

*   Generate a MIP trace file when MIPtrace is equal to 1 (see rungem batch file).
$   if not %PlotMIPtrace%==1 $goto NoTrace3
    putclose bat 'copy MIPtrace.txt "%runName%-%scenarioName%-MIPtrace-' rt.tl '-' hY.tl '-' goal.tl '.txt"' ;
    execute 'temp.bat';
$   label NoTrace3

*   Collect information for solve summary report
    solveReport(rt,hY,goal,'ObjFnValue') = TOTALCOST.l ;
    solveReport(rt,hY,goal,'OptFile') = gem.optfile ;
    solveReport(rt,hY,goal,'OptFile') = gem.optfile ;
    solveReport(rt,hY,goal,'OptCr') = gem.optcr ;
    solveReport(rt,hY,goal,'ModStat') = gem.modelstat ;
    solveReport(rt,hY,goal,'SolStat') = gem.solvestat ;
    solveReport(rt,hY,goal,'Vars') = gem.numvar ;
    solveReport(rt,hY,goal,'DVars') = gem.numdvar ;
    solveReport(rt,hY,goal,'Eqns') = gem.numequ ;
    solveReport(rt,hY,goal,'Iter') = gem.iterusd ;
    solveReport(rt,hY,goal,'Time') = gem.resusd ;
    solveReport(rt,hY,goal,'Gap%')$gem.objval = 100 * abs( gem.objest - gem.objval ) / gem.objval ;
    solveReport(rt,hY,goal,'GapAbs') = abs( gem.objest - gem.objval ) ;
    if(slacks > 0, solveReport(rt,hY,goal,'Slacks') = 1 else solveReport(rt,hY,goal,'Slacks') = -99 ) ;

* End of selected solve goal loop for investment timing solve.
  ) ;

* Collect up solution values - by run type (rt) and hydro year (hY).
$include CollectResults.txt

* Close the loop on run type (rt = TMG) and hydro year (hY = hydroYrForTiming).
) ;


$if %SuppressReopt%==1 $goto NoReOpt


** Solve the MIP again to re-optimise investment timing.
* Open loop on run type REO.
loop((reo(rt),hydroYrForReopt(hY)),

* Capture the current elements of the run type-hydro year tuple.
  activeSolve(rt,hY) = yes ;

* Select appropriate hydro year(s) in order to do the re-optimise solve.
  h(outcomes) = no ;
  h(outcomes)$( sameas(outcomes,'dum') ) = yes ;
  hydOutput(g,y,t,h) = 0 ;
  hydOutput(g,y,t,h) = hydroOutputScalar * sum((mapv_g(v,g),mapm_t(m,t)), hydroOutput(v,hY,m)) ;

* Capture the hydro domain index and the hydro year number.
  activeHD(rt,hY,h) = yes ;
  indexhY(rt,hY,y) = hydroYearNum(hY) ;

* Make sure renewable energy share constraint is not suppressed unless SprsRenShrReo = 1 or i_renewNrgShare(y) = 0 for all y.
  renNrgShrOn$( ( %SprsRenShrReo% = 1 ) or ( sum(y, i_renewNrgShare(y)) = 0 ) ) = 0 ;

* Fix the build (generation and transmission) to be the same as for the timing solve, but free up the movers.
  BUILD.fx(g,y) = BUILD.l(g,y) ;

  TXPROJVAR.fx(tupg,y) = TXPROJVAR.l(tupg,y) ;
  TXUPGRADE.fx(validTransitions(paths,ps,pss),y) = TXUPGRADE.l(paths,ps,pss,y) ;
  BTX.fx(paths,ps,y) = BTX.l(paths,ps,y) ;

  loop((g,movers(k))$( (noExist(g) * mapg_k(g,k)) * (not moverExceptions(g)) ),
    BUILD.lo(g,y)$validYrBuild(g,y) = 0 ;
    BUILD.up(g,y)$validYrBuild(g,y) = i_nameplate(g) ;
  ) ;

* Fix the retirements from the timing run.
  BRET.fx(g,y) = BRET.l(g,y) ;
  ISRETIRED.fx(g) = ISRETIRED.l(g) ;
  RETIRE.fx(g,y) = RETIRE.l(g,y) ;

* Apply the selected solve goal for the re-optimised timing solve.
  loop(solveGoal(goal),
    gem.reslim = timeAllowed(solveGoal) ;
    gem.optcr = 0.00001 ;
    gem.optca = 0 ;
    if(sameas(solveGoal,'QDsol'),  gem.optfile = 2 ; gem.optcr = %QDoptCr% ) ;
    if(sameas(solveGoal,'VGsol'),  gem.optfile = 3 ) ;
    if(sameas(solveGoal,'MinGap'), gem.optfile = 4 ) ;

    if(%LimitOutput% = 1, option limcol = 0, limrow = 0, sysout = off, solprint = off ;) ; 
    Solve GEM using %GEMtype% minimizing TOTALCOST ;

*   Figure out if run is to be aborted and report that fact before aborting.
    slacks = %AddUp10Slacks% ;
    counter = 0 ;
    counter$( GEM.modelstat <> 1 and GEM.modelstat <> 8 ) = 1 ;

*   Post a progress message to report for use by GUI and to the console.
    if(counter = 1,
      putclose rep // 'The ' rt.tl '-' hY.tl ' solve finished with some sort of problem and the job is now going to abort.' /
                      'Examine GEMsolve.lst and/or GEMsolve.log to see what went wrong.' ;
      else
      putclose rep // 'The ' rt.tl '-' hY.tl ' solve finished at ', system.time / 'Objective function value: ' TOTALCOST.l:<12:1 / ;
    ) ;
    putclose con // '    The ' rt.tl '-' hY.tl ' solve for "%runName% -- %scenarioName% has just finished' /
                    '    Objective function value: ' TOTALCOST.l:<12:1 // ;

    abort$( GEM.modelstat <> 1 and GEM.modelstat <> 8 ) "Problem encountered solving GEM when doing re-optimisation..." ;

*   Generate a MIP trace file when MIPtrace is equal to 1 (see rungem batch file).
$   if not %PlotMIPtrace%==1 $goto NoTrace4
    putclose bat 'copy MIPtrace.txt "%runName%-%scenarioName%-MIPtrace-' rt.tl '-' hY.tl '.txt"' ;
    execute 'temp.bat';
$   label NoTrace4

*   Collect information for solve summary report
    solveReport(rt,hY,goal,'ObjFnValue') = TOTALCOST.l ;
    solveReport(rt,hY,goal,'OptFile') = gem.optfile ;
    solveReport(rt,hY,goal,'OptCr') = gem.optcr ;
    solveReport(rt,hY,goal,'ModStat') = gem.modelstat ;
    solveReport(rt,hY,goal,'SolStat') = gem.solvestat ;
    solveReport(rt,hY,goal,'Vars') = gem.numvar ;
    solveReport(rt,hY,goal,'DVars') = gem.numdvar ;
    solveReport(rt,hY,goal,'Eqns') = gem.numequ ;
    solveReport(rt,hY,goal,'Iter') = gem.iterusd ;
    solveReport(rt,hY,goal,'Time') = gem.resusd ;
    solveReport(rt,hY,goal,'Gap%')$gem.objval = 100 * abs( gem.objest - gem.objval ) / gem.objval ;
    solveReport(rt,hY,goal,'GapAbs') = abs( gem.objest - gem.objval ) ;
    if(slacks > 0, solveReport(rt,hY,goal,'Slacks') = 1 else solveReport(rt,hY,goal,'Slacks') = -99 ) ;

* End of selected solve goal loop for re-optimised timing solve.
  ) ;

* Collect up solution values - by run type (rt) and hydro year (hY).
$ include CollectResults.txt

* Close the loop on run type (rt = REO) and hydro year (hY = hydroYrForReopt).
) ;


$label NoReOpt
$if %RunType%==1 $goto NoDISP


* Now prepare for the dispatch solves, i.e. loop over the hydrology years (hY) and solve DISPatch with pre-determined build decisions.
* First, fix the investment timing decisions (of generation, refurbishment, and transmission) and the retirements from the timing solve(s).
BUILD.fx(g,y) = BUILD.l(g,y) ;

BRET.fx(g,y) = BRET.l(g,y) ;
ISRETIRED.fx(g) = ISRETIRED.l(g) ;
RETIRE.fx(g,y) = RETIRE.l(g,y) ;

TXPROJVAR.fx(tupg,y) = TXPROJVAR.l(tupg,y) ;
TXUPGRADE.fx(validTransitions(paths,ps,pss),y) = TXUPGRADE.l(paths,ps,pss,y) ;
BTX.fx(paths,ps,y) = BTX.l(paths,ps,y) ;

* But, if RunType = 2, fix investment timing according to the externally specified build schedule.
$label NoGEM
$if not %RunType%==2 $goto CarryOn1
$ontext
BUILD.fx(g,y) = 0 ;
BUILD.fx(g,y)$( commit(g) * validYrBuild(g,y) ) = i_nameplate(g) ;
BUILD.fx(g,y)$( new(g)    * validYrBuild(g,y) ) = InstallMW(g,y) ;

RETIRE.fx(g,y) = 0 ;
RETIRE.fx(g,y)$exogretirem(g,y)  = ExogRetireSched(g,y) ;
RETIRE.fx(g,y)$endogenousRetireYrs(g,y) = EndogRetireSched(g,y) ;

BRET.fx(g,y) = 0 ;
BRET.fx(g,y)$bretfix(g,y) = bretfix(g,y) ;

ISRETIRED.fx(g) = sum(y, BRET.l(g,y)) ;

TXPROJVAR.fx(tupg,y) = 0 ;
TXUPGRADE.fx(paths,ps,pss,y) = 0 ;
BTX.fx(paths,ps,y) = 0 ;
TXPROJVAR.fx(tupg,y) = txproject(tupg,y) ;
TXUPGRADE.fx(paths,ps,pss,y) = txupgrades(paths,ps,pss,y) ;
BTX.fx(paths,ps,y) = btxfix(paths,ps,y) ;
$offtext
$label CarryOn1

* Make sure the only active element of set h is 'dum' and zero out any previously used hydrology output data.
h(outcomes) = no ;
h(outcomes)$( sameas(outcomes,'dum') ) = yes ;
hydOutput(g,y,t,h) = 0 ;

* Construct hydrology output sequences starting with all hydro years (including the average year but excluding the 'multiple' year) if DInflowYr = 0:
hydroYrForDispatch(hY)$( %DInflowYr%  = 0 and (not sameas(hY,'Multiple')) ) = yes ;
* If DInflowYr is not zero and is outside the valid range of hydro years, then solve using the average hydro year only.
hydroYrForDispatch(hY)$( (%DInflowYr% <> 0) * ( %DInflowYr% < i_firstHydroYear or %DInflowYr% > lastHydroYear ) ) = yes$( sameas(hY,'Average') ) ;
* If DInflowYr is inside valid hydro year range, then the only element of the hydroYrForDispatch set is the hydro output indicated by DInflowYr:
hydroYrForDispatch(hY)$( (%DInflowYr% >= i_firstHydroYear) * (%DInflowYr% <= lastHydroYear) ) = yes$( hydroYearNum(hY) = %DInflowYr% ) ;

* Open the loop over hydro years:
loop(hY$( hydroYrForDispatch(hY) and (ord(hY) <= %LimHydYr%) ),

* Define indices to handle sequential inflow simulation (this excludes the 'multiple' and average year).
  hydroYrIndex(hY1)$( ord(hY1) > averageHydroYear ) =
    ( ord(hY1) - ord(hY) + 1            )$( ord(hY1) >= ord(hY) ) +  { index for inflow years >= the simulated inflow year }
    ( ord(hY1) - ord(hY) + card(hY) - 1 )$( ord(hY1) <  ord(hY) ) ;  {'wraparound' index for inflow years < the simulated inflow year}

* Define inflow data for all modelled years depending on whether the model run uses sequential or constant hydro data.
* DInflwYrType = 1 ==> sequential; DInflwYrType = 2 ==> constant.
  hydOutput(g,y,t,h)$( %DInflwYrType% = 1 ) = i_hydroOutputAdj(y) * sum((mapv_g(v,g),hY1,mapm_t(m,t))$( hydroYrIndex(hY1) = ord(y) ), hydroOutput(v,hY1,m) ) ;
  hydOutput(g,y,t,h)$( %DInflwYrType% = 2 or ord(hY) = averageHydroYear ) = i_hydroOutputAdj(y) * sum((mapv_g(v,g),mapm_t(m,t)), hydroOutput(v,hY,m)) ;
* This last statement means that if DInflwYrType = 2, the inflows commensurate with the inflow year (hY) being
* looped over will be used for all modelled years. Note that this includes the average inflow year too.

** Solve the RMIP to simulate dispatch given an investment schedule.
*  Open loop on run type DIS.
  loop(dis(rt),

* Capture the current elements of the run type-hydro year tuple and the hydro domain index.
  activeSolve(rt,hY) = yes ;
  activeHD(rt,hY,h) = yes ;

* Make sure renewable energy share constraint is not suppressed unless SprsRenShrDis = 1 or i_renewNrgShare(y) = 0 for all y.
  renNrgShrOn$( ( %SprsRenShrDis% = 1 ) or ( sum(y, i_renewNrgShare(y)) = 0 ) ) = 0 ;

* Capture the hydro year to be assigned to each modelled year:
* First assign the average year to everything.
  indexhY(rt,hY,y) = averageHydroYear ;
* Then if %DInflwYrType% = 2, i.e. constant hydro year for each modelled year, set indexhY equal to hydroYearNum.
  indexhY(rt,hY,y) = hydroYearNum(hY) ;
* Finally, if %DInflwYrType% = 1, i.e. the wraparound thing, set indexhY accordingly.
  if(%DInflwYrType% = 1,
    loop((y,hY1),
      if(sameas(hY,'Average'),
        indexhY(rt,hY,y)$( ord(y) = hydroYrIndex(hY1) ) = averageHydroYear ;
        else
        indexhY(rt,hY,y)$( ord(y) = hydroYrIndex(hY1) ) = hydroYearNum(hY1) ;
      ) ;
    ) ;
  ) ;

* Solve the RMIP (i.e. DISP):
  if(%LimitOutput% = 1, option limcol = 0, limrow = 0, sysout = off, solprint = off ;) ; 
  Solve DISP using %DISPtype% minimizing TOTALCOST ;

* Figure out if run is to be aborted and report that fact before aborting.
  slacks = %AddUp10Slacks% ;
  counter = 0 ;
  counter$( DISP.modelstat <> 1 and DISP.modelstat <> 8 ) = 1 ;

* Post a progress message to report for use by GUI and to the console.
  if(counter = 1,
    putclose rep // 'The ' rt.tl '-' hY.tl ' solve finished with some sort of problem and the job is now going to abort.' /
                    'Examine GEMsolve.lst and/or GEMsolve.log to see what went wrong.' ;
    else
    putclose rep // 'The ' rt.tl '-' hY.tl ' solve finished at ', system.time / 'Objective function value: ' TOTALCOST.l:<12:1 / ;
  ) ;
  putclose con // '    The ' rt.tl '-' hY.tl ' solve for "%runName% -- %scenarioName% has just finished' /
                  '    Objective function value: ' TOTALCOST.l:<12:1 // ;

  abort$( DISP.modelstat <> 1 and DISP.modelstat <> 8 ) "Problem encountered when solving DISP..." ;

* Collect information for solve summary report
  solveReport(rt,hY,'','ObjFnValue') = TOTALCOST.l ;
  solveReport(rt,hY,'','ModStat') = disp.modelstat ;
  solveReport(rt,hY,'','SolStat') = disp.solvestat ;
  solveReport(rt,hY,'','Vars') = disp.numvar ;
  solveReport(rt,hY,'','Eqns') = disp.numequ ;
  solveReport(rt,hY,'','Iter') = disp.iterusd ;
  solveReport(rt,hY,'','Time') = disp.resusd ;
  if(slacks > 0, solveReport(rt,hY,'','Slacks') = 1 else solveReport(rt,hY,'','Slacks') = -99 ) ;

* Now, collect up solution values - by Run type (rt) and hydro year (hY):
$ include CollectResults.txt

* Close loop on run type DIS:
  ) ;

* End of loop over hydro years (hY) for the RMIP/DISP model:
) ;

$label NoDISP

putclose rep // 'All models in the scenario called "%scenarioName%" have now been solved. (', system.time, ').' //// ;



*===============================================================================================
* 6. Prepare results to pass along to report codes in the form of a GDX file. 

** Beware - what is now s2 was previously s3.
** What is happenning here is that the for each run type, the s_ params are being averaged over all hY and collected
** into the s2 params. Hence, we lose the hY domain on s2, otherwise all else (including explanatory text) is identical
** to the s_ param. Be aware that averaging over hY makes no sense for TMG and REO if they ever get done for more than one
** hY (which to date they have not been). But this may change when we code up Geoff's stochastic stuff. 

* Re-declared and initialised sets.
Set dum(outcomes)  'The dummy element of outcomes set'   / dum / ;

Parameters
* Misc params
  s2_hydOutput(rt,g,y,t,outcomes)   'Right hand side of limit_hydro constraint, i.e. energy available for dispatch'
  ;

activeRT(rt)$sum(activeSolve(rt,hY), 1) = yes ;

disHydYrs(hY)$sum(activeSolve(rt,hY)$dis(rt), 1) = yes ;
disHydYrs(hY)$sameas(hY,'Multiple') = no ;
disHydYrs(hY)$sameas(hY,'Average') = no ;

numDisYrs = sum(disHydYrs(hY), 1 ) ;

loop(activeRT(rt),
  if(not sameas(rt,'dis'),
    s2_TOTALCOST(rt)                                = sum(activeSolve(rt,hY), s_TOTALCOST(rt,hY) ) ;
    s2_TX(rt,paths,y,t,lb,outcomes)                 = sum(activeSolve(rt,hY), s_TX(rt,hY,paths,y,t,lb,outcomes) ) ;
    s2_BRET(rt,g,y)                                 = sum(activeSolve(rt,hY), s_BRET(rt,hY,g,y) ) ;
    s2_ISRETIRED(rt,g)                              = sum(activeSolve(rt,hY), s_ISRETIRED(rt,hY,g) ) ;
    s2_BTX(rt,paths,ps,y)                           = sum(activeSolve(rt,hY), s_BTX(rt,hY,paths,ps,y) ) ;
    s2_REFURBCOST(rt,g,y)                           = sum(activeSolve(rt,hY), s_REFURBCOST(rt,hY,g,y) ) ;
    s2_BUILD(rt,g,y)                                = sum(activeSolve(rt,hY), s_BUILD(rt,hY,g,y) ) ;
    s2_RETIRE(rt,g,y)                               = sum(activeSolve(rt,hY), s_RETIRE(rt,hY,g,y) ) ;
    s2_CAPACITY(rt,g,y)                             = sum(activeSolve(rt,hY), s_CAPACITY(rt,hY,g,y) ) ;
    s2_TXCAPCHARGES(rt,paths,y)                     = sum(activeSolve(rt,hY), s_TXCAPCHARGES(rt,hY,paths,y) ) ;
    s2_GEN(rt,g,y,t,lb,outcomes)                    = sum(activeSolve(rt,hY), s_GEN(rt,hY,g,y,t,lb,outcomes) ) ;
    s2_VOLLGEN(rt,s,y,t,lb,outcomes)                = sum(activeSolve(rt,hY), s_VOLLGEN(rt,hY,s,y,t,lb,outcomes) ) ;
    s2_PUMPEDGEN(rt,g,y,t,lb,outcomes)              = sum(activeSolve(rt,hY), s_PUMPEDGEN(rt,hY,g,y,t,lb,outcomes) ) ;
    s2_LOSS(rt,paths,y,t,lb,outcomes)               = sum(activeSolve(rt,hY), s_LOSS(rt,hY,paths,y,t,lb,outcomes) ) ;
    s2_TXPROJVAR(rt,tupg,y)                         = sum(activeSolve(rt,hY), s_TXPROJVAR(rt,hY,tupg,y) ) ;
    s2_TXUPGRADE(rt,paths,ps,pss,y)                 = sum(activeSolve(rt,hY), s_TXUPGRADE(rt,hY,paths,ps,pss,y) ) ;
    s2_RESV(rt,g,rc,y,t,lb,outcomes)                = sum(activeSolve(rt,hY), s_RESV(rt,hY,g,rc,y,t,lb,outcomes) ) ;
    s2_RESVVIOL(rt,rc,ild,y,t,lb,outcomes)          = sum(activeSolve(rt,hY), s_RESVVIOL(rt,hY,rc,ild,y,t,lb,outcomes) ) ;
    s2_RESVTRFR(rt,rc,ild,ild1,y,t,lb,outcomes)     = sum(activeSolve(rt,hY), s_RESVTRFR(rt,hY,rc,ild,ild1,y,t,lb,outcomes) ) ;
    s2_RENNRGPENALTY(rt,y)                          = sum(activeSolve(rt,hY), s_RENNRGPENALTY(rt,hY,y) ) ;
    s2_ANNMWSLACK(rt,y)                             = sum(activeSolve(rt,hY), s_ANNMWSLACK(rt,hY,y) ) ;
    s2_SEC_NZSLACK(rt,y)                            = sum(activeSolve(rt,hY), s_SEC_NZSLACK(rt,hY,y) ) ;
    s2_SEC_NI1SLACK(rt,y)                           = sum(activeSolve(rt,hY), s_SEC_NI1SLACK(rt,hY,y) ) ;
    s2_SEC_NI2SLACK(rt,y)                           = sum(activeSolve(rt,hY), s_SEC_NI2SLACK(rt,hY,y) ) ;
    s2_NOWIND_NZSLACK(rt,y)                         = sum(activeSolve(rt,hY), s_NOWIND_NZSLACK(rt,hY,y) ) ;
    s2_NOWIND_NISLACK(rt,y)                         = sum(activeSolve(rt,hY), s_NOWIND_NISLACK(rt,hY,y) ) ;
    s2_RENCAPSLACK(rt,y)                            = sum(activeSolve(rt,hY), s_RENCAPSLACK(rt,hY,y) ) ;
    s2_HYDROSLACK(rt,y)                             = sum(activeSolve(rt,hY), s_HYDROSLACK(rt,hY,y) ) ;
    s2_MINUTILSLACK(rt,y)                           = sum(activeSolve(rt,hY), s_MINUTILSLACK(rt,hY,y) ) ;
    s2_FUELSLACK(rt,y)                              = sum(activeSolve(rt,hY), s_FUELSLACK(rt,hY,y) ) ;
    s2_bal_supdem(rt,r,y,t,lb,outcomes)             = sum(activeSolve(rt,hY), s_bal_supdem(rt,hY,r,y,t,lb,outcomes) ) ;
*++++++++++
*   More non-free reserves code.
    s2_RESVCOMPONENTS(rt,paths,y,t,lb,outcomes,stp) = sum(activeSolve(rt,hY), s_RESVCOMPONENTS(rt,hY,paths,y,t,lb,outcomes,stp) ) ;
*++++++++++
    else
    if(numDisYrs < 1, numDisYrs = 1 ) ; ! DInflowYr must have been 1 in which case only the average year was used and numDisYrs = 1
    s2_TOTALCOST(rt)                                = sum(disHydYrs(hY), s_TOTALCOST(rt,hY) ) / numDisYrs ;
    s2_TX(rt,paths,y,t,lb,dum)                      = sum(disHydYrs(hY), s_TX(rt,hY,paths,y,t,lb,dum) ) / numDisYrs ;
    s2_BRET(rt,g,y)                                 = sum(disHydYrs(hY), s_BRET(rt,hY,g,y) ) / numDisYrs ;
    s2_ISRETIRED(rt,g)                              = sum(disHydYrs(hY), s_ISRETIRED(rt,hY,g) ) / numDisYrs ;
    s2_BTX(rt,paths,ps,y)                           = sum(disHydYrs(hY), s_BTX(rt,hY,paths,ps,y) ) / numDisYrs ;
    s2_REFURBCOST(rt,g,y)                           = sum(disHydYrs(hY), s_REFURBCOST(rt,hY,g,y) ) / numDisYrs ;
    s2_BUILD(rt,g,y)                                = sum(disHydYrs(hY), s_BUILD(rt,hY,g,y) ) / numDisYrs ;
    s2_RETIRE(rt,g,y)                               = sum(disHydYrs(hY), s_RETIRE(rt,hY,g,y) ) / numDisYrs ;
    s2_CAPACITY(rt,g,y)                             = sum(disHydYrs(hY), s_CAPACITY(rt,hY,g,y) ) / numDisYrs ;
    s2_TXCAPCHARGES(rt,paths,y)                     = sum(disHydYrs(hY), s_TXCAPCHARGES(rt,hY,paths,y) ) / numDisYrs ;
    s2_GEN(rt,g,y,t,lb,dum)                         = sum(disHydYrs(hY), s_GEN(rt,hY,g,y,t,lb,dum) ) / numDisYrs ;
    s2_VOLLGEN(rt,s,y,t,lb,dum)                     = sum(disHydYrs(hY), s_VOLLGEN(rt,hY,s,y,t,lb,dum) ) / numDisYrs ;
    s2_PUMPEDGEN(rt,g,y,t,lb,dum)                   = sum(disHydYrs(hY), s_PUMPEDGEN(rt,hY,g,y,t,lb,dum) ) / numDisYrs ;
    s2_LOSS(rt,paths,y,t,lb,dum)                    = sum(disHydYrs(hY), s_LOSS(rt,hY,paths,y,t,lb,dum) ) / numDisYrs ;
    s2_TXPROJVAR(rt,tupg,y)                         = sum(disHydYrs(hY), s_TXPROJVAR(rt,hY,tupg,y) ) / numDisYrs ;
    s2_TXUPGRADE(rt,paths,ps,pss,y)                 = sum(disHydYrs(hY), s_TXUPGRADE(rt,hY,paths,ps,pss,y) ) / numDisYrs ;
    s2_RESV(rt,g,rc,y,t,lb,dum)                     = sum(disHydYrs(hY), s_RESV(rt,hY,g,rc,y,t,lb,dum) ) / numDisYrs ;
    s2_RESVVIOL(rt,rc,ild,y,t,lb,dum)               = sum(disHydYrs(hY), s_RESVVIOL(rt,hY,rc,ild,y,t,lb,dum) ) / numDisYrs ;
    s2_RESVTRFR(rt,rc,ild,ild1,y,t,lb,dum)          = sum(disHydYrs(hY), s_RESVTRFR(rt,hY,rc,ild,ild1,y,t,lb,dum) ) / numDisYrs ;
    s2_RENNRGPENALTY(rt,y)                          = sum(disHydYrs(hY), s_RENNRGPENALTY(rt,hY,y) ) / numDisYrs ;
    s2_ANNMWSLACK(rt,y)                             = sum(disHydYrs(hY), s_ANNMWSLACK(rt,hY,y) ) / numDisYrs ;
    s2_SEC_NZSLACK(rt,y)                            = sum(disHydYrs(hY), s_SEC_NZSLACK(rt,hY,y) ) / numDisYrs ;
    s2_SEC_NI1SLACK(rt,y)                           = sum(disHydYrs(hY), s_SEC_NI1SLACK(rt,hY,y) ) / numDisYrs ;
    s2_SEC_NI2SLACK(rt,y)                           = sum(disHydYrs(hY), s_SEC_NI2SLACK(rt,hY,y) ) / numDisYrs ;
    s2_NOWIND_NZSLACK(rt,y)                         = sum(disHydYrs(hY), s_NOWIND_NZSLACK(rt,hY,y) ) / numDisYrs ;
    s2_NOWIND_NISLACK(rt,y)                         = sum(disHydYrs(hY), s_NOWIND_NISLACK(rt,hY,y) ) / numDisYrs ;
    s2_RENCAPSLACK(rt,y)                            = sum(disHydYrs(hY), s_RENCAPSLACK(rt,hY,y) ) / numDisYrs ;
    s2_HYDROSLACK(rt,y)                             = sum(disHydYrs(hY), s_HYDROSLACK(rt,hY,y) ) / numDisYrs ;
    s2_MINUTILSLACK(rt,y)                           = sum(disHydYrs(hY), s_MINUTILSLACK(rt,hY,y) ) / numDisYrs ;
    s2_FUELSLACK(rt,y)                              = sum(disHydYrs(hY), s_FUELSLACK(rt,hY,y) ) / numDisYrs ;
    s2_bal_supdem(rt,r,y,t,lb,dum)                  = sum(disHydYrs(hY), s_bal_supdem(rt,hY,r,y,t,lb,dum) ) / numDisYrs ;
*++++++++++
*   More non-free reserves code.
    s2_RESVCOMPONENTS(rt,paths,y,t,lb,dum,stp)      = sum(disHydYrs(hY), s_RESVCOMPONENTS(rt,hY,paths,y,t,lb,dum,stp) ) / numDisYrs ;
*++++++++++
  ) ;
) ;

Display s2_TOTALCOST, disHydYrs, activeSolve, activeHD, indexhY, solveReport ;



*===============================================================================================
* 7. Dump results out to GDX files and rename/relocate certain output files.

* Dump output prepared for report writing into a GDX file.
Execute_Unload "PreparedOutput - %runName% - %scenarioName%.gdx",
* Miscellaneous sets
  h activeSolve activeHD activeRT solveGoal
* Miscellaneous parameters
  solveReport numDisYrs
* The 's2' output parameters
  s2_TOTALCOST s2_TX s2_BRET s2_ISRETIRED s2_BTX s2_REFURBCOST s2_BUILD s2_RETIRE s2_CAPACITY s2_TXCAPCHARGES s2_GEN s2_VOLLGEN
  s2_PUMPEDGEN s2_LOSS s2_TXPROJVAR s2_TXUPGRADE s2_RESV s2_RESVVIOL s2_RESVTRFR s2_bal_supdem
*++++++++++
* More non-free reserves code.
  s2_RESVCOMPONENTS
*++++++++++
* The 's2' penalties and slacks
  s2_RENNRGPENALTY s2_ANNMWSLACK s2_SEC_NZSLACK s2_SEC_NI1SLACK s2_SEC_NI2SLACK s2_NOWIND_NZSLACK s2_NOWIND_NISLACK s2_RENCAPSLACK s2_HYDROSLACK s2_MINUTILSLACK s2_FUELSLACK
  ;

* Dump all 's' slacks and penalties into a GDX file.
Execute_Unload "Slacks and penalties - %runName% - %scenarioName%.gdx",
  s_RENNRGPENALTY s_ANNMWSLACK s_SEC_NZSLACK s_SEC_NI1SLACK s_SEC_NI2SLACK s_NOWIND_NZSLACK s_NOWIND_NISLACK s_RENCAPSLACK s_HYDROSLACK s_MINUTILSLACK s_FUELSLACK
  ;

* Dump all variable levels and constraint marginals into a GDX file. 
Execute_Unload "Levels and marginals - %runName% - %scenarioName%.gdx",
*+++++++++++++++++++++++++
* More non-free reserves code.
  s_RESVCOMPONENTS s_calc_nfreserves s_resv_capacity
*+++++++++++++++++++++++++
* Free Variables
  s_TOTALCOST s_TX s_THETA
* Binary Variables
  s_BGEN s_BRET s_ISRETIRED s_BTX s_NORESVTRFR
* Positive Variables
  s_REFURBCOST s_GENBLDCONT s_CGEN s_BUILD s_RETIRE s_CAPACITY s_TXCAPCHARGES s_GEN s_VOLLGEN s_PUMPEDGEN s_SPILL s_LOSS s_TXPROJVAR s_TXUPGRADE
* Reserve variables
  s_RESV s_RESVVIOL s_RESVTRFR s_RESVREQINT
* Penalty and slack variables
  s_ANNMWSLACK s_RENNRGPENALTY s_SEC_NZSLACK s_SEC_NI1SLACK s_SEC_NI2SLACK s_NOWIND_NZSLACK s_NOWIND_NISLACK s_RENCAPSLACK s_HYDROSLACK s_MINUTILSLACK s_FUELSLACK
* Equations (ignore the objective function)
  s_calc_refurbcost s_calc_txcapcharges s_bldgenonce s_buildcapint s_buildcapcont s_annnewmwcap s_endogpltretire s_endogretonce s_balance_capacity s_bal_supdem
  s_security_nz s_security_ni1 s_security_ni2 s_nowind_nz s_nowind_ni s_limit_maxgen s_limit_mingen s_minutil s_limit_fueluse s_limit_nrg
  s_minreq_rennrg s_minreq_rencap s_limit_hydro s_limit_pumpgen1 s_limit_pumpgen2 s_limit_pumpgen3 s_boundtxloss s_tx_capacity s_tx_projectdef s_tx_onestate
  s_tx_upgrade s_tx_oneupgrade s_tx_dcflow s_tx_dcflow0 s_equatetxloss s_txGrpConstraint s_resvsinglereq1 s_genmaxresv1
  s_resvtrfr1 s_resvtrfr2 s_resvtrfr3 s_resvrequnit s_resvreq2 s_resvreqhvdc s_resvtrfr4 s_resvtrfrdef s_resvoffcap s_resvreqwind
  ;

bat.ap = 0 ;
putclose bat
  'copy "PreparedOutput - %runName% - %scenarioName%.gdx"       "%OutPath%\%runName%\GDX\"' /
  'copy "Slacks and penalties - %runName% - %scenarioName%.gdx" "%OutPath%\%runName%\GDX\"' /
  'copy "Levels and marginals - %runName% - %scenarioName%.gdx" "%OutPath%\%runName%\GDX\"' /
  'copy "GEMsolve.log"                                          "%OutPath%\%runName%\%runName% - %scenarioName% - GEMsolve.log"' /
  ;
execute 'temp.bat' ;




$stop
$ontext
Do we need the slacks as s2?
What about BGEN, cGEN and GENBLDCONT that all used to get added up to be s_buildgen?

    s_buildgen(rt,hYr,g,y)         = BGEN.l(g,y) + CGEN.l(g,y) + GENBLDCONT.l(g,y) ;
    s3_hydoutput(mds,rt,g,y,t,outcomes)       = sum(s_solveindex(mds,rt,hYr), s2_hydoutput(mds,rt,hYr,g,y,t,outcomes)  ) ;

    s3_rennrgpenalty(mds,rt,y)                = sum(s_solveindex(mds,rt,hYr), s2_rennrgpenalty(mds,rt,hyr,y) ) ;
    s3_sec_nzslack(mds,rt,y)                  = sum(s_solveindex(mds,rt,hYr), s2_sec_nzslack(mds,rt,hyr,y) ) ;
    s3_sec_ni1slack(mds,rt,y)                 = sum(s_solveindex(mds,rt,hYr), s2_sec_ni1slack(mds,rt,hyr,y) ) ;
    s3_sec_ni2slack(mds,rt,y)                 = sum(s_solveindex(mds,rt,hYr), s2_sec_ni2slack(mds,rt,hyr,y) ) ;
    s3_nowind_nzslack(mds,rt,y)               = sum(s_solveindex(mds,rt,hYr), s2_nowind_nzslack(mds,rt,hyr,y) ) ;
    s3_nowind_nislack(mds,rt,y)               = sum(s_solveindex(mds,rt,hYr), s2_nowind_nislack(mds,rt,hyr,y) ) ;
    s3_annmwslack(mds,rt,y)                   = sum(s_solveindex(mds,rt,hYr), s2_annmwslack(mds,rt,hyr,y) ) ;
    s3_rencapslack(mds,rt,y)                  = sum(s_solveindex(mds,rt,hYr), s2_rencapslack(mds,rt,hyr,y) ) ;
    s3_hydroslack(mds,rt,y)                   = sum(s_solveindex(mds,rt,hYr), s2_hydroslack(mds,rt,hyr,y) ) ;
    s3_minutilslack(mds,rt,y)                 = sum(s_solveindex(mds,rt,hYr), s2_minutilslack(mds,rt,hyr,y) ) ;
    s3_fuelslack(mds,rt,y)                    = sum(s_solveindex(mds,rt,hYr), s2_fuelslack(mds,rt,hyr,y) ) ;
  else
Order of var/eqn declarations
Binary Variables
  BGEN(g,y)                         'Binary variable to identify build year for new generation plant'
Positive Variables
  REFURBCOST(g,y)                   'Annualised generation plant refurbishment expenditure charge, $'
  GENBLDCONT(g,y)                   'Continuous variable to identify build year for new scalable generation plant - for plant in linearPlantBuild set'
  CGEN(g,y)                         'Continuous variable to identify build year for new scalable generation plant - for plant in integerPlantBuild set (CGEN or BGEN = 0 in any year)'
  BUILD(g,y)                        'New capacity installed by generating plant and year, MW'
$offtext



*===============================================================================================
*  5. Move MIPtrace files to output directory and generate miptrace.bat.

$if not %PlotMIPtrace%==1 $goto NoTrace
* Copy current MIPtrace files from the programs to the Traceplots directory, and erase MIPtrace files from programs directory. 
putclose bat 'copy "%runName%-%scenarioName%-MIPtrace*.txt" "%OutPath%\%runName%\Traceplots"' / 'erase *MIPtrace*.txt' ;
execute 'temp.bat';

* Create the batch file to call Matlab to make the MIPtrace plots - note that miptrace.bat will be invoked from RunGem.gms.
if(%MexOrMat% = 1,
  putclose miptrace '"%MatCodePath%plot_all_objective_traces.exe" "%OutPath%\%runName%\Traceplots" "%runName%" "%Solver% trace"' ;
  else
  putclose miptrace "call matlab /r ", '"plot_all_objective_traces(', "'%OutPath%\%runName%\Traceplots','%runName%',","'%Solver% trace'); exit", '"' ;
) ;
$label NoTrace



*===============================================================================================
*  6. Create an awk script which, when executed, will produce a file containing the number of integer solutions per MIP model.

$if %GEMtype%=="rmip" $goto NoMIP
$onecho > f.awk
/Restarting execution/ {
  ++count2
  if (count1>0) {
    print "Model: " name "  Integer solutions: " count1
    count1 = 0
  }
}

/^\* / {
  ++count1
}

/^--- LOOPS / {
# Assumes there will be 3 nested loops
  name = $NF
  getline
  name = name "-" $NF
  getline
  name = name "-" $NF
}
$offecho
$label NoMIP




* End of file.
