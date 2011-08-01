* GEMsolve.gms

* Last modified by Dr Phil Bishop, 01/08/2011 (imm@ea.govt.nz)

*** To do:
*** Make sure the writing of GEMdataGDX is all that it should be
*** Sort out the MIPtrace stuff
*** Sort out GEMsolve.log. Where does it go and how does it get there?
*** does each model type have the correct modelstat error condition driving the abort stmt?
*** The abort if slacks present has gone. Bring it back? Warning if penalties?

$ontext
 This program continues sequentially from GEMdata. The GEMdata work file must be called
 at invocation. Note that GEMdata was invoked by restarting from the GEMGEMdeclarations
 work file. This program is followed by GEMreports.

 Code sections:
  1. Take care of preliminaries.
  2. Prepare the outcome-dependent input data; key user-specified settings are obtained from GEMstochastic.inc.
  3. Write the GEMdataGDX file.
  4. Set bounds, initial levels and, in some cases, fix variables to a specified level.
  5. Loop through all the solves
  6. Prepare results to pass along to GEMreports in the form of a GDX file. 
  7. Dump results out to GDX files and rename/relocate certain output files.


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

putclose rep 'Run: "%runName%"' / 'Scenario: "%scenarioName%"' / '  - started at ', system.time, ' on ' system.date ;

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
* 2. Prepare the outcome-dependent input data; key user-specified settings are obtained from GEMstochastic.inc.

$include GEMstochastic.gms

* Pro-rate weightOutcomesBySet values so that weights sum to exactly one for each outcomeSets:
counter = 0 ;
loop(outcomeSets,
  counter = sum(outcomes, weightOutcomesBySet(outcomeSets,outcomes)) ;
  weightOutcomesBySet(outcomeSets,outcomes)$counter = weightOutcomesBySet(outcomeSets,outcomes) / counter ;
  counter = 0 ;
) ;

* Compute the short-run marginal cost (and its components) for each generating plant, $/MWh.
totalFuelCost(g,y,outcomes) = 1e-3 * i_heatrate(g) * sum(mapg_f(g,f), ( i_fuelPrices(f,y) * outcomeFuelCostFactor(outcomes) + i_FuelDeliveryCost(g) ) ) ;

CO2taxByPlant(g,y,outcomes) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_co2tax(y) * outcomeCO2TaxFactor(outcomes) * (1 - i_CCSfactor(y,k)) * i_emissionFactors(f) ) ;

CO2CaptureStorageCost(g,y) = 1e-9 * i_heatrate(g) * sum((mapg_f(g,f),mapg_k(g,k)), i_CCScost(y,k) * i_CCSfactor(y,k) * i_emissionFactors(f) ) ;

SRMC(g,y,outcomes) = i_varOM(g) + totalFuelCost(g,y,outcomes) + CO2taxByPlant(g,y,outcomes) + CO2CaptureStorageCost(g,y) ;

* If SRMC is zero or negligible (< .05) for any plant, assign a positive small value.
SRMC(g,y,outcomes)$( SRMC(g,y,outcomes) < .05 ) = 1e-3 * ord(g) / card(g) ;

* Capture the island-wide AC loss adjustment factors.
AClossFactors('ni') = %AClossesNI% ;
AClossFactors('si') = %AClossesSI% ;

* Transfer i_NrgDemand to NrgDemand and adjust for intraregional AC transmission losses and the outcome-specific energy factor.
NrgDemand(r,y,t,lb,outcomes) = sum(mapild_r(ild,r), (1 + AClossFactors(ild)) * i_NrgDemand(r,y,t,lb)) * outcomeNRGfactor(outcomes) ;

* Use the GWh of NrgDemand and hours per LDC block to compute ldcMW (MW).
ldcMW(r,y,t,lb,outcomes)$hoursPerBlock(t,lb) = 1e3 * NrgDemand(r,y,t,lb,outcomes) / hoursPerBlock(t,lb) ;

