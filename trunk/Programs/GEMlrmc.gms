* GEMlrmc.gms


* Last modified by Dr Phil Bishop, 26/08/2011 (imm@ea.govt.nz)

* This program takes the GEM input data and computes the LRMC by plant.
* It gets $include'd into GEMdata.


* Declare required sets and parameters.
Sets
  z                      'A sequence of years'        / z1 * z100  /
  mc                     'Index for LRMC values'      / c1 * c2000 / ;

Parameters
  LRMC_offset            'A constant added to 1 to kick off the candidate LRMC series'   / 50 /
  small_LRMC             'Smallest LRMC'
  large_LRMC             'Largest LRMC'
  plantLifeYears(g)      'Plant life, years'
  depreciation(g,z)      'Depreciation in each year of plant life, $m'
  unDepCapital(g,z)      'Undepreciated capital in each year of plant life, $m'
  totalCosts(g,z)        'Total costs, $m'
  cndte_LRMC(mc)         'Candidate LRMCs, $/MWh'
  dcf(g,mc)              'Post-tax discounted cashflows by plant at each candidate LRMC level, $m'
  LRMC(g)                'LRMC of each plant, $/MWh'
  ;

* Convert plant life by technology to plant life by plant.
plantLifeYears(noExist(g)) = sum(mapg_k(g,k), i_plantLife(k)) ;

* Compute depreciation and undepreciated capital by sequential year. 
unDepCapital(noExist(g),z)$( (ord(z) = 1) * possibleToBuild(g) ) = 1e-6 * i_nameplate(g) * capexPlant(g) ;

loop((noExist(g),z)$( ( ord(z) > 1 ) and ( ord(z) <= plantLifeYears(g) ) ),
  depreciation(g,z)$possibleToBuild(g) = sum(mapg_k(g,k), i_depRate(k) * unDepCapital(g,z-1) ) ;
  unDepCapital(g,z)$possibleToBuild(g) = unDepCapital(g,z-1) - depreciation(g,z) ;
) ;

* Convert costs from modelled years (y) to sequential years (z), from $/MWh to $m, and collect into a parameter called totalCosts.
loop((noExist(g),z,y)$( ( ord(z) <= plantLifeYears(g) ) and ( ord(z) = ord(y) ) ),
  totalCosts(g,z)$possibleToBuild(g) = 1e-6 * ( 1e3 * assumedGWh(g) * sum(reportingOutcome(outcomes), SRMC(g,y,outcomes)) + i_nameplate(g) * i_fixedOM(g) ) ;
) ;

* Complete the series for sequential years up to the number of plant life years.
loop((noExist(g),z)$( ord(z) > 1  and ord(z) <= plantLifeYears(g) and sum(possibleToBuild(g), 1) ),
  totalCosts(g,z)$( possibleToBuild(g) and (not totalCosts(g,z)) ) = totalCosts(g,z-1) ; 
) ;

* Add depreciation expense to total costs.
totalCosts(g,z)$possibleToBuild(g) = totalCosts(g,z) + depreciation(g,z) ;

* Loop around the candidate LRMCs and declare the LRMC to be when the DCF goes positive.
counter = 0 ;  LRMC(g) = 0 ;
loop((noExist(g),mc)$( possibleToBuild(g) and LRMC(g) = 0 ),
  cndte_LRMC(mc) = ord(mc) + LRMC_offset ;
  dcf(g,mc)$assumedGWh(g) = -capexPlant(g) * i_nameplate(g) * 1e-6 + sum(z$( ord(z) <= plantLifeYears(g) ),
                             ( ( 1 - taxRate ) * ( 1e-3 * assumedGWh(g) * cndte_LRMC(mc) - totalCosts(g,z) ) + depreciation(g,z) ) /
                             ( ( 1 + WACCg) ** ( ord(z) ) )
                           ) ;
  if(dcf(g,mc) > 0 and counter = 0,
    counter = 1 ;
    LRMC(g) = cndte_LRMC(mc) ;
  ) ;
  counter = 0 ;
) ;

* Compute the smallest and largest LRMC and compare with LRMC_offset.
small_LRMC = smin((g)$LRMC(g), LRMC(g)) ;
large_LRMC = smax((g), LRMC(g)) ;

* Dump LRMCs into a csv file.
put lrmc_inData 'LRMCs for plant in the GEM picklist that is able to be built - LRMC based on input data, not a GEM solution.' /
  "Note that calculations assume plant is built today and the input cost/price series' develop according to GEM assumptions." /
  'LRMC offset:', (1 + LRMC_offset):3:0 /
  'Lowest LRMC:', small_LRMC:3:0 /
  'NB: Re-run with a lower LRMC offset if LRMC offset equals lowest LRMC' //
  'Plant', 'Technology', 'Island', 'MW', 'CapFactor', 'GWh', 'LRMC, $/MWh' ;
loop((k,noExist(g),ild)$( mapg_k(g,k) * sum(possibleToBuild(g), 1) * mapg_ild(g,ild) ),
  put / g.tl, k.tl, ild.tl, i_nameplate(g), i_capFacTech(k), assumedGWh(g), LRMC(g) ;
) ;

*Display assumedGWh, plantLifeYears, depreciation, unDepCapital, totalCosts, cndte_LRMC, dcf, LRMC, large_LRMC, small_LRMC, LRMC_offset ;



* End of file.
