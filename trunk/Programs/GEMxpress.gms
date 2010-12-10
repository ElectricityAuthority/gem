* GEMxpress.gms

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

 The purpose of this program is to create a bunch of Xpress options files. The specific options
 file to be used by Xpress depends on the user's choice of solution 'goal'.
 This file will be $include'd into GEMexec.gms.

 This file may require some fine tuning as it has not been tested extensively. The options were
 suggested by Erwin Kalvelagen (Amsterdam Optimization Modeling Group) based upon those used in
 GEMcplex.gms. But Xpress doesn't contain the range of options that Cplex does so a complete
 correspondence is not possible. 

$offtext

$onecho > xpress.op2
* Goal: QDsol (a coarse optcr value is supplied by user in RunGEM)
  loadmipsol    0
  threads       %Threads%
  mipcleanup    0
  covercuts     1000
  cutdepth      50
  cutfreq       8
  cutstrategy   2
  gomcuts       100
  algorithm     barrier
$offecho
$onecho > xpress.op3
* Goal: VGsol
  loadmipsol    0
  threads       %Threads%
  mipcleanup    0
  covercuts     1000
  cutdepth      50
  cutfreq       8
  cutstrategy   2
  gomcuts       100
$offecho
$onecho > xpress.op4
* Goal: MinGap
  loadmipsol    0
  threads       %Threads%
  mipcleanup    0
  covercuts     1000
  cutdepth      50
  cutfreq       8
  cutstrategy   2
  gomcuts       100
$offecho

* NB: An option called 'miptrace' exists in Xpress but I have never tested it and
*     do not know if the resulting file is compatible with that created by the Cplex
*     miptrace option. If the file format is different to the Cplex version, then I 
*     would imagine the Matlab code to create trace plots will not work either.
$if not %PlotMIPtrace%==1 $goto noTraceOption
$onecho >> Xpress.op2
  miptrace  MIPtrace.txt
$offecho
$onecho >> Xpress.op3
  miptrace  MIPtrace.txt
$offecho
$onecho >> Xpress.op4
  miptrace  MIPtrace.txt
$offecho
$label noTraceOption


* End of file.