* Transfer i_peakLoadNZ/NI to peakLoadNZ/NI and adjust for embedded generation and the outcome-specific peak load factor.
peakLoadNZ(y,outcomes) = ( i_peakLoadNZ(y) + %embedAdjNZ% ) * outcomePeakLoadFactor(outcomes) ;
peakLoadNI(y,outcomes) = ( i_peakLoadNI(y) + %embedAdjNI% ) * outcomePeakLoadFactor(outcomes) ;

* Transfer hydro output for all hydro years from i_historicalHydroOutput to historicalHydroOutput (no outcome-specific adjustment factors at this time).
historicalHydroOutput(v,hY,m) = i_historicalHydroOutput(v,hY,m) ;



*===============================================================================================
* 3. Write the GEMdataGDX file.

* NB: The following symbols from input data file may have been changed in GEMdata.
*     Sets: y, exist, commit, new, neverBuild
*     Parameters: i_nrgtxCapacity, i_txCapacityPO

Execute_Unload "%GEMdataGDX%",
*+++++++++++++++++++++++++
* More code to do the non-free reserves stuff. 
  freeReserves nonFreeReservesCap bigSwd bigNwd pNFresvCap pNFresvCost
*+++++++++++++++++++++++++
* Sets
* Re-declared and initialised
  y ct d dt n
* Time/date-related sets
  firstYr lastYr allButFirstYr firstPeriod
* Various mappings, subsets and counts.
  mapg_k mapg_f mapg_o mapg_i mapg_r mapg_e mapg_ild mapg_fc mapi_r mapi_e mapild_r mapv_g thermalFuel
* Financial
* Fuel prices and quantity limits.
* Generation data.
  exist commit new neverBuild
  noExist nigen sigen schedHydroPlant pumpedHydroPlant moverExceptions validYrBuild integerPlantBuild linearPlantBuild
  possibleToBuild possibleToRefurbish possibleToEndogRetire possibleToRetire endogenousRetireDecisnYrs endogenousRetireYrs
  validYrOperate
* Load data.
* Transmission data.
  slackBus regLower interIsland nwd swd paths uniPaths biPaths transitions validTransitions allowedStates notAllowedStates
  upgradedStates txEarlyComYrSet txFixedComYrSet validTGC nSegment
* Parameters
* Time/date-related sets and parameters.
  lastYear yearNum hydroYearNum lastHydroYear hoursPerBlock
* Various mappings, subsets and counts.
  numReg
* Financial parameters.
  CBAdiscountRates PVfacG PVfacT PVfacsM PVfacsEY PVfacs capexLife annuityFacN annuityFacR txAnnuityFacN txAnnuityFacR
  capRecFac depTCrecFac txCapRecFac txDeptCRecFac
* Fuel prices and quantity limits.
  SRMC totalFuelCost CO2taxByPlant CO2CaptureStorageCost
* Generation data.
  initialCapacity capitalCost capexPlant capCharge refurbCapexPlant refurbCapCharge exogMWretired continueAftaEndogRetire
  WtdAvgFOFmultiplier reservesCapability peakConPlant NWpeakConPlant maxCapFactPlant minCapFactPlant
* Load data.
  AClossFactors NrgDemand ldcMW peakLoadNZ peakLoadNI bigNIgen nxtbigNIgen
* Transmission data.
  locFac_Recip txEarlyComYr txFixedComYr reactanceYr susceptanceYr BBincidence pCap pLoss bigLoss slope intercept
  txCapitalCost txCapCharge
* Reserve energy data.
  reservesAreas reserveViolationPenalty windCoverPropn bigM singleReservesReqF
* Hydrology output data.
  historicalHydroOutput
  ;



*===============================================================================================
* 4. Set bounds, initial levels and, in some cases, fix variables to a specified level.

* Fix CGEN to zero for all years less than cGenYr and fix BGEN to zero for all years greater than or equal to cGenYr.
CGEN.up(g,y) = 1 ;     CGEN.fx(g,y)$( yearNum(y) <  cGenYr ) = 0 ;
BGEN.up(g,y) = 1 ;     BGEN.fx(g,y)$( yearNum(y) >= cGenYr ) = 0 ;

* Restrict refurbishment cost to be zero in years prior to refurbishment.
REFURBCOST.fx(g,y)$( yearNum(y) < i_refurbDecisionYear(g) ) = 0 ;

