* GEMplots.gms


* Last modified by Dr Phil Bishop, 24/05/2010 (gem@electricitycommission.govt.nz)


set GEMPlotsVer 'GEMplots.gms version number' / '1.5.11' / ;


$ontext
 --------------------------------------------------------------------------------
 Generation Expansion Model (GEM)
 Copyright (C) 2007, Electricity Commission

 This file is part of GEM.

 GEM is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

 GEM is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with GEM; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 --------------------------------------------------------------------------------


 The purpose of GEMplots.gms is produce text files that can be read into other software applications, e.g. Matlab,
 so that plots of various model outputs can be generated. This program is to be run following GEMreports. It will
 ordinarily be invoked from the batch file, RunGEM.gms, but can also be invoked manually. The relevant GEMbase work
 file must be called at invocation. For example, DOS prompt> gams GEMplots r=GEMbase

 Code sections:
  1. Import from the GDX files as necessary to generate plot files.
  2. Declare sets and parameters local to GEMplots.
  3. Create output files - by plant, by year, by plant and year, by year and period, and for energy reserves.
     a) Compute results by generating plant, set 'pr'.
     b) Compute results by generating plant by year, set 'pryr'.
     c) Compute results by year, set 'ryr'.
     d) Compute results by year and period, set 'rper'.
     e) Compute various results related to reserves.
     f) Compute reserve energy results, set 'rrsv'.
     g) Write out a whole slew of delimited files using the parameters created in (a) thru (f).
  4. Write out various files of output relating to generation, e.g. energy dispatched, energy prices etc.
  5. Write out the transmission results.
  6. Dump selected output into a into a GDX file for use in subsequent programs, e.g. GEMaccess.
  7. Write the housekeeping files.
$offtext



*===============================================================================================
* 1. Import from the GDX files as necessary to generate plot files.

Set GEMbaseoutVer 'GEMbaseout.gms version number' ;

* First, redeclare parameters created in, and imported from, GEMreports, i.e. these declarations are not in GEMbase.g00
Parameters
  genyr(mds,rt,g,y,hd)                           'Generation by plant and year, GWh'
  buildyr(mds,g)                                 'Year in which new generating plant is built, or first built if built over multiple years'
  capchrg_r(mds,rt,g,y)                          'Capex charges (net of depreciation tax credit effects) by built plant by year, $m (real)'
  capchrg_pv(mds,rt,g,y,d)                       'Capex charges (net of depreciation tax credit effects) by built plant by year, $m (present value)'
  capchrgyr_r(mds,rt,y)                          'Capex charges on built plant (net of depreciation tax credit effects) by year, $m (real)'
  capchrgyr_pv(mds,rt,y,d)                       'Capex charges on built plant (net of depreciation tax credit effects) by year, $m (present value)'
  taxcred_r(mds,rt,g,y)                          'Tax credit on depreciation by built plant by year, $m (real)'
  taxcred_pv(mds,rt,g,y,d)                       'Tax credit on depreciation by built plant by year, $m (present value)'
  fopexgross_r(mds,rt,g,y,t)                     'Fixed O&M expenses (before tax benefit) by built plant by year by period, $m (real)'
  fopexnet_r(mds,rt,g,y,t)                       'Fixed O&M expenses (after tax benefit) by built plant by year by period, $m (real)'
  hvdcgross_r(mds,rt,g,y,t)                      'HVDC charges (before tax benefit) by built plant by year by period, $m (real)'
  hvdcnet_r(mds,rt,g,y,t)                        'HVDC charges (after tax benefit) by built plant by year by period, $m (real)'
  txcapchrgyr_r(mds,rt,y)                        'Transmission capex charges (net of depreciation tax credit effects) by year, $m (real)'
  txcapchrgyr_pv(mds,rt,y,d)                     'Transmission capex charges (net of depreciation tax credit effects) by year, $m (present value)'
  ;

$gdxin '%OutPrefix% - GEMbaseoutVer.gdx'
$loaddc GEMbaseoutVer
$gdxin '%OutPath%%Outprefix%\GDX\%Outprefix% - PreparedOutput.gdx'
$loaddc mds_rt mds_rt_hd s3_hydoutput s3_build s3_retire s3_capacity s3_gen s3_Tx s3_loss s3_btx s3_txprojvar s3_bal_supdem s3_resv s3_resvviol s3_resvtrfr
$gdxin '%OutPath%\%Outprefix%\GDX\%Outprefix% - ReportsData.gdx'
$loaddc GEMexecVer GEMprepoutVer GEMreportsVer
$loaddc problems warnings slacks numdisyrs genyr buildyr capchrg_r capchrg_pv capchrgyr_r capchrgyr_pv taxcred_r taxcred_pv
$loaddc fopexgross_r fopexnet_r hvdcgross_r hvdcnet_r txcapchrgyr_r txcapchrgyr_pv



*===============================================================================================
*  2. Declare sets and parameters local to GEMplots.

