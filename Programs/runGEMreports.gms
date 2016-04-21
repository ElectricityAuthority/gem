* runGEMreports.gms

* Last modified by Dr Phil Bishop, 17/04/2016 (emi@ea.govt.nz)

$ontext
  Use this file to specify which previously created GEM runs are to be merged and reported on.
  Steps:
    - Give the report about to be generated a name - see the setglobal called reportName.
    - Specify the two setglobals that define the base case run name and run version (baseCaseRun & baseCaseRV).
      The notion of a base case merely idebtifies a set of files from which generic information is obtained.
    - Manually edit baseCasePath if what's already there won't work.
    - Specify the elements of sets: repRuns, repRVs, mapRuns_RVs, and runVersionColor.
$offtext

$inlinecom { }
$eolcom !

* Specify setglobals
$setglobal primaryOutput "%system.fp%..\Output\"  ! Primary GEM output folder
                                                  ! Folder where current report files will be located
                                                  ! Output location of the GEM folder from where current runGEMreports is located
                                                  ! Probably the location where the base case solution output folder is located
$setglobal reportName    "v17Report"              ! Name for report (need not be the name of a run or a run version)
$setglobal baseCaseRun   "CBAv17"                 ! Specify a previously created GEM run name as the base case run name
$setglobal baseCaseRV    "18regWith2Bld"          ! Specify a previously created GEM run version as the base case run version
$setglobal baseCasePath  "%primaryOutput%\%baseCaseRun%"

Sets col 'RGB color codes' /0*256/; Alias(col,red,green,blue) ;
Sets
  repRuns 'Run names of GEM runs to be reported on (include pathname as set element description)'
  /
  CBAv17   "%baseCasePath%"
* CBAv17   "C:\a\GEM\TPAG_redux\TPM_CBA\Output\CBAv17\"
  /

  repRVs 'Run version names and descriptions to be reported on'
  /
  18regWith2Bld  '18-region model with build schedule from 2-region model imposed on it'
  18RegCopy      'Some ad hoc model run'
  /

  mapRuns_RVs(repRuns,repRVs) 'Map run labels to run version labels'
  /
  CBAv17.(18regWith2Bld,18regCopy)
  /

  runVersionColor(repRVs,red,green,blue) 'RGB color mix for the run versions being reported on'
  /
  "18regWith2Bld".0.0.255
  "18regCopy".255.0.255
  / ;

Display repRuns, repRVs, mapRuns_RVs, runVersionColor ;

File bat "A recyclable batch file" / "temp.bat" / ; bat.lw = 0 ;

* 1. Make a report directory and copy the base case data files into it.
putclose bat
  'cls' /
  'if exist "%primaryOutput%\rep%reportName%" rmdir "%primaryOutput%\rep%reportName%" /s /q' /
  'mkdir "%primaryOutput%\rep%reportName%"' /
  'mkdir "%primaryOutput%\rep%reportName%\repData"' /
  'copy  "%baseCasePath%\Input data checks\Configuration info for use in GEMreports - %baseCaseRun%_%baseCaseRV%.inc" "%primaryOutput%\rep%reportName%\repData\Configuration info.inc"' /
  'copy  "%baseCasePath%\Input data checks\Selected prepared input data - %baseCaseRun%_%baseCaseRV%.gdx" "%primaryOutput%\rep%reportName%\repData\Base case input data.gdx"' / ;
execute 'temp.bat' ;


* 2. Merge the 'Selected prepared input data' GDX file from each runVersion into a single GDX file called 'selectedInputData.gdx'
put bat
loop(mapRuns_RVs(repRuns,repRVs),
  put 'del "', repRVs.tl, '.gdx"' / ;
  put 'copy "', repRuns.te(repRuns), '\Input data checks\Selected prepared input data - ', repRuns.tl, '_', repRVs.tl, '.gdx" "',
       repRVs.tl, '.gdx"' / ;
) ; putclose ;
execute 'temp.bat' ;

put bat 'gdxmerge' loop(repRVs, put ' "', repRVs.tl, '.gdx"' ) ;
put ' output="%primaryOutput%\rep%reportName%\repData\selectedInputData.gdx" big=100000' ; putclose ;
execute 'temp.bat' ;


* 3. Merge the 'allExperimentsReportOutput GDX file' from each runVersion into a single GDX file called 'selectedInputData.gdx'
put bat
loop(mapRuns_RVs(repRuns,repRVs),
  put 'del "', repRVs.tl, '.gdx"' / ;
  put 'copy "', repRuns.te(repRuns), '\GDX\allExperimentsReportOutput - ', repRuns.tl, '_', repRVs.tl, '.gdx" "',
       repRVs.tl, '.gdx"' / ;
) ; putclose ;
execute 'temp.bat' ;

put bat 'gdxmerge' loop(repRVs, put ' "', repRVs.tl, '.gdx"' ) ;
put ' output="%primaryOutput%\rep%reportName%\repData\reportOutput.gdx" big=100000' ; putclose ;
execute 'temp.bat' ;


* 4. Merge the 'allExperimentsAllOutput GDX file' from each runVersion into a single GDX file called 'selectedInputData.gdx'
put bat
loop(mapRuns_RVs(repRuns,repRVs),
  put 'del "', repRVs.tl, '.gdx"' / ;
  put 'copy "', repRuns.te(repRuns), '\GDX\allExperimentsAllOutput - ', repRuns.tl, '_', repRVs.tl, '.gdx" "',
       repRVs.tl, '.gdx"' / ;
) ; putclose ;
execute 'temp.bat' ;

put bat 'gdxmerge' loop(repRVs, put ' "', repRVs.tl, '.gdx"' ) ;
put ' output="%primaryOutput%\rep%reportName%\repData\allOutput.gdx" big=100000' ; putclose ;
execute 'temp.bat' ;


* 5. Create GEMreportSettings.inc
put bat
'$setglobal primaryOutput "%primaryOutput%"' /
'$setglobal reportName "%reportName%"' //
"Set runVersions 'All run versions to be reported on in the current report' /" ;
loop(repRVs,
  put / '"', repRVs.tl, '"  "', repRVs.te(repRVs), '"' ;
) ; 
put '  /;' //
"Set runVersionColor(runVersions,*,*,*) 'RGB color mix for the run versions being reported on - used to pass to plotting applications' ;" ;
loop((repRVs,red,green,blue)$runVersionColor(repRVs,red,green,blue),
  put / 'runVersionColor("', repRVs.tl, '","', red.tl, '","', green.tl, '","', blue.tl, '") = yes ;' ;
) ; putclose ;
execute 'copy temp.bat GEMreportSettings.inc'


* 6. Create a batch file to invoke GEMreports
$setglobal ide "ide=%gams.ide% lo=%gams.lo% errorlog=%gams.errorlog% errmsg=1"
putclose bat "start /wait gams GEMreports rf=GEMreports s=GEMreports gdx=GEMreports %ide%" ;
execute 'temp.bat' ;

** Haven't yet written code to figure out if GEMreports finished successfully.
*$if errorlevel 1 $abort +++ Check GEMreports.lst for errors +++

* Create a progress report file indicating that runGEMreports is now finished.
File rep "Write a progess report" / "runGEMreportsProgress.txt" / ; rep.lw = 0 ;
putclose rep "runGEMreports has now finished..." / "Time: " system.time / "Date: " system.date ;



$stop
* Old stuff from GEMreportSettings.inc that hasn't yet been used:
*$setglobal singleDomain   "'oldWayLite','timing','averageHydro'"
*$setglobal FigureTitles    0
