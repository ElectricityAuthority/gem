$setglobal reportName "reports12345"

$setglobal BaseCaseRun "Test123"
$setglobal BaseCaseRV "mds3"

Set runVersions "All run versions to be reported on in the current report" / 
  "mds1" "Sustainable path"
  "mds2" "South Island wind"
  "mds3" "Medium renewables"
  "mds4" "Coal"
  "mds5" "High gas discovery"
 / ;

Set runVersionColor(runVersions,*,*,*) "RGB color mix for the run versions being reported on - used to pass to plotting applications";
runVersionColor("mds1","0","0","255") = yes ;
runVersionColor("mds2","255","0","0") = yes ;
runVersionColor("mds3","0","255","0") = yes ;
runVersionColor("mds4","0","0","0") = yes ;
runVersionColor("mds5","255","0","255") = yes ;

$setglobal ProgPath       "%system.fp%"
$setglobal DataPath       "%system.fp%..\Data\"
$setglobal OutPath        "%system.fp%..\Output\"

*$setglobal singleDomain   "'oldWayLite','timing','averageHydro'"
*$setglobal FigureTitles    0
