* runGEMwithoutGUI.gms

* Last modified by Dr Phil Bishop, 12/09/2011 (imm@ea.govt.nz)

$ontext
 Purpose:
 This file describes the process to manually operate GEM, i.e. without resort to emi. Manual operation of GEM may
 be undertaken using the GAMS IDE, or a text editor and the command line. Note that the files called GEMpathsAndFiles.inc,
 GEMsettings.inc and GEMstochastic.inc are produced automatically by emi and are used by GEM. If they haven't been deleted,
 they will reside in the GEM programs directory.
   
 Steps:
 1. Create or edit a file called GEMpathsAndFiles.inc, place it in the GEM programs directory, and invoke runGEMsetup.gms once.
    - Use the GEMpathsAndFiles.inc template below if no GEMpathsAndFiles.inc file can be found.
    - There is much in GEMpathsAndFiles.inc that controls how GEM is configured and solved, so edit it carefully.

 2. Create or edit a file called GEMsettings.inc and place it in the GEM programs directory.
    - Use the GEMsettings.inc template below if no GEMsettings.inc file can be found.
    - There is much in GEMsettings.inc that controls how GEM is configured and solved, so edit it carefully.

 3. Create or edit a file called GEMstochastic.inc and place it in the GEM programs directory.
    - Use the GEMstochastic.inc template below if no GEMstochastic.inc file can be found.
    - There is much in GEMstochastic.inc that controls how GEM is configured and solved, so edit it carefully.

 4. Invoke runGEMDataAndSolve.gms as many times as there are versions of the current run to be solved.
    - But before each invocation of runGEMDataAndSolve.gms, take special care to ensure that:
      - runVersionName, GEMinputGDX, GEMnetworkGDX, GEMdemandGDX in GEMpathsAndFiles.inc are specified in accordance with the
        model run being solved.
      - runName in GEMpathsAndFiles.inc should be identical and unchanged for all runs.
      - baseRunVersion and the set called 'runVersions' in GEMpathsAndFiles.inc are not important (i.e. not used) at this stage.

