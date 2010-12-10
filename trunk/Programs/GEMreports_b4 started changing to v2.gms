* GEMreports.gms


* Last modified by Dr Phil Bishop, 24/05/2010 (gem@electricitycommission.govt.nz)


set GEMreportsVer 'GEMreports.gms version number'  / '1.5.11' / ;


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


 This program is to be run after GEMprepout and it must be run before GEMplots, i.e. GEMplots requires some
 GDX files that are passed from GEMreports. GEMreports will ordinarily be invoked from the batch file,
 RunGEM.gms, but can also be invoked manually. The relevant GEMbase work file must be called at invocation.
 For example, c:\> gams GEMreports r=GEMbase
 Recall that the 's3_' series of solution values has no hYr domain, i.e. s3 results for the 'dis' run type
 are averaged over all hydro years, excluding the average hydro year itself.

 Code sections:
  1. Load the data required to generate reports from the GDX files.
  2. Declare the sets and parameters local to GEMreports.
  3. Perform the various calculations required to generate reports.
  4. Write out the summary results report.
  5. Write out the generation and transmission investment schedules in various formats.
     a) Build, refurbishment and retirement data and outcomes in easy to read format suitable for importing into Excel.
     b) Write out generation and transmission investment schedules in a formatted text file (i.e. human-readable)
     c) Write out the build and retirement schedule - in SOO-ready format.
     d) Write out the forced builds by MDS - in SOO-ready format (in the same file as SOO build schedules).
     e) Build schedule in GAMS-readable format - only write this file if GEM was run (i.e. skip it if RunType = 2).
     f) Write out a file to create maps of generation plant builds/retirements.
     g) Write out a file to create maps of transmission upgrades.
  6. Write out various summaries of the MW installed net of retirements.
  7. Write out various summaries of activity associated with peaking plant.
  8. Write out the GIT summary results.
  9. Write a report of HVDC charges sliced and diced all different ways.
 10. Write a report of features common to all scenarios.
 11. Write out a file of miscellaneous scalars - to pass to Matlab.
 12. Write out the mapping of inflow years to modelled years.
 13. Collect national generation, transmission, losses and load (GWh) into a single parameter.
 14. Write the solve summary report.
 15. Report the presence of penalty or slack (i.e. violation) variables (if any).
 16. Dump certain parameters into GDX files for use in subsequent programs, e.g. GEMplots and GEMaccess.
$offtext




*===============================================================================================
* 1. Load the data required to generate reports from the GDX files.

$gdxin '%OutPath%\%Outprefix%\GDX\%Outprefix% - PreparedOutput.gdx'
$loaddc GEMexecVer GEMprepoutVer dum mds_rt mds_rt_hd numdisyrs s_solveindex s_hdindex s_inflowyr MIPreport RMIPreport
$loaddc s2_totalcost
$loaddc %List_10_s3params%, %List_13_s3params%, %List_10_s3slacks%



*===============================================================================================
* 2. Declare the sets and parameters local to GEMreports.

Sets
* Capacity
  activecap(mdsx,g,y)         'Identify all plant that are active in any given year, i.e. existing or built but never retired'
  pkrs_plus20(mdsx,rt,hd,g)   'Identify peakers that produce 20% or more energy in a year than they are theoretically capable of'
  noPkr_minus20(mdsx,rt,hd,g) 'Identify non-peakers that produce less than 20% of the energy in a year than they are theoretically capable of'

  a 'Activity'        / blt   'Potential and actual built capacity by technology (gross of retirements)'
                        rfb   'Potential and actual refurbished capacity by technology'
                        rtd   'Potential and actual retired capacity by technology'   /
* Objective value components
  objc      'Objective function components'
             / obj_total      'Objective function value'
               obj_gencapex   'Discounted levelised generation plant capital costs'
               obj_refurb     'Discounted levelised refurbishment capital costs'
               obj_txcapex    'Discounted levelised transmission capital costs'
               obj_fixOM      'After tax discounted fixed costs at generation plant'
               obj_hvdc       'After tax discounted HVDC charges'
               obj_varOM      'After tax discounted variable costs at generation plant'
               VoLLcost       'After tax discounted value of lost load'
               obj_rescosts   'After tax discounted reserve costs at generation plant'
               obj_nfrcosts   'After tax discounted cost of non-free reserve cover for HVDC'
               obj_renNrg     'Penalty cost of failing to meet renewables target'
               obj_resvviol   'Penalty cost of failing to meet reserves'
               slk_rstrctMW   'Slack on restriction on annual MW built'
               slk_nzsec      'Slack on NZ security constraint'
               slk_ni1sec     'Slack on NI1 security constraint'
               slk_ni2sec     'Slack on NI2 security constraint'
               slk_nzNoWnd    'Slack on NZ no wind security constraint'
               slk_niNoWnd    'Slack on NI no wind security constraint'
               slk_renCap     'Slack on renewable capacity constraint'
               slk_limHyd     'Slack on limit hydro output constraint'
               slk_minutil    'Slack on minimum utilisation constraint'
               slk_limFuel    'Slack on limit fuel use constraint'    /
  pen(objc) 'Penalty components of objective function'
             / obj_renNrg, obj_resvviol  /
  slk(objc) 'Slack components of objective function'
             / slk_rstrctMW, slk_nzsec, slk_ni1sec, slk_ni2sec, slk_nzNoWnd, slk_niNoWnd, slk_renCap, slk_limHyd, slk_minutil, slk_limFuel /

* GIT analysis
  cy        'Class of years'
             / git            'Years entering the GIT analysis'
               trm            'Terminal years' /
  item      'Item of GIT analysis'
             / itm1           'Capex (generation plant) before depreciation tax credit, $m PV'
               itm2           'Fixed Opex before tax, $m PV'
               itm3           'HVDC charge before tax, $m PV'
               itm4           'Variable Opex before tax, $m PV'
               itm5           'Capex (generation plant) after depreciation tax credit, $m PV'
               itm6           'Fixed Opex after tax, $m PV'
               itm7           'HVDC charge after tax, $m PV'
               itm8           'Variable Opex after tax, $m PV'
               itm9           'Capex (transmission equipment) before depreciation tax credit, $m PV'
               itm10          'Capex (transmission equipment) after depreciation tax credit, $m PV'
               itmA           'Generation fixed benefits (A)'
               itmB           'Generation variable benefits (B)'
               itmC           'Transmission costs (C)'
               itmD           'Terminal benefits (D)'
               itmE           'Expected net markets benefit (A+B-C+D)'  /
  git(cy)   'Years entering the GIT analysis'    / git /
  trm(cy)   'Terminal years'                     / trm /
  gityrs(y) 'GIT analysis years'
  trmyrs(y) 'Terminal period years'
  mapcy_y(cy,y) 'Map modelled years into year classes'

* Analysis of features common to all scenarios solved.
  buildall(g)              'Identify all plant built in all scenarios'
  buildall_sameyr(g)       'Identify all plant built in the same year in all scenarios'
  buildall_notsameyr(g)    'Identify all plant built in all scenarios but in different years in at least two scenarios'
  build_close5(g,mds,mdss) 'A step to identifying all plant built within 5 years of each other (but not in the same year) in all scenarios'
  buildclose5(g)           'Identify all plant built within 5 years of each other (but not in the same year) in all scenarios'
  buildplus5(g)            'Identify all plant built in all scenarios where the build year is more than 5 years apart'
  ;

Parameters
  obj_components_yr(mdsx,rt,y,*)       'Components of objective function value by year (tmg, reo and average over all hydrology for dispatch solves)'
  obj_components(mdsx,rt,objc)         'Components of objective function value (tmg, reo and average over all hydrology for dispatch solves)'
  GITresults(item,d,mdsx,dt,cy)        'GIT analysis summary'
  Chktotals(mds,rt,*)                  'Calculate national generation, transmission, losses and load, GWh'

* Items common to all MDSs (where more than one MDS is solved)
  numMDS_fact                          '(NumMDS)!'
  numMDS_fact2                         '(NumMDS - 2)!'
  numCombos                            'numMDS_fact / 2 * numMDS_fact2, i.e. the number of ways of picking k unordered outcomes from n possibilities'
  retiresame(mdsx,g,y)                 'MW retired and year retired is the same across all MDSs'
  refurbsame(mdsx,g)                   'Refurbishment year is the same across all MDSs'
  txupgradesame(mdsx,tupg,y)           'Transmission upgrade and upgrade year is the same across all MDSs'

* Capacity and dispatch
  pot_cap(mdsx,k,a)                    'Potential capacity able to be built/refurbished/retired by technology, MW'
  act_cap(mdsx,rt,k,a)                 'Actual capacity built/refurbished/retired by technology, MW'
  actual_cappc(mdsx,rt,k,a)            'Actual capacity built/refurbished/retired as a percentage of potential by technology'
  PartialMWblt(mdsx,g)                 'The MW actually built in the case of plant not fully constructed'
  numpltbldyrs(mdsx,g,y)               'Identify the number of years taken to build a generating plant (-1 indicates plant is retired)'
  buildorretireMW(mdsx,g,y)            'Collect up both build (positive) and retirement (negative), MW'
  buildyr(mdsx,g)                      'Year in which new generating plant is built, or first built if built over multiple years'
  retireyr(mdsx,g)                     'Year in which generating plant is retired'
  buildMW(mdsx,g)                      'MW built at each generating plant able to be built'
  retireMW(mdsx,g)                     'MW retired at each generating plant able to be retired'
  finalMW(mdsx,g)                      'Existing plus built less retired MW by plant'
  totexistMW(mdsx)                     'Total existing generating capacity, MW'
  totexistdsm(mdsx)                    'Total existing DSM and IL capacity, MW'
  totbuiltMW(mdsx)                     'Total new generating capacity installed, MW'
  totbuiltdsm(mdsx)                    'Total new DSM and IL capacity installed, MW'
  totretiredMW(mdsx)                   'Total retired capacity, MW'
  genyr(mdsx,rt,g,y,hd)                'Generation by plant and year, GWh'
  defgen(mdsx,rt,hd,y,t,lb)            'Aggregate deficit generation (i.e. sum over all shortage generators), GWh'
  defgenyr(mdsx,rt,hd,y)               'Deficit generation by year, GWh'
  xsdefgen(mdsx,rt,hd,y,t,lb)          'Excessive deficit generation in any load block, period or year (excessive means it exceeds 3% of total generation), GWh'
  genTWh(mdsx,rt,hd)                   'Generation - includes DSM, IL and Shortage (deficit) generation, TWh'
  gendsm(mdsx,rt,hd)                   'DSM and IL dispatched, GWh'
  genpkr(mdsx,rt,hd)                   'Generation by thermal peakers, GWh'
  txlossGWh(mdsx,rt,hd)                'Transmission losses, GWh'
  actualtxcap(mdsx,rt,r,rr,y)          'Actual transmission capacity for each path in each modelled year'
  numtxbldyrs(mdsx,tupg,y)             'Identify the number of years taken to build a particular upgrade of a transmission investment'
  frcap(r,rr,ps)                       'Transmission capacity prior to a state change for all states (assuming binary state changes), MW'
  tocap(r,rr,ps)                       'Transmission capacity after a state change for all states (assuming binary state changes), MW'

* Reserves
  totalresvviol(mds,rt,rc,hd)          'Total energy reserves violation, MW (to be written into results summary report)'

* Generation capex
  capchrg_r(mds,rt,g,y)                'Capex charges (net of depreciation tax credit effects) by built plant by year, $m (real)'
  capchrg_pv(mds,rt,g,y,d)             'Capex charges (net of depreciation tax credit effects) by built plant by year, $m (present value)'
  capchrgyr_r(mds,rt,y)                'Capex charges on built plant (net of depreciation tax credit effects) by year, $m (real)'
  capchrgyr_pv(mds,rt,y,d)             'Capex charges on built plant (net of depreciation tax credit effects) by year, $m (present value)'
  capchrgplt_r(mds,rt,g)               'Capex charges (net of depreciation tax credit effects) by plant, $m (real)'
  capchrgplt_pv(mds,rt,g,d)            'Capex charges (net of depreciation tax credit effects) by plant, $m (present value)'
  capchrgtot_r(mds,rt)                 'Total capex charges on built plant (net of depreciation tax credit effects), $m (real)'
  capchrgtot_pv(mds,rt,d)              'Total capex charges on built plant (net of depreciation tax credit effects), $m (present value)'

  taxcred_r(mds,rt,g,y)                'Tax credit on depreciation by built plant by year, $m (real)'
  taxcred_pv(mds,rt,g,y,d)             'Tax credit on depreciation by built plant by year, $m (present value)'
  taxcredyr_r(mds,rt,y)                'Tax credit on depreciation of built plant by year, $m (real)'
  taxcredyr_pv(mds,rt,y,d)             'Tax credit on depreciation of built plant by year, $m (present value)'
  taxcredplt_r(mds,rt,g)               'Tax credit on depreciation by plant, $m (real)'
  taxcredplt_pv(mds,rt,g,d)            'Tax credit on depreciation by plant, $m (present value)'
  taxcredtot_r(mds,rt)                 'Total tax credit on depreciation of built plant, $m (real)'
  taxcredtot_pv(mds,rt,d)              'Total tax credit on depreciation of built plant, $m (present value)'

* Generation plant fixed costs
  fopexgross_r(mds,rt,g,y,t)           'Fixed O&M expenses (before tax benefit) by built plant by year by period, $m (real)'
  fopexgross_pv(mds,rt,g,y,t,d)        'Fixed O&M expenses (before tax benefit) by built plant by year by period, $m (present value)'
  fopexnet_r(mds,rt,g,y,t)             'Fixed O&M expenses (after tax benefit) by built plant by year by period, $m (real)'
  fopexnet_pv(mds,rt,g,y,t,d)          'Fixed O&M expenses (after tax benefit) by built plant by year by period, $m (present value)'
  fopexgrosstot_r(mds,rt)              'Total fixed O&M expenses (before tax benefit), $m (real)'
  fopexgrosstot_pv(mds,rt,d)           'Total fixed O&M expenses (before tax benefit), $m (present value)'
  fopexnettot_r(mds,rt)                'Total fixed O&M expenses (after tax benefit), $m (real)'
  fopexnettot_pv(mds,rt,d)             'Total fixed O&M expenses (after tax benefit), $m (present value)'

* Generation plant HVDC costs
  hvdcgross_r(mds,rt,g,y,t)            'HVDC charges (before tax benefit) by built plant by year by period, $m (real)'
  hvdcgross_pv(mds,rt,g,y,t,d)         'HVDC charges (before tax benefit) by built plant by year by period, $m (present value)'
  hvdcnet_r(mds,rt,g,y,t)              'HVDC charges (after tax benefit) by built plant by year by period, $m (real)'
  hvdcnet_pv(mds,rt,g,y,t,d)           'HVDC charges (after tax benefit) by built plant by year by period, $m (present value)'
  hvdcgrosstot_r(mds,rt)               'Total HVDC charges (before tax benefit), $m (real)'
  hvdcgrosstot_pv(mds,rt,d)            'Total HVDC charges (before tax benefit), $m (present value)'
  hvdcnettot_r(mds,rt)                 'Total HVDC charges (after tax benefit), $m (real)'
  hvdcnettot_pv(mds,rt,d)              'Total HVDC charges (after tax benefit), $m (present value)'

* Generation plant total SRMCs
  vopexgross_r(mds,rt,g,y,t,hd)        'Variable O&M expenses with LF adjustment (before tax benefit) by built plant by year by period, $m (real)'
  vopexgross_pv(mds,rt,g,y,t,hd,d)     'Variable O&M expenses with LF adjustment (before tax benefit) by built plant by year by period, $m (present value)'
  vopexnet_r(mds,rt,g,y,t,hd)          'Variable O&M expenses with LF adjustment (after tax benefit) by built plant by year by period, $m (real)'
  vopexnet_pv(mds,rt,g,y,t,hd,d)       'Variable O&M expenses with LF adjustment (after tax benefit) by built plant by year by period, $m (present value)'
  vopexgrosstot_r(mds,rt,hd)           'Total variable O&M expenses with LF adjustment (before tax benefit), $m (real)'
  vopexgrosstot_pv(mds,rt,hd,d)        'Total variable O&M expenses with LF adjustment (before tax benefit), $m (present value)'
  vopexnettot_r(mds,rt,hd)             'Total variable O&M expenses with LF adjustment (after tax benefit), $m (real)'
  vopexnettot_pv(mds,rt,hd,d)          'Total variable O&M expenses with LF adjustment (after tax benefit), $m (present value)'

  vopexgrossnolf_r(mds,rt,g,y,t,hd)    'Variable O&M expenses without LF adjustment (before tax benefit) by built plant by year by period, $m (real)'
  vopexgrossnolf_pv(mds,rt,g,y,t,hd,d) 'Variable O&M expenses without LF adjustment (before tax benefit) by built plant by year by period, $m (present value)'
  vopexnetnolf_r(mds,rt,g,y,t,hd)      'Variable O&M expenses without LF adjustment (after tax benefit) by built plant by year by period, $m (real)'
  vopexnetnolf_pv(mds,rt,g,y,t,hd,d)   'Variable O&M expenses without LF adjustment (after tax benefit) by built plant by year by period, $m (present value)'
  vopexgrosstotnolf_r(mds,rt,hd)       'Total variable O&M expenses without LF adjustment (before tax benefit), $m (real)'
  vopexgrosstotnolf_pv(mds,rt,hd,d)    'Total variable O&M expenses without LF adjustment (before tax benefit), $m (present value)'
  vopexnettotnolf_r(mds,rt,hd)         'Total variable O&M expenses without LF adjustment (after tax benefit), $m (real)'
  vopexnettotnolf_pv(mds,rt,hd,d)      'Total variable O&M expenses without LF adjustment (after tax benefit), $m (present value)'