Sets
  pr     Labels for results by generating plant
       / 'ErlyYr'          'Earliest build year'
         'BldYr'           'Build year'
         'InstMW'          'Installed capacity, MW'
         'FirmMW'          'Firm capacity, MW'
         'MinUtil'         '1 indicates the minimum utilisation constraint applies'
         'RetireYr'        'Retirement year'
         'RetireMW'        'Retired capacity, MW' /

  pryr   Labels for results by generating plant and year
       / 'GenGWh'          'Output, GWh'
         'NZInstMW'        'Installed capacity in NZ, MW'
         'NZFirmMW'        'Firm capacity in NZ, MW'
         'NIInstMW'        'Installed capacity in NI, MW'
         'NIFirmMW'        'Firm capacity in NI, MW'
         'MaxPotGWh'       'Theoretical maximum annual energy production, GWh'
         'Util%'           'Utilisation, percent'
         'FuelPJ'          'Fuel use, PJ'
         'tCO2'            'CO2e emissions, tonnes'
         'CapexPV$m'       'Annualised pre tax capital expenditure, PV (discd at WACCg), $m'
         'TaxCrdPV$m'      'Annualised depreciation tax credit, PV (discd at WACCg), $m'
         'CapexR$m'        'Annualised generation capex (post depreciation tax credit), real, $m'
         'TaxCrdR$m'       'Annualised depreciation tax credit, real, $m'
         'CapCost$m'       'Pre tax lumpy capital cost of new plants, real, $m'
         'fOMpre$m'        'Fixed O&M expenses (pre tax), $m'
         'fOMpost$m'       'Fixed O&M expenses (post tax), $m'
         'HVDCpre$m'       'HVDC charges (pre tax), $m'
         'HVDCpost$m'      'HVDC charges (post tax), $m'
         'vOMpre$m'        'Variable O&M expenses with LF adjustment (pre tax), $m'
         'vOMpreNoLF$m'    'Variable O&M expenses without LF adjustment (pre tax), $m'
         'vOMpost$m'       'Variable O&M expenses with LF adjustment (post tax), $m'
         'vOMpostNoLF$m'   'Variable O&M expenses without LF adjustment (post tax), $m'
         'Fuelpre$m'       'Fuel expenses with LF adjustment (pre tax), $m'
         'FuelpreNoLF$m'   'Fuel expenses without LF adjustment (pre tax), $m'
         'Fuelpost$m'      'Fuel expenses with LF adjustment (post tax), $m'
         'FuelpostNoLF$m'  'Fuel expenses without LF adjustment (post tax), $m'
         'Ctaxpre$m'       'CO2 charges with LF adjustment (pre tax), $m'
         'CtaxpreNoLF$m'   'CO2 charges without LF adjustment (pre tax), $m'
         'Ctaxpost$m'      'CO2 charges with LF adjustment (post tax), $m'
         'CtaxpostNoLF$m'  'CO2 charges without LF adjustment (post tax), $m'
         'CCSpre$m'        'CCS expenses with LF adjustment (pre tax), $m'
         'CCSpreNoLF$m'    'CCS expenses without LF adjustment (pre tax), $m'
         'CCSpost$m'       'CCS expenses with LF adjustment (post tax), $m'
         'CCSpostNoLF$m'   'CCS expenses without LF adjustment (post tax), $m'  /

  ryr    Labels for results by year
       / 'TxUpgrades'      'Identify the years in which transmission upgrades are made'
         'NZInstMW'        'Installed capacity in NZ, MW'
         'NZFirmMW'        'Firm capacity in NZ, MW'
         'NIInstMW'        'Installed capacity in NI, MW'
         'NIFirmMW'        'Firm capacity in NI, MW'
         'RetireMW'        'Retired capacity, MW'
         'MaxPotGWh'       'Theoretical maximum annual energy production, GWh'
         'GenGWh'          'Total New Zealand output, GWh'
         'RenewGWh'        'Energy produced from renewable sources, GWh'
         'TxGWh'           'Total New Zealand interregional transmission, GWh'
         'IITxGWh'         'Total inter-island transmission, GWh'
         'TxLossGWh'       'Total New Zealand interregional transmission losses, GWh'
         'IITxLossGWh'     'Total inter-island transmission losses, GWh'
         'IntraLossGWh'    'Total intraregional transmission losses, GWh'
         'Losses$m'        'Annual value of losses (intraregional and interregional) valued at LRMC, $m'
         'DemGWh'          'Energy demand, GWh'
         'tCO2'            'CO2e emissions, tonnes'
         'fOMpre$m'        'Fixed O&M expenses (pre tax), $m'
         'fOMpost$m'       'Fixed O&M expenses (post tax), $m'
         'HVDCpre$m'       'HVDC charges (pre tax), $m'
         'HVDCpost$m'      'HVDC charges (post tax), $m'
         'vOMpre$m'        'Variable O&M expenses with LF adjustment (pre tax), $m'
         'vOMpreNoLF$m'    'Variable O&M expenses without LF adjustment (pre tax), $m'
         'vOMpost$m'       'Variable O&M expenses with LF adjustment (post tax), $m'
         'vOMpostNoLF$m'   'Variable O&M expenses without LF adjustment (post tax), $m'
         'Fuelpre$m'       'Fuel expenses with LF adjustment (pre tax), $m'
         'FuelpreNoLF$m'   'Fuel expenses without LF adjustment (pre tax), $m'
         'Fuelpost$m'      'Fuel expenses with LF adjustment (post tax), $m'
         'FuelpostNoLF$m'  'Fuel expenses without LF adjustment (post tax), $m'
         'Ctaxpre$m'       'CO2 charges with LF adjustment (pre tax), $m'
         'CtaxpreNoLF$m'   'CO2 charges without LF adjustment (pre tax), $m'
         'Ctaxpost$m'      'CO2 charges with LF adjustment (post tax), $m'
         'CtaxpostNoLF$m'  'CO2 charges without LF adjustment (post tax), $m'
         'CCSpre$m'        'CCS expenses with LF adjustment (pre tax), $m'
         'CCSpreNoLF$m'    'CCS expenses without LF adjustment (pre tax), $m'
         'CCSpost$m'       'CCS expenses with LF adjustment (post tax), $m'
         'CCSpostNoLF$m'   'CCS expenses without LF adjustment (post tax), $m'
         'CapCost$m'       'Pre tax lumpy capital cost of new generation plants, $m (real)'
         'CapexR$m'        'Generation capex charges (net of depreciation tax credit effects) by year, $m (real)'
         'CapexPV$m'       'Generation capex charges (net of depreciation tax credit effects) by year, $m (present value)'
         'TxCapCost$m'     'Pre tax lumpy capital cost of new transmission investments by year, $m (real)'
         'TxCapexR$m'      'Transmission capex charges (net of depreciation tax credit effects) by year, $m (real)'
         'TxCapexPV$m'     'Transmission capex charges (net of depreciation tax credit effects) by year, $m (present value)'       /

  rper   Labels for results by time period
       / 'RegNRG$/MWh'    'Regional energy price, $/MWh'   /

  rrsv   Labels for reserve results
       / 'NI RESV'         'Reserves scheduled in NI, MW'
         'SI RESV'         'Reserves scheduled in SI, MW'
         'SI>>NI'          'Reserves transferred from SI to NI, MW'
         'NI>>SI'          'Reserves transferred from NI to SI, MW'
         'NI REQ'          'NI reserve requirement, MW'
         'SI REQ'          'SI reserve requirement, MW'
         'SINGLE REQ'      'Single reserve requirement, MW'
         'NI VIOL'         'NI reserve violation, MW'
         'SI VIOL'         'SI reserve violation, MW'       /

$ontext
  The peak results are not calculated or used at this point in time.
  peakr  Labels for peak results
       / 'NI GEN'          'Generation in the NI during peak, MW'
         'SI GEN'          'Generation in the SI during peak, MW'
         'NI>>SI TX'       'Flow from NI to SI during peak, MW'
         'SI>>NI TX'       'Flow from SI to NI during peak, MW'
         'NI>>SI LOSS'     'Losses from NI to SI during peak, MW'
         'SI>>NI LOSS'     'Losses from SI to NI during peak, MW'
         'NI LOAD'         'Load in the NI during peak, MW'
         'SI LOAD'         'Load in the SI during peak, MW'  /
$offtext
  ;