* Restrict generation:
* Don't allow generation unless the unit is in validYrOperate; validYrOperate embodies the appropriate date for existing, committed, and new units.
GEN.fx(g,y,t,lb,outcomes)$( not validYrOperate(g,y,t) ) = 0 ;
* Force generation from the must-run plant, i.e base load (convert MW capacity to GWh for each load block).
GEN.fx(g,y,t,lb,outcomes)$( ( exist(g) or commit(g) ) * i_baseload(g) * validYrOperate(g,y,t) ) =
1e-3 * hoursPerBlock(t,lb) * i_nameplate(g) * maxCapFactPlant(g,t,lb) ;

* Place restrictions on VOLL plants:
VOLLGEN.up(s,y,t,lb,outcomes) = 1e-3 * hoursPerBlock(t,lb) * i_VOLLcap(s) ;  ! Respect the capacity of VOLL plants
VOLLGEN.fx(s,y,t,lb,outcomes)$( ord(lb) <= noVOLLblks ) = 0 ;                ! Don't allow VOLL in user-specified top load blocks 

* Fix bounds on TX according to the largest capacity allowed in any state. Lower bound must be zero if transportation formulation is being used.
TX.lo(paths,y,t,lb,outcomes) = -smax(ps, i_txCapacity(paths,ps)) ;
TX.lo(paths,y,t,lb,outcomes)$(DCloadFlow = 0) = 0 ;
TX.up(paths,y,t,lb,outcomes) = +smax(ps, i_txCapacity(paths,ps)) ;

* Fix the reference bus angle to zero (only used in case of DC load flow formulation).
THETA.fx(slackBus(r),y,t,lb,outcomes) = 0 ;

* Fix various reserves variables to zero if they are not needed.
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
RESV.fx(g,rc,y,t,lb,outcomes)$( not validYrOperate(g,y,t) ) = 0 ;



*===============================================================================================
* 5. Loop through all the solves

$set AddUpSlacks    "sum(y, ANNMWSLACK.l(y) + RENCAPSLACK.l(y) + HYDROSLACK.l(y) + MINUTILSLACK.l(y) + FUELSLACK.l(y) )"
$set AddUpPenalties "sum((y,oc), PEAK_NZ_PENALTY.l(y,oc) + PEAK_NI_PENALTY.l(y,oc) + NOWINDPEAK_NZ_PENALTY.l(y,oc) + NOWINDPEAK_NI_PENALTY.l(y,oc) )"

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

