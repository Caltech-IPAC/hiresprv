Function Starham, tpar, pder $
				, info=info $
				, ghparam=ghparam


; PURPOSE:  Construct a synthetic Hamilton stellar+idoine spectrum by 
;			multiplying an FTS I2 spectrum with a debinned-deconvolved template
; 			spectrum and convolving with a PSF and binning the result to 
;			Hamilton pixels.
;
; INPUT: 
;       TPAR   dblarr(15)    input parameters (transformed ones, transpar.pro)
; OPTIONAL:
;       PDER   dblarr(40,15) dphotons/dpar  for synthetic spectrum
; KEYWORD:
;		INFO	structure containing spec, template, other important information
;       
;Mar-91 GWM,RPB	Create.
;Apr-92 GWM	Modified.
;May-92 JAV	Renamed from ipfunct, extracted most of the code up one level
;		 to the calling routine (ipsolve), made into function.
;April 21, 1993 Add the NSO (no more recovered iodine)                   (PB)
;May   9, 1993  Modify to run with debinned-deconvolved stellar template (PB)
;Aug 1995 GWM   Modify for transformed parameters

if n_params() lt 1 then begin
  print,'syntax: yfit = starham(par,pder)'
  retall
endif

;Initialize some parameters
npix = n_elements(info.obchunk)              ;# pixels in spectrum chunk (=40)
tpar(0) = abs(tpar(0))                  	 ;force positive gaussian width 

par = tpar                              	 ;No Transpar
yfit = starsyn(par, info=info, ghparam=ghparam) ;Synthesize spec, orig. par's
if n_elements(yfit) lt 2 then return,yfit 

IF n_params() eq 2 then begin           	 ;Calculate partial derivatives
  pder = dblarr(npix,info.nfltpar)
  FOR n = 0,(info.nfltpar-1) do begin
     ind = info.fltpar(n)                           ;index of current parameter
     dumpar = double(tpar)                    		;init dumpar array size
     dumpar(ind) = tpar(ind)+info.dstep(ind)        ;Incrementeach parameter
     par = dumpar                             		;No Transpar
     hifit = starsyn(par, info=info, ghparam=ghparam)  ;synth spectrum 
     												   ;   at higher par
     if n_elements(hifit) lt 2 then return,hifit 
     pder(*,n) = (hifit-yfit)/info.dstep(ind)      ;partial deriv.
     izero = where(pder(*,n) eq 0., nzero)    ;eliminate zero values of pder
     if nzero ge 1 then pder(izero,n) = 1.d-50*median(yfit)/info.dstep(ind) ;set low
  ENDFOR
ENDIF
BOMB: return,yfit
end

;DOUBLE SIDED  (tests show that single-sided is OK to 10 m/s)
;     ENDIF ELSE BEGIN                           ;Double-Sided (default)
;       dumpar(ind) = tpar(ind) + 0.5*dstep(ind)
;       par = transpar(dumpar,-1)
;       hifit = starsyn(par)
;       dumpar(ind) = tpar(ind) - 0.5*dstep(ind)
;       par = transpar(dumpar,-1)
;       lofit = starsyn(par)
;       pder(*,n) = (hifit-lofit)/dstep(ind)     ;partial deriv. (dbl-sided)
;     ENDELSE

