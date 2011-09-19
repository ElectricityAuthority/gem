* GEMsolve.gms


* Last modified by Dr Phil Bishop, 19/09/2011 (imm@ea.govt.nz)


*** To do:
*** Sort out the MIPtrace stuff, also, can it be made to work on all solvers?
*** does each model type have the correct modelstat error condition driving the abort stmt?
*** The abort if slacks present has gone. Bring it back? Warning if penalties?

* NB: The following symbols from input data file may have been changed in GEMdata: Sets y and exist.

$ontext
 This program continues sequentially from GEMdata. The GEMdata work file must be called
 at invocation. Note that GEMdata was invoked by restarting from the GEMGEMdeclarations
 work file. This program is followed by GEMreports.

 Code sections:
  1. Take care of preliminaries.
  2. Set bounds, initial levels and, in some cases, fix variables to a specified level.
  3. Loop through all the solves
  4. Prepare results to pass along to GEMreports in the form of a GDX file. 
  5. Dump results out to GDX files and rename/relocate certain output files.

  x. Move MIPtrace files to output directory and generate miptrace.bat.
  x. Create an awk script, which when executed, will produce a file containing the number of integer solutions per MIP model.
$offtext

* Track memory usage.
* Higher numbers are for more detailed information inside loops. Alternatively, on the command line, type: gams xxx profile=1
*option profile = 1 ;
*option profile = 2 ;
*option profile = 3 ;

option seed = 101 ;

* Turn the following stuff on/off as desired.
$offupper onempty inlinecom { } eolcom !
$offuelxref offuellist	
*$onuelxref  onuellist	
$offsymxref offsymlist
*$onsymxref  onsymlist



*===============================================================================================
* 1. Take care of preliminaries.

* Declare and create basic run-time reporting capability.
File rep "Write to a report"       / "%ProgPath%Report.txt" / ; rep.lw = 0 ; rep.ap = 1 ;
File con "Write to the console"    / con / ;                    con.lw = 0 ;
File dummy ;

putclose rep 'Run: "%runName%"' / 'Run version: "%runVersionName%"' / '  - started at ', system.time, ' on ' system.date ;

* Specify various .lst file and solver-related options.
if(%limitOutput% = 1, option limcol = 0, limrow = 0, sysout = off, solprint = off ; ) ; 
option reslim = 500, iterlim = 10000000 ;
*option solprint = on ;

* Select the solver and include the relevant solver options files:
option LP = %Solver%, MIP = %Solver%, RMIP = %Solver% ;
$include 'GEM%Solver%.gms'

* Capture the specified solve goal (for GEM, not DISP) and intialise various model solve settings.
Set solveGoal(goal) 'User-selected solve goal' / %solveGoal% / ;
gem.reslim = 500 ;     disp.reslim = 300 ;
gem.optfile = 1 ;      disp.optfile = 0 ;
gem.optcr = 0.00001 ;  gem.optca = 0 ;
loop(solveGoal(goal),
  if(sameas(solveGoal,'QDsol'),  gem.optfile = 2 ; gem.optcr = %QDoptCr% ; gem.reslim = %QDsolSecs% ) ;
  if(sameas(solveGoal,'VGsol'),  gem.optfile = 3 ; gem.reslim = %VGsolSecs% ) ;
  if(sameas(solveGoal,'MinGap'), gem.optfile = 4 ; gem.reslim = %MinGapSecs% ) ;
) ;

* To suppress use of an options file, use the command: 'xxx.OptFile = 0 ;'. Or simply comment out the
* command that calls the options file for the specific model name.

* Turn on the following to use the GAMSCHK routines.
*option MIP=GAMSCHK ;



*===============================================================================================
* 2. Set bounds, initial levels and, in some cases, fix variables to a specified level.

* Fix CGEN to zero for all years less than cGenYr and fix BGEN to zero for all years greater than or equal to cGenYr.
CGEN.up(g,y) = 1 ;     CGEN.fx(g,y)$( yearNum(y) <  cGenYr ) = 0 ;
BGEN.up(g,y) = 1 ;     BGEN.fx(g,y)$( yearNum(y) >= cGenYr ) = 0 ;

