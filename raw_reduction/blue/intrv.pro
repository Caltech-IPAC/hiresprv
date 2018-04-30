;+
; NAME:
;   intrv
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
;   coeff = efc2d(x, y, z, invsig, npoly, nbkptord, fullbkpt)
;
; INPUTS:
;   x          - data x values
;   y          - data y values
;   z          - data z values
;   invsig     - inverse error array of y
;   npoly      - Order of polynomial (as a function of y)
;   nbkptord   - Order of b-splines (4 is cubic)
;   fullbkpt   - Breakpoint vector returned by efc
;
; RETURNS:
;   coeff      - B-spline coefficients calculated by efc
;
; OUTPUTS:
;
; OPTIONAL KEYWORDS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   does the same function as intrv, although slower but easier to follow
;    sorting is done here
;   assumes x is monotonically increasing
;
; EXAMPLES:
;
; REVISION HISTORY:
;   31-Aug-2000 Written by Scott Burles, FNAL
;-
;------------------------------------------------------------------------------
function intrv, x, fullbkpt, nbkptord 
    
      nx = n_elements(x)
      nbkpt= n_elements(fullbkpt)
      n = (nbkpt - nbkptord)

      ileft = nbkptord - 1L
      indx = lonarr(nx)

      for i=0L, nx-1 do begin
        while (x[i] GT fullbkpt[ileft+1] AND ileft LT n-1 ) do $
            ileft = ileft + 1L
        indx[i] = ileft
      endfor
     
     return, indx
end 
