pro  xcorlb, star,temp,range,shft,plot=pl,out=ot
 
if n_params() lt 4 then begin
   print,'XCORL, fixed,test,range,shft[,plot=pl,out=ot]' &
   print, 'Uses spline to find extremum'   
return
endif
;Measures the shift of temp. relative to star (a shift to rt. is +)
;Accuracy is typically 0.05pxl.   
;G. Marcy 12/88
     ln = n_elements(temp)
     ls = n_elements(star)
     len = min([ln,ls])
     newln = len - 2*range    ; Leave "RANGE" on ends for overhang.
     te = temp/(total(temp)/ln)
     st = star/(total(star)/ls); Be normal already!
     newend = range + newln - 1
     x =findgen(2 * range+1) - range
     chi = fltarr(2 * range+1)
     for j = -range,range do begin     ; Goose step, baby.
        dif = te(range:newend) - st(range+j:newend+j)
        chi(j+range) = total(dif^2)  ;Too bad sdev. doesn't work.
     endfor
     xcr = chi
     if keyword_set(pl) then begin
	!p.multi=[0,1,2]
	plot,star
	oplot,temp-.5
        plot, chi,/ynozero
	!p.multi=0
     endif
     len = n_elements(x) * 100
     xl = findgen(len)
     xl = xl/100. - range
     xp = xl[0:len-100]
     cp = fspline(x,chi,xp)
     mm = where(cp eq min(cp))
     shft = xp(mm[0])
     if keyword_set(ot) then begin
;    	print, 'spline', peak
;    	q = where(min(chi)) & peak=q(0) & x=x(peak-2:peak+2) 
;    	chi=chi(peak-2:peak+2)
;    	coef = poly_fit(x,chi,2) & shft = -0.5 * coef(1)/coef(2)
;    	print,'parabola', shft
        print,'The shift is: ',shft
    endif
end

