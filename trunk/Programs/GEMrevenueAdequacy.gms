* GEMrevenueAdequacy.gms

* Last modified by Dr Phil Bishop, 17/11/2010 (imm@ea.govt.nz)

$ontext
  This program does....
  In the first instance, I am building a GEM2.0 replica of BB's revenue adequacy algorithm
  See below the $stop and/or "get_adequate_prices_2010SOO - BB's revenue adequacy stuff.gms"

 Code sections:
  1. Load data...
  2. xxx
  3. xxx
$offtext

option limcol = 0, limrow = 0, reslim = 50000, iterlim = 1000000, seed = 101, sysout = on, solprint = off ;

$include GEMsettings.inc

$offupper onempty inlinecom { } eolcom !

* Turn the following maps on/off as desired.
$offuelxref offuellist	
*$onuelxref  onuellist	

$offsymxref offsymlist
*$onsymxref  onsymlist


*===============================================================================================
* 1. Load data from a solution.

Sets
  k            'Generation technologies'
  f            'Fuels'
  g            'Generation plant'
  t            'Time periods (within a year)'
  lb           'Load blocks'
  hY           'Hydrology output years'
  hd           'Hydrology domain for multiple hydro years'
  ;

Alias (sc,scc), (hY,hY1) ;

* Re-initialise set y with the modelled years from GEMsettings.inc (the set y in the GDX input file contains all data years).
Set y / %firstYear% * %lastYear% / ;

* Get the other required fundamental sets from the first scenario's input GDX file.
$gdxin "%DataPath%%firstScenario%"
$loaddc k f g t lb hY hd

$gdxin 'all_prepout.gdx'
* Sets
$loaddc h activeSolve activeHD activeRT solveGoal
* Parameters
$loaddc numDisYrs s2_CAPACITY s2_GEN



*s_genyr_2(mds,rt,g,hYr,y) = SUM((t,lb,hd)$(sameas(hd,'dum')),s_gen_2(mds,rt,hYr,g,y,t,lb,hd));



*===============================================================================================
* 2. Declare and initialise sets and parameters specific to this program.

Sets
  require_adequacy_peak(k)   'Peaking technologies for which we assert adequacy'                                    / GasPkr, DslPkr, DslRecip, BioPkr, HydPD /
  require_adequacy_mid(k)    'Mid-order technologies for which we assert adequacy'                                  / Coal, IGCC, IGCC_CCS, Lig, IGCC_Lig, IGCC_LigCCS, CCGT, CCGT_CCS, HydPk /
  require_adequacy_base(k)   'Baseload, intermittent and process-driven technologies for which we assert adequacy'  / CoalCog, GasCog, Geo, BioCog, OthCog, HydRR, Wind, Wave, Tide, Solar /
  ;


$ontext
Phil notes
- Why not put hydro peaking in peak(k) set? BB has it in mid-order set.
- 7 of 31 technologies not accounted for. Why? See Coal_DY, OCGT, HydSC, HydDG, WindDG, DSM, IL

$offtext
















$stop
* cd "c:\soo2010 revenue adequacy"
* gams "\\tsclient\C\SOO2008\MarDraft\Revenue adequacy\get_adequate_prices_2010SOO.gms" r=GEMbase gdx=get_adequate_prices_2010SOO



PARAMETERS
  CAPCHRG_R(rt,mds,hYr,g,y)       'Capex charges (net of depreciation tax credit effects) by built plant by year, $m (real)'
  FOPEXGROSS_R(rt,mds,hYr,g,y,t)  'Fixed O&M expenses (before tax benefit) by built plant by year by period, $m (real)'  
  S_CAPACITY_2(mds,rt,hYr,g,y)  
  S_GEN_2(mds,rt,hYr,g,y,t,lb,hd)  
  S_GENYR_2(mds,rt,g,hYr,y)
  ; 

loop((rt,mds,hYr)$s_solveindex(mds,rt,hYr),
  fopexgross_r(rt,mds,hYr,g,y,t)    = 0.001 * ( 1/card(t) ) * gendata(g,'fOM') * s_capacity_2(mds,rt,hYr,g,y) ;
  capchrg_r(rt,mds,hYr,g,y)         = 0.000001 * capchargem(g,y,mds) * s_capacity_2(mds,rt,hYr,g,y) ;
);

