* runGEMwithoutGUI.gms

* Last modified by Dr Phil Bishop, 02/12/2010 (imm@ea.govt.nz)

$ontext
 Purpose:
 This file describes the process to manually operate GEM, i.e. without resort to EAME. Manual operation of
 GEM may be undertaken using the GAMS IDE, or a text editor and the command line. Note that the files called
 GEMpaths.inc and GEMsettings.inc are produced automatically by EAME and are used by GEM. If they haven't been
 deleted, they will reside in the GEM programs directory.
   
 Steps:
 1. Create or edit a file called GEMpaths.inc, place it in the GEM programs directory, and invoke runGEMsetup.gms once.
    - Use the GEMpaths.inc template below if no GEMpaths.inc file can be found.
    - The only 2 items in GEMpaths.inc that really need to be specified at this point are runName and mode.

 2. Create or edit a file called GEMsettings.inc and place it in the GEM programs directory.
    - Use the GEMsettings.inc template below if no GEMsettings.inc file can be found.
    - There is much in GEMsettings.inc that controls how GEM is configured and solved, so edit it carefully. At
      this point, the sets called 'sc' and 'scenarioColor', and the setglobal called firstScenario can be ignored.

 3. Invoke runGEMDataAndSolve.gms as many times as there are scenarios to be solved.
    - But before each invocation of runGEMDataAndSolve.gms, take special care to ensure that:
      - scenarioName, GDXinputFile, and GEMdataGDX in GEMpaths.inc are specified in accordance with the scenario
        being solved.
      - runName in both GEMpaths.inc and GEMsettings.inc should be identical and unchanged for all scenarios.
      - firstScenario and the set called 'sc' in GEMsettings.inc are not important (i.e. not used) at this stage.

 4. Prepare to generate reports by editing firstScenario and the sets called 'sc' and 'scenarioColor' in GEMsettings.inc.
    - firstScenario must be specified to be the GDX input file name corresponding to the first scenario solved.
      (whether or not the notion of a base case matters, the first scenario is assumed to be the base case.)
    - Each scenario previously solved and for which reporting is desired must be entered as elements in set sc:
        - specify both an element label (must be GAMS-compliant) and an element description. The description does
          not need to be the GDX input file name although common sense would suggest it might be similar.
    - Each scenario (member of set 'sc') must also be assigned an RGB colour code in the set called 'scenarioColor'. 

 5. Create a file called runMergeGDXs.gms, place it in the GEM programs directory, and invoke it once.
    - Use the runMergeGDXs.gms template below if no runMergeGDXs.gms file can be found.
    - For each of the 3 sets of commands (i.e. commands relating to raw input files, GEMdata GDX files, and prepared
      output GDX files), it is necessary to create a 'del', and 'copy' statement for each scenario. The short names
      of the files to be deleted and copied to must be the set element names from the set 'sc' in GEMsettings.inc (see
      note #4 above).
    - See also the notes in runMergeGDXs.gms.

 6. Invoke the file called runGEMreports.gms (it should be present in the GEM programs directory).
$offtext



*=== Templates ===
$ontext

* GEMpaths.inc template:
$setglobal runName        "Test"
$setglobal scenarioName   "mds2"
$setglobal GDXinputFile   "Final GEM2.0 input data (2Reg 9Block mds2).gdx"
$setglobal GEMdataGDX     "GEMdataOutput - %runName% - %scenarioName%.gdx"
$setglobal Mode            0

$inlinecom { } eolcom !
$setglobal ProgPath       "%system.fp%"
$setglobal DataPath       "%system.fp%..\Data\"
$setglobal MatCodePath    "%system.fp%..\Matlab code\"
$setglobal OutPath        "%system.fp%..\Output\"

* Set LogMode to 0 if it hasn't already been set to 1 via invocation, e.g. gams GEMsolve --LogMode=1
* 0 ==> GAMSIDE will display log info in process window, capture it, and then subsequently archive it.
* 1 ==> log info written to a log file and subsequently archived (log info not echoed to command prompt).
$if not set LogMode $setglobal LogMode 1
				   
* Flags to run the GEM codes better under the IDE (ide is used for all GEM programs except GEMsolve, which uses ideSolve).
$setglobal ide "ide=%gams.ide% lo=%gams.lo% errorlog=%gams.errorlog% errmsg=1"
$if %LogMode%==0 $setglobal ideSolve "ide=%gams.ide% lo=%gams.lo% rf=GEMsolve errorlog=%gams.errorlog% errmsg=1"
$if %LogMode%==1 $setglobal ideSolve "ide=%gams.ide% lo=2 lf=GEMsolve.log rf=GEMsolve errorlog=%gams.errorlog% errmsg=1"



* GEMsettings.inc template:
$inlinecom { } eolcom !
$setglobal ProgPath         "%system.fp%"
$setglobal DataPath         "%system.fp%..\Data\"
$setglobal MatCodePath      "%system.fp%..\Matlab code\"
$setglobal OutPath          "%system.fp%..\Output\"

$setglobal runName          "Test"

Set sc 'Scenarios'     / mds2 'MDS2' /;
Set scenarioColor(sc,*,*,*) 'RGB color mix for scenarios - to pass to plotting applications' ;
scenarioColor('mds2','0','0','255') = yes ;

$setglobal firstScenario    "Final GEM2.0 input data (2Reg 9Block mds2).gdx"

*== Model ===
$setglobal firstYear 2010
$setglobal lastYear 2035
$setglobal RunType 0        ! default = 0 = run both GEM and DISP, 1 = Run GEM only, 2 = Run DISPatch only
$setglobal GEMtype RMIP
$setglobal DISPtype RMIP
$setglobal SuppressReopt 1
$setglobal SprsRenShrReo 0
$setglobal SprsRenShrDis 1
$setglobal LimHydYr 4
$setglobal Mode 0

*== Hydrology ===
$setglobal hydroYrForTiming Average
Scalar hydroOutputScalar / .97 / ;
$setglobal hydroYrForReopt 1932
$setglobal DInflowYr 0
$setglobal DInflwYrType 1

*== Capital Expenditure ===
Scalar WACCg / .08 / ;
Scalar WACCt / .08 / ;
Scalar taxRate / .3 / ;
Scalar depType / 1 / ;
Scalar txPlantLife / 60 / ;
Scalar txDepRate / .06 / ;
Scalar randomCapexCostAdjuster / 0 / ;

*== Gem constraints ===
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

*== Load ===
$setglobal GrowthProfile Medium
$setglobal AClossesNI 0.0368
$setglobal AClossesSI 0.0368
$setglobal EmbedAdjNZ 198
$setglobal EmbedAdjNI 144

*== Solver ===
$setglobal Solver Cplex
$setglobal SolveGoal QDsol
$setglobal QDoptCr .0075
$setglobal QDsolSecs 500
$setglobal VGsolSecs 7200
$setglobal Threads 4
$setglobal MinGapSecs 10800

*== Plots ===
$setglobal MexOrMat 1
$setglobal PlotInFigures 0
$setglobal PlotOutFigures 1
$setglobal PlotMIPtrace 0
$setglobal FigureTitles 0



* runMergeGDXs.gms template:
$include GEMpaths.inc

* Note: GEMpaths.inc is used to supply %DataPath%, %ProgPath%, %OutPath% and %runName%.

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