* Transmission equipment capex
  txcapchrg_r(mds,rt,r,rr,ps,y)        'Transmission capex charges (net of depreciation tax credit effects) by built equipment by year, $m (real)'
  txcapchrg_pv(mds,rt,r,rr,ps,y,d)     'Transmission capex charges (net of depreciation tax credit effects) by built equipment by year, $m (present value)'
  txcapchrgyr_r(mds,rt,y)              'Transmission capex charges (net of depreciation tax credit effects) by year, $m (real)'
  txcapchrgyr_pv(mds,rt,y,d)           'Transmission capex charges (net of depreciation tax credit effects) by year, $m (present value)'
  txcapchrgeqp_r(mds,rt,r,rr,ps)       'Transmission capex charges (net of depreciation tax credit effects) by equipment, $m (real)'
  txcapchrgeqp_pv(mds,rt,r,rr,ps,d)    'Transmission capex charges (net of depreciation tax credit effects) by equipment, $m (present value)'
  txcapchrgtot_r(mds,rt)               'Total transmission capex charges (net of depreciation tax credit effects), $m (real)'
  txcapchrgtot_pv(mds,rt,d)            'Total transmission capex charges (net of depreciation tax credit effects), $m (present value)'

  txtaxcred_r(mds,rt,r,rr,ps,y)        'Tax credit on depreciation by built transmission equipment by year, $m (real)'
  txtaxcred_pv(mds,rt,r,rr,ps,y,d)     'Tax credit on depreciation by built transmission equipment by year, $m (present value)'
  txtaxcredyr_r(mds,rt,y)              'Tax credit on depreciation on transmission equipment by year, $m (real)'
  txtaxcredyr_pv(mds,rt,y,d)           'Tax credit on depreciation on transmission equipment by year, $m (present value)'
  txtaxcredeqp_r(mds,rt,r,rr,ps)       'Tax credit on depreciation by transmission equipment, $m (real)'
  txtaxcredeqp_pv(mds,rt,r,rr,ps,d)    'Tax credit on depreciation by transmission equipment, $m (present value)'
  txtaxcredtot_r(mds,rt)               'Total tax credit on depreciation of transmission equipment, $m (real)'
  txtaxcredtot_pv(mds,rt,d)            'Total tax credit on depreciation of transmission equipment, $m (present value)'   ;



*===============================================================================================
* 3. Perform the various calculations required to generate reports.

* Compute the components of the objective function value by year (Note that for run type 'dis', it's the average that gets computed).
obj_components_yr(mds_rt(mds,rt),y,'PVfacG_t1')    = sum(firstper(t), PVfacG(y,t)) ;
obj_components_yr(mds_rt(mds,rt),y,'PVfacT_t1')    = sum(firstper(t), PVfacT(y,t)) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_total')    = s3_totalcost(mds,rt) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_gencapex') = 1e-6 * sum(posbuildm(g,mds), capchargem(g,y,mds) * s3_capacity(mds,rt,g,y) ) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_refurb')   = 1e-6 * sum(posrefurbm(g,mds), s3_refurbcost(mds,rt,g,y) ) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_txcapex')  = sum(paths, s3_txcapcharges(mds,rt,paths,y) ) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_fixOM')    = 1e-6 / card(t) * (1 - taxrate) * sum((g,t), PVfacG(y,t) * fixedOM(g) * s3_capacity(mds,rt,g,y)) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_hvdc')     = 1e-6 / card(t) * (1 - taxrate) *
                                                     sum((g,k,o,t)$( (not demgen(k)) * sigen(g) * posbuildm(g,mds) * mapg_k(g,k) * mapg_o(g,o) ),
                                                     PVfacG(y,t) * hvdcshr(o) * hvdcchargem(y,mds) * s3_capacity(mds,rt,g,y) ) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_varOM')    = 1e-6 * (1 - taxrate) * sum((t,hd), PVfacG(y,t) * 1e3 * hydweight(hd) *
                                                     sum((g,lb), s3_gen(mds,rt,g,y,t,lb,hd) * srmcm(g,y,mds) * sum(mapg_e(g,e), locfac_recip(e)) ) ) ;
obj_components_yr(mds_rt(mds,rt),y,'VoLLcost')     = 1e-6 * (1 - taxrate) * sum((t,hd), PVfacG(y,t) * 1e3 * hydweight(hd) *
                                                     sum((s,lb), s3_vollgen(mds,rt,s,y,t,lb,hd) * voll(s) ) ) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_rescosts') = 1e-6 * (1 - taxrate) * sum((g,arc,t,lb,hd), PVfacG(y,t) * hydweight(hd) * s3_resv(mds,rt,g,arc,y,t,lb,hd) * resvcost(g,arc) ) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_nfrcosts') = 1e-6 * (1 - taxrate) * sum((paths,t,lb,hd,stp)$( nwd(paths) or swd(paths) ),
                                                     PVfacG(y,t) * hydweight(hd) * (hrsperblk(t,lb) * s3_resvcomponents(mds,rt,paths,y,t,lb,hd,stp)) * pnfresvcost(paths,stp) ) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_renNrg')   = penaltyRenNrg * s3_rennrgpenalty(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'obj_resvviol') = 1e-6 * sum((arc,ild,t,lb,hd), hydweight(hd) * resvvpen(arc,ild) * s3_resvviol(mds,rt,arc,ild,y,t,lb,hd) ) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_rstrctMW') = 9999 * s3_annmwslack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_nzsec')    = 9998 * s3_sec_NZslack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_ni1sec')   = 9998 * s3_sec_NI1slack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_ni2sec')   = 9998 * s3_sec_NI2slack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_nzNoWnd')  = 9997 * s3_NoWind_NZslack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_niNoWnd')  = 9997 * s3_NoWind_NIslack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_rencap')   = 9996 * s3_renCapSlack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_limhyd')   = 9995 * s3_hydroSlack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_minutil')  = 9994 * s3_minutilSlack(mds,rt,y) ;
obj_components_yr(mds_rt(mds,rt),y,'slk_limfuel')  = 9993 * s3_fuelSlack(mds,rt,y) ;