PARAMETERS
  COST_CAPEX(rt,mds,hYr,hd,g,y)        'Capex including depreciation benefit'
  COST_FOPEX(rt,mds,hYr,hd,g,y)        'Fixed O&M, no LFs, pre tax'
  COST_VOPEX(rt,mds,hYr,hd,g,y)        'Variable O&M, no LFs, pre tax'
  COST_FUEL(rt,mds,hYr,hd,g,y)         'Fuel cost, no LFs, pre tax'
  COST_CARBON(rt,mds,hYr,hd,g,y)       'Carbon cost, no LFs, pre tax'
  COST_CCS(rt,mds,hYr,hd,g,y)          'CCS cost, no LFs, pre tax'

  COST_TOTAL_POSTTAX_M(mds,hYr,g,y)    'Total post tax cost - dispatch runs with hYr<>Average'
  OUTPUT_M(mds,hYr,g,y,t,lb)           'Generation in MWh'
  TOTAL_OUTPUT_M(mds,y,t,lb)           'Generation in GWh'
  
  COST_TOTAL_POSTTAX(hYr,g,y)          'Total post tax cost - dispatch runs with hYr<>Average'
  OUTPUT(hYr,g,y,t,lb)                 'Generation in MWh'
  TOTAL_OUTPUT(y,t,lb)                 'Generation in GWh'

  DISCOUNT_FACTORS(y)                  'For depreciating at 8%' 
  ;

* Compute results by stations by year:
LOOP((rt,mds,hYr,hd,g,y,k,f)$( s_hdindex(mds,rt,hyr,hd) * mapg_k(g,k) * mapg_f(g,f) ),
  cost_capex(rt,mds,hYr,hd,g,y) = capchrg_r(rt,mds,hYr,g,y) ;
  cost_fopex(rt,mds,hYr,hd,g,y) = SUM(t, fopexgross_r(rt,mds,hYr,g,y,t)) ;
  cost_vopex(rt,mds,hYr,hd,g,y) = 0.001 * varOMm(g,y,mds) * s_genyr_2(mds,rt,g,hYr,y) ;
  cost_fuel(rt,mds,hYr,hd,g,y)  = 0.001 * fuelcostm(g,y,mds) * s_genyr_2(mds,rt,g,hYr,y) ;
  cost_carbon(rt,mds,hYr,hd,g,y)= 0.001 * co2taxm(g,y,mds) * s_genyr_2(mds,rt,g,hYr,y) ;
  cost_ccs(rt,mds,hYr,hd,g,y)   = 0.001 * carboncscostm(g,y,mds) * s_genyr_2(mds,rt,g,hYr,y) ;
) ;
* Note there are also refurbishment costs for existing thermals, but I don't care about that (not new plants)

cost_total_posttax_m(mds,hYr,g,y)$(not sameas(hYr,'Average')) = cost_capex('DIS',mds,hYr,'dum',g,y) + 0.7 * (cost_fopex('DIS',mds,hYr,'dum',g,y) + cost_vopex('DIS',mds,hYr,'dum',g,y) + cost_fuel('DIS',mds,hYr,'dum',g,y) + cost_carbon('DIS',mds,hYr,'dum',g,y) + cost_ccs('DIS',mds,hYr,'dum',g,y) ) ;

output_m(mds,hYr,g,y,t,lb)$(not sameas(hYr,'Average') ) = s_gen_2(mds,'DIS',hYr,g,y,t,lb,'dum') ;
total_output_m(mds,y,t,lb) = SUM((g,hYr), output_m(mds,hYr,g,y,t,lb))/1000 ;

discount_factors(y) = 1 / ( 1.08  ** (yearnum(y) - firstyear) ) ;

FREE VARIABLES
  SUMPRICE                             'This is the objective function'
  ;  
                                                      
POSITIVE VARIABLES
  PRICE(hYr,y,t,lb)                    'Haywards price, $/MWh'
  PEAK_SLACK(y)                        'Slack on the peak constraint'
  ;
 
