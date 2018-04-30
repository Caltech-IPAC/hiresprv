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
;6-8-2013 HTI, removed line "if i eq 21 or i eq 22..." ; reminant from old chip
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
     ys[*,i] = poly(ix,orc[*,i]) 		;defines orders
     if i gt 0 then begin
       tys[*,i-1]=round((ys[*,i-1]+ys[*,i])/2.)
       for j=0,ncol-1 do trough[j,i-1] = median(im[j,tys[j,i-1]-2:tys[j,i-1]+2])
;       plot, trough(*,i-1),psym=3, yrange=[-20,20],/ysty
       xs = ix
       ;stop
;       if i eq 21 or i eq 22 then remove,indgen(150)+925,xs
       remove,where(xs mod 4 ne 0),xs ; smooth out the trough.
       splinefit = bspline_iterfit(xs, trough[xs,i-1], bkspace = 200, upper = 3, lower = 3, /silent) 
       trough[*,i-1] = bspline_valu(ix, splinefit)
;       oplot, trough(*,i-1)
;		oplot,im[*,i-1],co=90
;stop
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

;display,im
;for i=0,nord-1 do oplot,tys[*,i],co=99
;stop

;begin new:
;display some representative plots 
;plot,im[2000,*],yr=[-100,500]
;plot,im[2000,200:400],yr=[-100,500]
; plot,im[2000,*],yr=[-100,100] 
; oplot,sky[2000,*],co=99 


;mash ten columns

;b1 = 2001  ;begin mashed pix
;e1 = 2010	;end mashed pix
;b1 = 1051
;e1 = 1060

;b2 = 0  	;remove bottom order
;e2 =700		;remove top junk

;mash = (total(im[b1:e1,b2:e2],1))/10. ;creats 10 mashed columns of 713 pixels.
;mashS = total(sky[b1:e1,b2:e2],1)/10 ;sam for sky

;b= 0
;e= 700
;ps_open,'sky_test3',/color
;plot,mash[b:e],yr=[min(mash[b+100:e-50])-10,min(mash[b+100:e-50])+40],$
;	  /xsty,/ysty,ps=10 , $
;	  xtitle = 'Row Number', charsize = 1.0, $
;  	  title = 'Obs: rj29.118, HD4628: Scattered light found in getsky.pro is shown in blue' , $
;	  title = 'Obs: rj50.221, HR708: Scattered light found in getsky.pro is shown in blue' , $
;		  title = 'Obs: rj81.302, HIP109388: Scattered light found in getsky.pro is shown in blue' , $
;
;	  ytitle = 'Average counts (Dn) per raw pixel, averaged over 10 columns'
	  
;oplot,mashS[b:e],co =99
;xyouts, 100, min(mash[b+100:e-50])-5, 'Peak counts are 2,000 dn per raw pixel',charsize= .9  ;10k for hr708 and 4629, 2k for hipstar

;end new
im=im-sky  
;save,sky,file='sky2'
;stop
;print,'%TEST, NO SKY(SCATTERED LIGHT) SUBTRACTION IN GETSKY.PRO' ;HTI Apr 2011


;begin new
;mash = total(im[b1:e1,b2:e2],1)/10. ;creats 10 mashed columns of 713 pixels.
;mashS = total(sky[b1:e1,b2:e2],1)/10. ;sam for sky

;plot,mash[b:e],yr=[min(mash[b+100:e-50])-10,min(mash[b+100:e-50])+40], $
;		/xsty,/ysty,ps=10 , charsize= 1.0 ,$
;	 xtitle = 'Row Number', $
;	  title = 'Obs: rj29.118, HD4628: with scattered light removed', $
;	  title = 'Obs: rj50.221, HR708: with scattered light removed', $
;;	  title = 'Obs: rj81.302, HIP109388: with scattered light removed', $
;	  ytitle = 'Average counts (Dn) per raw pixel, averaged over 10 columns'
	  
;oplot,intarr(e-b), co =99	  
;xyouts, 100, min(mash[b+100:e-50])-5, 'Peak counts are 2,000 dn per raw pixel' ,charsize=.9
;ps_close

;stop
;end new


;Now loop through orders, subtracting sky.

  trace,15,'GETSKY: Scattered light subtracted - returning to caller.'

return
end