*   Third, loop over each outcomeSet for this step of the experiment.
    loop(allSolves(experiments,steps,outcomeSets),

*     Initialise the desired outcomes for this solve
      oc(outcomes) = no ;
      oc(outcomes)$mapOutcomes(outcomeSets,outcomes) = yes ;

*     Select the appropriate outcome weight.
      outcomeWeight(oc) = 0 ;
      outcomeWeight(oc) = weightOutcomesBySet(outcomeSets,oc) ;
      display 'Outcome and weight for this solve:', oc, outcomeWeight ;

*     Compute the hydro output values to use for the selected outcomes (NB: only works for hydroSeqTypes={same,sequential}).
      modelledHydroOutput(g,y,t,outcomes) = 0 ;
      loop(oc(outcomes),
        if(mapOC_hydroSeqTypes(outcomes,'same'),
          modelledHydroOutput(g,y,t,outcomes) = hydroOutputScalar * i_hydroOutputAdj(y) *
            sum((mapv_g(v,g),mapm_t(m,t),hY)$(mapOC_hY(outcomes,hY)), historicalHydroOutput(v,hY,m)) / sum(mapOC_hY(outcomes,hY1), 1) ;
          mapHydroYearsToModelledYears(experiments,steps,outcomeSets,oc,y,hY)$( ord(hY) = sum(mapOC_hY(outcomes,hY1), 1) ) = yes ;
          else
          loop(y,
            chooseHydroYears(hY) = no ;
            chooseHydroYears(hY)$(sum(hY1$(mapOC_hY(outcomes, hY1) and ord(hY1) + ord(y) - 1            = ord(hY)), 1)) = yes ;
            chooseHydroYears(hY)$(sum(hY1$(mapOC_hY(outcomes, hY1) and ord(hY1) + ord(y) - 1 - card(hY) = ord(hY)), 1)) = yes ;
            modelledHydroOutput(g,y,t,oc) =
              i_hydroOutputAdj(y) * sum((mapv_g(v,g),mapm_t(m,t),chooseHydroYears), historicalHydroOutput(v,chooseHydroYears,m)) / sum(chooseHydroYears, 1) ;
            mapHydroYearsToModelledYears(experiments,steps,outcomeSets,oc,y,chooseHydroYears) = yes ;
          ) ;
        ) ;
      ) ;
      display 'Hydro output:', modelledHydroOutput ;

*     Collect modelledHydroOutput for posterity.
      allModelledHydroOutput(experiments,steps,outcomeSets,g,y,t,oc) = modelledHydroOutput(g,y,t,oc) ;

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
        putclose rep // 'The ' experiments.tl ' - ' steps.tl ' - ' outcomeSets.tl ' solve finished with some sort of problem and the job is now going to abort.' /
                        'Examine GEMsolve.lst and/or GEMsolve.log to see what went wrong.' ;
        else
        putclose rep // 'The ' experiments.tl ' - ' steps.tl ' - ' outcomeSets.tl ' solve finished at ', system.time / 'Objective function value: ' TOTALCOST.l:<12:1 / ;
      ) ;
      putclose con // '    The ' experiments.tl ' - ' steps.tl ' - ' outcomeSets.tl ' solve for "%runName% -- %scenarioName% has just finished' /
                      '    Objective function value: ' TOTALCOST.l:<12:1 // ;

      if(sameas(steps,'dispatch'),
        abort$( DISP.modelstat <> 1 and DISP.modelstat <> 8 ) "Problem encountered when solving DISP..." ;
        else
        abort$( GEM.modelstat = 10 ) "GEM is infeasible - check out GEMsolve.log to see what you've done wrong in configuring a model that is infeasible" ;
        abort$( GEM.modelstat <> 1 and GEM.modelstat <> 8 ) "Problem encountered solving GEM..." ;
      ) ;

*     Generate a MIP trace file when MIPtrace is equal to 1 (MIPtrace specified in GEMsettings).
$     if not %PlotMIPtrace%==1 $goto NoTrace3
      putclose bat 'copy MIPtrace.txt "%runName%-%scenarioName%-MIPtrace-' experiments.tl ' - ' steps.tl ' - ' outcomeSets.tl '.txt"' ;
      execute 'temp.bat';
$     label NoTrace3

*     Collect information for solve summary report
      solveReport(allSolves,'ObjFnValue') = TOTALCOST.l ;    solveReport(allSolves,'OCcosts') = sum(oc(outcomes), OUTCOME_COSTS.l(oc) ) ;
      solveReport(allSolves,'OptFile')    = gem.optfile ;    solveReport(allSolves,'OptCr')   = gem.optcr ;
      solveReport(allSolves,'ModStat')    = gem.modelstat ;  solveReport(allSolves,'SolStat') = gem.solvestat ;
      solveReport(allSolves,'Vars')       = gem.numvar ;     solveReport(allSolves,'DVars')   = gem.numdvar ;
      solveReport(allSolves,'Eqns')       = gem.numequ ;     solveReport(allSolves,'Iter')    = gem.iterusd ;
      solveReport(allSolves,'Time')       = gem.resusd ;     solveReport(allSolves,'GapAbs')  = abs( gem.objest - gem.objval ) ;
      solveReport(allSolves,'Gap%')$gem.objval = 100 * abs( gem.objest - gem.objval ) / gem.objval ;
      if(slacks > 0,    solveReport(allSolves,'Slacks') = 1    else solveReport(allSolves,'Slacks') = -99 ) ;
      if(penalties > 0, solveReport(allSolves,'Penalties') = 1 else solveReport(allSolves,'Penalties') = -99 ) ;
      display 'solve report:', slacks, penalties, solveReport ;

*     Collect up solution values - by experiment, step and outcomeSet.
$     include CollectResults.txt