* Restrict refurbishment cost to be zero in years prior to refurbishment.
REFURBCOST.fx(g,y)$( yearNum(y) < i_refurbDecisionYear(g) ) = 0 ;

* Restrict generation:
* Don't allow generation unless the unit is in validYrOperate; validYrOperate embodies the appropriate date for existing, committed, and new units.
GEN.fx(g,y,t,lb,scenarios)$( not validYrOperate(g,y) ) = 0 ;
* Force generation from the must-run plant, i.e base load (convert MW capacity to GWh for each load block).
GEN.fx(g,y,t,lb,scenarios)$( ( exist(g) or commit(g) ) * i_baseload(g) * validYrOperate(g,y) ) =
1e-3 * hoursPerBlock(t,lb) * i_nameplate(g) * maxCapFactPlant(g,t,lb) ;

* Place restrictions on VOLL plants:
VOLLGEN.up(s,y,t,lb,scenarios) = 1e-3 * hoursPerBlock(t,lb) * i_VOLLcap(s) ;  ! Respect the capacity of VOLL plants
VOLLGEN.fx(s,y,t,lb,scenarios)$( ord(lb) <= noVOLLblks ) = 0 ;                ! Don't allow VOLL in user-specified top load blocks 

* Fix bounds on TX according to the largest capacity allowed in any state. Lower bound must be zero if transportation formulation is being used.
TX.lo(paths,y,t,lb,scenarios) = -smax(ps, i_txCapacity(paths,ps)) ;
TX.lo(paths,y,t,lb,scenarios)$(DCloadFlow = 0) = 0 ;
TX.up(paths,y,t,lb,scenarios) = +smax(ps, i_txCapacity(paths,ps)) ;

* Fix the reference bus angle to zero (only used in case of DC load flow formulation).
THETA.fx(slackBus(r),y,t,lb,scenarios) = 0 ;

* Fix various reserves variables to zero if they are not needed.
RESV.fx(g,rc,y,t,lb,scenarios)$(            ( not useReserves ) or ( not reservesCapability(g,rc) ) ) = 0 ;
RESVVIOL.fx(rc,ild,y,t,lb,scenarios)$(        not useReserves ) = 0 ;
RESVTRFR.fx(rc,ild,ild1,y,t,lb,scenarios)$( ( not useReserves ) or singleReservesReqF(rc) ) = 0 ;
RESVREQINT.fx(rc,ild,y,t,lb,scenarios)$(      not useReserves ) = 0 ;
NORESVTRFR.fx(ild,ild1,y,t,lb,scenarios)$(    not useReserves ) = 0 ;

* Fix to zero the intra-island reserve variables.
RESVTRFR.fx(rc,ild,ild,y,t,lb,scenarios) = 0 ;
NORESVTRFR.fx(ild,ild,y,t,lb,scenarios)  = 0 ;

* Set the lower bound on the reserve requirement if there is an external requirement specified.
RESVREQINT.lo(rc,ild,y,t,lb,scenarios)$( i_reserveReqMW(y,ild,rc) > 0 ) = i_reserveReqMW(y,ild,rc) * hoursPerBlock(t,lb) ;

* Reserve contribution cannot exceed the specified capability during peak or other periods.
RESV.up(g,rc,y,t,lb,scenarios)$( useReserves and reservesCapability(g,rc) ) = reservesCapability(g,rc) * hoursPerBlock(t,lb) ;

* Don't allow reserves from units prior to committed date or earliest allowable operation or if plant is retired.
RESV.fx(g,rc,y,t,lb,scenarios)$( not validYrOperate(g,y) ) = 0 ;



*===============================================================================================
* 3. Loop through all the solves

* The solve statement is inside 3 loops
* Outer loop: Experiments
*   Middle loop: Steps (i.e. timing, reopt, or dispatch)
*     Inner loop: scenarioSets
*
* If more than one scenario is defined in the current scenarioSet, then they're all solved simultaneously, i.e. in a single solve.

$set AddUpSlacks    "sum(y, ANNMWSLACK.l(y) + RENCAPSLACK.l(y) + HYDROSLACK.l(y) + MINUTILSLACK.l(y) + FUELSLACK.l(y) )"
$set AddUpPenalties "sum((y,sc), PEAK_NZ_PENALTY.l(y,sc) + PEAK_NI_PENALTY.l(y,sc) + NOWINDPEAK_NI_PENALTY.l(y,sc) )"

