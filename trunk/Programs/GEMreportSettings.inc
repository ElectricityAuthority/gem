$setglobal runName        "Test"
$setglobal baseRunVersion "mds3"
$setglobal singleDomain   "'oldWayLite','timing','averageHydro'"

$setglobal FigureTitles    0

$setglobal ProgPath       "%system.fp%"
$setglobal DataPath       "%system.fp%..\Data\"
$setglobal OutPath        "%system.fp%..\Output\"

Set runVersions "Variants or instances of the run - all stored in the 'runName' output directory" /
  mds1 'Sustainable path'
  mds2 'South Island wind'
  mds3 'Medium renewables'
  mds4 'Coal'
  mds5 'High gas discovery' / ;

Set runVersionColor(runVersions,*,*,*) 'RGB color mix for the various versions comprising the run - to pass to plotting applications' ;
runVersionColor('mds1','0','0','255')   = yes ;
runVersionColor('mds2','255','0','0')   = yes ;
runVersionColor('mds3','0','255','0')   = yes ;
runVersionColor('mds4','0','0','0')     = yes ;
runVersionColor('mds5','255','0','255') = yes ;
