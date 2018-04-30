pro shiftorc,im,dorc,orc,plot=plot
;  Search for order locations in a raw echelle image by vertically SHIFTING 
;  the default order locations. If the order locations are valid they are returned.
;
;  INPUTS:
;     im (input array (ncol, nrow)) image in which orders are to be
;        located.
;     dorc (input array (# coeff , # orders)) coefficients (from PIT) of polynomial 
;          fit to default locations of orders.
;  OUTPUTS:
;     orc  (output array (# coeff , # orders) OR scalar) If array, then contains
;          coefficients (from PIT) of polynomial fit to locations of orders in image.
;          If scalar, then valid order locations were not found. ALWAYS CHECK WHETHER
;   RETURNED ORC IS A SCALAR, INDICATING THAT ORDER LOCATIONS WERE NOT FOUND.
;28-Feb-95 GWM	Create

@ham.common					;get common block definition


if n_params() lt 3 then begin
  print,'syntax: shiftorc,im,dorc,orc'
  retall
end
;
  trace,25,'GETORC: Entering routine.'
  if ham_dord ne 2 then begin		;2 ==> always use shifted defaults
    trace,5,'SHIFTORC: Entered, despite ham_dord Keyword not set to 2!?! - returning to caller.'
    return					;return without orcs
  end
;
;Define useful quantities.
  range = 8                       ;vertical search range in rows (+-)
 ;	range = 10 ;hti 20jan2010		; more than 8 is outside the wideflat range.
  if ham_bin eq 2 then range = 4

  shft = findgen(range*2 + 1)-(range ) ; i
  nord = n_elements(dorc[0,*])    ;# full orders in orc
  arccts = fltarr(2*range + 1, nord)       ;Total Arc Counts: Shift orders +-5 rows.
  swid = 20					;# of columns in vertical swath
  orc = dorc					;scalar orc flags error
  ncol = n_elements(im[*,0])                            ;# columns in image
  nrow = n_elements(im[0,*])                            ;# rows in image
  ncoef = n_elements(dorc[*,0])                         ;# polyn. coeffs
  ix = findgen(ncol)              ;column indicies
  hipt =  fltarr(nord)
;

;Find order locations, if possible. Otherwise use defaults.
;Assume orders locations are within 2 rows of the default locations.
;
 FOR onum = 0,nord-1 do begin                ;loop thru orders    
   ;determine median of counts along order (+0.5row: round to nearest pixel)
   defy = fix(poly(ix,dorc[*,onum])+0.5)     ;default order location (y)
   FOR i = 0,2*range do begin    ;Loop thru row shifts
     arccts[i, onum] = median( im[ix,defy + shft[i]] ) ;median arc
   END
   hipt[onum] = max(arccts[*, onum],indmax)  ;indmax is shift at high pt of Cts vs Shift
   if abs(shft[indmax]) ge range-1 then begin

  print,'SHIFTORC: Apparent shift is',shft[indmax],' --- outside range,',range
  print,'Aborting' & return
   end
 
;Find optimal vertical shift in default orders to maximize cts
;   sarccts=smooth(arccts,5)  ;smooth to ensure a peak

   ind = [indmax-2,indmax-1, indmax, indmax+1,indmax+2]         ;indicies near peak
   coef = poly_fit(shft[ind],arccts[ind, onum],2)   ;coef's of fit to peak
   bestshft = -0.5*coef[1]/coef[2]     ;peak of parabola    
;
    if abs(bestshft) lt range+1 then begin  ;shift is a reasonable amount   
      orc[0,onum] = dorc[0,onum] + bestshft    ;add needed shift in rows to zeroth coef.
      print,'% SHIFTORC: Shifted Default Orders by:',bestshft,' rows.'
    end else begin                       ;shift too large to believe
      trace,5,'SHIFTORC: Unable to find order locations.' & return
    endelse
    end
;PLOTTING
 END
    IF keyword_set(plot) then FOR onum = 0,nord-1 do oplot,ix,poly(ix,orc[*,onum])
    IF keyword_set(plot) then plot, orc[0, *]-dorc[0, *]
    IF keyword_set(plot) then junk=get_kbrd(1)
;  trace,25,'SHIFTORC: Returning to caller.'

  return
end
