function gpfunc,x,par,offset=offset,plot_key=plot_key, info=info, psfpix=psfpix,psfsig=psfsig,test=test, gausarray=gausarray, array=array

;Gaussian-based function to model "arbitrarily wingy" instrumental profiles.
; x (input vector) pixel offsets at which to evaluate function.
; par (input vector) profile function parameters as described below:
;   0: standard deviation of the gaussian core. (0.5=narrow, 2=fat)
; Returns the normalized profile function evaluated at each point in x.
; Typical Hamilton input: par=[0.9,.01,.05,.1,.3,.1,.05,.02]
;11-May-92 JAV	Adapted from GM's glfunc.pro routine.
;06-feb-93 GM   Power Law wings removed, 6 little Gaussians put in

if n_params() lt 2 then begin
    print,'syntax: gpfunc(x,par)'
    retall
endif
if keyword_set(info) then begin
    psfpix = info.psfpix
    psfsig = info.psfsig
endif
if par(0) le 0.0 then message,/info,'Gaussian width must be positive.'

;Define useful quantities.
nx   = n_elements(x)            ;number of points
ipro = fltarr(nx)               ;initialize profile

; New zero-th moment PSF centering routine
if n_elements(offset) eq 1 then mdpnt=offset else mdpnt=0.
;if n_elements(par) eq 20 then if par(19) ne 0. then mdpnt=par(19)
;;allow PSF to slide 4 Mar 02 PB
tags = tag_names(info)
u = where(stregex(tags,'acco',/bool,/fold), nu)
scale = 1.
if nu then if keyword_set(info.accordion) then scale = par[19] 

;Compute central gaussian.
cen = 0.0-mdpnt 
wid=abs(par[0])*scale ;gaussian pos'n, width 
bigwid=max([wid*5.,2])
ind = where(x ge cen-bigwid and x le cen+bigwid) ;pts +/- bigwid
ipro(ind) = exp(-0.5*((x(ind)-cen)/wid)^2) ;Central Gaussian

parindex=[indgen(11),indgen(4)+15]
;Add in little gaussians:  Fixed centers and widths
nsig = n_elements(psfsig)
npix = n_elements(psfpix)

if stregex(info.test, 'sine', /bool) then begin
    parindex = [indgen(11), indgen(3)+15]
    nsig -= 1
    npix -= 1
endif

if nsig gt 1 and npix gt 1 then begin ;;; this is turned off by JJ 2/08
    for n=1,nsig-1 do begin
        cen = psfpix[n]*scale-mdpnt 
        wid = psfsig[n]*scale   ;gaussian pos'n, width
        if wid gt 0 then begin  ;if wid = 0, toss gaussian
            ind = where(x ge cen-5.*wid and x le cen+5*wid, nind) ;range of guassian
            if keyword_set(test) then stop
            if keyword_set(gausarray) then begin
                g = jjgauss(x, [par[parindex[n]], cen, wid])
                if n_elements(array) eq 0 then begin
                    array = fltarr(nx, nsig+1)
                    array[*, 0] = ipro
                endif
                array[*, n+1] = g
            endif
            if nind gt 0 then ipro(ind) = ipro(ind) + par(parindex(n))*exp(-0.5*((x(ind)-cen)/wid)^2)	
        endif
    endfor
endif else begin
    ipro = jjgauss(x, [1., 0., wid], /norm)
endelse

;ipro = 0
;for i = 0, nsig-1 do begin
;    ipro += par[parindex[i]] * info.gaussarr[*, i]
;endfor

;ipro = total(fan(par[parindex], 121, /tr)*(*info.gaussarr), 2)
;if total(par[parindex]) ne 1 then stop

;End Little Gaussian Addition

;Calculate dispersion. 
dx = (x(nx-1) - x(0)) / (nx-1)  ;dispersion
dydx = (dx * total(ipro))

;;; Force centering
if keyword_set(info) then if info.test eq 'jconv' then center = 1
if keyword_set(center) then begin
    xdydx = (dx * total(x*ipro))
;    com = int_tabulated(x, x*ipro)/int_tabulated(x, ipro)
    com =xdydx/dydx
;    if abs(com) gt 0.1 then stop
    ipro = shift_interp(ipro, -com/dx)
endif
;Normalize profile.
ipro = ipro / dydx              ;normalize profile

return,ipro                     ;return profile
end

