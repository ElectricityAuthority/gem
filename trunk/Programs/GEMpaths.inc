$setglobal runName        "Test"
$setglobal scenarioName   "mds1"
$setglobal GEMinputGDX    "Final GEM2.0 input data (2Reg 9Block mds1).gdx"
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