Parameters
  counter                                'A counter'
  pltresults(mds,rt,g,pr)                'Results pertaining to generating plant - see set pr'
  pltresultsyr(mds,rt,hd,pryr,g,y)       'Results pertaining to generating plant by year - see set pryr'
  resultsyr(mds,rt,hd,y,ryr)             'Results pertaining to years - see set ryr'
  resultsyrt(mds,rt,hd,y,t,r,rper)       'Results pertaining to periods within years - see set rper'
  largestunit(mds,rt,rc,ild,y,t,lb,hd)   'Reserve risk set by the largest dispatched unit during other periods, MW'
  windprop(mds,rt,rc,ild,y,t,lb,hd)      'Reserve risk set by the proportion of dispatched wind during other periods, MW'
  resvtrfrrisk(mds,rt,rc,ild,y,t,lb,hd)  'Reserve risk set by HVDC transfer during other periods, MW'
  resvreqdisp(mds,rt,rc,ild,y,t,lb,hd)   'Reserve requirement during other periods for display, MW'
  resultresv(mds,rt,hd,rc,y,t,lb,rrsv)   'Results pertaining to energy reserves per time period - see set rrsv'
  nrgtx(mds,rt,hd,r,rr,y,t,lb)           'Actual energy transmitted by path and load block, GWh'
  nrgtx_pot(mds,rt,hd,r,rr,y,t,lb)       'Potential energy transmitted by path and load block, GWh'
  nrgloss_pc(mds,rt,hd,r,rr,t,y)         'Energy (or MW for that matter) lost in transmission as a percent of transmission'
  ;



*===============================================================================================
* 3. Create output files - by plant, by year, by plant and year, by year and period, and for energy reserves.

* a) Compute results by generating plant, set 'pr'.
loop((mds,rt,g,k)$( mds_rt(mds,rt) * mapg_k(g,k) ),
  if(exist(g),
    loop(firstyr(y),
      pltresults(mds,rt,g,'InstMW')  = s3_capacity(mds,rt,g,y) ;
      pltresults(mds,rt,g,'FirmMW')  = peakconm(g,y,mds) * s3_capacity(mds,rt,g,y) ;
      pltresults(mds,rt,g,'MinUtil') = gendata(g,'MinUtil') ;
    ) ;
  else
    loop(y$s3_build(mds,rt,g,y),
      pltresults(mds,rt,g,'ErlyYr')  = erlyComYr(g,mds) ;
      pltresults(mds,rt,g,'BldYr')$( pltresults(mds,rt,g,'BldYr') = 0 ) = yearnum(y) ;
      pltresults(mds,rt,g,'InstMW')  = sum(yy, s3_build(mds,rt,g,yy)) ;
      pltresults(mds,rt,g,'FirmMW')  = peakconm(g,y,mds) * sum(yy, s3_build(mds,rt,g,yy)) ;
      pltresults(mds,rt,g,'MinUtil') = gendata(g,'MinUtil') ;
    ) ;
  ) ;
  loop(y$( s3_retire(mds,rt,g,y) or exogretireMWm(g,y,mds) ),
    pltresults(mds,rt,g,'RetireYr')  = fixDecomYr(g,mds) ;
    pltresults(mds,rt,g,'RetireMW')  = s3_retire(mds,rt,g,y) + exogretireMWm(g,y,mds) ;
  ) ;
) ;



* b) Compute results by generating plant by year, set 'pryr'.
loop((mds,rt,hd,g,y,k,f)$( mds_rt_hd(mds,rt,hd) * mapg_k(g,k) * mapg_f(g,f) ),
  pltresultsyr(mds,rt,hd,'GenGWh',g,y)             = genyr(mds,rt,g,y,hd) ;
  pltresultsyr(mds,rt,hd,'NZInstMW',g,y)           = s3_capacity(mds,rt,g,y) ;
  pltresultsyr(mds,rt,hd,'NZFirmMW',g,y)           = peakconm(g,y,mds) * s3_capacity(mds,rt,g,y) ;
  pltresultsyr(mds,rt,hd,'NIInstMW',g,y)           = sum(ild$( ni(ild) * mapg_ild(g,ild) ), s3_capacity(mds,rt,g,y)) ;
  pltresultsyr(mds,rt,hd,'NIFirmMW',g,y)           = sum(ild$( ni(ild) * mapg_ild(g,ild) ), peakconm(g,y,mds) * s3_capacity(mds,rt,g,y)) ;
  pltresultsyr(mds,rt,hd,'MaxPotGWh',g,y)$s3_capacity(mds,rt,g,y) = 1e-3 * s3_capacity(mds,rt,g,y) * sum((t,lb), maxcapfact(g,t,lb) * hrsperblk(t,lb)) ;
  pltresultsyr(mds,rt,hd,'Util%',g,y)$nameplate(g) = 100 * genyr(mds,rt,g,y,hd) / ( 8.76 * nameplate(g) ) ;
  pltresultsyr(mds,rt,hd,'FuelPJ',thermgen(g),y)   = genyr(mds,rt,g,y,hd) * heatrate(g) * 1e-6 ;
  pltresultsyr(mds,rt,hd,'tCO2',thermgen(g),y)     = genyr(mds,rt,g,y,hd) * heatrate(g) * (1 - CCSfac(y,k)) * emitm(mds,f) * 1e-6 ;
  pltresultsyr(mds,rt,hd,'CapexPV$m',g,y)          = sum(gend(d), capchrg_pv(mds,rt,g,y,d)) ;
  pltresultsyr(mds,rt,hd,'TaxCrdPV$m',g,y)         = sum(gend(d), taxcred_pv(mds,rt,g,y,d)) ;
  pltresultsyr(mds,rt,hd,'CapexR$m',g,y)           = capchrg_r(mds,rt,g,y) ;
  pltresultsyr(mds,rt,hd,'TaxCrdR$m',g,y)          = taxcred_r(mds,rt,g,y) ;
  pltresultsyr(mds,rt,hd,'CapCost$m',g,y)          = 1/1e6 * capcostm(g,mds) * s3_build(mds,rt,g,y) ;
  pltresultsyr(mds,rt,hd,'fOMpre$m',g,y)           = sum(t, fopexgross_r(mds,rt,g,y,t)) ;
  pltresultsyr(mds,rt,hd,'fOMpost$m',g,y)          = sum(t, fopexnet_r(mds,rt,g,y,t)) ;
  pltresultsyr(mds,rt,hd,'HVDCpre$m',g,y)          = sum(t, hvdcgross_r(mds,rt,g,y,t)) ;
  pltresultsyr(mds,rt,hd,'HVDCpost$m',g,y)         = sum(t, hvdcnet_r(mds,rt,g,y,t)) ;
  pltresultsyr(mds,rt,hd,'vOMpre$m',g,y)           = 1e-3 * sum(mapg_e(g,e), varOMm(g,y,mds) * genyr(mds,rt,g,y,hd) * locfac_recip(e) ) ;
  pltresultsyr(mds,rt,hd,'vOMpreNoLF$m',g,y)       = 1e-3 * varOMm(g,y,mds) * genyr(mds,rt,g,y,hd) ;
  pltresultsyr(mds,rt,hd,'vOMpost$m',g,y)          = (1 - taxrate) * pltresultsyr(mds,rt,hd,'vOMpre$m',g,y) ;
  pltresultsyr(mds,rt,hd,'vOMpostNoLF$m',g,y)      = (1 - taxrate) * pltresultsyr(mds,rt,hd,'vOMpreNoLF$m',g,y) ;
  pltresultsyr(mds,rt,hd,'Fuelpre$m',g,y)          = 1e-3 * sum(mapg_e(g,e), fuelcostm(g,y,mds) * genyr(mds,rt,g,y,hd) * locfac_recip(e) ) ;
  pltresultsyr(mds,rt,hd,'FuelpreNoLF$m',g,y)      = 1e-3 * fuelcostm(g,y,mds) * genyr(mds,rt,g,y,hd) ;
  pltresultsyr(mds,rt,hd,'Fuelpost$m',g,y)         = (1 - taxrate) * pltresultsyr(mds,rt,hd,'Fuelpre$m',g,y) ;
  pltresultsyr(mds,rt,hd,'FuelpostNoLF$m',g,y)     = (1 - taxrate) * pltresultsyr(mds,rt,hd,'FuelpreNoLF$m',g,y) ;
  pltresultsyr(mds,rt,hd,'Ctaxpre$m',g,y)          = 1e-3 * sum(mapg_e(g,e), co2taxm(g,y,mds) * genyr(mds,rt,g,y,hd) * locfac_recip(e) ) ;
  pltresultsyr(mds,rt,hd,'CtaxpreNoLF$m',g,y)      = 1e-3 * co2taxm(g,y,mds) * genyr(mds,rt,g,y,hd) ;
  pltresultsyr(mds,rt,hd,'Ctaxpost$m',g,y)         = (1 - taxrate) * pltresultsyr(mds,rt,hd,'Ctaxpre$m',g,y) ;
  pltresultsyr(mds,rt,hd,'CtaxpostNoLF$m',g,y)     = (1 - taxrate) * pltresultsyr(mds,rt,hd,'CtaxpreNoLF$m',g,y) ;
  pltresultsyr(mds,rt,hd,'CCSpre$m',g,y)           = 1e-3 * sum(mapg_e(g,e), carboncscostm(g,y,mds) * genyr(mds,rt,g,y,hd) * locfac_recip(e) ) ;
  pltresultsyr(mds,rt,hd,'CCSpreNoLF$m',g,y)       = 1e-3 * carboncscostm(g,y,mds) * genyr(mds,rt,g,y,hd) ;
  pltresultsyr(mds,rt,hd,'CCSpost$m',g,y)          = (1 - taxrate) * pltresultsyr(mds,rt,hd,'CCSpre$m',g,y) ;
  pltresultsyr(mds,rt,hd,'CCSpostNoLF$m',g,y)      = (1 - taxrate) * pltresultsyr(mds,rt,hd,'CCSpreNoLF$m',g,y) ;
) ;