*   End of OutcomeSet loop.
    ) ;

* End of steps loop.
  ) ;

* End of experiments loop.
) ;



*===============================================================================================
* 6. Prepare results to pass along to GEMreports in the form of a GDX file. 
*    The 's_' solution values are averaged over all outcomeSets in an experiment. Hence, we lose the 'outcomeSets' domain.

loop(experiments,

  loop(steps,

    sumSolves(outcomeSets) = no;
    sumSolves(outcomeSets)$allSolves(experiments,steps,outcomeSets) = yes;
    numSolves = sum(sumSolves, 1);

    s2_TOTALCOST(experiments,steps)$numSolves                          = sum(sumSolves, s_TOTALCOST(experiments,steps,sumSolves)) / numSolves ;
    s2_OUTCOME_COSTS(experiments,steps,oc)$numSolves                   = sum(sumSolves, s_OUTCOME_COSTS(experiments,steps,sumSolves,oc)) / numSolves ;
    s2_TX(experiments,steps,paths,y,t,lb,oc)$numSolves                 = sum(sumSolves, s_TX(experiments,steps,sumSolves,paths,y,t,lb,oc) ) / numSolves ;
    s2_BRET(experiments,steps,g,y)$numSolves                           = sum(sumSolves, s_BRET(experiments,steps,sumSolves,g,y) ) / numSolves ;
    s2_ISRETIRED(experiments,steps,g)$numSolves                        = sum(sumSolves, s_ISRETIRED(experiments,steps,sumSolves,g) ) / numSolves ;
    s2_BTX(experiments,steps,paths,ps,y)$numSolves                     = sum(sumSolves, s_BTX(experiments,steps,sumSolves,paths,ps,y) ) / numSolves ;
    s2_REFURBCOST(experiments,steps,g,y)$numSolves                     = sum(sumSolves, s_REFURBCOST(experiments,steps,sumSolves,g,y) ) / numSolves ;
    s2_BUILD(experiments,steps,g,y)$numSolves                          = sum(sumSolves, s_BUILD(experiments,steps,sumSolves,g,y) ) / numSolves ;
    s2_RETIRE(experiments,steps,g,y)$numSolves                         = sum(sumSolves, s_RETIRE(experiments,steps,sumSolves,g,y) ) / numSolves ;
    s2_CAPACITY(experiments,steps,g,y)$numSolves                       = sum(sumSolves, s_CAPACITY(experiments,steps,sumSolves,g,y) ) / numSolves ;
    s2_TXCAPCHARGES(experiments,steps,paths,y)$numSolves               = sum(sumSolves, s_TXCAPCHARGES(experiments,steps,sumSolves,paths,y) ) / numSolves ;
    s2_GEN(experiments,steps,g,y,t,lb,oc)$numSolves                    = sum(sumSolves, s_GEN(experiments,steps,sumSolves,g,y,t,lb,oc) ) / numSolves ;
    s2_VOLLGEN(experiments,steps,s,y,t,lb,oc)$numSolves                = sum(sumSolves, s_VOLLGEN(experiments,steps,sumSolves,s,y,t,lb,oc) ) / numSolves ;
    s2_PUMPEDGEN(experiments,steps,g,y,t,lb,oc)$numSolves              = sum(sumSolves, s_PUMPEDGEN(experiments,steps,sumSolves,g,y,t,lb,oc) ) / numSolves ;
    s2_LOSS(experiments,steps,paths,y,t,lb,oc)$numSolves               = sum(sumSolves, s_LOSS(experiments,steps,sumSolves,paths,y,t,lb,oc) ) / numSolves ;
    s2_TXPROJVAR(experiments,steps,tupg,y)$numSolves                   = sum(sumSolves, s_TXPROJVAR(experiments,steps,sumSolves,tupg,y) ) / numSolves ;
    s2_TXUPGRADE(experiments,steps,paths,ps,pss,y)$numSolves           = sum(sumSolves, s_TXUPGRADE(experiments,steps,sumSolves,paths,ps,pss,y) ) / numSolves ;
    s2_RESV(experiments,steps,g,rc,y,t,lb,oc)$numSolves                = sum(sumSolves, s_RESV(experiments,steps,sumSolves,g,rc,y,t,lb,oc) ) / numSolves ;
    s2_RESVVIOL(experiments,steps,rc,ild,y,t,lb,oc)$numSolves          = sum(sumSolves, s_RESVVIOL(experiments,steps,sumSolves,rc,ild,y,t,lb,oc) ) / numSolves ;
    s2_RESVTRFR(experiments,steps,rc,ild,ild1,y,t,lb,oc)$numSolves     = sum(sumSolves, s_RESVTRFR(experiments,steps,sumSolves,rc,ild,ild1,y,t,lb,oc) ) / numSolves ;
    s2_RENNRGPENALTY(experiments,steps,y)$numSolves                    = sum(sumSolves, s_RENNRGPENALTY(experiments,steps,sumSolves,y) ) / numSolves ;
    s2_PEAK_NZ_PENALTY(experiments,steps,y,oc)$numSolves               = sum(sumSolves, s_PEAK_NZ_PENALTY(experiments,steps,sumSolves,y,oc) ) / numSolves ;
    s2_PEAK_NI_PENALTY(experiments,steps,y,oc)$numSolves               = sum(sumSolves, s_PEAK_NI_PENALTY(experiments,steps,sumSolves,y,oc) ) / numSolves ;
    s2_NOWINDPEAK_NZ_PENALTY(experiments,steps,y,oc)$numSolves         = sum(sumSolves, s_NOWINDPEAK_NZ_PENALTY(experiments,steps,sumSolves,y,oc) ) / numSolves ;
    s2_NOWINDPEAK_NI_PENALTY(experiments,steps,y,oc)$numSolves         = sum(sumSolves, s_NOWINDPEAK_NI_PENALTY(experiments,steps,sumSolves,y,oc) ) / numSolves ;
    s2_ANNMWSLACK(experiments,steps,y)$numSolves                       = sum(sumSolves, s_ANNMWSLACK(experiments,steps,sumSolves,y) ) / numSolves ;
    s2_RENCAPSLACK(experiments,steps,y)$numSolves                      = sum(sumSolves, s_RENCAPSLACK(experiments,steps,sumSolves,y) ) / numSolves ;
    s2_HYDROSLACK(experiments,steps,y)$numSolves                       = sum(sumSolves, s_HYDROSLACK(experiments,steps,sumSolves,y) ) / numSolves ;
    s2_MINUTILSLACK(experiments,steps,y)$numSolves                     = sum(sumSolves, s_MINUTILSLACK(experiments,steps,sumSolves,y) ) / numSolves ;
    s2_FUELSLACK(experiments,steps,y)$numSolves                        = sum(sumSolves, s_FUELSLACK(experiments,steps,sumSolves,y) ) / numSolves ;
    s2_bal_supdem(experiments,steps,r,y,t,lb,oc)$numSolves             = sum(sumSolves, s_bal_supdem(experiments,steps,sumSolves,r,y,t,lb,oc) ) / numSolves ;
*++++++++++
* More non-free reserves code.
    s2_RESVCOMPONENTS(experiments,steps,paths,y,t,lb,outcomes,stp)$numSolves = sum(sumSolves, s_RESVCOMPONENTS(experiments,steps,sumSolves,paths,y,t,lb,outcomes,stp) ) / numSolves ;
*++++++++++

* End of steps loop
  ) ;

* End of experiments loop
) ;