* Compute the components of the objective function value (Note that for run type 'dis', it's the average that gets computed).
obj_components(mds_rt(mds,rt),'obj_total')    = s3_totalcost(mds,rt) ;
obj_components(mds_rt(mds,rt),'obj_gencapex') = 1e-6 * sum((y,firstper(t),posbuildm(g,mds)), PVfacG(y,t) * capchargem(g,y,mds) * s3_capacity(mds,rt,g,y) ) ;
obj_components(mds_rt(mds,rt),'obj_refurb')   = 1e-6 * sum((y,firstper(t),posrefurbm(g,mds)), PVfacG(y,t) * s3_refurbcost(mds,rt,g,y) ) ;
obj_components(mds_rt(mds,rt),'obj_txcapex')  = sum((paths,y,firstper(t)), PVfacT(y,t) * s3_txcapcharges(mds,rt,paths,y) ) ;
obj_components(mds_rt(mds,rt),'obj_fixOM')    = 1e-6 / card(t) * (1 - taxrate) * sum((g,y,t), PVfacG(y,t) * fixedOM(g) * s3_capacity(mds,rt,g,y)) ;
obj_components(mds_rt(mds,rt),'obj_hvdc')     = 1e-6 / card(t) * (1 - taxrate) *
                                                sum((g,k,o,y,t)$( (not demgen(k)) * sigen(g) * posbuildm(g,mds) * mapg_k(g,k) * mapg_o(g,o) ),
                                                  PVfacG(y,t) * hvdcshr(o) * hvdcchargem(y,mds) * s3_capacity(mds,rt,g,y) ) ;
obj_components(mds_rt(mds,rt),'obj_varOM')    = 1e-6 * (1 - taxrate) * sum((y,t,hd), PVfacG(y,t) * 1e3 * hydweight(hd) *
                                                sum((g,lb), s3_gen(mds,rt,g,y,t,lb,hd) * srmcm(g,y,mds) * sum(mapg_e(g,e), locfac_recip(e)) ) ) ;
obj_components(mds_rt(mds,rt),'VoLLcost')     = 1e-6 * (1 - taxrate) * sum((y,t,hd), PVfacG(y,t) * 1e3 * hydweight(hd) *
                                                sum((s,lb), s3_vollgen(mds,rt,s,y,t,lb,hd) * voll(s) ) ) ;
obj_components(mds_rt(mds,rt),'obj_rescosts') = 1e-6 * (1 - taxrate) * sum((g,arc,y,t,lb,hd), PVfacG(y,t) * hydweight(hd) * s3_resv(mds,rt,g,arc,y,t,lb,hd) * resvcost(g,arc) ) ;
obj_components(mds_rt(mds,rt),'obj_nfrcosts') = 1e-6 * (1 - taxrate) * sum((paths,y,t,lb,hd,stp)$( nwd(paths) or swd(paths) ),
                                                PVfacG(y,t) * hydweight(hd) * (hrsperblk(t,lb) * s3_resvcomponents(mds,rt,paths,y,t,lb,hd,stp)) * pnfresvcost(paths,stp) ) ;
obj_components(mds_rt(mds,rt),'obj_renNrg')   = sum(y, penaltyRenNrg * s3_rennrgpenalty(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'obj_resvviol') = 1e-6 * sum((arc,ild,y,t,lb,hd), hydweight(hd) * resvvpen(arc,ild) * s3_resvviol(mds,rt,arc,ild,y,t,lb,hd) ) ;
obj_components(mds_rt(mds,rt),'slk_rstrctMW') = 9999 * sum(y, s3_annmwslack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_nzsec')    = 9998 * sum(y, s3_sec_NZslack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_ni1sec')   = 9998 * sum(y, s3_sec_NI1slack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_ni2sec')   = 9998 * sum(y, s3_sec_NI2slack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_nzNoWnd')  = 9997 * sum(y, s3_NoWind_NZslack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_niNoWnd')  = 9997 * sum(y, s3_NoWind_NIslack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_rencap')   = 9996 * sum(y, s3_renCapSlack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_limhyd')   = 9995 * sum(y, s3_hydroSlack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_minutil')  = 9994 * sum(y, s3_minutilSlack(mds,rt,y)) ;
obj_components(mds_rt(mds,rt),'slk_limfuel')  = 9993 * sum(y, s3_fuelSlack(mds,rt,y)) ;

buildyr(mds,g) = 0 ;
retireyr(mds,g) = 0 ;
retireMW(mds,g) = 0 ;

loop(mds_rt(mds,rt),

* Capacity and dispatch
  pot_cap(mds,k,'blt') = sum(posbuildm(g,mds)$mapg_k(g,k), nameplate(g)) ;
  pot_cap(mds,k,'rfb') = sum(posrefurbm(g,mds)$mapg_k(g,k), nameplate(g)) ;
  pot_cap(mds,k,'rtd') = sum(posretirem(g,mds)$mapg_k(g,k), nameplate(g)) ;

* Calculations that relate only to the run type in which capacity expansion/contraction decisions are made.
  if(bldrslt(rt),

    activecap(mds,g,y)$s3_capacity(mds,rt,g,y) = yes ;

    act_cap(mds,rt,k,'blt') = sum(validbldyrm(g,y,mds)$mapg_k(g,k), s3_build(mds,rt,g,y)) ;
    act_cap(mds,rt,k,'rfb') = sum(posrefurbm(g,mds)$mapg_k(g,k), (1 - s3_isretired(mds,rt,g)) * nameplate(g) ) ;
    act_cap(mds,rt,k,'rtd') = sum((posretirem(g,mds),y)$mapg_k(g,k), s3_retire(mds,rt,g,y) + exogretireMWm(g,y,mds)) ;

    actual_cappc(mds,rt,k,a)$pot_cap(mds,k,a) = 100 * act_cap(mds,rt,k,a) / pot_cap(mds,k,a) ;

    PartialMWblt(mds_sim(mds),g)$( (nameplate(g) - sum(y, s3_build(mds,rt,g,y)) > 1.0e-9) ) = sum(y, s3_build(mds,rt,g,y)) ;

    counter = 0 ;
    loop(g,
      loop(y$s3_build(mds,rt,g,y), counter = counter + 1 ; numpltbldyrs(mds,g,y) = counter ) ;
      counter = 0 ;
    ) ;
    numpltbldyrs(mds,g,y)$( s3_retire(mds,rt,g,y) or exogretireMWm(g,y,mds) ) = -1 ;

    buildorretireMW(mds,g,y) = s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds) ;

    loop(y,
      buildyr(mds,g)$(  buildyr(mds,g) = 0  and   s3_build(mds,rt,g,y) ) = yearnum(y) ;
      retireyr(mds,g)$( retireyr(mds,g) = 0 and ( s3_retire(mds,rt,g,y) or exogretireMWm(g,y,mds) ) ) = yearnum(y) ;
    ) ;

    buildMW(mds,g) = sum(y, s3_build(mds,rt,g,y)) ;

    retireMW(mds,g) = sum(y, s3_retire(mds,rt,g,y) + exogretireMWm(g,y,mds)) ;

    finalMW(mds,g) = nameplate(g)$exist(g) + buildMW(mds,g) - retireMW(mds,g) ;

    totexistMW(mds)  = sum((g,f)$( exist(g) * mapg_f(g,f) ), nameplate(g) ) ;
    totexistdsm(mds) = sum((g,k)$( exist(g) * mapg_k(g,k) * demgen(k) ), nameplate(g) ) ;

    totbuiltMW(mds)  = sum(g, buildMW(mds,g)) ;
    totbuiltdsm(mds) = sum((g,k)$( mapg_k(g,k) * demgen(k) ), buildMW(mds,g)) ;

    totretiredMW(mds) = sum(g, retireMW(mds,g)) ;

* End of capacity expansion/contraction calculations.
  ) ;

  genyr(mds,rt,g,y,hd)$mds_rt_hd(mds,rt,hd)  = sum((t,lb), s3_gen(mds,rt,g,y,t,lb,hd)) ;

  genTWh(mds_rt_hd(mds,rt,hd)) = 1e-3 * sum((g,y), genyr(mds,rt,g,y,hd)) ;
  gendsm(mds_rt_hd(mds,rt,hd)) = sum((g,y,k)$( mapg_k(g,k) * demgen(k) ), genyr(mds,rt,g,y,hd)) ;
  genpkr(mds_rt_hd(mds,rt,hd)) = sum((g,y,k)$( mapg_k(g,k) * peaker(k) ), genyr(mds,rt,g,y,hd)) ;

  defgen(mds_rt_hd(mds,rt,hd),y,t,lb) = sum(s, s3_vollgen(mds,rt,s,y,t,lb,hd)) ;
  defgenyr(mds_rt_hd(mds,rt,hd),y) = sum((t,lb), defgen(mds,rt,hd,y,t,lb)) ;
  xsdefgen(mds_rt_hd(mds,rt,hd),y,t,lb)$( defgen(mds,rt,hd,y,t,lb) > ( .03 * sum(g, s3_gen(mds,rt,g,y,t,lb,hd)) ) ) = defgen(mds,rt,hd,y,t,lb) ;

  txlossGWh(mds_rt_hd(mds,rt,hd)) = 1e-3 * sum((r,rr,y,t,lb), s3_loss(mds,rt,r,rr,y,t,lb,hd) * hrsperblk(t,lb) ) ;

  actualtxcap(mds,rt,paths,y) = sum(ps, txcap(paths,ps) * s3_btx(mds,rt,paths,ps,y)) ; 

  counter = 0 ;
  loop(tupg$bldrslt(rt),
    loop(y$s3_txprojvar(mds,rt,tupg,y), counter = counter + 1 ; numtxbldyrs(mds,tupg,y) = counter ) ;
    counter = 0 ;
  ) ;

  loop(ps,
    frcap(r,rr,ps)$alltxps(r,rr,ps) = txcap(r,rr,ps) ;
    tocap(r,rr,ps+1)$alltxps(r,rr,ps+1) = txcap(r,rr,ps+1) ;
  ) ;

* Reserves
  totalresvviol(mds,rt,rc,hd)$mds_rt_hd(mds,rt,hd) = sum((ild,y,t,lb), s3_resvviol(mds,rt,rc,ild,y,t,lb,hd) ) ;

* Generation capex
  capchrg_r(mds,rt,g,y)    = 1e-6 * capchargem(g,y,mds) * s3_capacity(mds,rt,g,y) ;
  capchrg_pv(mds,rt,g,y,d) = sum(firstper(t), PVfacsM(y,t,d) * capchrg_r(mds,rt,g,y)) ;

  capchrgyr_r(mds,rt,y)    = sum(g, capchrg_r(mds,rt,g,y)) ;
  capchrgyr_pv(mds,rt,y,d) = sum(g, capchrg_pv(mds,rt,g,y,d)) ;

  capchrgplt_r(mds,rt,g)    = sum(y, capchrg_r(mds,rt,g,y)) ;
  capchrgplt_pv(mds,rt,g,d) = sum(y, capchrg_pv(mds,rt,g,y,d)) ;

  capchrgtot_r(mds,rt)    = sum((g,y), capchrg_r(mds,rt,g,y)) ;
  capchrgtot_pv(mds,rt,d) = sum((g,y), capchrg_pv(mds,rt,g,y,d)) ;

  taxcred_r(mds,rt,g,y)    = 1e-6 * sum(mapg_k(g,k), deptcrecfac(y,k,'genplt') * capcostm(g,mds) * s3_capacity(mds,rt,g,y)) ;
  taxcred_pv(mds,rt,g,y,d) = sum(firstper(t), PVfacsM(y,t,d) * taxcred_r(mds,rt,g,y)) ;

  taxcredyr_r(mds,rt,y)    = sum(g, taxcred_r(mds,rt,g,y)) ;
  taxcredyr_pv(mds,rt,y,d) = sum(g, taxcred_pv(mds,rt,g,y,d)) ;

  taxcredplt_r(mds,rt,g)    = sum(y, taxcred_r(mds,rt,g,y)) ;
  taxcredplt_pv(mds,rt,g,d) = sum(y, taxcred_pv(mds,rt,g,y,d)) ;

  taxcredtot_r(mds,rt)    = sum((g,y), taxcred_r(mds,rt,g,y)) ;
  taxcredtot_pv(mds,rt,d) = sum((g,y), taxcred_pv(mds,rt,g,y,d)) ;

* Generation plant fixed costs
  fopexgross_r(mds,rt,g,y,t)    = 1e-6 * ( 1/card(t) ) * fixedOM(g) * s3_capacity(mds,rt,g,y) ;
  fopexgross_pv(mds,rt,g,y,t,d) = PVfacsM(y,t,d) * fopexgross_r(mds,rt,g,y,t) ;
  fopexnet_r(mds,rt,g,y,t)      = (1 - taxrate)  * fopexgross_r(mds,rt,g,y,t) ;
  fopexnet_pv(mds,rt,g,y,t,d)   = PVfacsM(y,t,d) * fopexnet_r(mds,rt,g,y,t) ;

  fopexgrosstot_r(mds,rt)    = sum((g,y,t), fopexgross_r(mds,rt,g,y,t)) ;
  fopexgrosstot_pv(mds,rt,d) = sum((g,y,t), fopexgross_pv(mds,rt,g,y,t,d)) ;
  fopexnettot_r(mds,rt)      = sum((g,y,t), fopexnet_r(mds,rt,g,y,t)) ;
  fopexnettot_pv(mds,rt,d)   = sum((g,y,t), fopexnet_pv(mds,rt,g,y,t,d)) ; 

* Generation plant HVDC costs
  hvdcgross_r(mds,rt,g,y,t) =  1e-6 *
    ( 1/card(t) ) * sum((k,o)$( ( not demgen(k) ) * sigen(g) * posbuildm(g,mds) * mapg_k(g,k) * mapg_o(g,o) ), HVDCshr(o) * HVDCchargem(y,mds) * s3_capacity(mds,rt,g,y)) ;
  hvdcgross_pv(mds,rt,g,y,t,d) = PVfacsM(y,t,d) * hvdcgross_r(mds,rt,g,y,t) ;
  hvdcnet_r(mds,rt,g,y,t)      = (1 - taxrate)  * hvdcgross_r(mds,rt,g,y,t) ;
  hvdcnet_pv(mds,rt,g,y,t,d)   = PVfacsM(y,t,d) * hvdcnet_r(mds,rt,g,y,t) ;

  hvdcgrosstot_r(mds,rt)    = sum((g,y,t), hvdcgross_r(mds,rt,g,y,t)) ;
  hvdcgrosstot_pv(mds,rt,d) = sum((g,y,t), hvdcgross_pv(mds,rt,g,y,t,d)) ;
  hvdcnettot_r(mds,rt)      = sum((g,y,t), hvdcnet_r(mds,rt,g,y,t)) ;
  hvdcnettot_pv(mds,rt,d)   = sum((g,y,t), hvdcnet_pv(mds,rt,g,y,t,d)) ;

* Generation plant total SRMCs
  vopexgross_r(mds,rt,g,y,t,hd)$mds_rt_hd(mds,rt,hd)    = 1e-3 * sum((mapg_e(g,e),lb), srmcm(g,y,mds) * s3_gen(mds,rt,g,y,t,lb,hd) * locfac_recip(e) ) ;
  vopexgross_pv(mds,rt,g,y,t,hd,d)$mds_rt_hd(mds,rt,hd) = PVfacsM(y,t,d) * vopexgross_r(mds,rt,g,y,t,hd) ;
  vopexnet_r(mds,rt,g,y,t,hd)$mds_rt_hd(mds,rt,hd)      = (1 - taxrate)  * vopexgross_r(mds,rt,g,y,t,hd) ;
  vopexnet_pv(mds,rt,g,y,t,hd,d)$mds_rt_hd(mds,rt,hd)   = PVfacsM(y,t,d) * vopexnet_r(mds,rt,g,y,t,hd) ;

  vopexgrosstot_r(mds,rt,hd)$mds_rt_hd(mds,rt,hd)    = sum((g,y,t), vopexgross_r(mds,rt,g,y,t,hd)) ;
  vopexgrosstot_pv(mds,rt,hd,d)$mds_rt_hd(mds,rt,hd) = sum((g,y,t), vopexgross_pv(mds,rt,g,y,t,hd,d)) ;
  vopexnettot_r(mds,rt,hd)$mds_rt_hd(mds,rt,hd)      = sum((g,y,t), vopexnet_r(mds,rt,g,y,t,hd)) ;
  vopexnettot_pv(mds,rt,hd,d)$mds_rt_hd(mds,rt,hd)   = sum((g,y,t), vopexnet_pv(mds,rt,g,y,t,hd,d)) ;

  vopexgrossNoLF_r(mds,rt,g,y,t,hd)$mds_rt_hd(mds,rt,hd)    = 1e-3 * srmcm(g,y,mds) * sum(lb, s3_gen(mds,rt,g,y,t,lb,hd)) ;
  vopexgrossNoLF_pv(mds,rt,g,y,t,hd,d)$mds_rt_hd(mds,rt,hd) = PVfacsM(y,t,d) * vopexgrossNoLF_r(mds,rt,g,y,t,hd) ;
  vopexnetNoLF_r(mds,rt,g,y,t,hd)$mds_rt_hd(mds,rt,hd)      = (1 - taxrate)  * vopexgrossNoLF_r(mds,rt,g,y,t,hd) ;
  vopexnetNoLF_pv(mds,rt,g,y,t,hd,d)$mds_rt_hd(mds,rt,hd)   = PVfacsM(y,t,d) * vopexnetNoLF_r(mds,rt,g,y,t,hd) ;

  vopexgrosstotNoLF_r(mds,rt,hd)$mds_rt_hd(mds,rt,hd)    = sum((g,y,t), vopexgrossNoLF_r(mds,rt,g,y,t,hd)) ;
  vopexgrosstotNoLF_pv(mds,rt,hd,d)$mds_rt_hd(mds,rt,hd) = sum((g,y,t), vopexgrossNoLF_pv(mds,rt,g,y,t,hd,d)) ;
  vopexnettotNoLF_r(mds,rt,hd)$mds_rt_hd(mds,rt,hd)      = sum((g,y,t), vopexnetNoLF_r(mds,rt,g,y,t,hd)) ;
  vopexnettotNoLF_pv(mds,rt,hd,d)$mds_rt_hd(mds,rt,hd)   = sum((g,y,t), vopexnetNoLF_pv(mds,rt,g,y,t,hd,d)) ;

* Transmission equipment capex
  txcapchrg_r(mds,rt,alltxps,y) = 0 ;
  loop(y,
    txcapchrg_r(mds,rt,paths,ps,y) = txcapchrg_r(mds,rt,paths,ps,y-1) + sum(trntxps(paths,pss,ps), txcapcharge(paths,ps,y) * s3_txupgrade(mds,rt,paths,pss,ps,y) ) ;
  ) ;
  txcapchrg_pv(mds,rt,alltxps,y,d) = sum(firstper(t), PVfacsM(y,t,d) * txcapchrg_r(mds,rt,alltxps,y)) ;

  txcapchrgyr_r(mds,rt,y)    = sum(alltxps, txcapchrg_r(mds,rt,alltxps,y)) ;
  txcapchrgyr_pv(mds,rt,y,d) = sum(alltxps, txcapchrg_pv(mds,rt,alltxps,y,d)) ;

  txcapchrgeqp_r(mds,rt,alltxps)    = sum(y, txcapchrg_r(mds,rt,alltxps,y)) ;
  txcapchrgeqp_pv(mds,rt,alltxps,d) = sum(y, txcapchrg_pv(mds,rt,alltxps,y,d)) ;

  txcapchrgtot_r(mds,rt)    = sum((alltxps,y), txcapchrg_r(mds,rt,alltxps,y)) ;
  txcapchrgtot_pv(mds,rt,d) = sum((alltxps,y), txcapchrg_pv(mds,rt,alltxps,y,d)) ;

  txtaxcred_r(mds,rt,alltxps,y)    = txdeptcrecfac(y) * txcapcost(alltxps) * s3_btx(mds,rt,alltxps,y) ;
  txtaxcred_pv(mds,rt,alltxps,y,d) = sum(firstper(t), PVfacsM(y,t,d) * txtaxcred_r(mds,rt,alltxps,y)) ;

  txtaxcredyr_r(mds,rt,y)    = sum(alltxps, txtaxcred_r(mds,rt,alltxps,y)) ;
  txtaxcredyr_pv(mds,rt,y,d) = sum(alltxps, txtaxcred_pv(mds,rt,alltxps,y,d)) ;

  txtaxcredeqp_r(mds,rt,alltxps)    = sum(y, txtaxcred_r(mds,rt,alltxps,y)) ;
  txtaxcredeqp_pv(mds,rt,alltxps,d) = sum(y, txtaxcred_pv(mds,rt,alltxps,y,d)) ;

  txtaxcredtot_r(mds,rt)    = sum((alltxps,y), txtaxcred_r(mds,rt,alltxps,y)) ;
  txtaxcredtot_pv(mds,rt,d) = sum((alltxps,y), txtaxcred_pv(mds,rt,alltxps,y,d)) ;

) ;

Display obj_components
*  activecap, pot_cap, act_cap, actual_cappc, PartialMWblt, numpltbldyrs, buildorretireMW, buildyr, retireyr, finalMW, totexistMW
*  totexistdsm, totbuiltMW, totbuiltdsm, totretiredMW, genTWh, gendsm, genpkr, txlossGWh, actualtxcap, numtxbldyrs, frcap, tocap
*  capchrg_r,    capchrg_pv,    capchrgyr_r,  capchrgyr_pv,  capchrgplt_r,  capchrgplt_pv
*  taxcred_r,    taxcred_pv,    taxcredyr_r,  taxcredyr_pv,  taxcredplt_r,  taxcredplt_pv
*  fopexgross_r, fopexgross_pv, fopexnet_r,   fopexnet_pv
*  hvdcgross_r,  hvdcgross_pv,  hvdcnet_r,    hvdcnet_pv
*  vopexgross_r, vopexgross_pv, vopexnet_r,   vopexnet_pv
*  capchrgtot_r, capchrgtot_pv, taxcredtot_r, taxcredtot_pv
*  fopexgrosstot_r, fopexgrosstot_pv, hvdcgrosstot_r, hvdcgrosstot_pv
*  fopexnettot_r,   fopexnettot_pv,   hvdcnettot_r,   hvdcnettot_pv,   vopexnettot_r, vopexnettot_pv
*  vopexgrossnolf_r, vopexgrossnolf_pv, vopexnetnolf_r, vopexnetnolf_pv
*  vopexgrosstotnolf_r, vopexgrosstotnolf_pv, vopexnettotnolf_r,  vopexnettotnolf_pv
*  txcapchrg_r, txcapchrg_pv, txcapchrgyr_r, txcapchrgyr_pv, txcapchrgeqp_r, txcapchrgeqp_pv, txcapchrgtot_r, txcapchrgtot_pv
*  txtaxcred_r, txtaxcred_pv, txtaxcredyr_r, txtaxcredyr_pv, txtaxcredeqp_r, txtaxcredeqp_pv, txtaxcredtot_r, txtaxcredtot_pv
   ;



*===============================================================================================
* 4. Write out the summary results report.

put rep "Results summary for '" system.title "' generated on " system.date ' at ' system.time / ;

put //  'Existing capacity (includes DSM and IL, and excludes shortage), MW' / @30 ;
loop(mds_sim(mds), put mds.tl:>12 ) put / @30 loop(mds_sim(mds), put totexistMW(mds):12:1 ) ;

put /// 'Existing DSM and IL capacity, MW' / @30 loop(mds_sim(mds), put mds.tl:>12 ) put / @30 ;
loop(mds_sim(mds), put totexistDSM(mds):12:1 ) ;

put /// 'Installed new capacity (includes DSM and IL), MW' / @30 loop(mds_sim(mds), put mds.tl:>12 ) put / @30 ;
loop(mds_sim(mds), put totbuiltMW(mds):12:1 ) ;

put /// 'Installed new DSM and IL capacity, MW' / @30 loop(mds_sim(mds), put mds.tl:>12 ) put / @30 ;
loop(mds_sim(mds), put totbuiltDSM(mds):12:1 ) ;

put /// 'Retired capacity, MW' / @30 loop(mds_sim(mds), put mds.tl:>12 ) put / @30 ;
loop(mds_sim(mds), put totretiredMW(mds):12:1 ) ;

put /// 'Generation (includes DSM, IL, and Shortage), TWh' / @30 loop(mds_sim(mds), put mds.tl:>12 ) ;
loop((rt,hd)$sum(mds, genTWh(mds,rt,hd)),
  put / rt.tl @18 if(sameas(hd,'dum'), put @30 else put hd.tl, (100 * hydWeight(hd)):8:2, @30 ) ;
  loop(mds_sim(mds), put genTWh(mds,rt,hd):12:1 ) ;
) ;

put /// "'Generation' by DSM and IL, GWh" / @30 loop(mds_sim(mds), put mds.tl:>12 ) ;
loop((rt,hd)$sum(mds, gendsm(mds,rt,hd)),
  put / rt.tl @18 if(sameas(hd,'dum'), put @30 else put hd.tl, (100 * hydWeight(hd)):8:2, @30 ) ;
  loop(mds_sim(mds), put gendsm(mds,rt,hd):12:1 ) ;
) ;

put /// 'Unserved energy (shortage generation), GWh' / @30 loop(mds_sim(mds), put mds.tl:>12 ) ;
loop((rt,hd)$sum((mds,y), defgenyr(mds,rt,hd,y)),
  put / rt.tl @18 if(sameas(hd,'dum'), put @30 else put hd.tl, (100 * hydWeight(hd)):8:2, @30 ) ;
  loop(mds_sim(mds), put (sum(y, defgenyr(mds,rt,hd,y))):12:1 ) ;
) ;

put /// 'Generation by peakers, GWh' / @30 loop(mds_sim(mds), put mds.tl:>12 ) ;
loop((rt,hd)$sum(mds, genpkr(mds,rt,hd)),
  put / rt.tl @18 if(sameas(hd,'dum'), put @30 else put hd.tl, (100 * hydWeight(hd)):8:2, @30 ) ;
  loop(mds_sim(mds), put  genpkr(mds,rt,hd):12:1 ) ;
) ;

put /// 'Transmission losses, GWh' / @30 loop(mds_sim(mds), put mds.tl:>12 ) ;
loop((rt,hd)$sum(mds, txlossGWh(mds,rt,hd)),
  put / rt.tl @18 if(sameas(hd,'dum'), put @30 else put hd.tl, (100 * hydWeight(hd)):8:2, @30 ) ;
  loop(mds_sim(mds), put  txlossGWh(mds,rt,hd):12:1 ) ;
) ;

put /// 'Total energy reserve violation, MWh' / @30 ; loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @17 'Reserve class' ;
  loop((arc,hd)$(sum(mds, mds_rt(mds,rt)) and sum(mds, totalresvviol(mds,rt,arc,hd))),
    put / @27 arc.tl if(sameas(hd,'dum'), put @30 else put hd.tl, (100 * hydWeight(hd)):8:2, @30 ) ;
    loop(mds_sim(mds), put totalresvviol(mds,rt,arc,hd):12:1 ) ;
  ) ;
) ;

