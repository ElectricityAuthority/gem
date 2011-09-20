$setglobal runName         "Test"
$setglobal runVersionName  "mds1"
$setglobal baseRunVersion  "mds3"

$setglobal GEMinputGDX     "standardGEMinput9LB.gdx"
$setglobal GEMnetworkGDX   "2RegionNetwork.gdx"
$setglobal GEMdemandGDX    "NRG_2Region9LB_EVdemand.gdx"

$setglobal GEMoverrideGDX  "mds1_Override.gdx"

$setglobal useOverrides     1
$setglobal sprsGEMsolve     0
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
