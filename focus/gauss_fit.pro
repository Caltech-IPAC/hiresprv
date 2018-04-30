pro	gaussian,x,a,f,pder
z = (x-a(1))/a(2)		    ;get z
ez = exp(-z^2/2.)*(abs(z) le 7.)    ;gaussian part ignore small terms
f = a(3)+a(0)*ez		    ;function.
if n_params(0) le 3 then return	    ;need partial?
pder = fltarr(n_elements(x),4)	    ;yes, make array.
pder(0,0) = ez			    ;compute partials...
pder(0,1) = a(0) * ez * z/a(2)
pder(0,2) = pder(*,1) * z
pder(*,3) = 1.
return
end
function gauss_fit,x,y,a
;+
; NAME:
;	GAUSS_FIT
; PURPOSE:
; 	fit y=f(x) where:
; 	f(x) = a0*exp(-z^2/2) + a3
; 		and z=(x-a1)/a2
;	a0 = height of gaussian, a1 = center of gaussian, a2 = 1/e width,
;	a3 = background.
; 	Estimate the parameters a0,a1,a2,a3 and then call curfit.
; CATEGORY:
;	?? - fitting
; CALLING SEQUENCE:
;	yfit = gauss_fit(x,y,a)
; INPUTS:
;	x = independent variable, must be a vector.
;	y = dependent variable, must have the same number of points
;		as x.
;	quiet = set to inhibit printing curfit iterations.
; OUTPUTS:
;	yfit = fitted function.
; OPTIONAL OUTPUT PARAMETERS:
;	a = coefficients. a three element vector as described above.
;
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;	Adapted from GAUSSFIT
;	D. L. Windt, AT&T Bell Laboratories, March, 1990
;-
;
on_error,2		
cm=check_math(0.,1.)		; Don't print math error messages.
n = n_elements(y)		; # of points.
c=poly_fit(x,y,1,yf)		; Do a straight line fit.
yd=y-yf
ymax=max(yd) & xmax=x(!c) & imax=!c	;x,y and subscript of extrema
ymin=min(yd) & xmin=x(!c) & imin=!c

if abs(ymax) gt abs(ymin) then i0=imax else i0=imin ;emiss or absorp?
i0 = i0 > 1 < (n-2)		;never take edges
dy=yd(i0)			;diff between extreme and mean
del = dy/exp(1.)		;1/e value
i=0
while ((i0+i+1) lt n) and $	;guess at 1/2 width.
	((i0-i) gt 0) and $
	(abs(yd(i0+i)) gt abs(del)) and $
	(abs(yd(i0-i)) gt abs(del)) do i=i+1
a = [yd(i0), x(i0), abs(x(i0)-x(i0+i)),c(0)] ;estimates
!c=0				;reset cursor for plotting
return,curfit(x,y,replicate(1.,n),a,sigmaa,funct='gaussian',/quiet) ;call curfit
end