put /// 'Total capex charges - before deducting depreciation tax credit effects, $m (present value)' / @30 ;
loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(mds_sim(mds), put ( capchrgtot_pv(mds,rt,d) + taxcredtot_pv(mds,rt,d) ):12:1 ) ;
  ) ;
) ;

put /// 'Total capex charges - net of depreciation tax credit effects, $m (present value)' / @30 ;
loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(mds_sim(mds), put capchrgtot_pv(mds,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total fixed O&M expenses - before deducting tax, $m (present value)' / @30 ; loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(mds_sim(mds), put fopexgrosstot_pv(mds,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total fixed O&M expenses - net of tax, $m (present value)' / @30 ; loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(mds_sim(mds), put fopexnettot_pv(mds,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total HVDC charges - before deducting tax, $m (present value)' / @30 ; loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(mds_sim(mds), put hvdcgrosstot_pv(mds,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total HVDC charges - net of tax, $m (present value)' / @30 ; loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop(d,
    put / @26 (100 * GITdisc(d)):4:1 @30 ;
    loop(mds_sim(mds), put hvdcnettot_pv(mds,rt,d):12:1 ) ;
  ) ;
) ;

put /// 'Total variable O&M expenses with LF adjustment - before deducting tax, $m (present value)' / @30 ;
loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop((hd,d)$sum(mds, vopexgrosstot_pv(mds,rt,hd,d)),
    put / @14
    if(sameas(hd,'dum'),
      put @26 (100 * GITdisc(d)):4:1 @30 ;
    else
      put hd.tl, (100 * hydWeight(hd)):6:2, (100 * GITdisc(d)):6:1 @30 ;
    ) ;
    loop(mds_sim(mds), put vopexgrosstot_pv(mds,rt,hd,d):12:1 ) ;
  ) ;
) ;

put /// 'Total variable O&M expenses with LF adjustment - net of tax, $m (present value)' / @30 ;
loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop((hd,d)$sum(mds, vopexgrosstot_pv(mds,rt,hd,d)),
    put / @14
    if(sameas(hd,'dum'),
      put @26 (100 * GITdisc(d)):4:1 @30 ;
    else
      put hd.tl, (100 * hydWeight(hd)):6:2, (100 * GITdisc(d)):6:1 @30 ;
    ) ;
    loop(mds_sim(mds), put vopexnettot_pv(mds,rt,hd,d):12:1 ) ;
  ) ;
) ;

put /// 'Total variable O&M expenses without LF adjustment - before deducting tax, $m (present value)' / @30 ;
loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop((hd,d)$sum(mds, vopexgrosstot_pv(mds,rt,hd,d)),
    put / @14
    if(sameas(hd,'dum'),
      put @26 (100 * GITdisc(d)):4:1 @30 ;
    else
      put hd.tl, (100 * hydWeight(hd)):6:2, (100 * GITdisc(d)):6:1 @30 ;
    ) ;
    loop(mds_sim(mds), put vopexgrosstotNoLF_pv(mds,rt,hd,d):12:1 ) ;
  ) ;
) ;

put /// 'Total variable O&M expenses without LF adjustment - net of tax, $m (present value)' / @29 ;
loop(mds_sim(mds), put mds.tl:>12 ) ;
loop(rt$sum(mds, mds_rt(mds,rt)),
  put / ;
  if(tmg(rt), put 'Timing' else if(reo(rt), put 'Re-optimised' else put 'Dispatch' ) ) ;
  put @27 'PV%' ;
  loop((hd,d)$sum(mds, vopexgrosstot_pv(mds,rt,hd,d)),
    put / @14
    if(sameas(hd,'dum'),
      put @26 (100 * GITdisc(d)):4:1 @30 ;
    else
      put hd.tl, (100 * hydWeight(hd)):6:2, (100 * GITdisc(d)):6:1 @30 ;
    ) ;
    loop(mds_sim(mds), put vopexnettotNoLF_pv(mds,rt,hd,d):12:1 ) ;
  ) ;
) ;


**
** Yet to write out the 16 transmission capex related parameters... but do we even want to?
** txcapchrg_r(mds,rt,r,rr,ps,y)        'Transmission capex charges (net of depreciation tax credit effects) by built equipment by year, $m (real)'
** txcapchrg_pv(mds,rt,r,rr,ps,y,d)     'Transmission capex charges (net of depreciation tax credit effects) by built equipment by year, $m (present value)'
** txcapchrgyr_r(mds,rt,y)              'Transmission capex charges (net of depreciation tax credit effects) by year, $m (real)'
** txcapchrgyr_pv(mds,rt,y,d)           'Transmission capex charges (net of depreciation tax credit effects) by year, $m (present value)'
** txcapchrgeqp_r(mds,rt,r,rr,ps)       'Transmission capex charges (net of depreciation tax credit effects) by equipment, $m (real)'
** txcapchrgeqp_pv(mds,rt,r,rr,ps,d)    'Transmission capex charges (net of depreciation tax credit effects) by equipment, $m (present value)'
** txcapchrgtot_r(mds,rt)               'Total transmission capex charges (net of depreciation tax credit effects), $m (real)'
** txcapchrgtot_pv(mds,rt,d)            'Total transmission capex charges (net of depreciation tax credit effects), $m (present value)'
** txtaxcred_r(mds,rt,r,rr,ps,y)        'Tax credit on depreciation by built transmission equipment by year, $m (real)'
** txtaxcred_pv(mds,rt,r,rr,ps,y,d)     'Tax credit on depreciation by built transmission equipment by year, $m (present value)'
** txtaxcredyr_r(mds,rt,y)              'Tax credit on depreciation on transmission equipment by year, $m (real)'
** txtaxcredyr_pv(mds,rt,y,d)           'Tax credit on depreciation on transmission equipment by year, $m (present value)'
** txtaxcredeqp_r(mds,rt,r,rr,ps)       'Tax credit on depreciation by transmission equipment, $m (real)'
** txtaxcredeqp_pv(mds,rt,r,rr,ps,d)    'Tax credit on depreciation by transmission equipment, $m (present value)'
** txtaxcredtot_r(mds,rt)               'Total tax credit on depreciation of transmission equipment, $m (real)'
** txtaxcredtot_pv(mds,rt,d)            'Total tax credit on depreciation of transmission equipment, $m (present value)'   ;
**



*===============================================================================================
* 5. Write out the generation and transmission investment schedules in various formats.

* a) Build, refurbishment and retirement data and outcomes in easy to read format suitable for importing into Excel.
put bld 'MDS', 'Plant', 'Plant name', 'Zone', 'Region', 'Island', 'Technology', 'Fuel', 'RetireType', 'NameplateMW'
        'BuildYr', 'BuildMW', 'RefurbYr', 'RetireYr', 'RetireMW' ;
loop((mds,rt,g,e,r,ild,k,f,y)$( bldrslt(rt) * mapg_e(g,e) * mapg_r(g,r) * mapg_ild(g,ild) * mapg_k(g,k) * mapg_f(g,f) * buildorretireMW(mds,g,y) ),
  put / mds.tl, g.tl, g.te(g), e.te(e), r.te(r), ild.tl, k.te(k), f.te(f) ;
  if(posretirem(g,mds), if(exogretirem(g,y,mds), put 'Exogenous' else put 'Endogenous' ) else put '' ) ; 
  put nameplate(g) ;
  if(s3_build(mds,rt,g,y), put yearnum(y), s3_build(mds,rt,g,y) else put '', '' ) ;
  if(posrefurbm(g,mds) and (s3_isretired(mds,rt,g) = 0), put refurbyrm(g,mds), else put '' ) ;
  if(retireyr(mds,g), put retireyr(mds,g) else put '' ) ;
  if(retireMW(mds,g), put retireMW(mds,g) else put '' ) ;
) ;

* b) Write out generation and transmission investment schedules in a formatted text file (i.e. human-readable)
counter = 0 ;
put invest 'Generation and transmission investment schedules by year' ;
loop(mds_sim(mdsx),
* Write out transmission investments.
  put /// mdsx.tl, ': ', mdsx.te(mdsx) ;
  put //   'Transmission' / ;
  put @3   'Year' @10 'Project' @25 'From' @40 'To' @55 'FrState' @65 'ToState' @77 'FrmCap' @86 'ToCap' @93 'ActCap' @102 'numBlds' @110 'Free?'
      @116 'ErlyYr' @124 'Project description' ;
  loop((bldrslt(rt),y)$sum(tupg, s3_txprojvar(mdsx,rt,tupg,y)),
    put / @3 y.tl ;
    loop(transitions(tupg,r,rr,ps,pss)$s3_txprojvar(mdsx,rt,tupg,y),
      counter = counter + 1 ;
      if(counter = 1, put @10 else put / @10 ) ;
      put tupg.tl @25 r.tl @40 rr.tl @55 ps.tl @65 pss.tl @75 frcap(r,rr,ps):8:1, tocap(r,rr,pss):8:1, actualtxcap(mdsx,rt,r,rr,y):8:1, @100 numtxbldyrs(mdsx,tupg,y):5:0 ;
      if(txfixyr(transitions) = 0, put @112 'y' else put @112 'n' ) ;
      if(txfixyr(transitions) >= txerlyYr(transitions), put @116 txfixyr(transitions):6:0 else put @116 txerlyYr(transitions):6:0 ) ;
      put @124 tupg.te(tupg) ;
    ) ;
    counter = 0 ;
  ) ;
  counter = 0 ;
* Write out generation investments.
  loop(bldrslt(rt),
    put // 'Generation' / ;
    put @3 'Year' @10 'Plant' @25 'Tech' @40 'SubStn' @55 'Region' @75 'MW' @81 'npMW' @88 'numBlds' @97 'Plant description' ;
    loop(y$sum(g, buildorretireMW(mdsx,g,y)),
      put / @3 y.tl ;
      loop((k,i,r,g)$( mapg_k(g,k) * mapg_i(g,i) * mapg_r(g,r) * buildorretireMW(mdsx,g,y) ),
        counter = counter + 1 ;
        if(counter = 1, put @10 else put / @10 ) ;
        put g.tl @25 k.tl @40 i.tl @55 r.tl @70 buildorretireMW(mdsx,g,y):7:1, nameplate(g):8:1 @86 numpltbldyrs(mdsx,g,y):5:0 @97 g.te(g) ;
      ) ;
      counter = 0 ;
    ) ;
  ) ;
) ;

* c) Write out the build and retirement schedule - in SOO-ready format.
counter = 0 ;
put soobld ;
loop(mds_sim(mdsx),
  put mdsx.te(mdsx) ;
  loop(mds_rt(mdsx,rt)$bldrslt(rt),
    put / 'Year', 'Plant description', 'Technology description', 'MW', 'Nameplate MW', 'Substation' ;
    loop(y$sum(g, buildorretireMW(mdsx,g,y)),
      put / y.tl ;
      loop((k,g,i)$( mapg_k(g,k) * mapg_i(g,i) * buildorretireMW(mdsx,g,y) ),
        counter = counter + 1 ;
        if(counter = 1,
          put g.te(g), k.te(k), buildorretireMW(mdsx,g,y), nameplate(g), i.te(i) ;
        else
          put / '' g.te(g), k.te(k), buildorretireMW(mdsx,g,y), nameplate(g), i.te(i) ;
        ) ;
      ) ;
      counter = 0 ;
    ) ;
    put / ;
  ) ;
  put // ;
) ;

* d) Write out the forced builds by MDS - in SOO-ready format (in the same file as SOO build schedules).
counter = 0 ;
soobld.ap = 1 ;
put soobld / 'Summary of forced build dates by MDS' /  ;
loop(mds_sim(mdsx),
  put mdsx.te(mdsx) ;
  loop(mds_rt(mdsx,rt)$bldrslt(rt),
    put / 'Year', 'Plant description', 'Technology description', 'MW', 'Nameplate MW', 'Substation' ;
    loop(y$sum(g$( commitm(g,mdsx) * buildorretireMW(mdsx,g,y) ), 1 ),
      put / y.tl ;
      loop((k,g,i)$( mapg_k(g,k) * mapg_i(g,i) * commitm(g,mdsx) * buildorretireMW(mdsx,g,y) ),
        counter = counter + 1 ;
        if(counter = 1,
          put g.te(g), k.te(k), buildorretireMW(mdsx,g,y), nameplate(g), i.te(i) ;
        else
          put / '' g.te(g), k.te(k), buildorretireMW(mdsx,g,y), nameplate(g), i.te(i) ;
        ) ;
      ) ;
      counter = 0 ;
    ) ;
    put / ;
  ) ;
  put // ;
) ;

* e) Build schedule in GAMS-readable format - only write this file if GEM was run (i.e. skip it if RunType = 2).
$if %RunType%==2 $goto CarryOn2
put bld_GR ;
loop(bldrslt(rt),
* Write table of installed MW
  put "TABLE InstallMW(g,y,mds) 'Generation capacity to be installed by plant, year, and MDS, MW'" / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop((g,y)$sum(mds_sim(mds), s3_build(mds,rt,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(mds_sim(mds), if(s3_build(mds,rt,g,y), put s3_build(mds,rt,g,y):14:8 else put '              '  ) ) ;
  ) ;
* Write table of exogenously retired MW
  put '  ;' /// "TABLE ExogRetireSched(g,y,mds) 'Exogenous retirement schedule by plant, year, and MDS'" / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop((g,y)$sum(mds_sim(mds), exogretireMWm(g,y,mds)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(mds_sim(mds), if(exogretireMWm(g,y,mds), put exogretireMWm(g,y,mds):14:8 else put '              ' ) ) ;
  ) ;
* Write table of endogenously retired MW
  put '  ;' /// "TABLE EndogRetireSched(g,y,mds) 'Endogenous retirement schedule by plant, year, and MDS'" / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop((g,y)$sum(mds_sim(mds), s3_retire(mds,rt,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(mds_sim(mds), if(s3_retire(mds,rt,g,y), put s3_retire(mds,rt,g,y):14:8 else put '              ' ) ) ;
  ) ;
* Write table of indicator variables for endogenously retired plant
  put '  ;' /// "TABLE BRETFIX(g,y,mds) 'Indicate whether a plant has been endogenously retired'" / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop((g,y)$sum(mds_sim(mds), s3_bret(mds,rt,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(mds_sim(mds), if(s3_bret(mds,rt,g,y), put s3_bret(mds,rt,g,y):14:8 else put '              ' ) ) ;
  ) ;
* Write table of installation year for generation plant
  put '  ;' /// "TABLE BuildSched(g,y,mds) 'Generation build schedule by plant, year, and MDS'" / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop((g,y)$sum(mds_sim(mds), s3_build(mds,rt,g,y)),
    put / g.tl:>15, '.', y.tl:<6 ;
    loop(mds_sim(mds), if(s3_build(mds,rt,g,y), put yearnum(y):14:0 else put '              ' ) ) ;
  ) ;
