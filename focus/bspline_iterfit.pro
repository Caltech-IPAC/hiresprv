;+
; NAME:
;   bspline_iterfit
;
; PURPOSE:
;   Calculate a B-spline in the least squares sense with rejection
;
; CALLING SEQUENCE:
;   sset = bspline_iterfit( )
;
; INPUTS:
;   xdata      - Data x values
;   ydata      - Data y values
;
; OPTIONAL KEYWORDS:
;   invvar     - Inverse variance of y; if not set, then set to be
;                consistent with the standard deviation.  This only matters
;                if rejection is being done.
;   nord       - Order for spline fit; default to 4.
;   x2         - 2nd dependent variable for 2-D spline fitting.
;   npoly      - Polynomial order to fit over 2nd variable (X2); default to 2.
;   xmin       - Normalization minimum for X2; default to MIN(XDATA).
;   xmax       - Normalization maximum for X2; default to MAX(XDATA).
;   oldset     - If set, then use values of FULLBKPT, NORD, XMIN, XMAX, NPOLY
;                from this structure.
;   maxiter    - Maximum number of rejection iterations; default to 10;
;                set to 0 to disable rejection.
;   upper      - Upper rejection threshhold; default to 5 sigma.
;   lower      - Lower rejection threshhold; default to 5 sigma.
;   _EXTRA     - Keywords for BSPLINE_BKPTS() and/or DJS_REJECT().
;
; OUTPUTS:
;   sset       - Structure describing spline fit.
;
; OPTIONAL OUTPUTS:
;   outmask    - Output mask, set =1 for good points, =0 for bad points.
;
; COMMENTS:
;   Data points can be masked either by setting their weights to zero
;   (INVVAR[]=0), or by using INMASK and setting bad elements to zero.
;   INMASK is passed to DJS_REJECT().
;
;   If OLDSET is used, then the output structure SSET will be a structure
;   with the same name as OLDSET.  This will allow the two structures to
;   be concatented, i.e.
;     > junk = [oldset, sset]
;
;   Although I'm not sure how to treat data points which fall outside
;   minmax(bkpt), now I will set them equal to minmax with invvar = 0
;
; EXAMPLES:
;
; PROCEDURES CALLED:
;   bspline_bkpts()
;   bspline_fit()
;   djs_reject()
;
; REVISION HISTORY:
;   05-Sep-2000  Written by D. Schlegel & S. Burles
;-
;------------------------------------------------------------------------------
function bspline_iterfit, xdata, ydata, invvar=invvar, nord=nord, $
 x2=x2, npoly=npoly, xmin=xmin, xmax=xmax, yfit=yfit, mask=mask, $
 bkpt=bkpt, oldset=oldset, maxiter=maxiter, upper=upper, lower=lower, $
 outmask=outmask, bkspace=bkspace,  $
 nbkpts=nbkpts, everyn=everyn, silent=silent, bkspread=bkspread, _EXTRA=EXTRA

   if (n_params() LT 2) then begin
      print, 'Syntax -  sset = bspline_iterfit( )'
      return, -1
   endif

   ;----------
   ; Check dimensions of inputs

   nx = n_elements(xdata)
   if (n_elements(ydata) NE nx) then $
    message, 'Dimensions of XDATA and YDATA do not agree'

   if (NOT keyword_set(nord)) then nord = 4L
   if n_elements(upper) EQ 0 then upper = 5
   if n_elements(lower) EQ 0 then lower = 5

   if (keyword_set(invvar)) then begin
      if (n_elements(invvar) NE nx) then $
       message, 'Dimensions of XDATA and INVVAR do not agree'
   endif 

   if (keyword_set(x2)) then begin
      if (n_elements(x2) NE nx) then $
       message, 'Dimensions of X and X2 do not agree'
      if (NOT keyword_set(npoly)) then npoly = 2L
   endif
   if (n_elements(maxiter) EQ 0) then maxiter = 10

   if (NOT keyword_set(invvar)) then begin
      var = variance(ydata)
      if (var EQ 0) then return, -1
      invvar = 0.0 * ydata + 1.0/var
   endif

   outmask = invvar GT 0
   these = where(outmask, nthese)
 
   if nthese LT nord then begin
      message, 'Number of good data points fewer the nord', /continue
      return, -1
   endif

   ;----------
   ; Determine the break points and create output structure

   if (keyword_set(oldset)) then begin
      sset = oldset
      sset.bkmask = 0
      sset.coeff = 0
      tags = tag_names(oldset)
      if ((where(tags EQ 'XMIN'))(0) NE -1 AND NOT keyword_set(x2)) then $
       message, 'X2 must be set to be consistent with OLDSET'

   endif else begin

      fullbkpt = bspline_bkpts(xdata[these], nord=nord, bkpt=bkpt, bkspace=bkspace,  $
        nbkpts=nbkpts, everyn=everyn, silent=silent, bkspread=bkspread)
      sset = create_bsplineset(fullbkpt, nord, npoly=npoly) 

      ;----------
      ; Condition the X2 dependent variable by the XMIN, XMAX values.
      ; This will typically put X2NORM in the domain [-1,1].

      if keyword_set(x2) then begin
         if (NOT keyword_set(xmin)) then xmin = min(x2)
         if (NOT keyword_set(xmax)) then xmax = max(x2)
         if (xmin EQ xmax) then xmax = xmin + 1
         sset.xmin = xmin
         sset.xmax = xmax
      endif

   endelse

   ;----------
   ; It's okay now if the data fall outside breakpoint regions, the
   ; fit is just set to zero outside.

   ;----------
   ; Sort the data so that X is in ascending order.

   xsort = sort(xdata)
   xwork = xdata[xsort]
   ywork = ydata[xsort]
   invwork = invvar[xsort]
   if (keyword_set(x2)) then x2work = x2[xsort]

   ;----------
   ; Iterate spline fit

   iiter = 0
   error = 0
   outmask = invwork GT 0
   inmask = invwork GT 0

   while (((error[0] NE 0) OR (keyword_set(qdone) EQ 0)) $
    AND iiter LE maxiter) do begin

      ngood = total(outmask)
      goodbk = where(sset.bkmask NE 0)

      if (ngood LE 1 OR goodbk[0] EQ -1) then begin
         sset.coeff = 0
         iiter = maxiter + 1; End iterations
      endif else begin
        ; Do the fit.  
        ;  returns 0 if fit is good
        ;         -1 if bkpts are masked
        ;      or -2 if everything is screwed
        ;
        error = bspline_fit(xwork, ywork, invwork*outmask, sset, $
         x2=x2work, yfit=yfit, nord=nord, mask=mask)
      endelse

      iiter = iiter + 1

      if (error[0] EQ -2L) then begin
         ; All break points have been dropped.
         return, sset
      endif else if (error[0] EQ 0) then begin
         ; Iterate the fit -- next rejection iteration.
         inmask = outmask
         qdone = djs_reject(ywork, yfit, invvar=invwork, inmask=inmask, $
          outmask=outmask, upper=upper, lower=lower, _EXTRA=EXTRA)
      endif

   endwhile

   ;----------
   ; Re-sort the output arrays OUTMASK and YFIT to agree with the input data.

   temp = outmask
   outmask[xsort] = temp

   temp = yfit
   yfit[xsort] = temp

   return, sset
end
;------------------------------------------------------------------------------
