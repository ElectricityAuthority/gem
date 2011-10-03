* GEMgurobi.gms

* Last modified by Dr Phil Bishop, 03/10/2011 (imm@ea.govt.nz)

$ontext
 The purpose of this program is to create a bunch of Gurobi options files. The specific options
 file to be used by Gurobi depends on the user's choice of solution 'goal'. This file will be
 $include'd into GEMsolve.gms.
$offtext

$onecho > Gurobi.op2
* Goal: QDsol (a coarse optcr value is supplied by user in GEMsettings)
  threads       %Threads%
$offecho
$onecho > Gurobi.op3
* Goal: VGsol
  threads       %Threads%
$offecho
$onecho > Gurobi.op4
* Goal: MinGap
  threads       %Threads%
$offecho


$ontext
** There appears to be no Gurobi equivalent of the miptrace option used in Cplex.
** If there is, then reinstate/edit this bit of code.

$if not %PlotMIPtrace%==1 $goto noTraceOption
$onecho >> Gurobi.op2
  miptrace  MIPtrace.txt
$offecho
$onecho >> Gurobi.op3
  miptrace  MIPtrace.txt
$offecho
$onecho >> Gurobi.op4
  miptrace  MIPtrace.txt
$offecho
$label noTraceOption

$offtext




* End of file.