* Write table of installed MW for those cases where plant is partially built
  if(sum((mds,g), partialMWblt(mds,g)),
    put '  ;' /// "TABLE PartialMWbuilt(g,mds) 'MW actually built in the case of plant not fully constructed'" / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
    loop(g$sum(mds_sim(mds), PartialMWblt(mds,g)),
      put / g.tl:>15 @23 ;
      loop(mds_sim(mds), if(PartialMWblt(mds,g), put PartialMWblt(mds,g):14:8 else put '              ' ) ) ;
    ) ;
    put '  ;' /// ;
    else
    put /// ;
  ) ;
) ;
* Now write a summary of what happened to peakers if re-optimisation took place.
if(%SuppressReOpt% = 1,
  put '* Generation build schedule was not re-optimised by moving peakers about' /// ;
  else
  put '* Generation build schedule was re-optimised by allowing peakers to move' //
      '$ontext' / 'Summary of re-optimised peakers' / '  -Peakers in initial solution' / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop(movers(k),
    loop((tmg(rt),g,y)$( mapg_k(g,k) * (sum(mds_sim(mds), s3_build(mds,rt,g,y)) > 0) ),
      put / g.tl:>15, '.', y.tl:<6 ;
      loop(mds_sim(mds), if(s3_build(mds,rt,g,y), put yearnum(y):14:0 else put '              ' ) ) ;
    ) ;
  ) ;
  put / '  -Peakers in re-optimised solution' / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop(movers(k),
    loop((reo(rt),g,y)$( mapg_k(g,k) * (sum(mds_sim(mds), s3_build(mds,rt,g,y)) > 0) ),
      put / g.tl:>15, '.', y.tl:<6 ;
      loop(mds_sim(mds), if(s3_build(mds,rt,g,y), put yearnum(y):14:0 else put '              ' ) ) ;
    ) ;
  ) ;
  put / '$offtext' /// ;
) ;
* Finally, write summary tables pertaining to transmission upgrades.
bld_GR.ap = 1 ; put bld_GR ;
loop(bldrslt(rt),
  put "TABLE TXPROJECT(tupg,y,mds) 'Indicate whether an upgrade project is applied'" / @23 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop((tupg,y)$sum(mds_sim(mds), s3_txprojvar(mds,rt,tupg,y)),
    put / tupg.tl:>15, '.', y.tl:<6 ;
    loop(mds_sim(mds), if(s3_txprojvar(mds,rt,tupg,y), put s3_txprojvar(mds,rt,tupg,y):14:8 else put '              ' ) ) ;
  ) ;
  put '  ;' /// "TABLE TXUPGRADES(r,rr,ps,pss,y,mds) 'Indicate whether a transmission upgrade is applied'" / @71 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop((paths(r,rr),ps,pss,y)$sum(mds_sim(mds), s3_txupgrade(mds,rt,paths,ps,pss,y)),
    put / r.tl:>15, '.', rr.tl:>15, '.', ps.tl:>15, '.', pss.tl:>15, '.', y.tl:<6 ;
    loop(mds_sim(mds), if(s3_txupgrade(mds,rt,paths,ps,pss,y), put s3_txupgrade(mds,rt,paths,ps,pss,y):14:8 else put '              ' ) ) ;
  ) ;
  put '  ;' /// "TABLE BTXFIX(r,rr,ps,y,mds) 'Indicate the current state of a transmission path'" / @55 loop(mds_sim(mds), put mds.tl:>14 ) ;
  loop((paths(r,rr),ps,y)$sum(mds_sim(mds), s3_btx(mds,rt,paths,ps,y)),
    put / r.tl:>15, '.', rr.tl:>15, '.', ps.tl:>15, '.', y.tl:<6 ;
    loop(mds_sim(mds), if(s3_btx(mds,rt,paths,ps,y), put s3_btx(mds,rt,paths,ps,y):14:8 else put '              ' ) ) ;
  ) ;
  put '  ;' / ;
) ;
$label CarryOn2

* f) Write out a file to create maps of generation plant builds/retirements.
*    NB: In cases of builds over multiple years, the first year is taken as the build year.
put pltgeo ;
put 'mds', 'Plant', 'Substation', 'Tech', 'Fuel', 'FuelGrp', 'subY', 'subX', 'existMW', 'builtMW', 'retiredMW', 'finalMW'
    'BuildYr', 'RetireYr', 'Plant description', 'Tech description', 'Fuel description', 'Fuel group description' ;
loop((mds_sim(mdsx),g,i,k,f,fg)$( (exist(g) or finalMW(mdsx,g)) * mapg_i(g,i) * mapg_k(g,k) * mapg_f(g,f) * mapf_fg(f,fg) ),
  put / mdsx.tl, g.tl, i.tl, k.tl, f.tl, fg.tl, geodata(i,'Northing'), geodata(i,'Easting') ;
  if(exist(g),
    put nameplate(g), '', retireMW(mdsx,g), finalMW(mdsx,g), '', retireyr(mdsx,g) ;
    else
    put '', buildMW(mdsx,g), retireMW(mdsx,g), finalMW(mdsx,g), buildyr(mdsx,g), retireyr(mdsx,g) ;
  ) ;
  put g.te(g), k.te(k), f.te(f), fg.te(fg) ;
) ;

* g) Write out a file to create maps of transmission upgrades.
put txgeo ;
put 'mds', 'FrReg', 'ToReg', 'FrY', 'ToY', 'FrX', 'ToX', 'FrCap', 'ToCap', 'ActualCap', 'FrSte', 'ToSte', 'Year', 'Project', 'Project description'  ;
* First report the initial network
loop((mds_sim(mdsx),paths(r,rr),ps)$( sameas(ps,'initial') ),
  put / mdsx.tl, r.tl, rr.tl ;
  loop((i,ii)$( rcent(i,r) * rcent(ii,rr) ), put geodata(i,'Northing'), geodata(ii,'Northing'), geodata(i,'Easting'), geodata(ii,'Easting') ) ;
  put frcap(r,rr,ps) ;
) ;
txgeo.ap = 1 ;
* Now add on the upgrades.
loop((mds_sim(mdsx),bldrslt(rt),tupg,paths(r,rr),transitions(tupg,r,rr,ps,pss),y)$( s3_txprojvar(mdsx,rt,tupg,y) and txfixyr(tupg,paths,ps,pss) < 3333 ),
  put / mdsx.tl, r.tl, rr.tl ;
  loop((i,ii)$( rcent(i,r) * rcent(ii,rr) ), put geodata(i,'Northing'), geodata(ii,'Northing'), geodata(i,'Easting'), geodata(ii,'Easting') ) ;
  put frcap(r,rr,ps), tocap(r,rr,pss), actualtxcap(mdsx,rt,r,rr,y), ps.tl, pss.tl, yearnum(y), tupg.tl, tupg.te(tupg) ;
) ;



*===============================================================================================
* 6. Write out various summaries of the MW installed net of retirements.

Parameters
  TechIldMW(mdsx,k,ild)  'Built megawatts less retired megawatts by technology and island'
  TechZoneMW(mdsx,k,e)   'Built megawatts less retired megawatts by technology and zone'
  TechRegMW(mdsx,k,r)    'Built megawatts less retired megawatts by technology and region'
  TechYearMW(mdsx,k,y)   'Built megawatts less retired megawatts by technology and year'
  MDSyearMW(mdsx,y)      'Built megawatts less retired megawatts by MDS and year'
  ;

if(%RunType%=2,
  TechIldMW(mds,k,ild) = sum((dis(rt),mapg_k(g,k),mapg_ild(g,ild),y), s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
  TechZoneMW(mds,k,e)  = sum((dis(rt),mapg_k(g,k),mapg_e(g,e),y),     s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
  TechRegMW(mds,k,r)   = sum((dis(rt),mapg_k(g,k),mapg_r(g,r),y),     s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
  TechYearMW(mds,k,y)  = sum((dis(rt),mapg_k(g,k)),                   s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
  else
  if(%SuppressReopt%=1,
    TechIldMW(mds,k,ild) = sum((tmg(rt),mapg_k(g,k),mapg_ild(g,ild),y), s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
    TechZoneMW(mds,k,e)  = sum((tmg(rt),mapg_k(g,k),mapg_e(g,e),y),     s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
    TechRegMW(mds,k,r)   = sum((tmg(rt),mapg_k(g,k),mapg_r(g,r),y),     s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
    TechYearMW(mds,k,y)  = sum((tmg(rt),mapg_k(g,k)),                   s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
    else
    TechIldMW(mds,k,ild) = sum((reo(rt),mapg_k(g,k),mapg_ild(g,ild),y), s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
    TechZoneMW(mds,k,e)  = sum((reo(rt),mapg_k(g,k),mapg_e(g,e),y),     s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
    TechRegMW(mds,k,r)   = sum((reo(rt),mapg_k(g,k),mapg_r(g,r),y),     s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
    TechYearMW(mds,k,y)  = sum((reo(rt),mapg_k(g,k)),                   s3_build(mds,rt,g,y) - s3_retire(mds,rt,g,y) - exogretireMWm(g,y,mds)) ;
  ) ;
) ;

MDSyearMW(mds,y) = sum(k, TechYearMW(mds,k,y)) ;

put bldsum 'Various summaries of newly installed generation plant net of retirements, MW' / ;

put // 'Installed less retired MW by technology and island'
loop(mds_sim(mdsx)$sum((k,ild), TechIldMW(mdsx,k,ild)),
  put // mdsx.tl, ': ', mdsx.te(mdsx) @58 ; loop(ild, put ild.tl:>15 ) ; put '          Total' ;
  loop(k$sum(ild, TechIldMW(mdsx,k,ild)),
    put / @3 k.te(k) @58 ; loop(ild, put TechIldMW(mdsx,k,ild):15:1 ) ; put (sum(ild, TechIldMW(mdsx,k,ild))):15:1 ;
  ) ;
  put / @3 'Total' @58 ; loop(ild, put (sum(k, TechIldMW(mdsx,k,ild))):15:1 ) ; put (sum((k,ild), TechIldMW(mdsx,k,ild))):15:1 ;
) ;

put // 'Installed less retired MW by technology and zone'
loop(mds_sim(mdsx)$sum((k,e), TechZoneMW(mdsx,k,e)),
  put // mdsx.tl, ': ', mdsx.te(mdsx) @58 ; loop(e, put e.tl:>15 ) ; put '          Total' ;
  loop(k$sum(e, TechZoneMW(mdsx,k,e)),
    put / @3 k.te(k) @58 ; loop(e, put TechZoneMW(mdsx,k,e):15:1 ) ; put (sum(e, TechZoneMW(mdsx,k,e))):15:1 ;
  ) ;
  put / @3 'Total' @58 ; loop(e, put (sum(k, TechZoneMW(mdsx,k,e))):15:1 ) ; put (sum((k,e), TechZoneMW(mdsx,k,e))):15:1 ;
) ;

put /// 'Installed less retired MW by technology and region'
loop(mds_sim(mdsx)$sum((k,r), TechRegMW(mdsx,k,r)),
  put // mdsx.tl, ': ', mdsx.te(mdsx) @58 ; loop(r, put r.tl:>15 ) ; put '          Total' ;
  loop(k$sum(r, TechRegMW(mdsx,k,r)),
    put / @3 k.te(k) @58 ; loop(r, put TechRegMW(mdsx,k,r):15:1 ) ; put (sum(r, TechRegMW(mdsx,k,r))):15:1 ;
  ) ;
  put / @3 'Total' @58 ; loop(r, put (sum(k, TechRegMW(mdsx,k,r))):15:1 ) ; put (sum((k,r), TechRegMW(mdsx,k,r))):15:1 ;
) ;

put /// 'Installed less retired MW by technology and year'
loop(mds_sim(mdsx)$sum((k,y), TechYearMW(mdsx,k,y)),
  put // mdsx.tl, ': ', mdsx.te(mdsx) @58 ; loop(y, put y.tl:>8 ) ; put '    Total' ;
  loop(k$sum(y, TechYearMW(mdsx,k,y)),
    put / @3 k.te(k) @58 ; loop(y, put TechYearMW(mdsx,k,y):8:1 ) ; put (sum(y, TechYearMW(mdsx,k,y))):9:1 ;
  ) ;
  put / @3 'Total' @58 ; loop(y, put (sum(k, TechYearMW(mdsx,k,y))):8:1 ) ;
) ;

put /// 'Installed less retired MW by MDS and year' / @58 ; loop(y, put y.tl:>8 ) ; put '    Total' ;
loop(mds_sim(mdsx), put / @3 mdsx.te(mdsx) @58 ; loop(y, put MDSyearMW(mdsx,y):8:1 ) ; put (sum(y, MDSyearMW(mdsx,y))):9:1 ) ;

put /// 'Zone descriptions' ;
loop(e, put / e.tl @15 e.te(e) ) ;

put /// 'Region descriptions' ;
loop(r, put / r.tl @15 r.te(r) ) ;

put /// 'MDS descriptions' ;
loop(mds_sim(mdsx), put / mdsx.tl @15 mdsx.te(mdsx) ) ;



*===============================================================================================
* 7. Write out various summaries of activity associated with peaking plant.

* Figure out which peakers produce more than 20% energy in any year.
counter = 0 ;
loop((mds_rt_hd(mds,rt,hd),mapg_k(g,k))$( peaker(k) * sum(y$activecap(mds,g,y), 1) ),
  loop(y$( counter < 0.2 ),
    counter = genyr(mds,rt,g,y,hd) / (1e-3 * nameplate(g) * sum((t,lb), maxcapfact(g,t,lb) * hrsperblk(t,lb)) ) ;
    pkrs_plus20(mds,rt,hd,g)$( counter >= 0.2 ) = yes ;
  ) ;
  counter = 0 ;
) ;

* Figure out which non-peakers produce less than 20% energy in any year.
counter = 1 ;
loop((mds_rt_hd(mds,rt,hd),mapg_k(g,k))$( not peaker(k) ),
  loop(y$( counter > 0.2 ),
    counter$( nameplate(g) * sum((t,lb), maxcapfact(g,t,lb) * hrsperblk(t,lb)) ) =
      genyr(mds,rt,g,y,hd) / (1e-3 * nameplate(g) * sum((t,lb), maxcapfact(g,t,lb) * hrsperblk(t,lb)) ) ;
    nopkr_minus20(mds,rt,hd,g)$( counter > 0 and counter <= 0.2 ) = yes ;
  ) ;
  counter = 1 ;
) ;

put pksum 'Peaking plant and VOLL activity' / 'Run name:', '%OutPrefix%' /
 'First modelled year:', '%FirstYr%' /
 'Number of modelled years:', numyears:2:0  /
 'Technologies specified by user to be peaking:' loop(peaker(k), put k.tl ) ;

put /// 'Peaking capacity by technology, MW' / 'Technology' '' loop(mds_sim(mds), put mds.tl ) ;
loop(peaker(k),
  put / k.te(k) ;
  put 'Existing capacity'              loop(mds_sim(mds), put sum(mapg_k(g,k), initCap(g)) ) ; 
  put / '' 'Capacity able to be built' loop(mds_sim(mds), put pot_cap(mds,k,'blt') ) ; 
  put / '' 'Capacity actually built'   loop(mds_sim(mds), put sum(bldrslt(rt), act_cap(mds,rt,k,'blt')) ) ; 
) ;

put /// 'Peaking capacity installed by region, MW' / 'Region' loop(mds_sim(mds), put mds.tl ) ;
loop(r,
  put / r.te(r) ; loop(mds_sim(mds), put sum((g,k)$( peaker(k) * mapg_k(g,k) * mapg_r(g,r) ), buildMW(mds,g)) ) ;
) ;

put /// 'Peaking capacity installed by zone, MW' / 'Zone' loop(mds_sim(mds), put mds.tl ) ;
loop(e,
  put / e.te(e) ; loop(mds_sim(mds), put sum((g,k)$( peaker(k) * mapg_k(g,k) * mapg_e(g,e) ), buildMW(mds,g)) ) ;
) ;

put /// 'Peakers exceeding 20% utilisation in any year' / 'Plant' 'Run type' 'Hydro domain' loop(mds_sim(mds), put mds.tl ) ;
loop((g,rt,hd)$sum(mds, pkrs_plus20(mds,rt,hd,g)),
  put / g.te(g), rt.tl, hd.tl ;
  loop(mds_sim(mds),
    if(pkrs_plus20(mds,rt,hd,g), put 'y' else put '' ) ;
  ) ;
) ;

put /// 'Non-peakers at less than 20% utilisation in any year' / 'Plant' 'Run type' 'Hydro domain' loop(mds_sim(mds), put mds.tl ) ;
loop((g,rt,hd)$sum(mds, nopkr_minus20(mds,rt,hd,g)),
  put / g.te(g), rt.tl, hd.tl ;
  loop(mds_sim(mds),
    if(nopkr_minus20(mds,rt,hd,g), put 'y' else put '' ) ;
  ) ;
) ;

put /// 'Energy produced by peakers, GWh' / 'MDS' 'Run type' 'Hydro domain' 'Plant' 'Tech' 'Substn' 'MaxPotGWh' loop(y, put y.tl ) ; put '' 'Technology' ;
loop((mds_rt_hd(mds,rt,hd),g,peaker(k),i)$( mapg_k(g,k) * mapg_i(g,i) * sum(y$activecap(mds,g,y), 1) ),
  put / mds.tl, rt.tl, hd.tl, g.te(g), k.tl, i.tl, (1e-3 * nameplate(g) * sum((t,lb), maxcapfact(g,t,lb) * hrsperblk(t,lb)) )
  loop(y, put genyr(mds,rt,g,y,hd) ) ;
  put k.te(k) ;
) ;

put /// 'Energy produced by peakers as a proportion of potential' / 'MDS' 'Run type' 'Hydro domain' 'Plant' 'Tech' 'Substn' 'MaxPotGWh' loop(y, put y.tl ) ; put '' 'Technology' ;
loop((mds_rt_hd(mds,rt,hd),g,peaker(k),i)$( mapg_k(g,k) * mapg_i(g,i) * sum(y$activecap(mds,g,y), 1) ),
  put / mds.tl, rt.tl, hd.tl, g.te(g), k.tl, i.tl, (1e-3 * nameplate(g) * sum((t,lb), maxcapfact(g,t,lb) * hrsperblk(t,lb)) )
  loop(y, put ( genyr(mds,rt,g,y,hd) / (1e-3 * nameplate(g) * sum((t,lb), maxcapfact(g,t,lb) * hrsperblk(t,lb)) ) )  ) ;
  put k.te(k) ;
) ;

put /// 'VOLL by load block, period and year, GWh' / 'MDS' 'Run type' 'Hydro domain' 'Plant' 'Period' 'Load block' loop(y, put y.tl ) ;
loop((mds_rt_hd(mds,rt,hd),s,t,lb)$sum(y$s3_vollgen(mds,rt,s,y,t,lb,hd), 1),
  put / mds.tl, rt.tl, hd.tl, s.te(s), t.tl, lb.tl ;
  loop(y, put s3_vollgen(mds,rt,s,y,t,lb,hd) ) ;
) ;

put /// 'Energy produced by peakers by load block, period and year, GWh' / 'MDS' 'Run type' 'Hydro domain' 'Plant' 'Period' 'Load block' loop(y, put y.tl ) ;
loop((mds_rt_hd(mds,rt,hd),g,peaker(k),t,lb)$( mapg_k(g,k) * sum(y$s3_gen(mds,rt,g,y,t,lb,hd), 1) ),
  put / mds.tl, rt.tl, hd.tl, g.te(g), t.tl, lb.tl ;
  loop(y, put s3_gen(mds,rt,g,y,t,lb,hd) ) ;
) ;

*Display pkrs_plus20, nopkr_minus20 ;



*===============================================================================================
* 8. Write out the GIT summary results.

gityrs(y)$( yearnum(y) <  begtermyrs ) = yes ;
trmyrs(y)$( yearnum(y) >= begtermyrs ) = yes ;
mapcy_y(git,gityrs) = yes ;
mapcy_y(trm,trmyrs) = yes ;

GITresults('itm1',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),firstper(t)), PVfacs(y,t,gitd,dt) * ( capchrg_r(mds,rt,g,y) + taxcred_r(mds,rt,g,y)) ) ;

GITresults('itm2',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t), PVfacs(y,t,gitd,dt) * fopexgross_r(mds,rt,g,y,t) ) ;

GITresults('itm3',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t), PVfacs(y,t,gitd,dt) * hvdcgross_r(mds,rt,g,y,t) ) ;

GITresults('itm4',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t,hd), PVfacs(y,t,gitd,dt) * ( 1 / numhd ) * vopexgrossnolf_r(mds,rt,g,y,t,hd) ) ;

GITresults('itm5',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),firstper(t)), PVfacs(y,t,gitd,dt) * capchrg_r(mds,rt,g,y) ) ;

GITresults('itm6',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t), PVfacs(y,t,gitd,dt) * ( 1 - taxrate ) * fopexgross_r(mds,rt,g,y,t) ) ;

GITresults('itm7',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t), PVfacs(y,t,gitd,dt) * ( 1 - taxrate ) * hvdcgross_r(mds,rt,g,y,t) ) ;

GITresults('itm8',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),g,mapcy_y(cy,y),t,hd), PVfacs(y,t,gitd,dt) * ( 1 / numhd ) * ( 1 - taxrate ) * vopexgrossnolf_r(mds,rt,g,y,t,hd) ) ;

