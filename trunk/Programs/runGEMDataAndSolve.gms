$include GEMpathsAndfiles.inc

* Invoke GEMdata:
$call gams GEMdata rf=GEMdata r=GEMdeclarations s=GEMdata gdx=GEMdata %ide%
$if errorlevel 1 $abort +++ Check GEMdata.lst for errors +++

* Invoke GEMsolve:
$if %sprsGEMsolve%==1 $goto noGEMsolve
$call gams GEMsolve rf=GEMsolve r=GEMdata s=GEMsolve gdx=GEMsolve %ideSolve%
$if errorlevel 1 $abort +++ Check GEMsolve.lst for errors +++
$label noGEMsolve

* Create a progress report file indicating that runGEMdataAndSolve is now finished.
File rep "Write a progess report" / "runGEMdataAndSolveProgress.txt" / ; rep.lw = 0 ;
putclose rep "runGEMdataAndSolve has now finished..." / "Time: " system.time / "Date: " system.date ;


$ontext
Some notes for future development of GUI:
  - The fact that runGEMdataAndSolve has finished does not mean that the model(s) were successfully solved.
    One needs to check GEMsolveReport - %runName%.txt, GEMsolveLog - %runName%_%runVersionName%.txt, and/or
    GEMsolve.lst.
$offtext