Display s2_TOTALCOST, solveReport ;



*===============================================================================================
* 7. Dump results out to GDX files and rename/relocate certain output files.

* a) Dump output prepared for report writing into a GDX file (essentially, the 's2' parameters).
Execute_Unload "PreparedOutput - %runName% - %scenarioName%.gdx",
* Miscellaneous sets and parameters
  solveGoal experiments steps oc solveReport
* The 's2' output parameters
  s2_TOTALCOST s2_OUTCOME_COSTS s2_TX s2_BRET s2_ISRETIRED s2_BTX s2_REFURBCOST s2_BUILD s2_RETIRE s2_CAPACITY s2_TXCAPCHARGES
  s2_GEN s2_VOLLGEN s2_PUMPEDGEN s2_LOSS s2_TXPROJVAR s2_TXUPGRADE s2_RESV s2_RESVVIOL s2_RESVTRFR s2_bal_supdem
*++++++++++
* More non-free reserves code.
  s2_RESVCOMPONENTS
*++++++++++
* The 's2' penalties.
  s2_RENNRGPENALTY s2_PEAK_NZ_PENALTY s2_PEAK_NI_PENALTY s2_NOWINDPEAK_NZ_PENALTY s2_NOWINDPEAK_NI_PENALTY
* The 's2' slacks.
  s2_ANNMWSLACK s2_RENCAPSLACK s2_HYDROSLACK s2_MINUTILSLACK s2_FUELSLACK
  ;