* First, loop through all the experiments
loop(experiments,

* Reset any variables that might have been fixed for an earlier reoptimisation or dispatch solve (reset fixes by initialising .lo and .up fields)

* Restrict the build variable (i.e. MW) to zero or i_nameplate under certain input assumptions:
  BUILD.lo(g,y) = 0 ;    BUILD.up(g,y) = i_nameplate(g) ;             ! Lower bound equals zero, upper bound equals i_nameplate.
  BUILD.fx(g,y)$( not validYrBuild(g,y) ) = 0 ;                       ! Don't allow capacity to be built in years outside the valid range of build years.
  BUILD.fx(g,y)$( commit(g) * validYrBuild(g,y) ) = i_nameplate(g) ;  ! For committed plant, fix the MW able to be built regardless of any other settings.

* Fix retired MW by year and generating plant to zero if not able to be endogenously retired.
  RETIRE.lo(g,y) = 0 ;   RETIRE.up(g,y) = inf ;
  RETIRE.fx(g,y)$( not endogenousRetireYrs(g,y) ) = 0 ;

* Fix the endogenous retirement binaries at zero for all cases where it's not required.
  BRET.lo(g,y) = 0 ;     BRET.up(g,y) = 1 ;
  BRET.fx(g,y)$( not endogenousRetireDecisnYrs(g,y) ) = 0 ;
  ISRETIRED.lo(g) = 0 ;  ISRETIRED.up(g) = 1 ;
  ISRETIRED.fx(g)$( not possibleToEndogRetire(g) ) = 0 ;

* Impose upper bound of 1 on continuous 0-1 transmission-related variables.
  TXUPGRADE.lo(r,rr,ps,pss,y) = 0 ;  TXUPGRADE.up(validTransitions(paths,ps,pss),y) = 1 ;
  TXPROJVAR.lo(tupg,y) = 0 ;         TXPROJVAR.up(tupg,y) = 1 ;

* Force transmission upgrades in the user-specified year (do this in either endogogenous or exogenous investment mode).
  loop((transitions(tupg,r,rr,ps,pss),y)$txFixedComYrSet(tupg,r,rr,ps,pss,y),
    TXUPGRADE.fx(r,rr,ps,pss,y) = 1 ;
  ) ;

* Fix the years prior to earliest year at zero for either exogenous or endogenous transmission investment.
  loop((transitions(tupg,r,rr,ps,pss),y)$txEarlyComYrSet(tupg,r,rr,ps,pss,y),
    TXUPGRADE.fx(r,rr,ps,pss,y) = 0 ;
  ) ;

* Fix transmission binaries to zero if they're not needed.
  BTX.lo(paths,ps,y) = 0 ;  BTX.up(paths,ps,y) = 1 ;
  BTX.fx(notAllowedStates,y) = 0 ;


* Second, loop through each of the steps: timing, reoptimisation, and dispatch.
  loop(steps,

*   If it's a reoptimisation solve, fix the build (generation and transmission) to be the same as for
*   the timing solve, but free up the movers.
    if(sameas(steps,'reopt'),
      BUILD.fx(g,y) = BUILD.l(g,y) ;

      TXPROJVAR.fx(tupg,y) = TXPROJVAR.l(tupg,y) ;
      TXUPGRADE.fx(validTransitions(paths,ps,pss),y) = TXUPGRADE.l(paths,ps,pss,y) ;
      BTX.fx(paths,ps,y) = BTX.l(paths,ps,y) ;

      loop((g,movers(k))$( (noExist(g) * mapg_k(g,k)) * (not moverExceptions(g)) ),
        BUILD.lo(g,y)$validYrBuild(g,y) = 0 ;
        BUILD.up(g,y)$validYrBuild(g,y) = i_nameplate(g) ;
      ) ;

*     Similarly, fix the retirements to be the same as for the timing solve.
      BRET.fx(g,y) = BRET.l(g,y) ; ISRETIRED.fx(g) = ISRETIRED.l(g) ; RETIRE.fx(g,y) = RETIRE.l(g,y) ;

*     If it's a dispatch solve, fix the timing decisions (of generation and transmission investment, and
*     generation retirement and refurbishment) from the timing/reoptimisation solve.
      else if(sameas(steps,'dispatch'),
        BUILD.fx(g,y) = BUILD.l(g,y) ;

        BRET.fx(g,y) = BRET.l(g,y) ;
        ISRETIRED.fx(g) = ISRETIRED.l(g) ;
        RETIRE.fx(g,y) = RETIRE.l(g,y) ;

        TXPROJVAR.fx(tupg,y) = TXPROJVAR.l(tupg,y) ;
        TXUPGRADE.fx(validTransitions(paths,ps,pss),y) = TXUPGRADE.l(paths,ps,pss,y) ;
        BTX.fx(paths,ps,y) = BTX.l(paths,ps,y) ;
      ) ;

*   End of step-type if
    ) ;

*   Third, loop over each scenarioSet for this step of the experiment.
    loop(allSolves(experiments,steps,scenarioSets),

*     Initialise the desired scenarios for this solve
      sc(scenarios) = no ;
      sc(scenarios)$mapScenarios(scenarioSets,scenarios) = yes ;

*     Select the appropriate scenario weight.
      scenarioWeight(sc) = 0 ;
      scenarioWeight(sc) = weightScenariosBySet(scenarioSets,sc) ;
      display 'Scenario and weight for this solve:', sc, scenarioWeight ;

*     Compute the hydro output values to use for the selected scenarios (NB: only works for hydroSeqTypes={same,sequential}).
      modelledHydroOutput(g,y,t,scenarios) = 0 ;
      loop(sc(scenarios),
        if(mapSC_hydroSeqTypes(scenarios,'same'),
          modelledHydroOutput(g,y,t,scenarios) = hydroOutputScalar *
            sum((mapv_g(v,g),mapm_t(m,t),hY)$(mapSC_hY(scenarios,hY)), historicalHydroOutput(v,hY,m)) / sum(mapSC_hY(scenarios,hY1), 1) ;
          mapHydroYearsToModelledYears(experiments,steps,scenarioSets,sc,y,hY)$( ord(hY) = sum(mapSC_hY(scenarios,hY1), 1) ) = yes ;
          else
          loop(y,
            chooseHydroYears(hY) = no ;
            chooseHydroYears(hY)$(sum(hY1$(mapSC_hY(scenarios, hY1) and ord(hY1) + ord(y) - 1            = ord(hY)), 1)) = yes ;
            chooseHydroYears(hY)$(sum(hY1$(mapSC_hY(scenarios, hY1) and ord(hY1) + ord(y) - 1 - card(hY) = ord(hY)), 1)) = yes ;
            modelledHydroOutput(g,y,t,sc) =
              sum((mapv_g(v,g),mapm_t(m,t),chooseHydroYears), historicalHydroOutput(v,chooseHydroYears,m)) / sum(chooseHydroYears, 1) ;
            mapHydroYearsToModelledYears(experiments,steps,scenarioSets,sc,y,chooseHydroYears) = yes ;
          ) ;
        ) ;
      ) ;
      display 'Hydro output:', modelledHydroOutput ;

*     Collect modelledHydroOutput for posterity.
      allModelledHydroOutput(experiments,steps,scenarioSets,g,y,t,sc) = modelledHydroOutput(g,y,t,sc) ;

*     Solve either GEM or DISP, depending on what step we're at.
      if(sameas(steps,'dispatch'),
        Solve DISP using %DISPtype% minimizing TOTALCOST ;
        else
        Solve GEM using %GEMtype% minimizing TOTALCOST ;
      ) ;

*     Figure out if entire model invocation is to be aborted - but report that fact before aborting.
      slacks = %AddUpSlacks% ;
      penalties = %AddUpPenalties% ;

      counter = 0 ;
      if(sameas(steps,'dispatch'),
        counter$( DISP.modelstat <> 1 and DISP.modelstat <> 8 ) = 1 ;
        else
        counter$( ( GEM.modelstat = 10 ) or ( GEM.modelstat <> 1 and GEM.modelstat <> 8 ) ) = 1 ;
      ) ;

*     Post a progress message to report for use by GUI and to the console.
      if(counter = 1,
        putclose rep // 'The ' experiments.tl ' - ' steps.tl ' - ' scenarioSets.tl ' solve finished with some sort of problem and the job is now going to abort.' /
                        'Examine GEMsolve.lst and/or GEMsolve.log to see what went wrong.' ;
        else
        putclose rep // 'The ' experiments.tl ' - ' steps.tl ' - ' scenarioSets.tl ' solve finished at ', system.time / 'Objective function value: ' TOTALCOST.l:<12:1 / ;
      ) ;
      putclose con // '    The ' experiments.tl ' - ' steps.tl ' - ' scenarioSets.tl ' solve for "%runName% -- %runVersionName% has just finished' /
                      '    Objective function value: ' TOTALCOST.l:<12:1 // ;

      if(sameas(steps,'dispatch'),
        abort$( DISP.modelstat <> 1 and DISP.modelstat <> 8 ) "Problem encountered when solving DISP..." ;
        else
        abort$( GEM.modelstat = 10 ) "GEM is infeasible - check out GEMsolve.log to see what you've done wrong in configuring a model that is infeasible" ;
        abort$( GEM.modelstat <> 1 and GEM.modelstat <> 8 ) "Problem encountered solving GEM..." ;
      ) ;

*     Generate a MIP trace file when MIPtrace is equal to 1 (MIPtrace specified in GEMsettings).
$     if not %PlotMIPtrace%==1 $goto NoTrace3
      putclose bat 'copy MIPtrace.txt "%runName%-%runVersionName%-MIPtrace-' experiments.tl ' - ' steps.tl ' - ' scenarioSets.tl '.txt"' ;
      execute 'temp.bat';
$     label NoTrace3

*     Collect information for solve summary report
      solveReport(allSolves,'ObjFnValue') = TOTALCOST.l ;    solveReport(allSolves,'SCcosts') = sum(sc(scenarios), SCENARIO_COSTS.l(sc) ) ;
      solveReport(allSolves,'OptFile')    = gem.optfile ;    solveReport(allSolves,'OptCr')   = gem.optcr ;
      solveReport(allSolves,'ModStat')    = gem.modelstat ;  solveReport(allSolves,'SolStat') = gem.solvestat ;
      solveReport(allSolves,'Vars')       = gem.numvar ;     solveReport(allSolves,'DVars')   = gem.numdvar ;
      solveReport(allSolves,'Eqns')       = gem.numequ ;     solveReport(allSolves,'Iter')    = gem.iterusd ;
      solveReport(allSolves,'Time')       = gem.resusd ;     solveReport(allSolves,'GapAbs')  = abs( gem.objest - gem.objval ) ;
      solveReport(allSolves,'Gap%')$gem.objval = 100 * abs( gem.objest - gem.objval ) / gem.objval ;
      if(slacks > 0,    solveReport(allSolves,'Slacks') = 1    else solveReport(allSolves,'Slacks') = -99 ) ;
      if(penalties > 0, solveReport(allSolves,'Penalties') = 1 else solveReport(allSolves,'Penalties') = -99 ) ;
      display 'solve report:', slacks, penalties, solveReport ;

*     Collect up solution values - by experiment, step and scenarioSet.
$     include CollectResults.inc

*   End of scenarioSet loop.
    ) ;

* End of steps loop.
  ) ;

