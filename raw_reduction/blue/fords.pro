pro fords,im,swid,orc,ome,minreq=minreq
;Maps out and fits polynomials to order positions.  Returns both polynomial
;  coefficients and mean difference between polynomial and actual locations.
; im (input array (# columns , # rows)) image on which order locations are to
;   be mapped.
; swid (input scalar) swath width, the number of columns desired in each swath. 
; orc (output array (# coeff per fit , # orders) OR scalar) either an array
;   containing the coefficients of the polynomials giving the row number as a
;   function of column number for each order OR a scalar equal to zero 
;   indicating a consistent set of orders locations could not be found.
;   ALWAYS CHECK TO SEE IF THE orc RETURNED IS A SCALAR, INDICATING TROUBLE!
; [ome (optional output vector (# orders))] each entry gives the mean of the
;   absolute value of the difference between order locations and the polynomial
;   fit to these locations.
; [minreq (optional input scalar keyword)] the minimum number of orders that
;   must be found in order for a successful order location.
;Calls FNDPKS, FALSPK
;18-Apr-92 JAV	Removed common block definition.
;30-Apr-92 JAV	Added resampling logic.
;05-Sep-92 JAV	Added minreq logic.
;12-Sep-92 JAV	Added test for parabolic order peak off image.
;28-Sep-92 JAV	Try median of past three peaks (mdpk) when new peak is not in
;		 poff window in case most recent peak was only marginally good.
;29-Sep-92 JAV	Inserted logic to set poff to 2 pixels for binned images.
;12-Dec-92 JAV	Discard orders whose bounding troughs are within poff of edge.
;21-Jan-93 JAV	Only discard orders whose bounding troughs are off edge.
;28-Jan-94 JAV  Improve accuracy in order location fits by first subtracting
;		 the mean row number in each order.

@ham.common				;get common block definition

if n_params() lt 3 then begin
   print,'syntax: fords,im,swid,orc[,ome].'
   retall
endif
if n_elements(minreq) eq 0 then minreq = 0	;any number of orders will do
;
ham_trace=25
  trace,25,'FORDS: Entering routine.'
;
;Define adjustable parameters. When choosing the degree of the polynomial
;  (orcdeg) to fit to the order locations, keep in mind that while increasing
;  orcdeg initially decreases the fit residuals (ome), eventually loss of
;  precision begins increasing the errors again. If you decide to increase
;  orcdeg, check the "ome" return argument to MAKE SURE THAT THE RESIDUALS
;  ACTUALLY DECREASE.
  smbox = 5				;initial swath smoothing window size
  poff = 3				;offset to edge of peak poly fit window
  if ham_bin ge 2 then poff = 2		;use smaller window for binned images
  orcdeg = 4				;degree of poly for order location fits
  mmfrac = 0.25				;maximum fraction missing peaks allowed
  maxome = 0.50				;max allowable mean pixel error in orcs
  trace,20,'FORDS: Degree of polynomial fit to order locations = ' $
    + strtrim(string(orcdeg),2)
;
;Define useful quantities.
  sz = size(im)				;variable info block
  ncol = sz[1]				;number of cols in image
  nrow = sz[2]				;number of rows in image
  soff = (swid - 1) / 2.0		;offset to edge of swath window
  nswa = long(ncol/swid)		;# of full swaths in image
  trace,15,'FORDS: Number of swaths = ' + strtrim(string(nswa),2)
  trace,15,'FORDS: Number of cols,rows = ' + $
                   strtrim(string(ncol),2) + '  ' + strtrim(string(nrow),2)
;
;Determine centers of swaths to mash. If swaths fit perfectly, then distribute
;  them uniformly. If extra columns remain, then add a full sized swath in 
;  center of image. Some central columns will be oversampled, but this is
;  preferable to reducing swath size, which makes order location harder.
;
;  if ncol mod swid eq 0 then begin		;Do swaths fit perfectly?
;    scen = swid * findgen(nswa) + soff		; yes - find swath centers
;  endif else begin				; no - need one more swath
;    nswa = nswa + 1				;increment swath count
;    csid = swid * findgen(nswa/2) + soff	;low side swath centers
;    if nswa mod 2 eq 0 then begin		;Even number of swaths?
;      scen = [csid,reverse(ncol-1-csid)]	; yes - reflect about im center 
;    endif else begin				; no - add swath in middle
;      cmid = long((ncol-1)/2.0 - soff) + soff	;center or just left
;      scen = [csid,cmid,reverse(ncol-1-csid)]	;reflect sides and add middle
;    endelse
;  endelse
;
;Forget the last (right) swath - find those that fit in ncol:
   scen = swid * findgen(nswa) + soff
;Determine positions of order peaks and verify their validity.
  trace,20,'FORDS: Estimating positions of order peaks in first swath.'
  aswa = fltarr(nrow,nswa)			;array for all swaths
; First fill the array with all swaths (faster to do all at once)
;  FOR irow=0,nrow-1 do begin
;    row=im(*,irow)				;get row from image
;    for isw=0,nswa-1 do begin			;loop thru swaths
;      aswa(irow,isw)=total(row(scen(isw)-soff:scen(isw)+soff)) ;extract swaths
;    endfor
;  ENDFOR
    for isw=0,nswa-1 do begin			;loop thru swaths
      aswa[*,isw]=total(im[scen[isw]-soff:scen[isw]+soff,*],1) ;extract swaths
    endfor
;
  swa = aswa[*,0]				;sum columns in first swath
  swa = smooth(median(swa,smbox-1),smbox)	 ;smooth swath to reduce noise
  fndpks,swa,pk					;get order peaks
  if not keyword_set(pk) then begin        	;check for error in FNDPKS
    orc = 0					;scalar orc sets error flag
    trace,15,'FORDS: Invalid order peaks in swath - returning without ORCs.'
    return					;return without ORCs
  endif

if ham_id ne 29 then pk = pk[where(pk gt 42)]
if ham_id eq 29 then pk = pk[where(pk gt 15)]
;if pk(0) gt 62 then begin               ;1st order position is probably off.
;  print,''
;  print,'*** WARNING: POSSIBLE ERROR IN LOCATION OF FIRST ORDER. ***
;  print,'            Check observation manually.'
;end


  nord = n_elements(pk)				;number of orders
  trace,20,'FORDS: Number of peaks found = ' + strtrim(string(nord),2)
  if nord lt minreq then begin			;true: too few orders found
    orc = 0					;scalar orc flags error
    trace,15,'FORDS: Too few orders found in initial swath' $
      + ' - returning without ORCs.'
    return
  endif
    
  ords = fltarr(nswa,nord)		;peak locations for swaths

;Loop through the swaths, determining exact positions of peaks by fitting
;  quadratic polynomials in vicinity of previous peaks. Store new peaks, as
;  long as they are reasonably close to previous peak positions. Postions
;  with poor peak determinations are left zero.
  trace,20,'FORDS: Mapping entire image.  Be patient....'
  pk = long(pk+0.5)				;make sure pk is integral
;Remove next if block, if no bug report by Dec-92.
  if pk[0] eq pk[1] then begin			;fix strange new error
    message,/info,'The "strange new error" has occured - inform Jeff Valenti.'
    pk=pk[1:nord-1]
    nord=nord-1
  endif

;Find the peaks in each swath.
  xfine = findgen(20*poff+1)/10 - poff		;abscissa for fine resmapling
  ix = findgen(2*poff+1)			;indicies for maxima fit below
  FOR isw=0,nswa-1 do begin			;loop thru swaths
    swa = aswa[*,isw]				;recover swath
    swa = smooth(median(swa,smbox-1),smbox)	 ;smooth swath to reduce noise
  for ior=0,nord-1 do begin			;loop thru orders
      opk = pk[ior]				;old peak location
      if opk lt poff or opk gt nrow-poff-1 then begin
	pk[ior] = 0				;flag peak off edge
        goto,edge				;peak too near edge,next order
      endif
      z = swa[opk-poff:opk+poff]		;region where peak is expected
      dummy = max(z,mx)				;get location of maximum
      mx = opk - poff + mx[0]			;local max pixel OR edge
      if mx lt poff or mx gt nrow-poff-1 then begin
	pk[ior] = 0				;flag peak off edge
	goto,edge 				;max too near edge,next order
      endif
      z = swa[mx-poff:mx+poff]			;region around max pixel
      cf = poly_fit(ix,z,2)			;coeff of quadratic fit
      peak = -cf[1] / (2*cf[2]) + mx - poff	;extremum of polynomial
      if peak lt poff or peak gt nrow-poff-1 then begin
	pk[ior] = 0
	goto,edge
      endif

;Resampling code: We've just fit a polynomial to the peak pixel and "poff"
;  pixels on either side. When the true peak is near the edge of a pixel, we
;  are oversampling one side of the peak (by nearly a pixel). As the true peak
;  passes into the next row's pixel (due to the curvature of the orders), the
;  extra pixel being oversampled jumps to the *other* side. If the order
;  shapes were really parabolas, this would have no effect, but they're not.
;  The peaks of the parabolic fits jump, when the true peak crosses a pixel
;  boundary. We correct for this below by splining the pixels around the peak
;  onto a much finer scale and then fitting another parabola to the splined
;  points within a well-defined window.
      locut = (long(peak - poff)) > 0		;low index of region to cut
      hicut = (long(peak + poff + 0.999)) < (nrow-1)  ;high index of cut region
      zcut = swa[locut:hicut]			;cut region to finely sample
      xcut = findgen(hicut - locut + 1) $	;indicies for cut region
	+ (locut - peak)			;  (0 is at true peak)
;      zfine = fspline(xcut,zcut,xfine)		;finely sample peak region
  zfine = spl_interp(xcut,zcut,spl_init(xcut,zcut),xfine,/double) ;IDL internal
      cf = poly_fit(xfine,zfine,2)		;fit poly to fine sampling
      peak = -cf[1] / (2*cf[2]) + peak		;peak at extremum of parabola
;End Resampling code.

      if peak ge opk-poff and $
	 peak le opk+poff then begin 		;only keep peaks near pixel max
	ords[isw,ior] = peak			;valid peak, save in array
	pk[ior] = long(peak+0.5)		;search near peak in next swath
      endif else begin				;else: maybe last peak off
	if isw ge 3 then begin			;true: can do median
	  mdpk = median(ords[isw-3:isw-1,ior])	;median of last three peaks
	  if peak ge mdpk-poff and $
	     peak le mdpk+poff then begin 	;only keep peaks near pixel max
	    ords[isw,ior] = peak		;valid peak, save in array
	    pk[ior] = long(peak+0.5)		;search near peak in next swath
	  endif
	endif
      endelse
      edge:    					;jump here to skip a swath
    endfor		;end order loop
  ENDFOR		;end swath loop

;Loop through orders, fitting polynomials to order locations determined above.
;  If too large a fraction of the peaks are missing in an order not on the
;  edge, then return with orc set to scalar zero, flagging error condition.
;  Also compute the mean error in the polynomial fit. If this is too large,
;  then return with orc set to scalar zero, flagging error condition.
  trace,20,'FORDS: Fitting polynomials to order peaks.'
  orc = fltarr(orcdeg+1,nord)			;init order coefficient array
  ome = orc[0,*]				;init order mean error
  tomiss = 0					;init total missing peak count
  FOR ior = 0,nord-1 do begin
;stop
    iwhr = where(ords[*,ior] gt 0,nwhr)		;find valid peaks
    x = scen[iwhr]				;get swath centers with peaks
    y = ords[iwhr,ior]				;get nonzero peaks
    nmiss = nswa - nwhr				;number of missing peaks
;   print,'Order:',ior,'  # misses:',nmiss
    if float(nmiss)/nswa gt mmfrac then begin	;sufficient peaks to fit?
      if ior le 4 or ior ge nord-4 then $       ;test
	goto,jump1				;ignore problems near edges
      orc = 0					;scalar zero flags error
      fstr = strtrim(string(form='(f10.1)',(100.0*nmiss)/nswa),2)
      trace,15,'FORDS: ' + fstr + '% of peaks in order missing.'
      trace,15,'FORDS: Too many missing peaks - returning without orcs.'
      return
    endif
    tomiss = tomiss + nmiss			;increment total missing peaks
    mny = total(y) / nwhr			;mean row number
    y = y - mny					;better precision w/ mean=0
    ind = indgen(nwhr-2) + 1                    ;indices excluding ends (gm)
    xp = x[ind]
    yp = y[ind]
    orc[*,ior] = poly_fit(xp,yp,orcdeg,fit)       ;fit polynomial to peaks
    ome[ior] = stdev(yp - fit)
    if ome[ior] gt maxome then begin		;orc mean error too large?
      trace,15,'FORDS: Excessive scatter in peaks - returning without orcs.'
      orc = 0					;scalar zero flags error
      return
    endif
    orc[0,ior] = orc[0,ior] + mny		;renormalize
    jump1:					;jump here if skipping an order
  ENDFOR


;Trim first four and last four order coefficients, if they are still zero.
;  FOR j=0,3 do begin
;  if total(orc(*,nord-1)) eq 0 then begin	;too few peaks in last order
;    orc = orc(*,0:nord-2)			;remove last order
;    ome = ome(0:nord-2)				;remove last error point
;    nord = nord - 1				;decrement order count
;   trace,15,'FORDS: Trimming last order - too few peaks.'
; endif
; if total(orc(*,0)) eq 0 then begin		;too few peaks in first order
;   orc = orc(*,1:nord-1)			;remove first order
;   ome = ome(1:nord-1)				;remove first error point
;   nord = nord - 1				;decrement peak count
;   trace,15,'FORDS: Trimming first order - too few peaks.'
; endif
;		  END

;comment out following for hires mosaic
;Trim first and last order coefficients until nonzero.
; WHILE total(orc[*,nord-1]) eq 0 do begin      ;too few peaks in last order
;   orc = orc[*,0:nord-2]                        ;remove last order
;   ome = ome[0:nord-2]                          ;remove last error point
;   nord = nord - 1                              ;decrement order count

;  trace,15,'FORDS: Trimming last order - too few peaks.'
; ENDWHILE

;Comment out following chunk of code for hires mosaic
; WHILE total(orc[*,0]) eq 0 do begin ;too few peaks in first order
;   orc = orc[*,1:nord-1]                       ;remove first order
;   ome = ome[1:nord-1]                         ;remove first error point
;   nord = nord - 1                             ;decrement peak count
;   trace,15,'FORDS: Trimming first order - too few peaks.'
; ENDWHILE

;Discard first or last order, if they extend beyond edge of image.
; x = findgen(ncol)				;column indicies
;yy = poly(x,orc[*,nord-2])
; y = poly(x,orc[*,nord-1])			;center of last order
; if max(y) gt nrow-poff-1 then begin		;order extends beyond image
; if max(y+0.5*(y-yy)) gt nrow-poff-1 then begin;order extends beyond image
; if max(y+0.5*(y-yy)) gt nrow-1 then begin	;order extends beyond image
;   orc = orc[*,0:nord-2]			;remove last order
;   ome = ome[0:nord-2]				;remove last error point
;   nord = nord - 1				;decrement order count
;   trace,15,'FORDS: Trimming last order - off edge of image.'
; end
;y = poly(x,orc[*,1])				;edge of first order
; y = poly(x,orc[*,0])				;edge of first order
; if min(y) lt poff then begin			;order extends beyond image
; if min(y-0.5*(yy-y)) lt poff then begin	;order extends beyond image
; if min(y-0.5*(yy-y)) lt 0 then begin		;order extends beyond image
;   orc = orc[*,1:nord-1]			;remove first order
;   ome = ome[1:nord-1]				;remove first error point
;   nord = nord - 1				;decrement order count
;   trace,15,'FORDS: Trimming first order - off edge of image.'
; endif

;Order coefficients determined.
  trace,10,'FORDS: Total missing peaks = ' + strtrim(string(tomiss),2)
  trace,10,'FORDS: Orders found = ' + strtrim(string(nord),2)
  if nord lt minreq then begin			;true: too few orders found
    orc = 0					;scalar orc flags error
    trace,15,'FORDS: Too few orders found in initial swath' $
      + ' - returning without ORCs.'
    return
  endif
  return
end
