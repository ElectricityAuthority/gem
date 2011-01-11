$inlinecom { }
$eolcom !
$setglobal ProgPath         "%system.fp%"
$setglobal DataPath         "%system.fp%..\Data\"
$setglobal MatCodePath      "%system.fp%..\Matlab code\"
$setglobal OutPath          "%system.fp%..\Output\"

$setglobal runName          "Test"

Set sc 'Scenarios'     / mds1 'MDS1', mds2 'MDS2' /;
Set scenarioColor(sc,*,*,*) 'RGB color mix for scenarios - to pass to plotting applications' ;
scenarioColor('mds1','0','0','255') = yes ;
scenarioColor('mds2','0','255','255') = yes ;

$setglobal firstScenario    "Final GEM2.0 input data (2Reg 9Block mds1).gdx"


*** Model ***
$setglobal firstYear 2010
* First modelled year.
$setglobal lastYear 2035
* Last modelled year.
$setglobal RunType 0
* default = 0 = run both GEM and DISP, 1 = Run GEM only, 2 = Run DISPatch only
$setglobal GEMtype RMIP
* Specify whether GEM is to be a MIP or an RMIP - take care to get the spelling exact (default = MIP).
$setglobal DISPtype RMIP
* Specify whether DISP is to be a MIP or an RMIP - take care to get the spelling exact (default = RMIP).
$setglobal SuppressReopt 1
* Select 1 when in GEM/DISP or GEM-only mode (i.e. RunType = 0 or 1) to skip re-optimisation of the GEM MIP; Otherwise select 0 to invoke re-optimisation.
$setglobal SprsRenShrReo 0
* Select 1 to suppress the renewable energy share constraint when/if solving the re-optimisation (REO) model; 0 otherwise.
$setglobal SprsRenShrDis 1
* Select 1 to suppress the renewable energy share constraint when/if solving the simulation (DISP) model; 0 otherwise.  
$setglobal LimHydYr 4
* (default = 100) Limit the number of Hydro years to solve the DISP model over, i.e. restrict to 5, say, to get a quick turnaround.
$setglobal Mode 0
* Select 0 to run with standard developer license; 1 to run with runtime license.  


*** Hydrology ***
$setglobal hydroYrForTiming Average
* inflow year used to determine timing of new builds. Choices are Multiple, Average, 1932, 1933, ... 2007
Scalar hydroOutputScalar / .97 / ;
$setglobal hydroYrForReopt 1932
* Hydro inflow year used to determine timing of new builds when re-optimising initial decision. 
$setglobal DInflowYr 0
* 
* Indicator used to determine hydroYrForDispatch, which in turn determines the hydro year looped over when                                      
* solving DISPatch and, therefore, the year used in the first modelled year to kick off development of                                      
* the hydro sequences for all modelled years (default = 0).                                      
* 0    --> use all hydro years including the average hydro year (but excluding the 'multiple' inflow year)                                      
* 1    --> use only the average hydro year                                      
* xxxx --> use the single hydro year indicated by xxxx (i.e. pick one from 1932...2007)
$setglobal DInflwYrType 1
* 
* Set equal to 1 or 2 to determine how the hydro sequence is developed, i.e. sequentially or constant (default = 1)                                      
* Note that DInflwYrType works in conjunction with DInflowYr. DInflowYr initiates the start of the sequence for the                                      
* first modelled year, while DInflwYrType controls how the initiated sequence develops for subsequent modelled years.                                      
* 1 --> hydro years are mapped into modelled years in sequence for each modelled year, e.g. if modelled year                                      
* 2010 started with hydro year 1932, then modelled year 2011 would use hydro year 1933, and the 2012                                      
* modelled year would use 1934 hydrology and so on and so on. DInflowYr determines how the sequence starts.                                      
* 2 --> the same, or constant, hydro year is used for each modelled year i.e. if looping over hydro year                                      
* 1951, say, then the 1951 hydro would be used for all modelled years from FirstYr to LastYr.                                      
* See 'XXX - hydro years mapped to modelled years.csv' for a complete enumeration.


*** CapitalExpenditure ***
Scalar WACCg / .08 / ;
Scalar WACCt / .08 / ;
Scalar taxRate / .3 / ;
Scalar depType / 1 / ;
Scalar txPlantLife / 60 / ;
Scalar txDepRate / .06 / ;
Scalar randomCapexCostAdjuster / 0 / ;


*** GemConstraints ***
Scalar cGenYr / 2025 / ;
Scalar AnnualMWlimit / 1000 / ;
Scalar noRetire / 2 / ;
Scalar gridSecurity / 1 / ;
Scalar renNrgShrOn / 1 / ;
Scalar penaltyViolateRenNrg / 0.4 / ;
Scalar noVOLLblks / 0 / ;
Scalar DCloadFlow / 0 / ;
Scalar useReserves / 0 / ;
$setglobal NumVertices 3
* Number of vertices for piecewise linear transmission losses function (number of vertices = number of segments  + l) ;  


*** Load ***
$setglobal GrowthProfile Medium
* User-specified load growth profile (Low, Medium, or High)
$setglobal AClossesNI 0.0368
* Upwards adjustment to load to account for NI AC (or intraregional) losses - .0368 for 2-region and .0120 for 18-region
$setglobal AClossesSI 0.0368
* Upwards adjustment to load to account for SI AC (or intraregional) losses - .0534 for 2-region and .0180 for 18-region
$setglobal EmbedAdjNZ 198
* MW added to NZ peak load to overcome potential double-counting of embedded generation
$setglobal EmbedAdjNI 144
* MW added to NI peak load to overcome potential double-counting of embedded generation


*** Solver ***
$setglobal Solver Cplex
* Specify which LP and MIP solver to use - Cplex, Gurobi, or Xpress.
$setglobal SolveGoal QDsol
* Select either QDsol, VGsol, or MinGap
$setglobal QDoptCr .0075
* Quick and dirty relative optimality criterion for MIP (i.e. .003 equals .3%)
$setglobal QDsolSecs 500
* CPU seconds available for solver to spend solving GEM for solve goal QDsol.
$setglobal VGsolSecs 7200
* CPU seconds available for solver to spend solving GEM for solve goal VGsol.
$setglobal Threads 4
* Number of threads your MIP solver is licensed to use.
$setglobal MinGapSecs 10800
* CPU seconds available for solver to spend solving GEM for solve goal MinGap.
$setglobal limitOutput 1
* Set to 1 to limit the amount of output written to the listing file


*** Plots ***
$setglobal MexOrMat 1
* 1 to use .mex executable for Matlab figures, 0 to use Matlab and source codes. All other values are illegal.
$setglobal PlotInFigures 0
* 1 to generate plots of various model inputs; 0 to prevent the generation of such plots.
$setglobal PlotOutFigures 1
* 1 to generate plots of various model outputs; 0 to prevent the generation of such plots.
$setglobal PlotMIPtrace 0
* 1 to generate MIPtrace plots; 0 to prevent the generation of MIPtrace plots.
$setglobal FigureTitles 0
* 1 to put titles on the figures, 0 to suppress the use of titles, any other value is illegal.