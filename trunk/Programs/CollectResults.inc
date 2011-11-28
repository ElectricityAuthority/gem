*+++++++++++++++++++++++++
* More non-free reserves code.
* Positive Variables
  s_RESVCOMPONENTS(steps,scenSet,r,rr,y,t,lb,sc,stp)    = RESVCOMPONENTS.l(r,rr,y,t,lb,sc,stp) ;
* Equations
  s_calc_nfreserves(steps,scenSet,r,rr,y,t,lb,sc)       = calc_nfreserves.m(r,rr,y,t,lb,sc) ;
  s_resv_capacity(steps,scenSet,r,rr,y,t,lb,sc,stp)     = resv_capacity.m(r,rr,y,t,lb,sc,stp) ;
*+++++++++++++++++++++++++
* Free Variables
  s_TOTALCOST(steps,scenSet)                            = TOTALCOST.l ;
  s_SCENARIO_COSTS(steps,scenSet,sc)                    = SCENARIO_COSTS.l(sc) ;
  if(DCloadFlowOn,
    s_TX(steps,scenSet,r,rr,y,t,lb,sc)$( TX.l(r,rr,y,t,lb,sc) > 0 ) = TX.l(r,rr,y,t,lb,sc) ;
    else
    s_TX(steps,scenSet,r,rr,y,t,lb,sc)                  = TX.l(r,rr,y,t,lb,sc) ;
  ) ;
  s_THETA(steps,scenSet,r,y,t,lb,sc)                    = THETA.l(r,y,t,lb,sc) ;
* Binary Variables
  s_BRET(steps,scenSet,g,y)                             = BRET.l(g,y) ;
  s_ISRETIRED(steps,scenSet,g)                          = ISRETIRED.l(g) ;
  s_BTX(steps,scenSet,r,rr,ps,y)                        = BTX.l(r,rr,ps,y) ;
  s_NORESVTRFR(steps,scenSet,ild,ild1,y,t,lb,sc)        = NORESVTRFR.l(ild,ild1,y,t,lb,sc) ;
* Positive Variables
  s_REFURBCOST(steps,scenSet,g,y)                       = REFURBCOST.l(g,y) ;
  s_BUILD(steps,scenSet,g,y)                            = BUILD.l(g,y) ;
  s_RETIRE(steps,scenSet,g,y)                           = RETIRE.l(g,y) ;
  s_CAPACITY(steps,scenSet,g,y)                         = CAPACITY.l(g,y) ;
  s_TXCAPCHARGES(steps,scenSet,paths,y)                 = TXCAPCHARGES.l(paths,y) ;
  s_GEN(steps,scenSet,g,y,t,lb,sc)                      = GEN.l(g,y,t,lb,sc) ;
  s_VOLLGEN(steps,scenSet,s,y,t,lb,sc)                  = VOLLGEN.l(s,y,t,lb,sc) ;
  s_PUMPEDGEN(steps,scenSet,g,y,t,lb,sc)                = PUMPEDGEN.l(g,y,t,lb,sc) ;
  s_LOSS(steps,scenSet,r,rr,y,t,lb,sc)                  = LOSS.l(r,rr,y,t,lb,sc) ;
  s_TXPROJVAR(steps,scenSet,tupg,y)                     = TXPROJVAR.l(tupg,y) ;
  s_TXUPGRADE(steps,scenSet,r,rr,ps,pss,y)              = TXUPGRADE.l(r,rr,ps,pss,y) ;
* Reserve variables
  s_RESV(steps,scenSet,g,rc,y,t,lb,sc)                  = RESV.l(g,rc,y,t,lb,sc) ;
  s_RESVVIOL(steps,scenSet,rc,ild,y,t,lb,sc)            = RESVVIOL.l(RC,ILD,y,t,lb,sc) ;
  s_RESVTRFR(steps,scenSet,rc,ild,ild1,y,t,lb,sc)       = RESVTRFR.l(rc,ild1,ild,y,t,lb,sc) ;
  s_RESVREQINT(steps,scenSet,rc,ild,y,t,lb,sc)          = RESVREQINT.l(rc,ild,y,t,lb,sc) ;