* Before going around the 'Experiments' loop again, dump all output for the current experiment to a GDX file named after the experiment.
  put dummy ;
  put_utility 'gdxout' / '%OutPath%\%runName%\GDX\temp\AllOut\' experiments.tl ;
  execute_unload
*+++++++++++++++++++++++++
* More non-free reserves code.
  s_RESVCOMPONENTS, s_calc_nfreserves, s_resv_capacity
*+++++++++++++++++++++++++
* Free Variables
  s_TOTALCOST, s_SCENARIO_COSTS, s_TX, s_THETA
* Binary Variables
  s_BGEN, s_BRET, s_ISRETIRED, s_BTX, s_NORESVTRFR
* Positive Variables
  s_REFURBCOST, s_GENBLDCONT, s_CGEN, s_BUILD, s_RETIRE, s_CAPACITY, s_TXCAPCHARGES, s_GEN, s_VOLLGEN, s_PUMPEDGEN, s_LOSS, s_TXPROJVAR, s_TXUPGRADE
* Reserve variables
  s_RESV, s_RESVVIOL, s_RESVTRFR, s_RESVREQINT
* Penalty variables
  s_RENNRGPENALTY, s_PEAK_NZ_PENALTY, s_PEAK_NI_PENALTY, s_NOWINDPEAK_NI_PENALTY
