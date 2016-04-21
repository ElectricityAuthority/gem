*+++ Model +++
$setglobal firstYear 2016
* First modelled year.
$setglobal lastYear 2050
* Last modelled year.
$setglobal RunType 2
* default = 0 = run both GEM and DISP, 1 = Run GEM only, 2 = Run DISPatch only
$setglobal GEMtype MIP
* Specify whether GEM is to be a MIP or an RMIP - take care to get the spelling exact (default = MIP).
$setglobal DISPtype RMIP
* Specify whether DISP is to be a MIP or an RMIP - take care to get the spelling exact (default = RMIP).

$setglobal calcInputLRMCs 1
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
Scalar randomCapexCostAdjuster / .03 / ;


*+++ GemConstraints +++
Scalar txLossesRMIP / 0 / ;
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
$setglobal NumVertices 3
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
* Choose solver - Gurobi, Cplex, or Xpress
*$setglobal optcr .0075
$setglobal optcr .01
* Relative optimality criterion for MIP (i.e. .003 equals .3%)
$setglobal CPUsecsGEM 50400
* CPU seconds available for solver to spend solving GEM
$setglobal Threads 4
* Number of threads your MIP solver is licensed to use.
$setglobal limitOutput 0
* Set to 1 to limit the amount of output written to the listing file