GITresults('itm9',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),alltxps,mapcy_y(cy,y),firstper(t)), PVfacs(y,t,gitd,dt) * ( txcapchrg_r(mds,rt,alltxps,y) + txtaxcred_r(mds,rt,alltxps,y)) ) ;

GITresults('itm10',gitd,mds_sim(mds),dt,cy) = sum((dis(rt),alltxps,mapcy_y(cy,y),firstper(t)), PVfacs(y,t,gitd,dt) * txcapchrg_r(mds,rt,alltxps,y) ) ;

GITresults('itmA',gitd,mds_sim(mds),dt,cy) = GITresults('itm1',gitd,mds,dt,cy) + GITresults('itm2',gitd,mds,dt,cy) + GITresults('itm3',gitd,mds,dt,cy) ;

GITresults('itmB',gitd,mds_sim(mds),dt,cy) = GITresults('itm4',gitd,mds,dt,cy) ;

GITresults('itmC',gitd,mds_sim(mds),dt,cy) = GITresults('itm9',gitd,mds,dt,cy) ;

GITresults('itmD',gitd,mds_sim(mds),dt,cy) = GITresults('itm1',gitd,mds,dt,'trm') + GITresults('itm2',gitd,mds,dt,'trm') + GITresults('itm3',gitd,mds,dt,'trm') + GITresults('itm4',gitd,mds,dt,'trm') ;
 
GITresults('itmE',gitd,mds_sim(mds),dt,cy) = GITresults('itmA',gitd,mds,dt,cy) + GITresults('itmB',gitd,mds,dt,cy) - GITresults('itmC',gitd,mds,dt,cy) + GITresults('itmD',gitd,mds,dt,cy) ;

*Display cy, item, git, trm, mapcy_y, gityrs, trmyrs, GITresults ;

put gits
  'GIT analysis' /
  'Run name:', '%OutPrefix%' /
  'All results in millions of %FirstYr% dollars' /
  'All results are averages over the hydro sequences simulated (i.e. model DISP)' /
  'Number of inflow sequences simulated:' ;
loop(mds_sim(mds), put / '', mds.tl, numdisyrs(mds):0 ) ;

put // 'Summary GIT results - mid-period discounting (absolute, not change from base)', 'Discount rate' ;
loop(mds_sim(mds), put mds.tl ) ;
loop(item$( ord(item) > 10 ),
  put / item.te(item) ;
  counter = 0 ;
  loop(gitd(d),
    counter = counter + 1 ;
    if(counter = 1, put d.te(d) else put / '', d.te(d) ) ;
    loop(mds_sim(mds), put GITresults(item,gitd,mds,'mid','git') ) ;
  ) ;
) ;

put /// 'Summary GIT results - end-of-year discounting (absolute, not change from base)', 'Discount rate' ;
loop(mds_sim(mds), put mds.tl ) ;
loop(item$( ord(item) > 10 ),
  put / item.te(item) ;
  counter = 0 ;
  loop(gitd(d),
    counter = counter + 1 ;
    if(counter = 1, put d.te(d) else put / '', d.te(d) ) ;
    loop(mds_sim(mds), put GITresults(item,gitd,mds,'eoy','git') ) ;
  ) ;
) ;

put /// 'Components of GIT analysis - mid-period discounting', 'Discount rate' ;
loop(mds_sim(mds), put mds.tl ) ;
loop(item$( ord(item) < 11 ),
  put / item.te(item) ;
  counter = 0 ;
  loop(gitd(d),
    counter = counter + 1 ;
    if(counter = 1, put d.te(d) else put / '', d.te(d) ) ;
    loop(mds_sim(mds), put GITresults(item,gitd,mds,'mid','git') ) ;
  ) ;
) ;

put /// 'Components of GIT analysis - end-of-year discounting', 'Discount rate' ;
loop(mds_sim(mds), put mds.tl ) ;
loop(item$( ord(item) < 11 ),
  put / item.te(item) ;
  counter = 0 ;
  loop(gitd(d),
    counter = counter + 1 ;
    if(counter = 1, put d.te(d) else put / '', d.te(d) ) ;
    loop(mds_sim(mds), put GITresults(item,gitd,mds,'eoy','git') ) ;
  ) ;
) ;



*===============================================================================================
* 9. Write a report of HVDC charges sliced and diced all different ways.

put HVDCsum 'HVDC charges by year - before deducting tax, $m (real)' / 'MDS' ; loop(y, put y.tl ) ;
loop((bldrslt(rt),mds_sim(mds))$sum((g,y,t), hvdcgross_r(mds,rt,g,y,t)),
  put / mds.tl ;
  loop(y, put ( sum((g,t), hvdcgross_r(mds,rt,g,y,t)) ) ) ;
) ;

put /// 'HVDC charges by year - after deducting tax, $m (real)' / 'MDS' ; loop(y, put y.tl ) ;
loop((bldrslt(rt),mds_sim(mds))$sum((g,y,t), hvdcnet_r(mds,rt,g,y,t)),
  put / mds.tl ;
  loop(y, put ( sum((g,t), hvdcnet_r(mds,rt,g,y,t)) ) ) ;
) ;

put /// 'HVDC charges by plant - before deducting tax, $m (real)' / 'Plant' 'Tech' 'Fuel' 'Region' 'Zone' 'Owner' 'Share' 'Nameplate' ;
loop(mds_sim(mds), put mds.tl ) ;
loop((bldrslt(rt),g,k,f,r,e,o)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) * mapg_e(g,e) * mapg_o(g,o) * sum((mds,y,t), hvdcgross_r(mds,rt,g,y,t)) ),
  put / g.tl, k.tl, f.tl, r.tl, e.tl, o.tl, HVDCshr(o), nameplate(g) ;
  loop(mds_sim(mds), put ( sum((y,t), hvdcgross_r(mds,rt,g,y,t)) ) ) ;
) ;

put /// 'HVDC charges by plant - after deducting tax, $m (real)' / 'Plant' 'Tech' 'Fuel' 'Region' 'Zone' 'Owner' 'Share' 'Nameplate' ;
loop(mds_sim(mds), put mds.tl ) ;
loop((bldrslt(rt),g,k,f,r,e,o)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) * mapg_e(g,e) * mapg_o(g,o) * sum((mds,y,t), hvdcnet_r(mds,rt,g,y,t)) ),
  put / g.tl, k.tl, f.tl, r.tl, e.tl, o.tl, HVDCshr(o), nameplate(g) ;
  loop(mds_sim(mds), put ( sum((y,t), hvdcnet_r(mds,rt,g,y,t)) ) ) ;
) ;



$ontext
This chunk of code needs to be finished, i.e. it is to see if the revenue collected from HVDC charges is sufficient, and if it ain't,
you can reset the level of $/kw charge in the input data. 

Parameter ImpliedHVDC(mdsx,y) 'Implied HVDC charge, $/kW' ;
ImpliedHVDC(mds,y)$sum((bldrslt(rt),g)$( sigen(g) * posbuildm(g,mds) ), s3_capacity(mds,rt,g,y)) =
  sum((bldrslt(rt),g,t), hvdcgross_r(mds,rt,g,y,t)) / sum((bldrslt(rt),k,g)$(( not demgen(k) ) * sigen(g) * posbuildm(g,mds) * mapg_k(g,k)), s3_capacity(mds,rt,g,y)) ;

Display ImpliedHVDC, i_HVDCrevenue ;

*put /// 'Implied HVDC charges by plant, $/kW (real)' / 'Plant' 'Tech' 'Fuel' 'Region' 'Zone' 'Owner' 'Share' 'Nameplate' ;
*loop(mds_sim(mds), put mds.tl ) ;
*loop((g,k,f,r,e,o)$( mapg_k(g,k) * mapg_f(g,f) * mapg_r(g,r) * mapg_e(g,e) * mapg_o(g,o) * sum((mds,y,t), ImpliedHVDC(mds,g,y,t)) ),
*  put / g.tl, k.tl, f.tl, r.tl, e.tl, o.tl, HVDCshr(o), nameplate(g) ;
*  loop(mds_sim(mds), put ( sum((y,t), ImpliedHVDC(mds,g,y,t)) ) ) ;
*) ;


* NB: The HVDC charge applies only to committed and new SI projects.
  1e-6 * sum((y,t), PVfacG(y,t) * (1 - taxrate) * (
           ( 1/card(t) ) * (
           sum((g,k,o)$((not demgen(k)) * sigen(g) * posbuild(g) * mapg_k(g,k) * mapg_o(g,o)), HVDCshr(o) * HVDCcharge(y) * CAPACITY(g,y))
           )
         ) )

* Generation plant HVDC costs
  hvdcgross_r(mds,rt,g,y,t) =  1e-6 *
    ( 1/card(t) ) * sum((k,o)$( ( not demgen(k) ) * sigen(g) * posbuildm(g,mds) * mapg_k(g,k) * mapg_o(g,o) ), HVDCshr(o) * HVDCchargem(y,mds) * s3_capacity(mds,rt,g,y)) ;
  hvdcgross_pv(mds,rt,g,y,t,d) = PVfacsM(y,t,d) * hvdcgross_r(mds,rt,g,y,t) ;
  hvdcnet_r(mds,rt,g,y,t)      = (1 - taxrate)  * hvdcgross_r(mds,rt,g,y,t) ;
  hvdcnet_pv(mds,rt,g,y,t,d)   = PVfacsM(y,t,d) * hvdcnet_r(mds,rt,g,y,t) ;
HVDCchargem(y,mds) = 1e3 * i_HVDCcharge(y,mds) ;
$offtext





*===============================================================================================
* 10. Write a report of features common to all scenarios.

* Skip this entire section if numMDS = 1.
if(NumMDS > 1,

* Figure out the number of combinations - used in counting all MDS pairs where build year is within 5 years.
  numMDS_fact = numMDS ;      counter = numMDS_fact ;
  numMDS_fact2 = numMDS - 2 ; counter2 = numMDS_fact2 ;
  loop(mds_sim(mds),
    if(counter > 1,  numMDS_fact  = numMDS_fact *  ( counter - 1 ) ) ;
    if(counter2 > 1, numMDS_fact2 = numMDS_fact2 * ( counter2 - 1 ) ) ;
    counter =  counter  - 1 ;
    counter2 = counter2 - 1 ;
  ) ;

* numCombos equals 1 if numMDS = 2, otherwise it equals numMDS - 2 
  numCombos = 1 ;
  numCombos$( numMDS > 2 ) = numMDS_fact / ( 2 * numMDS_fact2 ) ;

* Figure out which plants get built in all scenarios.
  buildall(g)$( ( sum(mds_sim(mds), buildyr(mds,g)) >= numMDS * firstyear ) and
                ( sum(mds_sim(mds), buildyr(mds,g)) <= numMDS * lastyear ) ) = yes ;

* Of the plants built in all scenarios, identify which ones get built in the same year.
  loop(mds_sim(mds),
    buildall_sameyr(buildall(g))$( sum(mdss, buildyr(mdss,g)) = numMDS * buildyr(mds,g) ) = yes ;
  ) ;

* Of the plants built in all scenarios, identify which ones don't get built in the same year.
  buildall_notsameyr(buildall(g))$( not buildall_sameyr(g) ) = yes ; 

* Of the plants built in all scenarios but not all in the same year, identify those that get built within 5 years of each other.
  loop((g,mds,mdss)$( buildall_notsameyr(g) * mds_sim(mds) * mds_sim(mdss) * ( ord(mds) > ord(mdss) ) ),
    build_close5(g,mds,mdss)$( ( buildyr(mds,g) - buildyr(mdss,g) > -6 ) and ( buildyr(mds,g) - buildyr(mdss,g) < 6 ) ) = yes ;
  ) ;
  buildclose5(buildall_notsameyr(g))$( sum((mds,mdss)$build_close5(g,mds,mdss), 1 ) = numCombos ) = yes ;

* Of the plants built in all scenarios but not all in the same year, identify those that get built within 5 years of each other.
  buildplus5(buildall_notsameyr(g))$( not buildclose5(g) ) = yes ;

* Figure out retirements, refurbishments and transmission upgrades that happen in exactly the same year in each mds.
  loop(bldrslt(rt),
    retiresame(mds,g,y)$( sum(mdss, s3_retire(mdss,rt,g,y) + exogretireMWm(g,y,mdss)) = numMDS * ( s3_retire(mds,rt,g,y) + exogretireMWm(g,y,mds)) ) = s3_retire(mds,rt,g,y) + exogretireMWm(g,y,mds) ;
    refurbsame(mds,g)$( sum(mdss, s3_isretired(mdss,rt,g)) = numMDS ) = refurbyrm(g,mds) ;
    txupgradesame(mds,tupg,y)$( sum(mdss, s3_txprojvar(mdss,rt,tupg,y)) = numMDS ) = yearnum(y) ;
  ) ;

  Display numMDS_fact, numMDS_fact2, numCombos, buildall, buildall_sameyr, buildall_notsameyr, buildclose5, buildplus5, retiresame, refurbsame, txupgradesame ;

* Write common features report.
  put common 'Common features across all scenarios' /// 'Scenarios in this model run: ' loop(mds_sim(mds), put mds.tl ', ' ) ;
  put /  'NB: Build year refers to the year the first increment of plant is built in case of builds over multiple years.' / ;

  put // 'Year and MW for all plant built in the same year in all scenarios' / 'Plant' @18 'Year' @23 ; loop(mds_sim(mds), put mds.tl:>6 ) ;
  loop((y,buildall_sameyr(g))$( numMDS * yearnum(y) = sum(mds_sim(mds), buildyr(mds,g)) ),
    put / g.tl @18 y.tl @23 loop(mds_sim(mds), put buildMW(mds,g):>6:0 ) ;
  ) ;

  put // 'MW and year built for all plant built in all scenarios, not in same year, but within 5 years of each other' /
         'Plant' @23 loop(mds_sim(mds), put mds.tl:>6 ) put '      ' loop(mds_sim(mds), put mds.tl:>6 ) ;
  if(sum(buildclose5(g), 1) > 0,
    loop(buildclose5(g),
      put / g.tl @23 loop(mds_sim(mds), put buildMW(mds,g):>6:0 ) put '      ' loop(mds_sim(mds), put buildyr(mds,g):>6:0 ) ;
    ) ;
  else put / 'There are none' ) ;

  put // 'MW and year built for all plant built in all scenarios, not in same year, but more than 5 years apart' /
         'Plant' @23 loop(mds_sim(mds), put mds.tl:>6 ) put '      ' loop(mds_sim(mds), put mds.tl:>6 ) ;
  if(sum(buildplus5(g), 1) > 0,
    loop(buildplus5(g),
      put / g.tl @23 loop(mds_sim(mds), put buildMW(mds,g):>6:0 ) put '      ' loop(mds_sim(mds), put buildyr(mds,g):>6:0 ) ;
    ) ;
  else put / 'There are none' ) ;

  put // 'MW retired' / 'Year' @7 'Plant' @23 ; loop(mds_sim(mds), put mds.tl:>6 ) ;
  if(sum((mds,g,y)$retiresame(mds,g,y), 1) > 0,
    loop((y,g)$sum(mds_sim(mds), retiresame(mds,g,y)),
      put / y.tl @7 g.tl @23 loop(mds_sim(mds), put retiresame(mds,g,y):>6:0 ) ;
    ) ;
  else put / 'There are none' ) ;

  put // 'Plant for which the refurbishment decision year is the same in all scenarios' / 'Plant' @23 ; loop(mds_sim(mds), put mds.tl:>6 ) ;
  if(sum((mds,g)$refurbsame(mds,g), 1) > 0,
    loop(g$sum(mds_sim(mds), refurbsame(mds,g)),
      put / g.tl @23 loop(mds_sim(mds), put refurbsame(mds,g):>6:0 )
    ) ;
  else put / 'There are none' ) ;

  put // 'Transmission upgrade year' / 'Year' @7 'Upgrade' @23 ; loop(mds_sim(mds), put mds.tl:>6 ) ;
  if(sum((mds,tupg,y)$txupgradesame(mds,tupg,y), 1) > 0,
    loop((y,tupg)$sum(mds_sim(mds), txupgradesame(mds,tupg,y)),
      put / y.tl @7 tupg.tl @23 ;
      loop(mds_sim(mds), put txupgradesame(mds,tupg,y):>6:0 )
    ) ;
  else put / 'There are none' ) ;

  put // 'Build years for all plant not built in all scenarios' / 'Plant' @23 loop(mds_sim(mds), put mds.tl:>6 ) ;
  loop(noexist(g)$( not buildall(g) and sum(mds$buildyr(mds,g), 1) > 0 ),
    put / g.tl @23 loop(mds_sim(mds), put buildyr(mds,g):>6:0 )
  ) ;

) ;



