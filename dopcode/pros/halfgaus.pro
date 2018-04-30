;+
; NAME:
;        HALFGAUS
;
;
; PURPOSE:
;        Create half of a Gaussian such that G(X_min) = 1 and
;        G(X_min) = 0, i.e. Amp = 1, Xo = X_max and 
;        sigma = (X_max - X_min)/5.  Useful for creating 
;        Gaussian weighting funcitions
;
; CALLING SEQUENCE:
;        result = halfgaus(X [,SIGMAFRAC=])
;
; INPUTS:
;        X: monotonically increasing abscissa values
;
; KEYWORDS:
;        SIGMAFRAC: Sigma as a raction of Xrange. 
;                   sigma = (X_max - X_min)/sigmafrac where
;                   By default, SIGMAFRAC = 5
;
; OUTPUTS:
;        Half of a gaussian
;
; MODIFICATION HISTORY:
;        Written sometime in Ought 5 by JohnJohn
;-

function halfgaus, x, sigmafrac=frac, offsetfrac=off
if 1-keyword_set(frac) then frac = 5
if 1-keyword_set(off) then off = 0
coef = fltarr(3)
span = max(x) - x[0]
coef[0] = 1.
coef[1] = x[0] + off*span
coef[2] = span/frac
g = jjgauss(x, coef)
u = where(x lt off*span, nu)
if nu gt 0 then g[u] = 1
return, g
end