* Slack variables
  s_ANNMWSLACK, s_RENCAPSLACK, s_HYDROSLACK, s_MINUTILSLACK, s_FUELSLACK
* Equations (ignore the objective function)
  s_calc_scenarioCosts, s_calc_refurbcost, s_calc_txcapcharges, s_bldgenonce, s_buildcapint, s_buildcapcont, s_annnewmwcap, s_endogpltretire, s_endogretonce
  s_balance_capacity, s_bal_supdem, s_peak_nz, s_peak_ni, s_noWindPeak_ni, s_limit_maxgen, s_limit_mingen, s_minutil, s_limit_fueluse, s_limit_nrg
  s_minreq_rennrg, s_minreq_rencap, s_limit_hydro, s_limit_pumpgen1, s_limit_pumpgen2, s_limit_pumpgen3, s_boundtxloss, s_tx_capacity, s_tx_projectdef
  s_tx_onestate, s_tx_upgrade, s_tx_oneupgrade, s_tx_dcflow, s_tx_dcflow0, s_equatetxloss, s_txGrpConstraint, s_resvsinglereq1, s_genmaxresv1, s_resvtrfr1
  s_resvtrfr2, s_resvtrfr3, s_resvrequnit, s_resvreq2, s_resvreqhvdc, s_resvtrfr4, s_resvtrfrdef, s_resvoffcap, s_resvreqwind
  ;