* b) Dump all 's' slacks and penalties into a GDX file.
Execute_Unload "Slacks and penalties - %runName% - %scenarioName%.gdx",
  s_RENNRGPENALTY s_PEAK_NZ_PENALTY s_PEAK_NI_PENALTY s_NOWINDPEAK_NZ_PENALTY s_NOWINDPEAK_NI_PENALTY
  s_ANNMWSLACK s_RENCAPSLACK s_HYDROSLACK s_MINUTILSLACK s_FUELSLACK
  ;


* c) Dump all variable levels and constraint marginals into a GDX file (ignore the objective function marginal).
Execute_Unload "Levels and marginals - %runName% - %scenarioName%.gdx",
*+++++++++++++++++++++++++
* More non-free reserves code.
  s_RESVCOMPONENTS s_calc_nfreserves s_resv_capacity
*+++++++++++++++++++++++++
* Free variables.
  s_TOTALCOST s_OUTCOME_COSTS s_TX s_THETA
* Binary variables.
  s_BGEN s_BRET s_ISRETIRED s_BTX s_NORESVTRFR
* Positive variables (sans the reserves-related variables).
  s_REFURBCOST s_GENBLDCONT s_CGEN s_BUILD s_RETIRE s_CAPACITY s_TXCAPCHARGES s_GEN s_VOLLGEN s_PUMPEDGEN s_SPILL s_LOSS
  s_TXPROJVAR s_TXUPGRADE
* Reserve variables.
  s_RESV s_RESVVIOL s_RESVTRFR s_RESVREQINT
* Penalty variables.
  s_RENNRGPENALTY s_PEAK_NZ_PENALTY s_PEAK_NI_PENALTY s_NOWINDPEAK_NZ_PENALTY s_NOWINDPEAK_NI_PENALTY
* Slack variables.
  s_ANNMWSLACK s_RENCAPSLACK s_HYDROSLACK s_MINUTILSLACK s_FUELSLACK
* Equation marginals. 
  s_calc_outcomeCosts s_calc_refurbcost s_calc_txcapcharges s_bldgenonce s_buildcapint s_buildcapcont s_annnewmwcap s_endogpltretire
  s_endogretonce s_balance_capacity s_bal_supdem s_peak_nz s_peak_ni s_noWindPEak_nz s_noWindPeak_ni s_limit_maxgen s_limit_mingen
  s_minutil s_limit_fueluse s_limit_nrg s_minreq_rennrg s_minreq_rencap s_limit_hydro s_limit_pumpgen1 s_limit_pumpgen2 s_limit_pumpgen3
  s_boundtxloss s_tx_capacity s_tx_projectdef s_tx_onestate s_tx_upgrade s_tx_oneupgrade s_tx_dcflow s_tx_dcflow0 s_equatetxloss
  s_txGrpConstraint s_resvsinglereq1 s_genmaxresv1 s_resvtrfr1 s_resvtrfr2 s_resvtrfr3 s_resvrequnit s_resvreq2 s_resvreqhvdc
  s_resvtrfr4 s_resvtrfrdef s_resvoffcap s_resvreqwind
  ;