* c) Compute results by year, set 'ryr'.
loop((mds,rt,hd,y)$mds_rt_hd(mds,rt,hd),
  resultsyr(mds,rt,hd,y,'TxUpgrades')     = sum(tupg, s3_txprojvar(mds,rt,tupg,y)) ;
  resultsyr(mds,rt,hd,y,'NZInstMW')       = sum(g, s3_capacity(mds,rt,g,y)) ;
  resultsyr(mds,rt,hd,y,'NZFirmMW')       = sum(g, peakconm(g,y,mds) * s3_capacity(mds,rt,g,y)) ;
  resultsyr(mds,rt,hd,y,'NIInstMW')       = sum((g,ild)$( ni(ild) * mapg_ild(g,ild) ), s3_capacity(mds,rt,g,y)) ;
  resultsyr(mds,rt,hd,y,'NIFirmMW')       = sum((g,ild)$( ni(ild) * mapg_ild(g,ild) ), peakconm(g,y,mds) * s3_capacity(mds,rt,g,y)) ;
  resultsyr(mds,rt,hd,y,'RetireMW')       = sum(g, s3_retire(mds,rt,g,y) + exogretireMWm(g,y,mds)) ;
  resultsyr(mds,rt,hd,y,'MaxPotGWh')      = sum(g, pltresultsyr(mds,rt,hd,'MaxPotGWh',g,y)) ;
  resultsyr(mds,rt,hd,y,'GenGWh')         = sum(g, pltresultsyr(mds,rt,hd,'GenGWh',g,y)) ;
  resultsyr(mds,rt,hd,y,'RenewGWh')       = sum((g,k)$( mapg_k(g,k) * renew(k) ), genyr(mds,rt,g,y,hd)) ;
  resultsyr(mds,rt,hd,y,'TxGWh')          = sum((paths(r,rr),t,lb), s3_Tx(mds,rt,paths,y,t,lb,hd) * hrsperblk(t,lb) * 1e-3 ) ;
  resultsyr(mds,rt,hd,y,'IITxGWh')        = sum((paths(r,rr),t,lb)$( nwd(r,rr) or swd(r,rr) ), s3_Tx(mds,rt,paths,y,t,lb,hd) * hrsperblk(t,lb) * 1e-3 ) ;
  resultsyr(mds,rt,hd,y,'TxLossGWh')      = sum((paths(r,rr),t,lb), s3_loss(mds,rt,paths,y,t,lb,hd) * hrsperblk(t,lb) * 1e-3 ) ;
  resultsyr(mds,rt,hd,y,'IITxLossGWh')    = sum((paths(r,rr),t,lb)$( nwd(r,rr) or swd(r,rr) ), s3_loss(mds,rt,paths,y,t,lb,hd) * hrsperblk(t,lb) * 1e-3 ) ;
  resultsyr(mds,rt,hd,y,'IntraLossGWh')   = sum((ild,r,t,lb)$mapild_r(ild,r), load(y,lb,mds,r,t) * AClossFactor(ild) / ( 1 + AClossFactor(ild) ) ) ;
  resultsyr(mds,rt,hd,y,'Losses$m')       = 1.0e-3 * %LossValue% * (resultsyr(mds,rt,hd,y,'TxLossGWh') + resultsyr(mds,rt,hd,y,'IntraLossGWh')) ;
  resultsyr(mds,rt,hd,y,'Losses$m')       = 1.0e-3 * %LossValue% * (resultsyr(mds,rt,hd,y,'TxLossGWh')) ;
  resultsyr(mds,rt,hd,y,'DemGWh')         = sum((r,t,lb), ldcMWm(mds,r,t,lb,y) * hrsperblk(t,lb)) * 1e-3 ;
  resultsyr(mds,rt,hd,y,'tCO2')           = sum(g, pltresultsyr(mds,rt,hd,'tCO2',g,y)) ;
  resultsyr(mds,rt,hd,y,'fOMpre$m')       = sum(g, pltresultsyr(mds,rt,hd,'fOMpre$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'fOMpost$m')      = sum(g, pltresultsyr(mds,rt,hd,'fOMpost$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'HVDCpre$m')      = sum(g, pltresultsyr(mds,rt,hd,'HVDCpre$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'HVDCpost$m')     = sum(g, pltresultsyr(mds,rt,hd,'HVDCpost$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'vOMpre$m')       = sum(g, pltresultsyr(mds,rt,hd,'vOMpre$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'vOMpreNoLF$m')   = sum(g, pltresultsyr(mds,rt,hd,'vOMpreNoLF$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'vOMpost$m')      = sum(g, pltresultsyr(mds,rt,hd,'vOMpost$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'vOMpostNoLF$m')  = sum(g, pltresultsyr(mds,rt,hd,'vOMpostNoLF$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'Fuelpre$m')      = sum(g, pltresultsyr(mds,rt,hd,'Fuelpre$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'FuelpreNoLF$m')  = sum(g, pltresultsyr(mds,rt,hd,'FuelpreNoLF$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'Fuelpost$m')     = sum(g, pltresultsyr(mds,rt,hd,'Fuelpost$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'FuelpostNoLF$m') = sum(g, pltresultsyr(mds,rt,hd,'FuelpostNoLF$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'Ctaxpre$m')      = sum(g, pltresultsyr(mds,rt,hd,'Ctaxpre$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'CtaxpreNoLF$m')  = sum(g, pltresultsyr(mds,rt,hd,'CtaxpreNoLF$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'Ctaxpost$m')     = sum(g, pltresultsyr(mds,rt,hd,'Ctaxpost$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'CtaxpostNoLF$m') = sum(g, pltresultsyr(mds,rt,hd,'CtaxpostNoLF$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'CCSpre$m')       = sum(g, pltresultsyr(mds,rt,hd,'Ctaxpre$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'CCSpreNoLF$m')   = sum(g, pltresultsyr(mds,rt,hd,'CCSpreNoLF$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'CCSpost$m')      = sum(g, pltresultsyr(mds,rt,hd,'CCSpost$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'CCSpostNoLF$m')  = sum(g, pltresultsyr(mds,rt,hd,'CCSpostNoLF$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'CapCost$m')      = sum(g, pltresultsyr(mds,rt,hd,'CapCost$m',g,y)) ;
  resultsyr(mds,rt,hd,y,'CapexR$m')       = capchrgyr_r(mds,rt,y) ;
  resultsyr(mds,rt,hd,y,'CapexPV$m')      = sum(gend(d), capchrgyr_pv(mds,rt,y,d)) ;
  resultsyr(mds,rt,hd,y,'TxCapCost$m')    = sum(transitions(tupg,r,rr,ps,pss)$alltxps(r,rr,pss), txcapcost(r,rr,pss) * s3_txprojvar(mds,rt,tupg,y)) ;
  resultsyr(mds,rt,hd,y,'TxCapexR$m')     = txcapchrgyr_r(mds,rt,y) ;
  resultsyr(mds,rt,hd,y,'TxCapexPV$m')    = sum(txd(d), txcapchrgyr_pv(mds,rt,y,d)) ;
) ;



* d) Compute results by year and period, set 'rper'.
* Calculate regional prices for all run types by taking a weighted average over each period (hours per block are the weights).
loop((mds,rt,hd,y,t)$mds_rt_hd(mds,rt,hd),
  resultsyrt(mds,rt,hd,y,t,r,'RegNRG$/MWh') = 1e3 * sum((lb,gend(d)), hrsperblk(t,lb) * s3_bal_supdem(mds,rt,r,y,t,lb,hd) / PVfacsM(y,t,d)) / sum(lb, hrsperblk(t,lb)) ;
) ;



* e) Compute various results related to reserves.
largestunit(mds,rt,arc,ild,y,t,lb,hd)$( mds_rt_hd(mds,rt,hd) * useresv * resvact(arc) * ( (resvreq(arc,ild,y) = -1) or (resvreq(arc,ild,y) = -3) ) ) =
  smax(g$mapg_ild(g,ild), (1e3 * s3_gen(mds,rt,g,y,t,lb,hd) * unitlargestprop(g)) ) / hrsperblk(t,lb) ;

windprop(mds,rt,arc,ild,y,t,lb,hd)$( mds_rt_hd(mds,rt,hd) * useresv * resvact(arc) * ( (resvreq(arc,ild,y) = -2) or (resvreq(arc,ild,y) = -3) ) * propwindcover(arc) ) =
  ( propwindcover(arc) * sum(mapg_k(g,k)$( wind(k) * mapg_ild(g,ild) ), 1e3 * s3_gen(mds,rt,g,y,t,lb,hd) ) ) / hrsperblk(t,lb) ;

resvtrfrrisk(mds,rt,arc,ild,y,t,lb,hd)$( mds_rt_hd(mds,rt,hd) * useresv * resvact(arc) ) =
  sum((paths(r,rr),interild(ild,ild1))$(    mapild_r(ild1,r) * mapild_r(ild,rr) ), s3_tx(mds,rt,r,rr,y,t,lb,hd) - s3_loss(mds,rt,r,rr,y,t,lb,hd) ) -
  sum((paths(r,rr),ps,interild(ild,ild1))$( mapild_r(ild1,r) * mapild_r(ild,rr) ), txcapPO(r,rr,ps) * s3_btx(mds,rt,r,rr,ps,y) ) ;

resvreqdisp(mds,rt,arc,ild,y,t,lb,hd)$mds_rt_hd(mds,rt,hd) =
  max( resvreq(arc,ild,y)$( resvreq(arc,ild,y) > 0 ),
       resvtrfrrisk(mds,rt,arc,ild,y,t,lb,hd)$( not singleresvreqf(arc) ),
       largestunit(mds,rt,arc,ild,y,t,lb,hd)$( ( resvreq(arc,ild,y) = -1 ) or ( resvreq(arc,ild,y) = -3 ) ),
       windprop(mds,rt,arc,ild,y,t,lb,hd)$( ( resvreq(arc,ild,y) = -2 ) or ( resvreq(arc,ild,y) = -3 ) )
     ) ;

*Display largestunit, windprop, resvtrfrrisk, resvreqdisp  ;



* f) Compute reserve energy results, set 'rrsv'.
loop(mds_rt_hd(mds,rt,hd),
  resultresv(mds,rt,hd,arc,y,t,lb,'NI RESV') = sum(g$mapg_ild(g,'ni'), s3_resv(mds,rt,g,arc,y,t,lb,hd)) / hrsperblk(t,lb) ;
  resultresv(mds,rt,hd,arc,y,t,lb,'SI RESV') = sum(g$mapg_ild(g,'si'), s3_resv(mds,rt,g,arc,y,t,lb,hd)) / hrsperblk(t,lb) ;
  resultresv(mds,rt,hd,arc,y,t,lb,'SI>>NI') = s3_resvtrfr(mds,rt,arc,'si','ni',y,t,lb,hd) / hrsperblk(t,lb) ;
  resultresv(mds,rt,hd,arc,y,t,lb,'NI>>SI') = s3_resvtrfr(mds,rt,arc,'ni','si',y,t,lb,hd) / hrsperblk(t,lb) ;
  resultresv(mds,rt,hd,arc,y,t,lb,'NI REQ')$( not singleresvreqf(arc) ) = resvreqdisp(mds,rt,arc,'ni',y,t,lb,hd) ;
  resultresv(mds,rt,hd,arc,y,t,lb,'SI REQ')$( not singleresvreqf(arc) ) = resvreqdisp(mds,rt,arc,'si',y,t,lb,hd) ;
  resultresv(mds,rt,hd,arc,y,t,lb,'SINGLE REQ')$singleresvreqf(arc) = smax(ild, resvreqdisp(mds,rt,arc,ild,y,t,lb,hd)) ;
  resultresv(mds,rt,hd,arc,y,t,lb,'NI VIOL') = s3_resvviol(mds,rt,arc,'ni',y,t,lb,hd) / hrsperblk(t,lb) ;
  resultresv(mds,rt,hd,arc,y,t,lb,'SI VIOL') = s3_resvviol(mds,rt,arc,'si',y,t,lb,hd) / hrsperblk(t,lb) ;
) ;



* g) Write out a whole slew of delimited files using the parameters created in (a) thru (f).
*    NB: .txt tab-delimited for use in Matlab or .csv comma-delimited for use in Excel.

* Write out generating plant info, set 'pr'.
* - Row headers - plant, run type, technology, fuel type, zone, region, island and owner.
* - Column header is elements of set 'pr'.
* - One table of results per file, one file per MDS.
loop(mds$mds_sim(mds),

  putclose bat 'copy temp.dat "' "%OutPath%\%OutPrefix%\Processed files\", "%OutPrefix%", ' - Plant info - All inflows - ', mds.tl, '.%suffix%"' / ;

  put temp 'Plant', 'RT', 'Tech', 'Fuel', 'Zone', 'Region', 'Island', 'Owner' ; loop(pr, put pr.te(pr) ) ;
  loop((rt,g,k,f,e,r,ild,o)$(
      sum(pr, pltresults(mds,rt,g,pr)) * mapg_k(g,k) * mapg_f(g,f) * mapg_e(g,e) * mapg_r(g,r) * mapg_ild(g,ild) * mapg_o(g,o)  ),
    put / g.tl, rt.tl, k.tl, f.tl, e.tl, r.tl, ild.tl, o.tl ;
    loop(pr, put pltresults(mds,rt,g,pr)) ;
  ) ;
  putclose ;

  execute 'temp.bat';

) ;



* Write out generating plant info by year, set 'pryr'.
* - Row headers - plant, run type, hydro domain, technology, fuel type, zone, region and owner.
* - Column header is years.
* - One table of results per file, one file per MDS-pryr combo.
loop((mds,pryr)$mds_sim(mds),

  putclose bat 'copy temp.dat "' "%OutPath%\%OutPrefix%\Processed files\", "%OutPrefix%", ' - Plant info by year - ', pryr.te(pryr), ' - ', mds.tl, '.%suffix%"' / ;

  put temp 'Plant', 'RT', 'hd', 'Tech', 'Fuel', 'Zone', 'Region', 'Owner' ; loop(y, put y.tl ) ;
  loop((rt,hd,g,k,f,e,r,o)$( sum(y, pltresultsyr(mds,rt,hd,pryr,g,y)) * mapg_k(g,k) * mapg_f(g,f) * mapg_e(g,e) * mapg_r(g,r) * mapg_o(g,o) ),
    put / g.tl, rt.tl, hd.tl, k.tl, f.tl, e.tl, r.tl, o.tl ;
    loop(y, put pltresultsyr(mds,rt,hd,pryr,g,y) ) ;
  ) ;
  putclose ;

  execute 'temp.bat';

) ; 



* Write out results by year, set 'ryr'.
* - Row headers - Attribute, run type, and hydro domain.
* - Column header is years.
* - One table of results per file, one file per MDS.
loop(mds$mds_sim(mds),

  putclose bat 'copy temp.dat "' "%OutPath%\%OutPrefix%\Processed files\", "%OutPrefix%", ' - Yearly info - All inflows - ' ,mds.tl, '.%suffix%"' / ;

  put temp 'Series', 'RT', 'hd' ; loop(y, put y.tl ) ;
  loop((ryr,rt,hd)$( sum(y, resultsyr(mds,rt,hd,y,ryr)) ),
    put / put ryr.te(ryr), rt.tl, hd.tl ;
    loop(y, put resultsyr(mds,rt,hd,y,ryr)) ;
  ) ;
  putclose ;
  
  execute 'temp.bat';

) ;



* Write out results by period within the year, set 'rper'.
* - Row headers - Attribute, run type, hydro domain, region, and modelled year.
* - Column header is elements of set 't'.
* - One table of results per file, one file per MDS.
loop(mds$mds_sim(mds),

  putclose bat 'copy temp.dat "' "%OutPath%\%OutPrefix%\Processed files\", "%OutPrefix%", ' - Periodic info - All inflows - ' ,mds.tl, '.%suffix%"' / ;

  put temp 'Series', 'RT', 'hd', 'Region', 'Year' ; loop(t, put t.tl ) ;
  loop((rper,rt,hd,r,y)$mds_rt_hd(mds,rt,hd),
    put / rper.te(rper), rt.tl, hd.tl, r.tl, y.tl ; loop(t, put resultsyrt(mds,rt,hd,y,t,r,rper)) ;
  ) ;
  putclose ;

  execute 'temp.bat';

) ;



* Write out the energy reserves supplied by period (MW) - only if reserves formulation is activated, set 'rrsv'.
* - Row headers - MDS, run type, hydro domain, reserve class, modelled year, period and load block.
* - Column header is elements of set 'pr'.
* - Just one file.
if(useresv = 1,
  put ResvE 'MDS', 'RT', 'hd', 'ReserveClass', 'y', 't', 'LB' ; loop(rrsv, put rrsv.tl ) ;
  loop((mds_rt_hd(mds,rt,hd),arc,y,t,lb),
    put / mds.tl, rt.tl, hd.tl, arc.tl, y.tl, t.tl, lb.tl loop(rrsv, put resultresv(mds,rt,hd,arc,y,t,lb,rrsv) ) ;
  ) ;
) ;



* Write out the energy reserves generated by plant by period (MW) - only if reserves formulation is activated.
* - Row headers - MDS, run type, hydro domain, plant, reserve class, period and load block.
* - Column header is modelled years.
* - Just one file.
if(useresv = 1,
  put GResvE 'MDS', 'RT', 'hd', 'Plant', 'ReserveClass', 't', 'Lb' ; loop(y, put y.tl ) ;
  loop((mds_rt_hd(mds,rt,hd),g,arc,t,lb),
    put / mds.tl, rt.tl, hd.tl, g.tl, arc.tl, t.tl, lb.tl loop(y, put (s3_resv(mds,rt,g,arc,y,t,lb,hd) / hrsperblk(t,lb)) ) ;
  ) ;
) ;



*===============================================================================================
* 4. Write out various files of output relating to generation, e.g. energy dispatched, energy prices etc.

* Potential and actual GWh output at each plant by time period and load block.
put GenNrg 'MDS', 'RT', 'hd', 'Plant', 'Tech', 'Period', 'Blk', 'HrsPerBlk', 'MaxCapFact', 'ActOrPotGWh' ; loop(y, put y.tl:0 ) ;
loop((mds,rt,g,k,t,lb,hd)$( mds_rt_hd(mds,rt,hd) * mapg_k(g,k) * sum(y, s3_capacity(mds,rt,g,y)) ),
  put / mds.tl, rt.tl, hd.tl, g.tl, k.tl, t.tl, lb.tl, hrsperblk(t,lb), maxcapfact(g,t,lb), 'ActualGWh' loop(y, put s3_gen(mds,rt,g,y,t,lb,hd)) ;
  put / mds.tl, rt.tl, hd.tl, g.tl, k.tl, t.tl, lb.tl, hrsperblk(t,lb), maxcapfact(g,t,lb), 'PotentialGWh' ;
  if(schedhydro(g),
    loop(y, put ( s3_hydoutput(mds,rt,g,y,t,hd) * hrsperblk(t,lb) / sum(lbb, hrsperblk(t,lbb)) ) )  ;
  else
    loop(y, put ( 1e-3 * s3_capacity(mds,rt,g,y) * maxcapfact(g,t,lb) * hrsperblk(t,lb) ) ) ;
  ) ;
) ;

* Energy dispatched by plant by load block in .csv file format.
put nrgdis, 'MDS', 'RT', 'Plant', 't', 'Blk', 'hd', 'hrs' ; loop(y, put y.tl:0 ) ;
loop((mds,rt,g,t,lb,hd)$( mds_rt_hd(mds,rt,hd) and ( exist(g) or buildyr(mds,g) ) ),
  put / mds.tl, rt.tl, g.tl, t.tl, lb.tl, hd.tl, hrsperblk(t,lb) ;
  loop(y, put s3_gen(mds,rt,g,y,t,lb,hd) ) ;
) ;

* Energy prices by load block in .csv file format.
put nrgprce, 'MDS', 'RT', 'Reg', 't', 'Blk', 'hd', 'hrs' ; loop(y, put y.tl:0 ) ;
loop((mds,rt,r,t,lb,hd)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, r.tl, t.tl, lb.tl, hd.tl, hrsperblk(t,lb) ;
  loop(y, put s3_bal_supdem(mds,rt,r,y,t,lb,hd) ) ;
) ;



*===============================================================================================
* 5. Write out the transmission results.

nrgTx(mds,rt,hd,paths,y,t,lb)$mds_rt_hd(mds,rt,hd) = 1e-3 * s3_Tx(mds,rt,paths,y,t,lb,hd) * hrsperblk(t,lb) ;

nrgTx_pot(mds,rt,hd,paths,y,t,lb)$mds_rt_hd(mds,rt,hd) = 1e-3 * sum(alltxps(paths,ps), txcap(paths,ps) * s3_btx(mds,rt,paths,ps,y) * hrsperblk(t,lb) ) ;

nrgloss_pc(mds,rt,hd,paths,t,y)$sum(lb, s3_Tx(mds,rt,paths,y,t,lb,hd)) = 100 * sum(lb, s3_loss(mds,rt,paths,y,t,lb,hd)) / sum(lb, s3_Tx(mds,rt,paths,y,t,lb,hd)) ;

* Energy - write all valid arcs, not just the non-zeroes.
put TxNrga 'MDS', 'RT', 'hd', 'From', 'To', 't' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr),t)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl, t.tl ;
  loop(y, put (1e-3 * sum(lb, s3_Tx(mds,rt,paths,y,t,lb,hd) * hrsperblk(t,lb))) ) ;
) ;

put TxNrgb 'MDS', 'RT', 'hd', 'From', 'To', 't' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr),t)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl, t.tl ;
  loop(y, put sum((alltxps(paths,ps),lb), 1e-3 * txcap(paths,ps) * s3_btx(mds,rt,paths,ps,y) * hrsperblk(t,lb) ) ) ;
) ;