* Penalty variables
  s_RENNRGPENALTY(steps,scenSet,y)                      = RENNRGPENALTY.l(y) ;
  s_PEAK_NZ_PENALTY(steps,scenSet,y,sc)                 = PEAK_NZ_PENALTY.l(y,sc) ;
  s_PEAK_NI_PENALTY(steps,scenSet,y,sc)                 = PEAK_NI_PENALTY.l(y,sc) ;
  s_NOWINDPEAK_NI_PENALTY(steps,scenSet,y,sc)           = NOWINDPEAK_NI_PENALTY.l(y,sc) ;
* Slack variables
  s_ANNMWSLACK(steps,scenSet,y)                         = ANNMWSLACK.l(y) ;
  s_RENCAPSLACK(steps,scenSet,y)                        = RENCAPSLACK.l(y) ;
  s_HYDROSLACK(steps,scenSet,y)                         = HYDROSLACK.l(y) ;
  s_MINUTILSLACK(steps,scenSet,y)                       = MINUTILSLACK.l(y) ;
  s_FUELSLACK(steps,scenSet,y)                          = FUELSLACK.l(y) ;
* Equations, i.e. marginal values. (ignore the objective function)
  s_calc_scenarioCosts(steps,scenSet,sc)                = calc_scenarioCosts.m(sc) ;
  s_calc_refurbcost(steps,scenSet,g,y)                  = calc_refurbcost.m(g,y) ;
  s_calc_txcapcharges(steps,scenSet,paths,y)            = calc_txcapcharges.m(paths,y) ;
  s_balance_capacity(steps,scenSet,g,y)                 = balance_capacity.m(g,y) ;
  s_bal_supdem(steps,scenSet,r,y,t,lb,sc)               = bal_supdem.m(r,y,t,lb,sc) ;
  s_peak_nz(steps,scenSet,y,sc)                         = peak_NZ.m(y,sc) ;
  s_peak_ni(steps,scenSet,y,sc)                         = peak_NI.m(y,sc) ;
  s_noWindPeak_ni(steps,scenSet,y,sc)                   = noWindPeak_NI.m(y,sc) ;
  s_limit_maxgen(steps,scenSet,g,y,t,lb,sc)             = limit_maxgen.m(g,y,t,lb,sc) ;
  s_limit_mingen(steps,scenSet,g,y,t,lb,sc)             = limit_mingen.m(g,y,t,lb,sc) ;
  s_minutil(steps,scenSet,g,y,sc)                       = minutil.m(g,y,sc) ;
  s_limit_inflexPlant(steps,scenSet,g,y,t,lb,lbb,sc)    = limit_inflexPlant.m(g,y,t,lb,lbb,sc) ;
  s_limit_fueluse(steps,scenSet,f,y,sc)                 = limit_fueluse.m(f,y,sc) ;
  s_limit_nrg(steps,scenSet,f,y,sc)                     = limit_nrg.m(f,y,sc) ;
  s_minreq_rennrg(steps,scenSet,y,sc)                   = minReq_renNrg.m(y,sc) ;
  s_minreq_rencap(steps,scenSet,y)                      = minReq_renCap.m(y) ;
  s_limit_hydro(steps,scenSet,g,y,t,sc)                 = limit_hydro.m(g,y,t,sc) ;
  s_limit_pumpgen1(steps,scenSet,g,y,t,sc)              = limit_pumpgen1.m(g,y,t,sc) ;
  s_limit_pumpgen2(steps,scenSet,g,y,t,sc)              = limit_pumpgen2.m(g,y,t,sc) ;
  s_limit_pumpgen3(steps,scenSet,g,y,t,lb,sc)           = limit_pumpgen3.m(g,y,t,lb,sc) ;
  s_calcTxLossesMIP(steps,scenSet,r,rr,ps,y,t,lb,n,sc)  = calcTxLossesMIP.m(r,rr,ps,y,t,lb,n,sc) ;
  s_calcTxLossesRMIP(steps,scenSet,r,rr,y,t,lb,n,sc)    = calcTxLossesRMIP.m(r,rr,y,t,lb,n,sc) ;
  s_tx_capacity(steps,scenSet,r,rr,y,t,lb,sc)           = tx_capacity.m(r,rr,y,t,lb,sc) ;
  s_tx_projectdef(steps,scenSet,tupg,r,rr,ps,pss,y)     = tx_projectdef.m(tupg,r,rr,ps,pss,y) ;
  s_tx_onestate(steps,scenSet,r,rr,y)                   = tx_onestate.m(r,rr,y) ;
  s_tx_upgrade(steps,scenSet,r,rr,ps,y)                 = tx_upgrade.m(r,rr,ps,y) ;
  s_tx_oneupgrade(steps,scenSet,r,rr,y)                 = tx_oneupgrade.m(r,rr,y) ;
  s_tx_dcflow(steps,scenSet,r,rr,y,t,lb,sc)             = tx_dcflow.m(r,rr,y,t,lb,sc) ;
  s_tx_dcflow0(steps,scenSet,r,rr,y,t,lb,sc)            = tx_dcflow0.m(r,rr,y,t,lb,sc) ;
  s_equatetxloss(steps,scenSet,r,rr,y,t,lb,sc)          = equatetxloss.m(r,rr,y,t,lb,sc) ;
  s_txGrpConstraint(steps,scenSet,tgc,y,t,lb,sc)        = txGrpConstraint.m(tgc,y,t,lb,sc) ;
  s_resvsinglereq1(steps,scenSet,rc,ild,y,t,lb,sc)      = resvsinglereq1.m(rc,ild,y,t,lb,sc) ;
  s_genmaxresv1(steps,scenSet,g,y,t,lb,sc)              = genmaxresv1.m(g,y,t,lb,sc) ;
  s_resvtrfr1(steps,scenSet,ild,ild1,y,t,lb,sc)         = resvtrfr1.m(ild,ild1,y,t,lb,sc) ;
  s_resvtrfr2(steps,scenSet,rc,ild,ild1,y,t,lb,sc)      = resvtrfr2.m(rc,ild,ild1,y,t,lb,sc) ;
  s_resvtrfr3(steps,scenSet,rc,ild,ild1,y,t,lb,sc)      = resvtrfr3.m(rc,ild,ild1,y,t,lb,sc) ;
  s_resvrequnit(steps,scenSet,g,rc,ild,y,t,lb,sc)       = resvrequnit.m(g,rc,ild,y,t,lb,sc) ;
  s_resvreq2(steps,scenSet,rc,ild,y,t,lb,sc)            = resvreq2.m(rc,ild,y,t,lb,sc) ;
  s_resvreqhvdc(steps,scenSet,rc,ild,y,t,lb,sc)         = resvreqhvdc.m(rc,ild,y,t,lb,sc) ;
  s_resvtrfr4(steps,scenSet,ild1,ild,y,t,lb,sc)         = resvtrfr4.m(ild1,ild,y,t,lb,sc) ;
  s_resvtrfrdef(steps,scenSet,ild,ild1,y,t,lb,sc)       = resvtrfrdef.m(ild,ild1,y,t,lb,sc) ;
  s_resvoffcap(steps,scenSet,g,y,t,lb,sc)               = resvoffcap.m(g,y,t,lb,sc) ;
  s_resvreqwind(steps,scenSet,rc,ild,y,t,lb,sc)         = resvreqwind.m(rc,ild,y,t,lb,sc) ;
* Now write the statements that are contingent on the model type being solved.
* NB: these statements will not be executed when included in GEMsolve if RunType = 2.
$if %RunType%==2 $goto skip
* Variables
  s_BGEN(steps,scenSet,g,y)                             = BGEN.l(g,y) ;
  s_GENBLDCONT(steps,scenSet,g,y)                       = GENBLDCONT.l(g,y) ;
  s_CGEN(steps,scenSet,g,y)                             = CGEN.l(g,y) ;
* Equations
  s_bldgenonce(steps,scenSet,g)                         = bldGenOnce.m(g) ;
  s_buildcapint(steps,scenSet,g,y)                      = buildCapInt.m(g,y) ;
  s_buildcapcont(steps,scenSet,g,y)                     = buildCapCont.m(g,y) ;
  s_annNewMWcap(steps,scenSet,y)                        = annNewMWcap.m(y) ;
  s_endogpltretire(steps,scenSet,g,y)                   = endogpltretire.m(g,y) ;
  s_endogretonce(steps,scenSet,g)                       = endogretonce.m(g) ;
$label skip