* d) Dump selected input data into a GDX file (as imported, or from intermediate GEMdata steps, or what's actually used to solve the model).
*    NB: Some of what goes in here may also go into GEMdataGDX.
Execute_Unload "Selected prepared input data - %runName% - %scenarioName%.gdx",
* Basic sets, subsets, and mapping sets.
  y t f k g o lb r e ild ps outcomes rc n tgc
  mapg_k mapg_o mapg_e mapg_f maps_r mapg_r mapild_r paths nwd swd interIsland firstPeriod firstYr lastYr allButFirstYr pumpedHydroPlant wind gas diesel
  thermalFuel i_fuelQuantities renew schedHydroPlant nsegment demandGen 
  allSolves weightOutcomesBySet
* Financial, capex and cost related sets and parameters
  taxRate CBAdiscountRates PVfacG PVfacT PVfacsM PVfacsEY PVfacs capexLife annuityFacN annuityFacR TxAnnuityFacN TxAnnuityFacR
  capRecFac depTCrecFac txCapRecFac txDepTCrecFac i_capitalCost i_connectionCost capexPlant refurbCapexPlant
  capCharge refurbCapCharge txCapCharge
  bigNIgen nxtBigNIgen i_bigSIgen i_fkNI i_fkSI
  i_fixedOM i_HVDCshr i_HVDClevy srmc locFac_recip i_plantReservesCost
* Generation plant related sets and parameters
  exist noExist commit new nigen sigen possibleToBuild validYrBuild linearPlantBuild integerPlantBuild validYrOperate
  exogMWretired possibleToEndogRetire possibleToRetire possibleToRefurbish continueAftaEndogRetire peakConPlant NWpeakConPlant
  endogenousRetireDecisnYrs endogenousRetireYrs movers i_nameplate i_heatRate initialCapacity maxCapFactPlant minCapFactPlant AnnualMWlimit
  i_minUtilisation i_minUtilByTech i_maxNrgByFuel renNrgShrOn i_renewNrgShare i_renewCapShare i_VOLLcap i_VOLLcost i_fof
  i_distdGenRenew i_distdGenFossil i_pumpedHydroEffic i_PumpedHydroMonth i_UnitLargestProp
* Load and peak
  hoursPerBlock AClossFactors outcomeNRGfactor i_NrgDemand NrgDemand ldcMW i_peakLoadNZ i_peakLoadNI outcomePeakLoadFactor peakLoadNZ peakLoadNI
* Transmission and grid
  DCloadFlow gridSecurity transitions validTransitions allowedStates upgradedStates i_txCapacity i_HVDClosses i_northwardHVDCtransfer
  slope intercept bigLoss bigM susceptanceYr BBincidence regLower validTGC i_txGrpConstraintsLHS i_txGrpConstraintsRHS
* Reserves
  useReserves singleReservesReqF i_maxReservesTrnsfr i_reserveReqMW i_propWindCover windCoverPropn reservesCapability i_offlineReserve
* Hydro related sets and parameters
  hydroOutputScalar i_hydroOutputAdj allModelledHydroOutput mapHydroYearsToModelledYears
* Penalties
  penaltyViolateRenNrg reserveViolationPenalty penaltyLostPeak
*+++++++++++++++++++++++++
* More non-free reserves code.
  stp pNFresvCap pNFresvCost
*+++++++++++++++++++++++++
  ;

bat.ap = 0 ;
putclose bat
  'copy "%ProgPath%%GEMdataGDX%"                                        "%OutPath%\%runName%\GDX\"' /
  'copy "PreparedOutput - %runName% - %scenarioName%.gdx"               "%OutPath%\%runName%\GDX\"' /
  'copy "Slacks and penalties - %runName% - %scenarioName%.gdx"         "%OutPath%\%runName%\GDX\"' /
  'copy "Levels and marginals - %runName% - %scenarioName%.gdx"         "%OutPath%\%runName%\GDX\"' /
  'copy "Selected prepared input data - %runName% - %scenarioName%.gdx" "%OutPath%\%runName%\Input data checks\"' /
  'copy "GEMsolve.log"                                                  "%OutPath%\%runName%\%runName% - %scenarioName% - GEMsolve.log"' /
  ;
execute 'temp.bat' ;



$stop
*===============================================================================================
*  x. Move MIPtrace files to output directory and generate miptrace.bat.

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
