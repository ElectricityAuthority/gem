$include GEMpathsAndFiles.inc


File bat "A recyclable batch file" / "%ProgPath%temp.bat" / ; bat.lw = 0 ; bat.ap = 0 ;


* 1. Create and execute a batch file to:
*    - delete any GDX files that go by the name of the elements in runVersions.
*    - copy each Selected prepared input data GDX file to a GDX file that goes by its corresponding runVersion name, and
*    - merge all runVersion name GDX files into a single GDX file called 'all_SelectedInputData.gdx'.
putclose bat
  'del mds1.gdx /q' /
  'del mds3.gdx /q' /
  'copy "%OutPath%\%runName%\Input data checks\Selected prepared input data - %runName% - mds1.gdx" mds1.gdx' /
  'copy "%OutPath%\%runName%\Input data checks\Selected prepared input data - %runName% - mds3.gdx" mds3.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds1.gdx mds3.gdx output=allRV_SelectedInputData.gdx big=100000'


* 2. Create and execute a batch file to:
*    - delete any GDX files that go by the name of the elements in runVersions.
*    - copy each allExperimentsReportOutput GDX file to a GDX file that goes by its corresponding runVersion name, and
*    - merge all runVersion name GDX files into a single GDX file called 'all_ReportOutput.gdx'.
putclose bat
  'del mds1.gdx /q' /
  'del mds3.gdx /q' /
  'copy "%OutPath%\%runName%\GDX\allExperimentsReportOutput - mds1.gdx" mds1.gdx' /
  'copy "%OutPath%\%runName%\GDX\allExperimentsReportOutput - mds3.gdx" mds3.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds1.gdx mds3.gdx output=allRV_ReportOutput.gdx big=100000'


* 3. Create and execute a batch file to:
*    - copy the merged GDX files to their respective locations.
*    - delete the temp directory in the GDX folder, which contained the various 'experiment' GDX files.
putclose bat
  'copy allRV_SelectedInputData.gdx  "%OutPath%\%runName%\Input data checks\"' /
  'copy allRV_ReportOutput.gdx       "%OutPath%\%runName%\GDX\"' /
  'rmdir "%OutPath%\%runName%\GDX\temp" /s /q'
  ;
execute 'temp.bat' ;


* 4. Create a progress report file indicating that runMergeGDXs is now finished.
File rep "Write a progess report" / "runMergeGDXsProgress.txt" / ; rep.lw = 0 ;
putclose rep "runMergeGDXsProgress has now finished..." / "Time: " system.time / "Date: " system.date ;


* A note regarding the gdxmerge call:
* The 'big' parameter is used to specify a cutoff for symbols that will be written one at a time. Each symbol that
* exceeds the size will be processed by reading each GDX file and only processing the data for that symbol. This can
* lead to reading the same GDX file many times but it allows the merging of large data sets.
