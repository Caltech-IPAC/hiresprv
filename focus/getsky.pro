pro getsky,im,orc,sky = sky
;Subroutine determines the "sky" surrounding the "star" spectrum
; and subtracts it from the the sky swath, including the "star" swath.
; 
; im (input array (# columns , # rows)) image from which orc was
;   determined and from which sky is to be subtracted.
;   im is output, with its sky subtracted.
; orc (input array (# coeffs , # orders)) polynomial coefficients (from FORDS)
;   that describe the location of complete orders on the image.
;
;Calls HAMTRACE, GETARC
;27-Feb-95 GWM Create, based on Valenti's GETSPEC
;
@ham.common					;get common block definition
if n_params() lt 2 then begin
  print,'syntax: getsky,im,orc'
  retall
end

  trace,25,'GETSKY: Entering routine.'

;Define useful quantities.
  ncol = n_elements(im[*,0])				;# columns in image
  nrow = n_elements(im[0,*])				;# rows in image
  ncoef = n_elements(orc[*,0])				;# polyn. coeffs
  nord =  n_elements(orc[0,*])				;# full orders in orc
  ix = findgen(ncol)					;column indicies
  arc = ix*0.
  spec = fltarr(ncol,nord)				;init spectrum
  ys=fltarr(ncol,nord)
  tys=fltarr(ncol,nord)
  trough = fltarr(ncol,nord)
  sky = fltarr(ncol,nrow)
  for i=0,nord-1 do begin
;     print, i
     ys[*,i] = poly(ix,orc[*,i])
     if i gt 0 then begin
       tys[*,i-1]=round((ys[*,i-1]+ys[*,i])/2.)
       for j=0,ncol-1 do trough[j,i-1] = median(im[j,tys[j,i-1]-2:tys[j,i-1]+2])
;       plot, trough(*,i-1),psym=3, yrange=[-150,150]
       xs = ix
       if i eq 21 or i eq 22 then remove,indgen(150)+925,xs
       remove,where(xs mod 4 ne 0),xs
       splinefit = bspline_iterfit(xs, trough[xs,i-1], bkspace = 200, upper = 3, lower = 3, /silent) 
       trough[*,i-1] = bspline_valu(ix, splinefit)
;       oplot, trough(*,i-1)
       if i gt 1 then begin
         indlo = tys[*,i-2]+1
         indhi = tys[*,i-1]
         nind=indhi-indlo+1
         for j=0,ncol-1 do sky[j,indlo[j]:indhi[j]]=(trough[j,i-1]-trough[j,i-2])*indgen(nind[j])/nind[j]+trough[j,i-2]
       endif 
       if i eq 1 then begin
         indlo = replicate(0,ncol)
         indhi = tys[*,i-1]
         for j=0,ncol-1 do sky[j,indlo[j]:indhi[j]]=trough[j,i-1]
       endif
     endif 
  endfor
indlo = tys[*,i-2]+1
indhi = replicate(nrow-1,ncol)
for j=0,ncol-1 do sky[j,indlo[j]:indhi[j]]=trough[j,i-2]

im=im-sky


;Now loop through orders, subtracting sky.

  trace,15,'GETSKY: Sky subtracted - returning to caller.'

return
end