* Repeat the output dump to a GDX file named after the experiment, but this time dump only the output required for reporting.
  put dummy ;
  put_utility 'gdxout' / '%OutPath%\%runName%\GDX\temp\RepOut\' experiments.tl ;
  execute_unload
* Variable levels
  s_TOTALCOST, s_TX, s_REFURBCOST, s_BUILD, s_CAPACITY, s_TXCAPCHARGES, s_GEN, s_VOLLGEN
  s_RENNRGPENALTY, s_PEAK_NZ_PENALTY, s_PEAK_NI_PENALTY, s_NOWINDPEAK_NI_PENALTY
  s_ANNMWSLACK, s_RENCAPSLACK, s_HYDROSLACK, s_MINUTILSLACK, s_FUELSLACK, s_RESV, s_RESVVIOL, s_RESVCOMPONENTS
* Equation marginals (ignore the objective function)
  s_bal_supdem, s_peak_nz, s_peak_ni, s_noWindPeak_ni
  ;

* End of experiments loop.
) ;


* Merge the GDX files from each experiment into a single GDX file called 'allExperimentsXXX.gdx'.
execute 'gdxmerge "%OutPath%\%runName%\GDX\temp\AllOut\"*.gdx output="%OutPath%\%runName%\GDX\allExperimentsAllOutput - %runVersionName%.gdx" big=100000'
execute 'gdxmerge "%OutPath%\%runName%\GDX\temp\RepOut\"*.gdx output="%OutPath%\%runName%\GDX\allExperimentsReportOutput - %runVersionName%.gdx" big=100000'

* NB: The big parameter is used to specify a cutoff for symbols that will be written one at a time. Each symbol
* that exceeds the size will be processed by reading each gdx file and only process the data for that symbol. This
* can lead to reading the same gdx file many times, but it allows the merging of large data sets.



*===============================================================================================
* 4. Dump results out to GDX files and rename/relocate certain output files.

* edit above heading