*===============================================================================================
* 11. Write out a file of miscellaneous scalars - to pass to Matlab.
*     NB: It is not necessary to put every scalar known to GEM in this file.

Put miscs ;
put 'LossValue|%LossValue%|A user-specified value of the LRMC of generation plant' / ;
put 'partGenBld|', partGenBld:2:0, '|1 to enable some new plants to be partially and/or incrementally built; 0 otherwise' / ;
put 'annMW|', annMW:5:0, '|Annual MW upper bound on aggregate new generation plant builds' / ;
put 'TaxRate|', taxrate:5:3, '|Corporate tax rate' / ;
put 'PenaltyRenNRG|', penaltyrennrg:5:3, '|Penalty used to make renewable energy constraint feasible, $m/GWh' / ;
put 'security|', security:2:0, '|Switch to control usage of (N, N-1, N-2) security constraints' / ;
put 'useresv|',  useresv:2:0, '|Global reserve formulation activation flag (1 = use reserves, 0 = no reserves are modelled)' / ;



*===============================================================================================
* 12. Write out the mapping of inflow years to modelled years.

put HydYrs 'MDS', 'Run Type', 'hYr' loop(y, put y.tl ) ;
loop((mds,rt,hYr)$( sum(y, s_inflowyr(mds,rt,hYr,y)) ),
  put / mds.tl, rt.tl, hYr.tl ;
  loop(y,
    if(ahy(hYr), put 'Average' else put s_inflowyr(mds,rt,hYr,y) ) ;
  ) ;
) ;



*===============================================================================================
* 13. Collect national generation, transmission, losses and load (GWh) into a single parameter.

chktotals(mds_rt(mds,rt),'Gen')  = sum((r,g,y,t,lb,hd)$( mds_rt_hd(mds,rt,hd) and mapg_r(g,r) ), s3_gen(mds,rt,g,y,t,lb,hd)) ;
chktotals(mds_rt(mds,rt),'Tx')   = sum((r,rr,y,t,lb,hd)$mds_rt_hd(mds,rt,hd), hrsperblk(t,lb) * 1e-3 * s3_tx(mds,rt,r,rr,y,t,lb,hd)) ;
chktotals(mds_rt(mds,rt),'Loss') = sum((r,rr,y,t,lb,hd)$mds_rt_hd(mds,rt,hd), hrsperblk(t,lb) * 1e-3 * s3_loss(mds,rt,r,rr,y,t,lb,hd)) ;
chktotals(mds_rt(mds,rt),'Dem')  =
  sum((r,t,lb,y,hd)$mds_rt_hd(mds,rt,hd), ldcMWm(mds,r,t,lb,y) * hrsperblk(t,lb) * 1e-3 + sum(g$( mapg_r(g,r) * pdhydro(g) ), s3_pumpedgen(mds,rt,g,y,t,lb,hd)) ) ;

chktotals(mds,rt,'Bal')$mds_rt(mds,rt) = chktotals(mds,rt,'Gen') - chktotals(mds,rt,'Dem') - chktotals(mds,rt,'Loss') ;

Display chktotals ;



*===============================================================================================
* 14. Write the solve summary report.

* Message strings for use in solve summary report: 
$setglobal ModStatx    "++++ Solution is no good - check %ExecName%.lst ++++"
$setglobal ModStat1    "An optimal RMIP solution was obtained"
$setglobal ModStat8    "A valid integer solution was obtained"
$setglobal ModStat18   "An optimal integer solution was obtained"
$setglobal SolveStatx  "++++ The solver exited abnormally - check %ExecName%.lst ++++"
$setglobal SolveStat1  "The solver exited normally"
$setglobal SolveStat3  "The solver exited normally after hitting a resource limit"