EQUATIONS
  ADEQUACY_PEAK(y)                     'Require overall revenue half-adequacy for new peaking plants in each MDS'
  ADEQUACY_MID(y)                      'Require overall revenue adequacy for new mid-order plants in each MDS'
  ADEQUACY_BASE(y)                     'Require overall revenue adequacy for new baseload, intermittent and process-driven plants in each MDS'
  ADEQUACY_ALL(y)                      'Require overall revenue adequacy for combined new plants in each MDS'
  THIS_OBJECTIVEFN                     'Minimize prices consistent with adequacy' 
  DECREASING_PRICE_CURVE_0n(hyr,y,t)   'Price in LB 0n should be higher than LB 1n'
  DECREASING_PRICE_CURVE_1n(hyr,y,t)   'Price in LB 1n should be higher than LB 2n'
  DECREASING_PRICE_CURVE_2n(hyr,y,t)   'Price in LB 2n should be higher than LB 3'
  DECREASING_PRICE_CURVE_0w(hyr,y,t)   'Price in LB 0w should be higher than LB 1w'
  DECREASING_PRICE_CURVE_1w(hyr,y,t)   'Price in LB 1w should be higher than LB 2w'
  DECREASING_PRICE_CURVE_2w(hyr,y,t)   'Price in LB 2w should be higher than LB 3'
  DECREASING_PRICE_CURVE_3(hyr,y,t)    'Price in LB 3 should be higher than LB 4'
  DECREASING_PRICE_CURVE_4(hyr,y,t)    'Price in LB 4 should be higher than LB 5'
  CAP_1w(hyr,y,t)                      'Max price in LB 1w'
  CAP_2n(hyr,y,t)                      'Max price in LB 2n'
  CAP_2w(hyr,y,t)                      'Max price in LB 2w'
  CAP_3(hyr,y,t)                       'Max price in LB 3'
  CAP_4(hyr,y,t)                       'Max price in LB 4'
  CAP_5(hyr,y,t)                       'Max price in LB 5'
  WIND_HIGHER_0(hyr,y,t)               'Mean price in LB 0n should be higher than 0w'
  WIND_HIGHER_1(hyr,y,t)               'Mean price in LB 1n should be higher than 1w'
  WIND_HIGHER_2(hyr,y,t)               'Mean price in LB 2n should be higher than 2w'
  ;

PARAMETERS
   PRICES(mds,hYr,y,t,lb)              'Collect results - Haywards price, $/MWh'
   PEAK_SLACKS(mds,y)                  'Collect results - peak slack'
   MEAN_PRICES(mds,y)                  'Mean Haywards price, $/MWh'
   MEAN_PRICES_BY_LB(mds,y,lb)         'Mean Haywards price by load block, $/MWh'
   THIS_FIXCOMYR(g)                    'Year in which plant is fixed to be built (if any)'
   ;

adequacy_peak(y)..
  SUM((hYr,g,t,lb,k)$(posbuild(g) * mapg_k(g,k) * require_adequacy_peak(k)),0.7 * PRICE(hYr,y,t,lb) * output(hYr,g,y,t,lb) * discount_factors(y) / 1000) + peak_slack(y) =e= 0.5 * (1.1 * SUM((hYr,g,k)$(posbuild(g) * mapg_k(g,k) * require_adequacy_peak(k)),cost_total_posttax(hYr,g,y) * discount_factors(y))) ;
* only half the costs of the peaking category need be recouped by selling energy
* the other half can be drawn from ancillary services (regulation, IR, transmission alternative, etc) or from exploiting regional price differences
* note this is now an equality constraint!

adequacy_mid(y)..
  SUM((hYr,g,t,lb,k)$(posbuild(g) * mapg_k(g,k) * require_adequacy_mid(k) * (not (sameas(hYr,'Multiple') or sameas(hYr,'Average')))),0.7 * PRICE(hYr,y,t,lb) * output(hYr,g,y,t,lb) * discount_factors(y) / 1000) =g= 1.1 * SUM((hYr,g,k)$(posbuild(g) * mapg_k(g,k) * require_adequacy_mid(k)),cost_total_posttax(hYr,g,y) * discount_factors(y)) ;

adequacy_base(y)..
  SUM((hYr,g,t,lb,k)$(posbuild(g) * mapg_k(g,k) * require_adequacy_base(k) * (not (sameas(hYr,'Multiple') or sameas(hYr,'Average')))),0.7 * PRICE(hYr,y,t,lb) * output(hYr,g,y,t,lb) * discount_factors(y) / 1000) =g= 1.1 * SUM((hYr,g,k)$(posbuild(g) * mapg_k(g,k) * require_adequacy_base(k)),cost_total_posttax(hYr,g,y) * discount_factors(y)) ;

adequacy_all(y)..
  SUM((hYr,g,t,lb)$(posbuild(g) * (not (sameas(hYr,'Multiple') or sameas(hYr,'Average')))),0.7 * PRICE(hYr,y,t,lb) * output(hYr,g,y,t,lb) * discount_factors(y) / 1000) =g= 1.1 * SUM((hYr,g)$(posbuild(g)),cost_total_posttax(hYr,g,y) * discount_factors(y)) ;

decreasing_price_curve_0n(hYr,y,t)..
  PRICE(hYr,y,t,'b0n') =g= 1.2 * PRICE(hYr,y,t,'b1n') ;

decreasing_price_curve_1n(hYr,y,t)..
  PRICE(hYr,y,t,'b1n') =g= 1.2 * PRICE(hYr,y,t,'b2n') ;
  
decreasing_price_curve_2n(hYr,y,t)..
  PRICE(hYr,y,t,'b2n') =g= 1.2 * PRICE(hYr,y,t,'b3') ;
  
decreasing_price_curve_0w(hYr,y,t)..
  PRICE(hYr,y,t,'b0w') =g= 1.2 * PRICE(hYr,y,t,'b1w') ;