* x) Dump selected input data into a GDX file (as imported, or from intermediate steps in GEMdata, or what's actually used to solve the model).
Execute_Unload "Selected prepared input data - %runName% - %runVersionName%.gdx",
* Basic sets, subsets, and mapping sets.
  y t f k g s o lb i r e ild ps scenarios rc n tgc hY
  mapg_k mapg_o mapg_e mapg_f maps_r mapg_r mapild_r mapAggR_r isIldEqReg firstPeriod firstYr lastYr allButFirstYr
  paths nwd swd interIsland pumpedHydroPlant wind gas diesel
  thermalFuel i_fuelQuantities renew schedHydroPlant nsegment demandGen 
  allSolves weightScenariosBySet
* Financial, capex and cost related sets and parameters
  taxRate CBAdiscountRates PVfacG PVfacT PVfacsM PVfacsEY PVfacs capexLife annuityFacN annuityFacR TxAnnuityFacN TxAnnuityFacR
  capRecFac depTCrecFac txCapRecFac txDepTCrecFac i_capitalCost i_connectionCost capexPlant refurbCapexPlant
  capCharge refurbCapCharge txCapCharge
  i_largestGenerator, i_smallestPole, i_winterCapacityMargin, i_P200ratioNZ, i_P200ratioNI, i_fkNI
  i_fixedOM i_HVDCshr i_HVDClevy srmc locFac_recip i_plantReservesCost
* Generation plant related sets and parameters
  exist noExist commit new neverBuild nigen sigen possibleToBuild validYrBuild linearPlantBuild integerPlantBuild validYrOperate
  exogMWretired possibleToEndogRetire possibleToRetire possibleToRefurbish continueAftaEndogRetire peakConPlant NWpeakConPlant
  endogenousRetireDecisnYrs endogenousRetireYrs movers i_nameplate i_heatRate initialCapacity maxCapFactPlant minCapFactPlant AnnualMWlimit
  i_minUtilisation i_minUtilByTech i_maxNrgByFuel renNrgShrOn i_renewNrgShare i_renewCapShare i_VOLLcap i_VOLLcost i_fof
  i_distdGenRenew i_distdGenFossil i_pumpedHydroEffic i_PumpedHydroMonth i_UnitLargestProp
* Load and peak
  hoursPerBlock AClossFactors scenarioNRGfactor i_NrgDemand NrgDemand ldcMW scenarioPeakLoadFactor peakLoadNZ peakLoadNI
* Transmission and grid
  DCloadFlow transitions validTransitions allowedStates upgradedStates i_txCapacity
  slope intercept bigLoss bigM susceptanceYr BBincidence regLower validTGC i_txGrpConstraintsLHS i_txGrpConstraintsRHS
* Reserves
  useReserves singleReservesReqF i_maxReservesTrnsfr i_reserveReqMW i_propWindCover windCoverPropn reservesCapability i_offlineReserve
* Hydro related sets and parameters
  hydroOutputScalar allModelledHydroOutput mapHydroYearsToModelledYears
* Penalties
  penaltyViolatePeakLoad, penaltyViolateRenNrg, penaltyViolateReserves
*+++++++++++++++++++++++++
* More non-free reserves code.
  stp pNFresvCap pNFresvCost
*+++++++++++++++++++++++++
  ;

bat.ap = 0 ;
putclose bat
  'copy "Selected prepared input data - %runName% - %runVersionName%.gdx" "%OutPath%\%runName%\Input data checks\"' /
  'copy "GEMsolve.log"                                                    "%OutPath%\%runName%\%runName% - %runVersionName% - GEMsolve.log"' /
  ;
execute 'temp.bat' ;



$stop
*===============================================================================================
*  x. Move MIPtrace files to output directory and generate miptrace.bat.

$if not %PlotMIPtrace%==1 $goto NoTrace
* Copy current MIPtrace files from the programs to the Traceplots directory, and erase MIPtrace files from programs directory. 
putclose bat 'copy "%runName%-%runVersionName%-MIPtrace*.txt" "%OutPath%\%runName%\Traceplots"' / 'erase *MIPtrace*.txt' ;
execute 'temp.bat';

* Create the batch file to call Matlab to make the MIPtrace plots - note that miptrace.bat will be invoked from RunGem.gms.
if(%MexOrMat% = 1,
  putclose miptrace '"%MatCodePath%plot_all_objective_traces.exe" "%OutPath%\%runName%\Traceplots" "%runName%" "%Solver% trace"' ;
  else
  putclose miptrace "call matlab /r ", '"plot_all_objective_traces(', "'%OutPath%\%runName%\Traceplots','%runName%',","'%Solver% trace'); exit", '"' ;
) ;
$label NoTrace



*===============================================================================================
*  x. Create an awk script which, when executed, will produce a file containing the number of integer solutions per MIP model.

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
