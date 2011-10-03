* GEMcplex.gms

* Last modified by Dr Phil Bishop, 03/10/2011 (imm@ea.govt.nz)

$ontext
 The purpose of this program is to create a bunch of Cplex options files. The specific options
 file to be used by Cplex depends on the user's choice of solution 'goal'.  This file will be
 $include'd into GEMsolve.gms.
$offtext

$onecho > Cplex.op2
* Goal: QDsol (a coarse optcr value is supplied by user in GEMsettings)
  mipemphasis   2
  heurfreq      500
  rinsheur      500
  scaind        0
  mipstart      1
  repairtries   5
  threads       %Threads%
  lpmethod      2
$offecho
$onecho > Cplex.op3
* Goal: VGsol
* Emphasis: finding good integer solutions, straight solve with mipstart/repairtries
* Use fast cuts aggressively
  mipemphasis   1
  rinsheur      100
  heurfreq      50
  threads       %Threads%
  fraccuts      2
  mircuts       2
  implbd        2
  mipstart      1
  repairtries   5
  lpmethod      2
$offecho
$onecho > Cplex.op4
* Goal: MinGap
* Emphasis: reducing gap, straight solve without mipstart
* Use cuts aggressively
  mipemphasis   3
  rinsheur      500
  heurfreq      100
  threads       %Threads%
  cuts          3
  lpmethod      2
$offecho

$if not %PlotMIPtrace%==1 $goto noTraceOption
$onecho >> cplex.op2
  miptrace  MIPtrace.txt
$offecho
$onecho >> cplex.op3
  miptrace  MIPtrace.txt
$offecho
$onecho >> cplex.op4
  miptrace  MIPtrace.txt
$offecho
$label noTraceOption


$ontext
Brief explantion of CPLEX options. See the GAMS/CPLEX manual for complete description
preind      (def = 1 ) Use zero to turn pre-solve off
mipemphasis (def = 0 ) 1 = Emphasize feasibility over optimality, 2 = emphasise optimality over feasibility
heurfreq    (def = 0 ) Turn on rounding heuristics at node interval x
rinsheur    (def = 0 ) Turn on RINS heuristics at every x-th node in tree
scaind      (def = 0 ) Aggressive scaling may help
mipstart    (def = 0 ) Start from a given solution through var.l values
repairtries (def = 0 ) Maximum number of attempts at repairing a supplied infeasible MIP start 
threads     (def = 1 ) Declare how many threads barrier and MIP algorithms can use
lpmethod    (def = 0 ) 0 = Automatic - primal or dual simplex, depending on availability of a basis
                       1 = Primal simplex
                       2 = Dual simplex
                       3 = Network simplex
                       4 = solve the LP problem with barrier algorithm
                       6 = solve the LP problem with concurrent methods on multiple threads. First one to finish wins and stops the loser.
                           First thread uses dual simplex, 2nd uses barrier, and third (not relevant if only 2 threads) uses primal simplex.
rhsrng      Specify which equations to do RHS ranging on (default is to do no RHS ranging).
objrng      Specify which variables to calculate sensitivity ranges on (default is to do no variable ranging).
rngrestart  Specify a file to write ranging info to (default is to print to the listing file).
objrng       CAPACITY
rhsrng       bal_pkload_new_NZ
rngrestart   "%OutPath%%runName% - Ranging information.txt"

$offtext



* End of file.