put TxNrgc 'MDS', 'RT', 'hd', 'From', 'To', 't' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr),t)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl, t.tl ;
  loop(y, put (1e-3 * sum(lb, s3_loss(mds,rt,paths,y,t,lb,hd) * hrsperblk(t,lb))) ) ;
) ;

put TxNrgd 'MDS', 'RT', 'hd', 'From', 'To', 't' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr),t)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl, t.tl ;
  loop(y, put nrgloss_pc(mds,rt,hd,paths,t,y) ) ;
) ;

put TxNrge 'MDS', 'RT', 'hd', 'From', 'To', 't', 'LB' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr),t,lb)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl, t.tl, lb.tl, loop(y, put nrgTx(mds,rt,hd,paths,y,t,lb)) ;
) ;

put TxNrgf 'MDS', 'RT', 'hd', 'From', 'To', 't', 'LB' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr),t,lb)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl, t.tl, lb.tl ; loop(y,  put nrgTx_pot(mds,rt,hd,paths,y,t,lb)) ;
) ;

* Next 3 files are MW - write all valid arcs, not just the non-zeroes.
put TxMWa 'MDS', 'RT', 'hd', 'From', 'To' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr))$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl ;
  loop(y, put sum(alltxps(paths,ps), txcap(paths,ps) * s3_btx(mds,rt,paths,ps,y) ) ) ;
) ;