** need to edit from here on


 5. Prepare to generate reports by editing firstScenario and the sets called 'sc' and 'scenarioColor' in GEMsettings.inc.
    - firstScenario must be specified to be the GDX input file name corresponding to the first scenario solved.
      (whether or not the notion of a base case matters, the first scenario is assumed to be the base case.)
    - Each scenario previously solved and for which reporting is desired must be entered as elements in set sc:
        - specify both an element label (must be GAMS-compliant) and an element description. The description does
          not need to be the GDX input file name although common sense would suggest it might be similar.
    - Each scenario (member of set 'sc') must also be assigned an RGB colour code in the set called 'scenarioColor'. 

 6. Create a file called runMergeGDXs.gms, place it in the GEM programs directory, and invoke it once.
    - Use the runMergeGDXs.gms template below if no runMergeGDXs.gms file can be found.
    - For each of the 3 sets of commands (i.e. commands relating to raw input files, GEMdata GDX files, and prepared
      output GDX files), it is necessary to create a 'del', and 'copy' statement for each scenario. The short names
      of the files to be deleted and copied to must be the set element names from the set 'sc' in GEMsettings.inc (see
      note #4 above).
    - See also the notes in runMergeGDXs.gms.

 7. Invoke the file called runGEMreports.gms (it should be present in the GEM programs directory).
$offtext



*=== Templates ===
$ontext

* GEMpathsAndFiles.inc template:
$setglobal runName         "Test"
$setglobal runVersionName  "mds3"
$setglobal baseRunVersion  "mds3"

$setglobal GEMinputGDX     "standardGEMinput9LB.gdx"
$setglobal GEMnetworkGDX   "2RegionNetwork.gdx"
$setglobal GEMdemandGDX    "NRG_2Region9LB_Standard.gdx"

$setglobal GEMoverrideGDX  "mds1_Override.gdx"

$setglobal useOverrides     0
$setglobal Mode             0

$inlinecom { }
$eolcom !
$setglobal ProgPath        "%system.fp%"
$setglobal DataPath        "%system.fp%..\Data\"
$setglobal MatCodePath     "%system.fp%..\Matlab code\"
$setglobal OutPath         "%system.fp%..\Output\"


Set runVersions "Variants or instances of the run - all stored in the 'runName' output directory" /
  mds1 '2010 Sustainable path'
  mds2 '2010 SI wind'
  mds3 '2010 Medium renewables'
  mds4 '2010 Coal'
  mds5 '2010 High gas discovery' / ;

Set runVersionColor(runVersions,*,*,*) 'RGB color mix for the various versions comprising the run - to pass to plotting applications' ;
runVersionColor('mds1','0','0','255')   = yes ;
runVersionColor('mds2','255','0','0')   = yes ;
runVersionColor('mds3','0','255','0')   = yes ;
runVersionColor('mds4','0','0','0')     = yes ;
runVersionColor('mds5','255','0','255') = yes ;


* Set LogMode to 0 if it hasn't already been set to 1 via invocation, e.g. gams GEMsolve --LogMode=1
* 0 ==> GAMSIDE will display log info in process window, capture it, and then subsequently archive it.
* 1 ==> log info written to a log file and subsequently archived (log info not echoed to command prompt).
$if not set LogMode $setglobal LogMode 1

* Flags to run the GEM codes better under the IDE (ide is used for all GEM programs except GEMsolve, which uses ideSolve).
$setglobal ide "ide=%gams.ide% lo=%gams.lo% errorlog=%gams.errorlog% errmsg=1"
$if %LogMode%==0 $setglobal ideSolve "ide=%gams.ide% lo=%gams.lo% rf=GEMsolve errorlog=%gams.errorlog% errmsg=1"
$if %LogMode%==1 $setglobal ideSolve "ide=%gams.ide% lo=2 lf=GEMsolve.log rf=GEMsolve errorlog=%gams.errorlog% errmsg=1"



* GEMsettings.inc template:
*+++ Model +++
$setglobal firstYear 2012
* First modelled year.
$setglobal lastYear 2020
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
$setglobal LimHydYr 4
* (default = 100) Limit the number of Hydro years to solve the DISP model over, i.e. restrict to 5, say, to get a quick turnaround.
$setglobal Mode 0
* Select 0 to run with standard developer license; 1 to run with runtime license.  


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
$setglobal QDsolSecs 500
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



* runMergeGDXs.gms template:
$include GEMpathsAndFiles.inc

* Note: GEMpathsAndFiles.inc is used to supply %DataPath%, %ProgPath%, %OutPath% and %runName%.

File bat "A recyclable batch file" / "%ProgPath%temp.bat" / ; bat.lw = 0 ; bat.ap = 0 ;

* 1. Create and execute a batch file to:
*    - delete any GDX files that go by the name of the short scenarios,
*    - copy each raw input GDX file used to a GDX file that goes by its corresponding short scenario name, and
*    - merge all short scenario name GDX files into a single GDX file called 'all_input.gdx'.
putclose bat
  'del mds3.gdx /q' /
  'del mds5.gdx /q' /
  'copy "%DataPath%Final GEM2.0 input data (2Reg 9Block mds3).gdx" mds3.gdx' /
  'copy "%DataPath%Final GEM2.0 input data (2Reg 9Block mds5).gdx" mds5.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds3.gdx mds5.gdx output=all_input.gdx big=100000'


* 2. Create and execute a batch file to:
*    - delete any GDX files that go by the name of the short scenarios,
*    - copy each GEMdataOutput GDX file used to a GDX file that goes by its corresponding short scenario name, and
*    - merge all short scenario name GDX files into a single GDX file called 'all_gemdata.gdx'.
putclose bat
  'del mds3.gdx /q' /
  'del mds5.gdx /q' /
  'copy "%OutPath%\%runName%\GDX\GEMdataOutput - %runName% - mds3.gdx" mds3.gdx' /
  'copy "%OutPath%\%runName%\GDX\GEMdataOutput - %runName% - mds5.gdx" mds5.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds3.gdx mds5.gdx output=all_gemdata.gdx big=100000'


* 3. Create and execute a batch file to:
*    - delete any GDX files that go by the name of the short scenarios,
*    - copy each PreparedOutput GDX file used to a GDX file that goes by its corresponding short scenario name, and
*    - merge all short scenario name GDX files into a single GDX file called 'all_prepout.gdx'.
putclose bat
  'del mds3.gdx /q' /
  'del mds5.gdx /q' /
  'copy "%OutPath%\%runName%\GDX\PreparedOutput - %runName% - mds3.gdx" mds3.gdx' /
  'copy "%OutPath%\%runName%\GDX\PreparedOutput - %runName% - mds5.gdx" mds5.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds3.gdx mds5.gdx output=all_prepout.gdx big=100000'


* 4. Create a progress report file indicating that runMergeGDXs is now finished.
File rep "Write a progess report" / "runMergeGDXsProgress.txt" / ; rep.lw = 0 ;
putclose rep "runMergeGDXsProgress has now finished..." / "Time: " system.time / "Date: " system.date ;


* A note regarding the gdxmerge call:
* The 'big' parameter is used to specify a cutoff for symbols that will be written one at a time. Each symbol that
* exceeds the size will be processed by reading each GDX file and only processing the data for that symbol. This can
* lead to reading the same GDX file many times but it allows the merging of large data sets.


$offtext
