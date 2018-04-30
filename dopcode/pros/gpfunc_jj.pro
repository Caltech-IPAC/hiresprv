function gpfunc_jj,x,par,offset=offset,plot_key=plot_key,psfpix=pix, psfsig=sig

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

  if par(0) le 0.0 then message,/info,'Gaussian width must be positive.'

;Define useful quantities.
  nx   = n_elements(x)				;number of points
  ipro = fltarr(nx)				;initialize profile

; New zero-th moment PSF centering routine
  if n_elements(offset) eq 1 then mdpnt=offset else mdpnt=0.
  if n_elements(par) eq 20 then if par(19) ne 0. then mdpnt=par(19) ;allow PSF to slide 4 Mar 02 PB
  
  if (n_elements(pix) lt 1) or (n_elements(sig) lt 1) or $
     (n_elements(pix) ne n_elements(sig)) then begin
       print,'This version of GPFUNC requires the SIG and PIX as common block inputs' 
       STOP
  endif

;ancient PSF description
;   pix=[0.,-5.0,-3.0,-1.5,1.50,3.00,4.50,6.25]
;   sig=[0.,1.00,0.75,0.75,0.75,0.75,0.75,1.25]    

;modern PSF description for pre-fix
;    pix=[0.00,-5.00,-4.00,-3.00,-2.00,-1.00, 1.00, 2.00, 3.00, 4.00, 5.00]
;    sig=[0.85, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60]

;modern PSF description for post-fix
;    pix=[0.00,-2.40,-2.10,-1.60,-1.10,-0.60, 0.60, 1.10, 1.60, 2.10, 2.40]
;    sig=[0.40, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30]

;Compute central gaussian.
  cen = 0.0-mdpnt & wid=abs(par(0))                 ;gaussian pos'n, width 
  bigwid=max([wid*5.,2])
  ind = where(x ge cen-bigwid and x le cen+bigwid)  ;pts +/- bigwid
  ipro(ind) = exp(-0.5*((x(ind)-cen)/wid)^2)	    ;Central Gaussian

;  parindex=[indgen(11),indgen(5)+15]               ;19th element for "sliding"
  parindex=[indgen(11),indgen(4)+15]
;Add in little gaussians:  Fixed centers and widths
  for n=1,(n_elements(sig)-1) do begin
    cen = pix(n)-mdpnt & wid=sig(n) ;gaussian pos'n, width
    if wid gt 0 then begin  ;if wid = 0, toss gaussian
       ind = where(x ge cen-5.*wid and x le cen+5*wid)   ;range of guassian
       ipro(ind) = ipro(ind) + par(parindex(n))*exp(-0.5*((x(ind)-cen)/wid)^2)	
    endif
  endfor
;End Little Gaussian Addition

;Calculate dispersion. Normalize profile.
  dx = (x(nx-1) - x(0)) / (nx-1) 		;dispersion
  ipro = ipro / (dx * total(ipro))		;normalize profile
;if n_elements(plot_key) eq 1 then if plot_key eq 1 then begin
;   plot,x,ipro,xra=[-8,8],/xsty,thick=2
;   oplot,x,ipro,ps=7,symsize=1.4,co=151
;endif
  return,ipro					;return profile
end

