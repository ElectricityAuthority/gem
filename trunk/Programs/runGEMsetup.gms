$include GEMpathsAndFiles.inc

* Invoke GEMdeclarations - only if license type is developer (i.e. mode=0).
$if %Mode%==0    $call gams GEMdeclarations.gms rf=GEMdeclarations s=GEMdeclarations %ide%
$if errorlevel 1 $abort +++ Check GEMdeclarations.lst for errors +++

* Create a couple of files.
File bat "A recyclable batch file"  / "%ProgPath%\temp.bat" / ;     bat.lw = 0 ;
File rep "Write a progess report"   / "runGEMsetupProgress.txt" / ; rep.lw = 0 ;

* Create and execute a batch file to:
* - remove any output directory with the extant runName;
* - create a new output directory with the extant runName; and
* - archive the .gms/.g00 programs.
putclose bat
  'if exist report.txt                     erase report.txt /q' /
  'if exist runGEMsetupProgress.txt        erase runGEMsetupProgress.txt /q' /
  'if exist runGEMdataAndSolveProgress.txt erase runGEMdataAndSolveProgress.txt /q' /
  'if exist runMergeGDXsProgress.txt       erase runMergeGDXsProgress.txt /q' /
  'if exist runGEMreportsProgress.txt      erase runGEMreportsProgress.txt /q' /
  'if exist "%OutPath%%runName%"           rmdir "%OutPath%%runName%" /s /q' /

  'mkdir "%OutPath%\%runName%"' /
  'mkdir "%OutPath%\%runName%\Archive"' /
  'mkdir "%OutPath%\%runName%\GDX"' /
  'mkdir "%OutPath%\%runName%\GDX\All output"' /
  'mkdir "%OutPath%\%runName%\GDX\Report output"' /
  'mkdir "%OutPath%\%runName%\Processed files"' /
  'mkdir "%OutPath%\%runName%\Input data checks"' /

  'copy "%ProgPath%\GEMdeclarations.gms" "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%\GEMdeclarations.g00" "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%\CollectResults.inc"  "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%\GEMdata.gms"         "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%\GEMsolve.gms"        "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%\GEMreports.gms"      "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%\GEMcplex.gms"        "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%\GEMgurobi.gms"       "%OutPath%\%runName%\Archive\"' /
  'copy "%ProgPath%\GEMxpress.gms"       "%OutPath%\%runName%\Archive\"' / ;

execute 'temp.bat' ;

* Indicate that runGEMsetup is finished.
putclose rep "runGEMsetup has now finished..." / "Time: " system.time / "Date: " system.date ;


$ontext
Some notes for future development of emi (the EA models GUI):
  - If GEMdeclarations was invoked, emi needs to know if it was successful. If it returned errorlevel = 1
    and aborted, then do not proceed with the rest of the job and inform the user that the job is terminating.
  - If GEMdeclarations is not invoked, i.e. because the user has a runtime license (mode=1), then check for the
    presence of GEMdeclarations.g00 and CollectResults.inc in the current directory. These two files should have
    been distributed with GEM. But if they have been removed or deleted by the user, then the job should not and
    cannot proceed. The user should be informed as to why the job is terminating.
$offtext