put TxMWb 'MDS', 'RT', 'hd', 'From', 'To', 't', 'Lb', 'BlkHrs' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr),t,lb)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl, t.tl, lb.tl, hrsperblk(t,lb) loop(y, put s3_Tx(mds,rt,paths,y,t,lb,hd) ) ;
) ;

put TxMWc 'MDS', 'RT', 'hd', 'From', 'To', 't', 'Lb' ; loop(y, put y.tl ) ;
loop((mds,rt,hd,paths(r,rr),t,lb)$mds_rt_hd(mds,rt,hd),
  put / mds.tl, rt.tl, hd.tl, r.tl, rr.tl, t.tl, lb.tl loop(y, put s3_loss(mds,rt,paths,y,t,lb,hd) ) ;
) ;



*===============================================================================================
*  6. Dump selected output into a into a GDX file for use in subsequent programs, e.g. GEMaccess.

Execute_Unload '%OutPath%\%Outprefix%\GDX\%Outprefix% - PlotData.gdx',
  pr, pryr, ryr, rper, rrsv
  pltresults, pltresultsyr, resultsyr, resultsyrt, resultresv
  ;



*===============================================================================================
* 7. Write the housekeeping files.
*    Generate a batch file which, upon execution, will archive most of the input files.

bat.ap = 0 ;
putclose bat
  'copy %Solver%.op*                    "%OutPath%\%OutPrefix%\Archive\"' /
  'copy f.awk                           "%OutPath%\%OutPrefix%\Archive\f.awk"' /
  'copy temp.dat                        "%OutPath%\%OutPrefix%\Archive\ReadMe.txt"' /
  'copy *RunGEM*.gms                    "%OutPath%\%OutPrefix%\Archive\"' /
  'copy m*plot.bat                      "%OutPath%\%OutPrefix%\Archive\"' /
  'copy ModSettings.inc                 "%OutPath%\%OutPrefix%\Archive\ModSettings.inc"' /
  'copy %ModelName%.gms                 "%OutPath%\%OutPrefix%\Archive\%ModelName%.gms"' /
  'copy %ModelName%.g00                 "%OutPath%\%OutPrefix%\Archive\%ModelName%.g00"' /
  'copy %BaseName%.gms                  "%OutPath%\%OutPrefix%\Archive\%BaseName%.gms"' /
  'copy %BaseName%.g00                  "%OutPath%\%OutPrefix%\Archive\%BaseName%.g00"' /
  'copy %BaseOutName%.gms               "%OutPath%\%OutPrefix%\Archive\%BaseOutName%.gms"' /
  'copy %ExecName%.gms                  "%OutPath%\%OutPrefix%\Archive\%ExecName%.gms"' /
  'copy %PrepOutName%.gms               "%OutPath%\%OutPrefix%\Archive\%PrepOutName%.gms"' /
  'copy %RepName%.gms                   "%OutPath%\%OutPrefix%\Archive\%RepName%.gms"' /
  'copy %PlotName%.gms                  "%OutPath%\%OutPrefix%\Archive\%PlotName%.gms"' /
  'copy GEM%Solver%.gms                 "%OutPath%\%OutPrefix%\Archive\GEM%Solver%.gms"' /
  'copy GEMtoAccess.gms.gms             "%OutPath%\%OutPrefix%\Archive\GEMtoAccess.gms"' /
  'copy GEMcompare.gms                  "%OutPath%\%OutPrefix%\Archive\GEMcompare.gms"' /
  'copy "%DataPath%%InputData%"         "%OutPath%\%OutPrefix%\Archive\%InputData%"' /
  'copy "%DataPath%%TxInputData%"       "%OutPath%\%OutPrefix%\Archive\%TxInputData%"' /
  'copy "%DataPath%%GDXfilename%"       "%OutPath%\%OutPrefix%\Archive\%GDXfilename%"' /
  'if exist %logfile% copy %logfile%    "%OutPath%\%OutPrefix%\Archive\%logfile%"' /
  'if exist RunGEM.cmd copy RunGEM.cmd  "%OutPath%\%OutPrefix%\Archive\RunGEM.cmd"' /
  'erase "%OutPrefix% - *.gdx"' / ;
