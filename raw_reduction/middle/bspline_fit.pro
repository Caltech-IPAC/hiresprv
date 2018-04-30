;+
; NAME:
;   bspline_fit
;
; PURPOSE:
;   Calculate a B-spline in the least-squares sense 
;     based on two variables: x which is sorted and spans a large range
;				  where bkpts are required
;  		and 	      y which can be described with a low order
;				  polynomial	
;
; CALLING SEQUENCE:
;   
;   error_code = bspline_fit(x, y, invvar, sset, $
;                fullbkpt=fullbkpt, nord=, x2=, npoly=, yfit=, mask=)
;
; INPUTS:
;   x          - independent variable
;   y          - dependent variable
;   invvar     - inverse variance of y
;   sset       - Structure to be returned with all fit parameters
;
; RETURNS:
;   error_code - Non negative numbers indicate ill-conditioned bkpts
;
; OUTPUTS:
;
; OPTIONAL KEYWORDS:
;   fullbkpt   - Pass fullbkpt to seed structure
;   nord       - Order of b-splines (4 is cubic, default)
;   x2         - Orthogonal dependent variable
;   npoly      - Order of x2 polynomial fit
;   yfit       - evaluation of spline at x (& x2)
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   please sort x for this routine?  This might not be necessary
;   replacement for efcmn and efc2d which calls slatec library
;
; EXAMPLES:
;
;
; PROCEDURES CALLED:
;   bspline_action()
;   bspline_maskpoints()
;   bspline_valu()
;   cholesky_band()
;   cholesky_solve()
;
; REVISION HISTORY:
;   20-Aug-2000 Written by Scott Burles, FNAL
;   12-Oct-2000  Changed return codes
;                 0 is good
;                -1 is dropped breakpoints, try again
;                -2 is failure, should abort
;-
;------------------------------------------------------------------------------

function bspline_fit, xdata, ydata, invvar, sset, fullbkpt=fullbkpt, $
       x2=x2, npoly=npoly, nord=nord, yfit=yfit, mask=mask

      if NOT keyword_set(nord) then nord=4L

      if datatype(sset, /tname) EQ 'UNDEFINED' then $
          sset = create_bsplineset(fullbkpt, nord, npoly=npoly) 

      if ((where(tag_names(sset) EQ 'NPOLY'))(0) NE -1) then npoly=sset.npoly
      if NOT keyword_set(npoly) then npoly=1L
    
      goodbk = where(sset.bkmask[nord:*] NE 0, nbkpt)

      nord = sset.nord

      if nbkpt LT nord then return, -2L

      n = nbkpt 
      nfull = n*npoly
      bw = npoly * nord   ; this is the bandwidth

      ;  The next line is REQUIRED to fill a1

      a1 = bspline_action(xdata, sset, x2=x2, lower=lower, upper=upper)

      a2 = a1 * (invvar # replicate(1,bw))

      alpha = dblarr(bw,nfull+bw)
      beta = dblarr(nfull+bw)

      bi = lindgen(bw)
      bo = lindgen(bw)
      for i=1,bw-1 do bi = [bi,lindgen(bw-i)+(bw+1)*i]
      for i=1,bw-1 do bo = [bo,lindgen(bw-i)+bw*i]

      for i=0L, n-nord do begin

        itop = i*npoly
        ibottom = (itop < nfull + bw) - 1
       
        ict = upper[i] - lower[i] + 1
  
        if (ict GT 0) then begin

          work = a2[lower[i]:upper[i],*] ## transpose(a1[lower[i]:upper[i],*])
          wb =  ydata[lower[i]:upper[i]] # a2[lower[i]:upper[i],*] 

          alpha[bo+itop*bw] = alpha[bo+itop*bw] + work[bi]
          beta(itop:ibottom) = beta(itop:ibottom) + wb

        endif
      endfor

;-----------------------------------------------------------------------------
;
;     This was used to test the full matrix inversion, just to compare with
;       band matrix inversion
;
;
;    afull = fltarr(nfull+bw, nx)
;    afull[0:bw-1,*] = transpose(a1)
;    for i=0,nx-1 do afull[*,i] = shift(afull[*,i],(indx[i]-min(indx))*npoly)
;    afull = afull[0:nfull-1, *]
;    jj = afull # transpose(afull)
;    choldc, jj, p
;    res = cholsol(jj, p, transpose(ydata # transpose(afull)))
;
;-----------------------------------------------------------------------------

;
;	This is an attempt to drop bkpts where minimal influence is located
;
    minimum_influence = 1.0e-10 * total(invvar)/nfull
    yfit = ydata*0.0

;
;       cholesky_band operates on alpha and changes contents
;


    errb = cholesky_band(alpha, mininf=minimum_influence) 


    if (errb[0] NE -1) then begin 
      return, bspline_maskpoints(sset, errb, npoly)
    endif
 
; this changes beta to contain the solution

    errs = cholesky_solve(alpha, beta)   
    if (errs[0] NE -1) then begin
      return, bspline_maskpoints(sset, errs, npoly)
    endif

    sc = size(sset.coeff)
    if sc[0] EQ 2 then begin
      sset.icoeff[*,goodbk] = reform(alpha[0,lindgen(nfull)],npoly,n)
      sset.coeff[*,goodbk] = reform(beta(lindgen(nfull)), npoly, n) 
    endif else begin
      sset.icoeff[goodbk] = alpha[0,lindgen(nfull)]
      sset.coeff[goodbk] = beta(lindgen(nfull))
    endelse

;
;	Now evaluate fit just since we can
;
    yfit = bspline_valu(xdata, sset, x2=x2, action=a1, upper=upper, $
            lower=lower, mask=mask)

    return, 0L
end 
