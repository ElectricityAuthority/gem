$include GEMpaths.inc

* Note: GEMpaths.inc is used to supply %DataPath%, %ProgPath%, %OutPath% and %runName%.

File bat "A recyclable batch file" / "%ProgPath%temp.bat" / ; bat.lw = 0 ; bat.ap = 0 ;

* 1. Create and execute a batch file to:
*    - delete any GDX files that go by the name of the short scenarios,
*    - copy each raw input GDX file used to a GDX file that goes by its corresponding short scenario name, and
*    - merge all short scenario name GDX files into a single GDX file called 'all_input.gdx'.
putclose bat
  'del mds1.gdx /q' /
  'del mds2.gdx /q' /
  'copy "%DataPath%Final GEM2.0 input data (2Reg 9Block mds1).gdx" mds1.gdx' /
  'copy "%DataPath%Final GEM2.0 input data (2Reg 9Block mds2).gdx" mds2.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds1.gdx mds2.gdx output=all_input.gdx big=100000'


* 2. Create and execute a batch file to:
*    - delete any GDX files that go by the name of the short scenarios,
*    - copy each GEMdataOutput GDX file used to a GDX file that goes by its corresponding short scenario name, and
*    - merge all short scenario name GDX files into a single GDX file called 'all_gemdata.gdx'.
putclose bat
  'del mds1.gdx /q' /
  'del mds2.gdx /q' /
  'copy "%OutPath%\%runName%\GDX\GEMdataOutput - %runName% - mds1.gdx" mds1.gdx' /
  'copy "%OutPath%\%runName%\GDX\GEMdataOutput - %runName% - mds2.gdx" mds2.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds1.gdx mds2.gdx output=all_gemdata.gdx big=100000'


* 3. Create and execute a batch file to:
*    - delete any GDX files that go by the name of the short scenarios,
*    - copy each PreparedOutput GDX file used to a GDX file that goes by its corresponding short scenario name, and
*    - merge all short scenario name GDX files into a single GDX file called 'all_prepout.gdx'.
putclose bat
  'del mds1.gdx /q' /
  'del mds2.gdx /q' /
  'copy "%OutPath%\%runName%\GDX\PreparedOutput - %runName% - mds1.gdx" mds1.gdx' /
  'copy "%OutPath%\%runName%\GDX\PreparedOutput - %runName% - mds2.gdx" mds2.gdx' /
  ;
execute 'temp.bat' ;
execute 'gdxmerge mds1.gdx mds2.gdx output=all_prepout.gdx big=100000'


* 4. Create a progress report file indicating that runMergeGDXs is now finished.
File rep "Write a progess report" / "runMergeGDXsProgress.txt" / ; rep.lw = 0 ;
putclose rep "runMergeGDXsProgress has now finished..." / "Time: " system.time / "Date: " system.date ;


* A note regarding the gdxmerge call:
* The 'big' parameter is used to specify a cutoff for symbols that will be written one at a time. Each symbol that
* exceeds the size will be processed by reading each GDX file and only processing the data for that symbol. This can
* lead to reading the same GDX file many times but it allows the merging of large data sets.