bat.ap = 1 ;
if(%PlotMIPtrace%=1, putclose bat 'copy miptrace.bat "%OutPath%\%OutPrefix%\Archive\miptrace.bat"' / ) ;
bat.ap = 0 ;

* Create the 'Readme.txt' file for the archive directory (use/overwrite temp.dat).
temp.lw = 0 ; temp.pc = 2 ;
put temp 'The files in this directory were used to generate the model run entitled "' system.title '".' //
  'The model run finished at ' system.time ' on ' system.date '.' //
  'Make sure you inspect the file called "%OutPrefix% - A solve summary report.txt" which, at the time of model' /
  'execution, would be located in the folder called "%OutPath%\%OutPrefix%".' //
  'File versions' /
  '  Main input data file:       Version ' loop(dataversion,   put DataVersion.tl ) ;   put '  (filename: "%InputData%")' /
  '  Regions/Tx input data file: Version ' loop(txdataversion, put TxDataVersion.tl ) ; put '  (filename: "%TxInputData%")' /
  '  GDX input file:             Version ' loop(GEMgdxVer,     put GEMgdxVer.tl ) ;     put '  (filename: "%GDXfilename%")' /
  '  %ModelName%.gms/g00:        Version ' loop(GEMmodelVer,   put GEMmodelVer.tl ) ;   put / 
  '  %BaseName%.gms:             Version ' loop(GEMbaseVer,    put GEMbaseVer.tl ) ;    put / 
  '  %BaseOutName%.gms:          Version ' loop(GEMbaseoutVer, put GEMbaseoutVer.tl ) ; put / 
  '  %ExecName%.gms:             Version ' loop(GEMexecVer,    put GEMexecVer.tl ) ;    put / 
  '  %PrepOutName%.gms:          Version ' loop(GEMprepoutVer, put GEMprepoutVer.tl ) ; put / 
  '  %RepName%.gms:              Version ' loop(GEMreportsVer, put GEMreportsVer.tl ) ; put / 
  '  %PlotName%.gms:             Version ' loop(GEMplotsVer,   put GEMplotsVer.tl ) ;
