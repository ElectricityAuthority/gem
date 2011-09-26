*+++ Model +++
$setglobal firstYear 2012
* First modelled year.
$setglobal lastYear 2025
* Last modelled year.
$setglobal RunType 1
* default = 0 = run both GEM and DISP, 1 = Run GEM only, 2 = Run DISPatch only
$setglobal GEMtype MIP
* Specify whether GEM is to be a MIP or an RMIP - take care to get the spelling exact (default = MIP).
$setglobal DISPtype RMIP
* Specify whether DISP is to be a MIP or an RMIP - take care to get the spelling exact (default = RMIP).
$setglobal SuppressReopt 1
* Select 1 when in GEM/DISP or GEM-only mode (i.e. RunType = 0 or 1) to skip re-optimisation of the GEM MIP; Otherwise select 0 to invoke re-optimisation.
$setglobal SprsRenShrReo 0
* Select 1 to suppress the renewable energy share constraint when/if solving the re-optimisation (REO) model; 0 otherwise.
$setglobal SprsRenShrDis 1
* Select 1 to suppress the renewable energy share constraint when/if solving the simulation (DISP) model; 0 otherwise.  
$setglobal GRschedule 1
* Select 1 to write out a GAMS-readable schedule of varibales to be used to fix levels in subsequent models.
$setglobal LimHydYr 4
* (default = 100) Limit the number of Hydro years to solve the DISP model over, i.e. restrict to 5, say, to get a quick turnaround.
$setglobal calcInputLRMCs 0


*+++ Hydrology +++
Scalar hydroOutputScalar / .97 / ;


*+++ CapitalExpenditure +++
Scalar WACCg / .07 / ;
Scalar WACCt / .07 / ;
Scalar discRateLow  / .04 / ;
Scalar discRateMed  / .07 / ;
Scalar discRateHigh / .10 / ;
Scalar taxRate / .28 / ;
Scalar depType / 1 / ;
Scalar txPlantLife / 60 / ;
Scalar txDepRate / .06 / ;
Scalar randomCapexCostAdjuster / 0 / ;


*+++ GemConstraints +++
Scalar cGenYr / 2025 / ;
Scalar AnnualMWlimit / 1000 / ;
Scalar noRetire / 2 / ;
Scalar renNrgShrOn / 1 / ;
Scalar penaltyViolatePeakLoad / 4000 / ;
Scalar penaltyViolateRenNrg / 400 / ;
Scalar slackCost / 9999 / ;
Scalar noVOLLblks / 3 / ;
Scalar DCloadFlow / 0 / ;
Scalar useReserves / 0 / ;
$setglobal NumVertices 4
* Number of vertices for piecewise linear transmission losses function (number of vertices = number of segments  + l) ;  


*+++ Load +++
*$setglobal AClossesNI 0.0368
*$setglobal AClossesNI 0.0120
$setglobal AClossesNI 0.0
* Upwards adjustment to load to account for NI AC (or intraregional) losses - .0368 for 2-region and .0120 for 18-region
*$setglobal AClossesSI 0.0534
*$setglobal AClossesSI 0.0180
$setglobal AClossesSI 0.0
* Upwards adjustment to load to account for SI AC (or intraregional) losses - .0534 for 2-region and .0180 for 18-region


*+++ Solver +++
$setglobal Solver Cplex
* Specify which LP and MIP solver to use - Cplex, Gurobi, or Xpress.
$setglobal SolveGoal QDsol
* Select either QDsol, VGsol, or MinGap
$setglobal QDoptCr .0075
* Quick and dirty relative optimality criterion for MIP (i.e. .003 equals .3%)
$setglobal QDsolSecs 1500
* CPU seconds available for solver to spend solving GEM for solve goal QDsol.
$setglobal VGsolSecs 7200
* CPU seconds available for solver to spend solving GEM for solve goal VGsol.
$setglobal Threads 4
* Number of threads your MIP solver is licensed to use.
$setglobal MinGapSecs 10800
* CPU seconds available for solver to spend solving GEM for solve goal MinGap.
$setglobal limitOutput 0
* Set to 1 to limit the amount of output written to the listing file


*+++ Plots +++
$setglobal MexOrMat 1
* 1 to use .mex executable for Matlab figures, 0 to use Matlab and source codes. All other values are illegal.
$setglobal PlotInFigures 0
* 1 to generate plots of various model inputs; 0 to prevent the generation of such plots.
$setglobal PlotOutFigures 0
* 1 to generate plots of various model outputs; 0 to prevent the generation of such plots.
$setglobal PlotMIPtrace 0
* 1 to generate MIPtrace plots; 0 to prevent the generation of MIPtrace plots.
$setglobal FigureTitles 0
* 1 to put titles on the figures, 0 to suppress the use of titles, any other value is illegal.
