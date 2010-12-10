* GEMgurobi.gms

$ontext
 --------------------------------------------------------------------------------
 Generation Expansion Model (GEM)
 Copyright (C) 2007, Electricity Commission

 This file is part of GEM.

 GEM is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 GEM is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with GEM; if not, write to the Free Software Foundation, Inc., 
 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 --------------------------------------------------------------------------------

 Last modified by Dr Phil Bishop, 16/11/2009 (gem@electricitycommission.govt.nz)

 The purpose of this program is to create a bunch of Gurobi options files. The specific options
 file to be used by Gurobi depends on the user's choice of solution 'goal'.
 This file will be $include'd into GEMexec.gms.

$offtext

$onecho > Gurobi.op2
* Goal: QDsol (a coarse optcr value is supplied by user in RunGEM)
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
