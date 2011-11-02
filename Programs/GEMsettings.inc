*+++ Model +++
$setglobal firstYear 2012
* First modelled year.
$setglobal lastYear 2025
* Last modelled year.
$setglobal RunType 1
* default = 0 = run both GEM and DISP, 1 = Run GEM only, 2 = Run DISPatch only
$setglobal GEMtype RMIP
* Specify whether GEM is to be a MIP or an RMIP - take care to get the spelling exact (default = MIP).
$setglobal DISPtype RMIP
* Specify whether DISP is to be a MIP or an RMIP - take care to get the spelling exact (default = RMIP).

$setglobal calcInputLRMCs 0
Scalar GRscheduleWrite / 1 / ;


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
Scalar V2GtechnologyOn / 0 / ;
Scalar renNrgShrOn / 0 / ;
Scalar renCapShrOn / 0 / ;
Scalar niNWpeakCnstrntOn / 0 / ;
Scalar limitNrgByFuelOn / 1 / ;
Scalar reservesOn / 0 / ;
Scalar DCloadFlowOn / 0 / ;
Scalar cGenYr / 2025 / ;
Scalar AnnualMWlimit / 1000 / ;
Scalar noRetire / 2 / ;
Scalar VOLLcap / 500 / ;
Scalar VOLLcost / 10000 / ;
Scalar penaltyViolatePeakLoad / 99999 / ;
Scalar penaltyViolateRenNrg / 99999 / ;

Scalar slackCost / 9999 / ;
Scalar noVOLLblks / 0 / ;
$setglobal NumVertices 4
* Number of vertices in piecewise linear transmission loss functions (number of vertices = number of tranches + l) ;  


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
$setglobal QDsolSecs 20000
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