decreasing_price_curve_1w(hYr,y,t)..
  PRICE(hYr,y,t,'b1w') =g= 1.2 * PRICE(hYr,y,t,'b2w') ;
  
decreasing_price_curve_2w(hYr,y,t)..
  PRICE(hYr,y,t,'b2w') =g= 1.2 * PRICE(hYr,y,t,'b3') ;
  
decreasing_price_curve_3(hYr,y,t)..
  PRICE(hYr,y,t,'b3') =g= 1.2 * PRICE(hYr,y,t,'b4') ;
  
decreasing_price_curve_4(hYr,y,t)..
  PRICE(hYr,y,t,'b4') =g= 1.2 * PRICE(hYr,y,t,'b5') ;

wind_higher_0(hyr,y,t)..
  PRICE(hYr,y,t,'b0n') =g= PRICE(hYr,y,t,'b0w') ;
  
wind_higher_1(hyr,y,t)..
  PRICE(hYr,y,t,'b1n') =g= PRICE(hYr,y,t,'b1w') ;
  
wind_higher_2(hyr,y,t)..
  PRICE(hYr,y,t,'b2n') =g= PRICE(hYr,y,t,'b2w') ;

cap_1w(hyr,y,t)..
  PRICE(hyr,y,t,'b1w') =l= 500;
  
cap_2n(hyr,y,t)..
  PRICE(hyr,y,t,'b2n') =l= 1000;
  
cap_2w(hyr,y,t)..
  PRICE(hyr,y,t,'b2w') =l= 250;
  
cap_3(hyr,y,t)..
  PRICE(hyr,y,t,'b3') =l= 180;
  
cap_4(hyr,y,t)..
  PRICE(hyr,y,t,'b4') =l= 120;
  
cap_5(hyr,y,t)..
  PRICE(hyr,y,t,'b5') =l= 80;
  
this_objectivefn..
  sumprice =e= 1e3*SUM(y,peak_slack(y)) + SUM((hYr,y,t,lb)$(not (sameas(hYr,'Multiple') or sameas(hYr,'Average'))),PRICE(hYr,y,t,lb) * discount_factors(y) * total_output(y,t,lb)) / (SUM((y,t,lb),total_output(y,t,lb)));
* minimise the discounted sum of all (price * volume) over the entire period
* kinda like the PV of all wholesale electricity sales costs...
* ADDED SLACK VARIABLE ON PEAK CONSTRAINT

MODEL get_adequate_prices /adequacy_all,adequacy_peak,adequacy_mid,adequacy_base,this_objectivefn,cap_1w,cap_2n,cap_2w,cap_3,cap_4,cap_5,decreasing_price_curve_0n,decreasing_price_curve_1n,decreasing_price_curve_2n,decreasing_price_curve_0w,decreasing_price_curve_1w,decreasing_price_curve_2w,decreasing_price_curve_3,decreasing_price_curve_4,wind_higher_0,wind_higher_1,wind_higher_2/;

PRICE.up(hYr,y,t,lb) = 5000 ;
PRICE.lo(hYr,y,t,lb) = 20 ;

LOOP((mds)$(sameas(mds,'mds1') or sameas(mds,'mds2') or sameas(mds,'mds3') or sameas(mds,'mds4') or sameas(mds,'mds5')),

  cost_total_posttax(hYr,g,y) = cost_total_posttax_m(mds,hYr,g,y) ;
  output(hYr,g,y,t,lb) = output_m(mds,hYr,g,y,t,lb) ;
  total_output(y,t,lb) = total_output_m(mds,y,t,lb);
  posbuild(g) = posbuildm(g,mds) ;
  this_fixcomyr(g) = fixcomyr(g,mds) ;

  SOLVE get_adequate_prices USING lp MINIMIZING sumprice ;

  mean_prices(mds,y) = SUM((hYr,t,lb)$(not(sameas(hYr,'Multiple') or sameas(hYr,'Average'))),PRICE.l(hYr,y,t,lb)*hrsperblk(t,lb)) / (numdisyrs(mds) * SUM((t,lb),hrsperblk(t,lb))) ;
  mean_prices_by_lb(mds,y,lb) = SUM((hYr,t)$(not(sameas(hYr,'Multiple') or sameas(hYr,'Average'))),PRICE.l(hYr,y,t,lb)*hrsperblk(t,lb)) / (numdisyrs(mds) * SUM((t),hrsperblk(t,lb))) ;

  prices(mds,hYr,y,t,lb) = PRICE.l(hYr,y,t,lb);
)

DISPLAY mean_prices ;       
DISPLAY mean_prices_by_lb ; 
* The above are averaged by time (not weighted by demand) 
