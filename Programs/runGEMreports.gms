$include GEMreportsettings.inc

file bat "A recyclable batch file" / "%ProgPath%\temp.bat" / ; bat.lw = 0 ;

* 1. Make a report directory and get the base case data files. 
putclose bat
  'cls' /
  'if exist "%OutPath%\rep%reportName%" rmdir "%OutPath%\rep%reportName%" /s /q' /
  'mkdir "%OutPath%\rep%reportName%"' /
  'mkdir "%OutPath%\rep%reportName%\repData"' /
  'copy  "%OutPath%\%BaseCaseRun%\Input data checks\Configuration info for use in GEMreports - %BaseCaseRun%_%BaseCaseRV%.inc" "%OutPath%\rep%reportName%\repData\Configuration info.inc"' /
  'copy  "%OutPath%\%BaseCaseRun%\Input data checks\Selected prepared input data - %BaseCaseRun%_%BaseCaseRV%.gdx"             "%OutPath%\rep%reportName%\repData\Base case input data.gdx"' /
  ;
execute 'temp.bat' ;

* 2. Merge the 'Selected prepared input data GDX file' from each runVersion into a single GDX file called 'selectedInputData.gdx'
putclose bat
  'del mds1.gdx /q' /
  'del mds2.gdx /q' /
  'del mds3.gdx /q' /
  'del mds5.gdx /q' /
  'copy "%OutPath%\Test\Input data checks\Selected prepared input data - Test_mds1.gdx" mds1.gdx' /
  'copy "%OutPath%\Test\Input data checks\Selected prepared input data - Test_mds2.gdx" mds2.gdx' /
  'copy "%OutPath%\Test\Input data checks\Selected prepared input data - Test_mds3.gdx" mds3.gdx' /
  'copy "%OutPath%\Test2\Input data checks\Selected prepared input data - Test2_mds5.gdx" mds5.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds1.gdx mds2.gdx mds3.gdx mds5.gdx output="C:\a\GEM\Output\rep%reportName%\repData\selectedInputData.gdx" big=100000'

* 3. Merge the 'allExperimentsReportOutput GDX file' from each runVersion into a single GDX file called 'selectedInputData.gdx'
putclose bat
  'del mds1.gdx /q' /
  'del mds2.gdx /q' /
  'del mds3.gdx /q' /
  'del mds5.gdx /q' /
  'copy "%OutPath%\Test\GDX\allExperimentsReportOutput - Test_mds1.gdx" mds1.gdx' /
  'copy "%OutPath%\Test\GDX\allExperimentsReportOutput - Test_mds2.gdx" mds2.gdx' /
  'copy "%OutPath%\Test\GDX\allExperimentsReportOutput - Test_mds3.gdx" mds3.gdx' /
  'copy "%OutPath%\Test2\GDX\allExperimentsReportOutput - Test2_mds5.gdx" mds5.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds1.gdx mds2.gdx mds3.gdx mds5.gdx output="C:\a\GEM\Output\rep%reportName%\repData\reportOutput.gdx" big=100000'

* 4. Merge the 'allExperimentsAllOutput GDX file' from each runVersion into a single GDX file called 'selectedInputData.gdx'
putclose bat
  'del mds1.gdx /q' /
  'del mds2.gdx /q' /
  'del mds3.gdx /q' /
  'del mds5.gdx /q' /
  'copy "%OutPath%\Test\GDX\allExperimentsAllOutput - Test_mds1.gdx" mds1.gdx' /
  'copy "%OutPath%\Test\GDX\allExperimentsAllOutput - Test_mds2.gdx" mds2.gdx' /
  'copy "%OutPath%\Test\GDX\allExperimentsAllOutput - Test_mds3.gdx" mds3.gdx' /
  'copy "%OutPath%\Test2\GDX\allExperimentsAllOutput - Test2_mds5.gdx" mds5.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds1.gdx mds2.gdx mds3.gdx mds5.gdx output="C:\a\GEM\Output\rep%reportName%\repData\allOutput.gdx" big=100000'

* 5. Create a batch file to invoke GEMreports
$setglobal ide "ide=%gams.ide% lo=%gams.lo% errorlog=%gams.errorlog% errmsg=1"
putclose bat "start /wait gams GEMreports rf=GEMreports s=GEMreports gdx=GEMreports %ide%" ;
execute 'temp.bat' ;

** No way yet to figure out if GEMreports finished successfully?
*$if errorlevel 1 $abort +++ Check GEMreports.lst for errors +++

* Create a progress report file indicating that runGEMreports is now finished.
File rep "Write a progess report" / "runGEMreportsProgress.txt" / ; rep.lw = 0 ;
putclose rep "runGEMreports has now finished..." / "Time: " system.time / "Date: " system.date ;
