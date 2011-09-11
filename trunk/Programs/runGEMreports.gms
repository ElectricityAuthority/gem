$include GEMpathsAndFiles.inc
$include GEMsettings.inc

* Invoke GEMreports:
$call gams GEMreports rf=GEMreports s=GEMreports gdx=GEMreports %ide%
$if errorlevel 1 $abort +++ Check GEMreports.lst for errors +++

* Create a progress report file indicating that runGEMreports is now finished.
File rep "Write a progess report" / "runGEMreportsProgress.txt" / ; rep.lw = 0 ;
putclose rep "runGEMreports has now finished..." / "Time: " system.time / "Date: " system.date ;