putclose ;

* Write some stuff to echo to the console when GEM run is finished.
put ver ///
  '    GEM has now finished running...' / '    ' system.time / '    ' system.date  ////
  '    Generation Expansion Model (GEM)' /
  '    Copyright (C) 2007, New Zealand Electricity Commission' /
  '    Reference: http://gemmodel.pbworks.com/' /
  '    Contact: gem@electricitycommission.govt.nz' //
  '    Main Excel input file:'       @34 'Version ' loop(dataversion,   put DataVersion.tl ) ;   put '   (filename: "%InputData%")' /
  '    Regions/Tx Excel input file:' @34 'Version ' loop(TxDataVersion, put TxDataVersion.tl ) ; put '   (filename: "%TxInputData%")' /
  '    GDX input file:'              @34 'Version ' loop(GEMgdxVer,     put GEMgdxVer.tl ) ;     put '   (filename: "%GDXfilename%")' /
  '    %ModelName%.gms/g00:'         @34 'Version ' loop(GEMmodelVer,   put GEMmodelVer.tl ) ;   put / 
  '    %BaseName%.gms:'              @34 'Version ' loop(GEMbaseVer,    put GEMbaseVer.tl ) ;    put / 
  '    %BaseOutName%.gms:'           @34 'Version ' loop(GEMbaseoutVer, put GEMbaseoutVer.tl ) ; put / 
  '    %ExecName%.gms:'              @34 'Version ' loop(GEMexecVer,    put GEMexecVer.tl ) ;    put / 
  '    %PrepOutName%.gms:'           @34 'Version ' loop(GEMprepoutVer, put GEMprepoutVer.tl ) ; put / 
  '    %RepName%.gms:'               @34 'Version ' loop(GEMreportsVer, put GEMreportsVer.tl ) ; put / 
  '    %PlotName%.gms:'              @34 'Version ' loop(GEMplotsVer,   put GEMplotsVer.tl ) ;   put //// ;
  if((slacks + problems + warnings) > 0,
    put '    ==========================================================================' //
        '              PROBLEMS REQUIRING ATTENTION EXIST WITH SOME SOLUTIONS.         ' /
        '         Examine the solve summary report (search for ++++), %logfile%,       ' /
        '         or %ExecName%.lst and, if necessary, resolve before proceeding.      ' //
        '    ==========================================================================' //// ;
  ) ;
putclose ;


* Put a final note in the solve summary report.
ss.ap = 1 ;
putclose ss //// 'The model run finished at ' system.time ' on ' system.date '.' ;




* End of file