problems = 0 ; warnings = 0 ;
ss.ap = 1 ;
loop(mds_sim(mds),
  put ss // 'MDS:' @6 put '(', mds.tl, ') ' ;
  loop(mdsx$(mds_sim(mdsx) and (ord(mdsx) - 1 = ord(mds)) ), put mdsx.te(mdsx) // ) ;

$ if %RunType%==2 $goto NoGEM

* Generate the MIP solve summary information, i.e. timing run and re-optimised run (if it exists).
  loop((rt,hYr,solvegoal(goal))$( s_solveindex(mds,rt,hYr) and (not sameas(rt,'dis') ) ),
    if(sameas(rt,'tmg'),
      put @3 'Solve goal:' @25 goal.tl:<6, ' - ', goal.te(goal) //
          @3 'Run type:'   @25 rt.te(rt) / ;
    else
      put // @3 'Run type:' @25 rt.te(rt) / ;
    ) ;
    put @3 'Model status:' @25 ;
    if(mipreport(mds,rt,hYr,goal,'ModStat') = 1, put '%ModStat18%' /
      else if(mipreport(mds,rt,hYr,goal,'ModStat') = 8, put '%ModStat8%' /
        else put '%ModStatx%' / ; problems = problems + 1 ;
      ) ;
    ) ;
    put @3 'Solver status:' @25 ;
    if(mipreport(mds,rt,hYr,goal,'SolStat') = 1, put '%SolveStat1%' / ;
      else if(mipreport(mds,rt,hYr,goal,'SolStat') = 2 or mipreport(mds,rt,hYr,goal,'SolStat') = 3, put '%SolveStat3%' / ;
        else put '%SolveStatx%' / ; problems = problems + 1 ;
      ) ;
    ) ; put
    @3 'Number equations:'     @25 mipreport(mds,rt,hYr,goal,'Eqns'):<10:0 / 
    @3 'Number variables:'     @25 mipreport(mds,rt,hYr,goal,'Vars'):<10:0 / 
    @3 'Number discrete vars:' @25 mipreport(mds,rt,hYr,goal,'DVars'):<10:0 / 
    @3 'Number iterations:'    @25 mipreport(mds,rt,hYr,goal,'Iter'):<12:0 / 
    @3 'Options file:'         @25 '%Solver%.op', mipreport(mds,rt,hYr,goal,'Optfile'):<2:0 /
    @3 'Optcr (%):'            @25 ( 100 * mipreport(mds,rt,hYr,goal,'Optcr') ):<6:3 /
    @3 'Gap (%):'              @25 mipreport(mds,rt,hYr,goal,'Gap%'):<6:3 /
    @3 'Absolute gap:'         @25 mipreport(mds,rt,hYr,goal,'GapAbs'):<10:2 /
    @3 'CPU seconds:'          @25 mipreport(mds,rt,hYr,goal,'Time'):<10:0 /
    @3 'Objective fn value:'   @25 s2_totalcost(mds,rt,hyr):<10:1 ;
    if(mipreport(mds,rt,hYr,goal,'Slacks') = 1, put '  ++++ This solution contains slack variables ++++' / else put / ) ;
    put @9 'Comprised of:' @25 ;
    loop(objc$( ord(objc) > 1 and not (pen(objc) or slk(objc)) ),
      put obj_components(mds,rt,objc):<10:1, @33 '- ', objc.te(objc) / @23 '+ ' ;
    ) ;
    put sum(pen(objc), obj_components(mds,rt,objc)):<10:1, @33 '- Sum of penalty components' / @23 '+ ' ;
    put sum(slk(objc), obj_components(mds,rt,objc)):<10:1, @33 '- Sum of slack components' ;
  ) ;

$ Label NoGEM
$ if %RunType%==1 $goto NoDISP

* Generate the RMIP (dispatch) solve summary information for each pass around the MDS loop.
  counter = 0 ;
  loop((rt,hYr)$( sameas(rt,'dis') and s_solveindex(mds,rt,hYr) ),
    counter = counter + 1 ;
    if(counter = 1,
      put /// @3 rt.te(rt) /
      @3 'Number equations:'     @25 rmipreport(mds,rt,hYr,'Eqns'):<10:0 / 
      @3 'Number variables:'     @25 rmipreport(mds,rt,hYr,'Vars'):<10:0 /
      @3 'Generation capex'      @25 obj_components(mds,rt,'obj_gencapex'):<10:1 /
      @3 'Refurbishment capex'   @25 obj_components(mds,rt,'obj_refurb'):<10:1 /
      @3 'Transmission capex'    @25 obj_components(mds,rt,'obj_txcapex'):<10:1 /
      @3 'HVDC charges'          @25 obj_components(mds,rt,'obj_hvdc'):<10:1 /
      @3 'Fixed opex'            @25 obj_components(mds,rt,'obj_fixOM'):<10:1 /
      @3 'Objective value in the following DISPatch solves differs only due to after tax discounted' /
      @3 'variable costs, the cost of providing reserves and, possibly, the value of any penalties.' //
      @3 mds.tl, '. DISPatch run on ' hYr.tl ' hydro year' /
      @3 'Model status:' @25 ;
      if(rmipreport(mds,rt,hYr,'ModStat') = 1,  put '%ModStat1%'   / else put '%ModStatx%'   / ; problems = problems + 1 ) ; put @3 'Solver status:' @25 ;
      if(rmipreport(mds,rt,hYr,'SolStat') = 1,  put '%SolveStat1%' / else put '%SolveStatx%' / ; problems = problems + 1 ) ; put
      @3 'Number iterations:'    @25 rmipreport(mds,rt,hYr,'Iter'):<10:0 / 
      @3 'CPU seconds:'          @25 rmipreport(mds,rt,hYr,'Time'):<10:0 / 
      @3 'Objective fn value:'   @25 s2_totalcost(mds,rt,hyr):<10:0  ;
      if(rmipreport(mds,rt,hYr,'Slacks') = 1, put '  ++++ This solution contains slack variables ++++' / else put / ) ;
    else put /
      @3 mds.tl, '. DISPatch run on ' hYr.tl ' hydro year' /
      @3 'Model status:' @25 ;
      if(rmipreport(mds,rt,hYr,'ModStat') = 1,  put '%ModStat1%'   / else put '%ModStatx%'   / ; problems = problems + 1 ) ; put @3 'Model status:' @25 ;
      if(rmipreport(mds,rt,hYr,'SolStat') = 1,  put '%SolveStat1%' / else put '%SolveStatx%' / ; problems = problems + 1 ) ; put
      @3 'Number iterations:'    @25 rmipreport(mds,rt,hYr,'Iter'):<10:0 / 
      @3 'CPU seconds:'          @25 rmipreport(mds,rt,hYr,'Time'):<10:0 / 
      @3 'Objective fn value:'   @25 s2_totalcost(mds,rt,hyr):<10:0  ;
      if(rmipreport(mds,rt,hYr,'Slacks') = 1, put '  ++++ This solution contains slack variables ++++' ) ; put / ;
    ) ;
  ) ;

$ Label NoDisp

* End of writing to solve summary report loop over MDS.
) ;


* Headers 
$set TmgHeader  " - results pertain to the timing run."
$set ReoHeader  " - results pertain to the re-optimisation run."
$set DisHeader  " - results pertain to the average of the dispatch runs."
$set DisExogHdr " - decisions were provided to GEM exogenously in the form of a build and retirement schedule."

* Write summaries of built, refurbished and retired capacity by technology.
loop(bldrslt(rt),
  loop(a,
    put /// a.te(a) ;
    if( sameas(a,'blt'),
      if(sameas(rt,'tmg'), put '%TmgHeader%' else if(sameas(rt,'reo'), put '%ReoHeader%' else put '%DisExogHdr%' ) ) ;
    else
      if(not sameas(rt,'dis'), put '%TmgHeader%' else put '%DisExogHdr%' ) ;
    ) ;
    loop(mds_rt(mdsx,rt),
      put // @3 mdsx.te(mdsx), ' (', mdsx.tl, ')' /  @58 'Potential MW' @71 'Actual MW' @89 '%' ;
      loop(k$pot_cap(mdsx,k,a),
        put / @5 k.te(k) @60, pot_cap(mdsx,k,a):10:0, act_cap(mdsx,rt,k,a):10:0, actual_cappc(mdsx,rt,k,a):10:1 ;
      ) ;
    ) ;
  ) ;
) ;

* Write a summary of transmission upgrades into the solve summary report.
loop(bldrslt(rt),
  put //// 'Summary of transmission upgrades' ;
  if(not sameas(rt,'dis'), put '%TmgHeader%' else put '%DisHeader%' ) ;
  loop(mds_rt(mdsx,rt),
    put // @3 mdsx.te(mdsx), ' (', mdsx.tl, ')' ;
    put / @5 'Project' @20 'From' @35 'To' @50 'From state' @65 'To state' @80 'Year' @87 'MW Capacity'
    loop((y,transitions(tupg,r,rr,ps,pss))$s3_txupgrade(mdsx,rt,r,rr,ps,pss,y),
      put / @5 tupg.tl:<15, r.tl:<15, rr.tl:<15, ps.tl:<15, pss.tl:<15, y.tl:<8, actualtxcap(mdsx,rt,r,rr,y):10:0  ;
    ) ;
  ) ;
) ;

* Write a summary of transmission losses into the solve summary report.
Parameters
  totalgen(mdsx,rt)     'Generation, GWh'
  intralosses(mdsx,rt)  'Intraregional losses, GWh'
  interlosses(mdsx,rt)  'Interregional losses, GWh'
  ;

totalgen(mds,rt) = sum((g,y,t,lb,hd)$mds_rt_hd(mds,rt,hd), s3_gen(mds,rt,g,y,t,lb,hd)) ;
intralosses(mds,rt) = sum((ild,y,r,t,lb)$mapild_r(ild,r), AClossFactor(ild) * load(y,lb,mds,r,t) / ( 1 + AClossFactor(ild) ) ) ;
interlosses(mds,rt) = sum((paths(r,rr),y,t,lb,hd)$mds_rt_hd(mds,rt,hd), s3_loss(mds,rt,paths,y,t,lb,hd) * hrsperblk(t,lb) * 1e-3 ) ;

put //// 'Summary of transmission losses (GWh and as percent of generation)' ;
*if(sameas(rt,'tmg'), put '%TmgHeader%' else if(sameas(rt,'reo'), put '%ReoHeader%' else put '%DisHeader%' ) ) ;
loop(mds_sim(mdsx),
  put // @3 mdsx.te(mdsx), ' (', mdsx.tl, ')' / @28 ;
  loop(mds_rt(mdsx,rt), put rt.tl:>10 '         ' ) ; 
  put  / @5 'Generation:'           @26 loop(mds_rt(mdsx,rt), put totalgen(mdsx,rt):10:1 '         ' ) ;
  put  / @5 'Intraregional losses:' @26 loop(mds_rt(mdsx,rt), put intralosses(mdsx,rt):10:1, ( 100 * intralosses(mdsx,rt) / totalgen(mdsx,rt) ):>6:2, '%  ' ) ;
  put  / @5 'Interregional losses:' @26 loop(mds_rt(mdsx,rt), put interlosses(mdsx,rt):10:1, ( 100 * interlosses(mdsx,rt) / totalgen(mdsx,rt) ):>6:2, '%  ' ) ;
) ;


* Write a summary of excessive shortage generation into the solve summary report (excessive is assumed to be 3% of generation).
if(sum((mds_rt_hd(mds,rt,hd),y,t,lb), xsdefgen(mds,rt,hd,y,t,lb)) = 0,
  put //// 'There is no excessive use of unserved energy (where excessive is defined to be 3% or more of generation).' ;
else
  put //// 'Examine "Objective value components and shortage generation.gdx" in the GDX output folder to see' /
           'what years and load blocks had excessive shortage generation (i.e. more than 3% of generation).' ;
) ;


* Write a summary breakdown of objective function values into the solve summary report.
loop(bldrslt(rt),
  put //// 'Summary breakdown of objective function values ($m)' ;
  if(sameas(rt,'tmg'), put '%TmgHeader%' else if(sameas(rt,'reo'), put '%ReoHeader%' else put '%DisHeader%' ) ) ;
  loop(s_solveindex(mdsx,rt,hYr),
    put // @3 mdsx.te(mdsx), ' (', mdsx.tl, ')' ;
    put /  @5 'Objective function value' @65 s3_totalcost(mdsx,rt):10:1 ;
    loop(objc$( ord(objc) > 1 and not (pen(objc) or slk(objc)) ),
      put / @5 objc.te(objc), @65 obj_components(mdsx,rt,objc):10:1 ;
    ) ;
    put / @5 'Sum of penalty components', @65 ( sum(pen(objc), obj_components(mdsx,rt,objc)) ):10:1 ;
    put / @5 'Sum of slack components',   @65 ( sum(slk(objc), obj_components(mdsx,rt,objc)) ):10:1 ;
  ) ;
) ;

* Write a note to solve summary report if problems (other than slacks or penalty violations) are present in some solutions, or if warnings are required.
* Figure out the warnings.
* Warning 1
if(lastyear - %begtermyrs% < 3, warnings = warnings + 1 ) ;
* Warning 2
counter = 0 ;
loop((g,mds)$( ( erlyComYr(g,mds) > 1 ) * ( fixComYr(g,mds) > 1 ) * ( fixComYr(g,mds) < erlyComYr(g,mds) ) ),
  counter  = counter + 1 ;
  warnings = warnings + 1 ;
) ;

if(warnings > 0,
  put ss ////
  '  ++++ WARNINGS ++++' // ;
  if(lastyear - %begtermyrs% < 3,
    put '  Terminal years begin in %begtermyrs% whereas the last modelled year is ', lastyear:<4:0, ' (although GEM changed %begtermyrs% to '
    begtermyrs:<4:0, ' and just carried on anyway). Check BegTermYrs in RunGEM.gms.' / ;
  ) ;
  if(counter > 0,
    put '  Some fixed plant commissioning years precede the earliest commissioning year. Examine badComYr in %BaseOutName%.lst.' / ;
  ) ;
) ;

if(problems > 0,
  put ////
  '  ++++ PROBLEMS OTHER THAN SLACKS OR PENALTIES EXIST WITH SOME SOLUTIONS ++++' /
  '  It could be that a model is infeasible or the solver has not exited        ' /
  '  normally for some reason. Examine this solve summary report (search        ' /
  '  for ++++) or %Logfile% for additional information and resolve before       ' /
  '  proceeding.                                                                ' //// ;
) ;



*===============================================================================================
* 15. Report the presence of penalty or slack (i.e. violation) variables (if any).

slacks = 0 ;
slacks = sum((mds_rt,slk), obj_components(mds_rt,slk)) + sum((mds_rt,pen), obj_components(mds_rt,pen)) ; 

Option slacks:0 ; Display slacks ;

if(slacks > 0,

  Display 'Slack or penalty variables have been used in at least one solution', %List_10_s3slacks%, s3_renNrgPenalty, s3_resvviol ;
  Execute_Unload '%OutPath%\%Outprefix%\GDX\S3 Slacks and penalties.gdx',       %List_10_s3slacks%, s3_renNrgPenalty, s3_resvviol ;

  put ss //// '++++ Slack or penalty variables are present in some solutions. Examine'    /
              '     %RepName%.lst and/or "Slacks and penalties.gdx" in the GDX directory' /
              '     for a detailed list of all slack and penalty variables.'              // ;
) ;



*===============================================================================================
* 16. Dump certain parameters into GDX files for use in subsequent programs, e.g. GEMplots and GEMaccess.

Execute_Unload '%OutPath%\%Outprefix%\GDX\%Outprefix% - Objective value components and shortage generation.gdx',
  obj_components_yr, obj_components, defgen, xsdefgen, problems, warnings, slacks ;

Execute_Unload '%OutPath%\%Outprefix%\GDX\%Outprefix% - ReportsData.gdx',
  GEMexecVer, GEMprepoutVer, GEMreportsVer
  activecap, problems, warnings, slacks, numdisyrs, genyr, buildyr, capchrg_r, capchrg_pv, capchrgyr_r, capchrgyr_pv
  taxcred_r, taxcred_pv, fopexgross_r, fopexnet_r, hvdcgross_r, hvdcnet_r, txcapchrgyr_r, txcapchrgyr_pv
  ;




* End of file






$ontext

** LRMC code still under development. Use the stuff in GEMbaseOut as a template to create estimates of LRMC by plant
** given the actual GEM solution.

Sets
  z                         'A sequence of years'            / z1 * z100  /
  mc                        'Index for LRMC values'          / c1 * c2000 /
  checkmap(mds,g,y,z)

Parameter
*  mwh(mds,g,y)              'MWh per year per plant actually generated'
  mwh(mds,g)              'MWh per year per plant actually generated'
  plantyrs(g)               'Plant life, years'
  depreciation(mds,g,z)     'Depreciation in each year of plant life, $m'
  undepcapital(mds,g,z)     'Undepreciated capital in each year of plant life, $m'
  cndte_lrmc(mc)            "Candidate lrmc's, $/MWh"
  dcf(mds,g,mc)             'Post-tax discounted cashflows by plant at each candidate LRMC level, $m'
  lrmc(mds,g)               'LRMC of each plant, $/MWh'
  totcosts(mds,g,z)         'Total costs, $m'
  lrmc_offset               'Constant to add to 1 to kick off the candidate LRMC series'     / 0 /
  ycount
  zcount(mdsx,g)
  ;

* h is dum only for rt=dis - need to do mwh for tmg and/or reo too 
*mwh(mds,noexist(g),y)$numdisyrs(mds) = 1e3 * sum((dis(rt),hyr,hd)$( s_hdindex(mds,rt,hyr,hd) * ( not (ahy(hYr) or mhy(hYr)) ) ), s2_genyr(mds,rt,hYr,g,y,hd)) / numdisyrs(mds) ;
mwh(mds,noexist(g)) = nameplate(g) * 8760 * (1 - fof(g)) ;


* Convert plant life by technology to plant life by plant.
plantyrs(noexist(g)) = sum(mapg_k(g,k), plantlife(k)) ;

zcount(mds_sim(mds),noexist(g)) = plantyrs(g) + lastyear - firstyear ;

loop((mds_sim(mds),noexist(g),y,z)$( ord(z) = ord(y) and buildyr(mds,'dis','1932',g) ),
  totcosts(mds,g,z) = 1e-6 * mwh(mds,g) * srmcm(g,y,mds) + 1e-9 * gendata(g,'fOM') * nameplate(g) ;
) ;

* Complete the series for sequential years up to the number of modelled years plus plant life years.
loop((mds_sim(mds),noexist(g),z)$( zcount(mds,g) and (ord(z) > 1) and (ord(z) <= zcount(mds,g)) ),
  totcosts(mds,g,z)$( not totcosts(mds,g,z) ) = totcosts(mds,g,z-1) ; 
) ;

* Zero out totcosts for all years prior to build year.
totcosts(mds,g,z)$( ord(z) < ( buildyr(mds,'dis','1932',g) - firstyear + 1 ) ) = 0 ;

* Compute depreciation and undepreciated capital for each relevant 'z' year. 
loop((mds_sim(mds),noexist(g),z)$totcosts(mds,g,z),
  undepcapital(mds,g,z)$( ord(z) = buildyr(mds,'dis','1932',g) - firstyear + 1 ) = 1e-6 * nameplate(g) * capandconcost(g) ;
  depreciation(mds,g,z)$( ord(z) > buildyr(mds,'dis','1932',g) - firstyear + 1 ) = sum(mapg_k(g,k), deprate(k) * undepcapital(mds,g,z-1) ) ;
  undepcapital(mds,g,z)$( ord(z) > buildyr(mds,'dis','1932',g) - firstyear + 1 ) = undepcapital(mds,g,z-1) - depreciation(mds,g,z) ;
) ;

* Add depreciation to totcosts.
totcosts(mds,g,z) = totcosts(mds,g,z) + depreciation(mds,g,z) ;

Parameter capex(mds,g,z) ;
capex(mds,g,z)$( zcount(mds,g) and (ord(z) = buildyr(mds,'dis','1932',g) - firstyear + 1) ) = -1e-6 * nameplate(g) * capandconcost(g) ;

counter = 0 ;
lrmc(mds,g) = 0 ;
loop((mds,noexist(g),mc)$( zcount(mds,g) and lrmc(mds,g) = 0 ),

  cndte_lrmc(mc) = ord(mc) + lrmc_offset ;

  dcf(mds,g,mc)$sum(z, capex(mds,g,z)) = 
                                sum(z$( ord(z) <= zcount(mds,g) ),
                                  capex(mds,g,z) / ( ( 1 + WACCg) ** ( ord(z) ) ) +
                                  ( ( 1 - taxrate ) * ( 1e-6 * mwh(mds,g) * cndte_lrmc(mc) - totcosts(mds,g,z) ) + depreciation(mds,g,z) ) /
                                  ( ( 1 + WACCg) ** ( ord(z) ) )
                                ) ;

  if(dcf(mds,g,mc) > 0 and counter = 0,
    counter = 1 ;
    lrmc(mds,g) = cndte_lrmc(mc) ;
  ) ;

  counter = 0 ;

) ;

Execute_Unload 'test.gdx', mwh, srmcm, buildyr, totcosts, zcount, undepcapital, depreciation, lrmc, capex ;

*$ontext

zcount = 0 ; counter = 0 ; lrmc(mds,g) = 0 ;
loop((mds_sim(mds),noexist(g),y)$( buildyr(mds,'dis','1932',g) = yearnum(y) ),

  loop(z$( ord(z) <= plantyrs(g) ),

    checkmap(mds,g,y,z) = yes ;

    zcount = zcount + 1 ;

    undepcapital(mds,g,z)$( ord(z) = 1 ) = 1e-6 * nameplate(g) * capandconcost(g) ;
    depreciation(mds,g,z)$( ord(z) > 1 ) = sum(mapg_k(g,k), deprate(k) * undepcapital(mds,g,z-1) ) ;
    undepcapital(mds,g,z)$( ord(z) > 1 ) = undepcapital(mds,g,z-1) - depreciation(mds,g,z) ;

    totcosts(mds,g,z) = 1e-6 * mwh(mds,g,y) * srmcm(g,y+zcount,mds) +
                        1e-9 * gendata(g,'fOM') * nameplate(g) ;
    ) ;

  zcount = 0 ;

* Complete the series for sequential years up to the number of plant life years.
  loop(z$( ord(z) > 1  and ord(z) <= plantyrs(g) ),
    totcosts(mds,g,z)$( not totcosts(mds,g,z) ) = totcosts(mds,g,z-1) ; 
  ) ;

* Add depreciation to totcosts.
  totcosts(mds,g,z) = totcosts(mds,g,z) + depreciation(mds,g,z) ;

  loop(mc$( lrmc(mds,g) = 0 ),
    cndte_lrmc(mc) = ord(mc) + lrmc_offset ;
    dcf(mds,g,mc)$mwh(mds,g,y) = -capandconcost(g) * nameplate(g) * 1e-6 +
                                 sum(z$( ord(z) <= plantyrs(g) ),
                                   ( ( 1 - taxrate ) * ( 1e-6 * mwh(mds,g,y) * cndte_lrmc(mc) - totcosts(mds,g,z) ) + depreciation(mds,g,z) ) /
                                   ( ( 1 + WACCg) ** ( ord(z) ) )
                                 ) ;
    if(dcf(mds,g,mc) > 0 and counter = 0,
      counter = 1 ;
      lrmc(mds,g) = cndte_lrmc(mc) ;
    ) ;

    counter = 0 ;

  ) ;

) ;


Execute_Unload 'test.gdx', mwh, srmcm, totcosts, checkmap, buildyr, undepcapital, depreciation, lrmc, dcf ;


file lrmc_mds  LRMCs based on GEM solution  / "LRMC estimates by MDS.csv" / ; lrmc_mds.pc = 5 ;

put lrmc_mds 'Plant', 'Technology', 'MW' ; loop(mds_sim(mds), put mds.tl ); loop(mds_sim(mds), put mds.tl ) ;
*loop((k,noexist(g))$( sum(mds, lrmc(mds,g)) * mapg_k(g,k) ),
loop((k,noexist(g))$( sum(mds, buildyr(mds,'dis','1932',g)) * mapg_k(g,k) ),
  put / g.tl, k.tl, nameplate(g) ;
  loop(mds_sim(mds), put lrmc(mds,g) ) ;
  loop(mds_sim(mds), put buildyr(mds,'dis','1932',g) ) ;
) ;



  tmg(rt)                'Run type TMG - determine timing'   / tmg /
  reo(rt)                'Run type REO - re-optimise timing' / reo /
  dis(rt)                'Run type DIS - dispatch'           / dis /

  loop((tmg(rt),tmnghydyr(hYr)),
  loop((reo(rt),reopthydyr(hYr)),

$ if %SuppressReopt%==1 $goto NoReOpt

    loop(dis(rt),

*   Capture the elements of the run type - MDS - hydro year tuple, i.e. the 3 looping sets:
    s_solveindex(mds,rt,hYr) = yes ;

*   Capture the hydro domain index.
     = yes ;

* Compute depreciation and undepreciated capital by sequential year. 
undepcapital(noexist(g),z)$( ord(z) = 1 ) = 1e-6 * nameplate(g) * capandconcost(g) ;

loop((noexist(g),z)$( ( ord(z) > 1 ) and ( ord(z) <= plantyrs(g) ) ),
  depreciation(g,z) = sum(mapg_k(g,k), deprate(k) * undepcapital(g,z-1) ) ;
  undepcapital(g,z) = undepcapital(g,z-1) - depreciation(g,z) ;
) ;

* Convert costs from modelled years (y) to sequential years (z), from $/MWh to $m, and collect into a parameter called totcosts.
loop((noexist(g),z,y)$( ( ord(z) <= plantyrs(g) ) and ( ord(z) = ord(y) ) ),
  totcosts(g,z,mds) = 1e-6 * mwh(g) * varomm(g,y,mds) +             ! Variable O&M costs, $m
                      1e-9 * gendata(g,'fOM') * nameplate(g) +      ! Fixed O&M costs, $m
                      1e-6 * mwh(g) * fuelcostm(g,y,mds) +          ! Fuel costs, $m
                      1e-6 * mwh(g) * co2taxm(g,y,mds)   ;          ! CO2 taxes, $m
) ;

$offtext
