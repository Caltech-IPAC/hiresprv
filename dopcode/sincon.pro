function sincon,x_arr,spar,pder
;x-arr is independent input array
;spar is a 3, 4, or 5 element array consisting of the sin parameters
;the firstthe  three parametert (x) specify the "sine"
;the 4th paramter is a "constant" offset
;the 5th paramter is a linear trend
;fnct is the function constructed from spar
;pder is an optional array of the partial derivatives from spar
;(pder is needed in curvefit)

if n_elements(spar) lt 3 then $
   stop,'Not enough parameters to specify a Sin (in sincon)!'
if n_elements(spar) gt 6 then $
   stop,'Too many parameters to specify a Sine + Line + Parab (in sincon)!'

spar=double(spar)
x_arr=double(x_arr)
tpi=!dpi*2.d0
gtz=(tpi*x_arr - spar(2))/spar(1)

;0 to 2pi
;for n=0,n_elements(gtz)-1 do begin
;   if gtz(n) gt tpi then begin
;      dum=long(gtz(n)/tpi)
;      gtz(n)=gtz(n)-dum*tpi
;   endif
;endfor

fnct=spar(0)*sin(gtz)
if n_elements(spar) ge 4 then fnct=fnct+spar(3)
if n_elements(spar) ge 5 then fnct=fnct+spar(4)*x_arr
if n_elements(spar) eq 6 then fnct=fnct+spar(5)*(x_arr^2.)

;partial derivatives
if n_params() eq 3 then begin
   pder=fltarr(n_elements(x_arr),n_elements(spar))
   pder(*,0)=sin(gtz)
   pder(*,1)=spar(0)*cos(gtz)*(-gtz/spar(1))
   pder(*,2)= spar(0)*cos(gtz)*(-1./spar(1))
;numerical derivative
;   pder(*,2)= (spar(0)/.02) * (sin(gtz+.01)-sin(gtz-.01))
   if n_elements(spar) ge 4 then pder(*,3)=1.
   if n_elements(spar) ge 5 then pder(*,4)=x_arr
   if n_elements(spar) eq 6 then pder(*,5)=x_arr^2.
endif   ;n_params

return,fnct
end;
