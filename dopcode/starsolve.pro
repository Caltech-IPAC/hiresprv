Function STARSOLVE,info_in, sigpar, chi, niter $
					, plot=plot $
					, par=par  $
					, fit=yfit $
            		, ghparam=ghparam $
            		, resid=resid $
            		, accordion=accordion $
                	, return_resid=return_resid $
                	, movie=movie

;PURPOSE:
;  Find free parameters, PAR, to fit synthetic to Observed Spectrum.
;
;INPUT:
;  PAR     fltarr(15)   Input Guesses of Free Parameters.
;    PAR (0:10) = IP parameters (see gpjv.pro or gpfunc.pro)
;    PAR(11) = wavelength zero point
;    PAR(12) = cZ
;    PAR(13) = dLambda/dpix
;  OBCHUNK fltarr(40)  Observed spectrum --- #photons in each pixel
;  WIOD    fltarr      Wavelengths for fts spectrum (iodine)
;  SIOD    fltarr      Fts spectrum (iodine) --- finely sampled spectrum
;  WSTAR   fltarr      Wavelengths of stellar spectrum (deconvolved)
;  SSTAR   fltarr      Stellar Spectrum (deconvolved)
;  W0      int         integer portion of wavelength of chunk
;  OSAMP   int         # of sub-pixels per original pixel (=4)
;  WT      fltarr      Pixel Weights in OBCHUNK:  1/eps^2 from photon stat
;  DSTEP   fltarr(15)  Differential increments in free parameters (~10m/s)
;  NPAR    int         # of parameters
;  FLTPAR   fltarr      Indices of 15 param's that are free to float.
;  KECK                Flags use of Keck/HIRES spectrum
;  TRACE:  optional output - higher values of trace ==> more screen diagnositcs
;
;OUTPUT:
;   PAR    fltarr(15)   Values of free parameters that best fit OBCHUNK
;   SIGPAR: Uncertainties in IP parameters
;   CHI:    chi-sq for fit
;   RMS:    optional output - rms to fit
;
;Update: 1/2015, HTI, adding in PSF priors.
;----------------------------------------------------------------

info = info_in
tags = tag_names(info)

if stregex(info.test, 'movie', /bool) or keyword_set(movie) then begin
    movie = 1b
    window,30,xs=850,ys=550,/pixmap
endif

if stregex(info.test, 'chi') gt 0 then chi_check = 1b
;if stregex(info.test, 'lowres') gt 0 then begin 
;    xkern = fillarr(0.25, -25, 25)  ; HTI commented out gkern 2/2015
;    gkern = jjgauss(xkern, [1.0, 0, 4], /norm)
;endif

if info.par[11] lt -1. or info.par[11] gt 2. or info.par[13] le 0. then begin
    if 1-keyword_set(info.noprint) then begin
        print,'STARSOLVE: Abort because of absurd input wavelength scale.'
        print,'par(11)=',info.par(11)
        print,'par(13)=',info.par(13)
    endif
    chi = 100. 
    return,-1
end
;
;Initialize some parameters.

numpix = n_elements(info.obchunk) ;# of pixels in OBCHUNK (40)
spec = info.obchunk               ;rename "obchunk": "spectrum"
newpar = info.par                 ;array for new par's
degf = n_elements(where(info.wt gt 0)) - info.nfltpar - 2 ;degrees of freedom in fit
bdpx = where(info.wt le 0,nbdpx) ;pixels given zero weight
lambda = 0.3d0                   ;init NLLS-gradient weight
lamfac = 10.d0                   ;factor to change lambda
idiag = indgen(info.nfltpar) * (info.nfltpar+1) ;indicies of main diagonal
uvec = fltarr(info.nfltpar) + 1                 ;make unit vector

;Initial Synthetic Spectrum: yfit
tpar = info.par                 ;No Transpar

yfit = starham(tpar, info=info, ghparam=ghparam) ;synthetic "fit" spectrum

;Check for serious flaws in synthetic spectrum or weights
IF (n_elements(yfit) le 1) or (degf le 1) or $
  (n_elements(where(yfit gt 0)) lt 2) then begin
    if 1-keyword_set(info.noprint) then begin
        print,'STARSOLVE BOMB:' 
        print,'  n_elements(yfit)=',n_elements(yfit)
        print,'  degf=',degf
        print,' '
    endif
    chi=100. & goto,BOMB
ENDIF
;
;Initial CHI-SQ
resid = double(spec - yfit)     ;compute reduced chi-sq
;if n_elements(gkern) gt 0 then begin; HTI commented out gkern 2/2015
;    old = resid
;    num_conv, resid, gkern, resid
;endif
wtres = info.wt * resid^2.0     ;weighted residuals^2
oldchisq = total(wtres) / degf  ;chi-squared
chisq=oldchisq
;
;Cross Correlate to refine input wavelength zero pt.

index = where(info.fltpar eq 11, ni) ;Is par(11) floating?
IF ni ge 0 then begin                ;Yes.  Refine it...
    dispobs = info.par[13]           ;dispersion - dlambda/dpixel
    xcorlb,spec,yfit,5,shft          ;shft is pixel shift
;    shft = ccpeak(yfit, spec)
    info.par[11] = info.par[11] - shft[0]*dispobs ;apply shft to wav zero pt
ENDIF
if keyword_set(movie) then begin
    plot_starsolve, info.par, spec, yfit, info, 0, chisq, ghparam=ghparam
endif

;Initialize parameters for iteration

tpar = info.par                 ;No Transpar
niter = 0                       ;number of iterations initially zero
iter = 0 
chicount = 0                    ;15 Feb '02  RPB
maxiter = 25
crit = 0.2                      ;Convergence Criterion = 0.2 dstep = 2m/s)
qq = where(info.dstep gt 0)     ;15 Feb '02 RPB

opar = tpar

REPEAT BEGIN                    ;ITERATION LOOP
    iter = iter + 1
    yfit = starham(tpar,pder, info=info, ghparam=ghparam) ;First synthetic spectrum
    YFIT1 = YFIT;HTI TEST code
    if n_elements(yfit) le 2 then begin
        if 1-keyword_set(info.noprint) then $
          print,'STARSOLVE: BOMB in starham' 
        chi=100. 
        GOTO,BOMB
    endif
    resid = double(spec-yfit)   ;residuals
;    if n_elements(gkern) gt 0 then begin ; HTI commented out gkern 2/2015
;        old = resid
;        num_conv, resid, gkern, resid
;    endif
    wtres = info.wt * resid^2.0 
    oldchisq = total(wtres) / degf ;calculate chi-squared
    beta = double(resid*info.wt # pder) 
    alpha = double(transpose(pder) # (info.wt#uvec * pder))

    norm = sqrt(alpha(idiag) # alpha(idiag)) ;norm of diagonal elements
    array0 = alpha / norm                    ;normalized "alpha"
    REPEAT BEGIN                             ;LAMBDA LOOP
        chicount=chicount+1
        array = array0
        array(idiag) = 1.0 + lambda ;set LS vs. gradient search
        array = invert(array)       ;invert array

        dfree = double(array/norm # transpose(beta))    ;parameter adjustments
        newpar[info.fltpar] = tpar[info.fltpar] + dfree ;try new free param values
;if info.nfltpar gt 3 then print,'Ord: ',str(info.order), ' Pix: ',str(info.pixel)
;if info.nfltpar gt 3 then forprint,info.fltpar,dfree ; HTI
;if info.nfltpar gt 3 then stop

;HTI, 12/2014, This could be where restrictions to the psf gaussians.
; 		This test is specific to the Keck2 psf descrition
;HTI BEGIN EXPERIMENTAL SECTION,
if 0 then begin
  FOR n = 0,(info.nfltpar-1) do begin
     ind = info.fltpar(n)                           ;index of current parameter

	If info.nfltpar gt 3 then begin ;avoid vdiods and zeroth pass,3rd pass
	;The goal is to restrict dumpar from being outside of a certain range.
	; psf pars are 2:10 and 15:17
	if (ind ge 2 and ind le 10) or (ind ge 15 and ind le 17) then begin

;		If the limit (set in stargrind) is passed set it back to the 
;		For example lim could be -2 sig and val could be -1 sig
	   if newpar[ind] lt info.psf_lowlim[ind] then begin 
;			print,'ind: ',str(ind),' orig low newpar: ',newpar[ind]		;
			newpar[ind] = info.psf_lowval[ind]
;			print,'ind: ',str(ind),' new newpar: ',newpar[ind]			
;		stop
	   endif ; if low

;		If the limit (set in stargrind) is passed set it back to the 
;		For example lim could be +2 sig and val could be +1 sig
	   if newpar[ind] gt info.psf_upplim[ind] then begin
;			print,'ind: ',str(ind),' orig high newpar: ',newpar[ind]		;;
	   		newpar[ind] = info.psf_uppval[ind]
;			print,'ind: ',str(ind),' new newpar: ',newpar[ind]			
;		stop
	   endif ; if high

	endif ; only little gaussians.

	EndIf ; 1st, 2nd pass only

  ENDFOR ; loop over floating pars.
endif ; 0 to not do it.
;HTI END EXPERIMENTAL SECTION

        yfit = starham(newpar, info=info, ghparam=ghparam) ;compute synthetic profile

;if info.nfltpar gt 3 then begin ;TESTING;
;	plot, yfit ; HTI TEST
;	oplot,spec,co=!red ;TESTING
;;	stop;TESTING        
;endif ;TESTING

;        if stregex(info.test,'sine',/bool) then begin
;            newpar[18] = median([8, newpar[18], 160])
;        endif
        if n_elements(yfit) le 2 then begin
            if 1-keyword_set(info.noprint) then $
              print,'STARSOLVE: BOMB in starham' & chi=100. & GOTO,BOMB
        endif
        resid = double(spec - yfit) ;residual of model fit
;        if n_elements(gkern) gt 0 then begin; HTI commented out gkern 2/2015
;            old = resid
;            num_conv, resid, gkern, resid
;        endif
        wtres = info.wt * resid^2   ;weighted residual squared
        chisq = total(wtres) / degf ;calculate chi-squared
        lambda = lambda * lamfac    ;assume fit worse;big lam => small step
    ENDREP UNTIL (chisq le oldchisq or lambda gt 1.d6) ;this lambda gave smaller chi
    if keyword_set(movie) then begin
        plot_starsolve, newpar, spec, yfit, info, iter, chisq, ghparam=ghparam
    endif
    lambda = lambda/lamfac^2                      ;prepare lambda for next iter
    if lambda lt 1d-4 then lambda = lambda*lamfac ;avoid lambda too low
;    CONVERGED?
    delta = newpar - tpar       ;change of params, this iter 

    if chisq le oldchisq then tpar = newpar ;22 Mar '02 gwm
    frac = delta(qq)/info.dstep(qq)         ; HTI 01/2015
    IF iter ge maxiter   or $               ;Convergence taking too long
      lambda gt 1.d6  then begin
        chi = 100.
        goto,BOMB
    ENDIF

;if info.nfltpar gt 3 then ;HELP,CHISQ,OLDCHISQ,FRAC,DELTA,LAMBDA,max(abs(frac));HTI TEST
;if info.nfltpar gt 3 then stop
ENDREP UNTIL max(abs(frac)) lt 0.1 ; 1/2015, HTI  ORIGINAL
;ENDREP UNTIL max(abs(frac)) lt 0.01 ; 1/2015, HTI  TEST
;if info.nfltpar gt 3 then stop ; HTI TEST
par = tpar
chi = sqrt(chisq)
niter=fix(iter)
;if iter ge maxiter then stop		; NOTE: 1.2828442, 1.2828435
;print,'chi=',str(chi);HTI
;if info.nfltpar gt 3 then stop;
;if chi gt 5 then stop; HTI
;PLOTTING SECTION

if n_elements(plot) eq 0 then plot = 0 ;default: no plots
if plot eq 1 then begin
    !p.charsize=1.
    !x.charsize=1
    !y.charsize=1
    xwav = dindgen(numpix)*par(13)+par(11)+info.w0 ;linear wavelength scale
    xtit='!6Wavelength ( '+ang()+' )'
    ytit='!6Residual Intensity'
    tit='!6 .+* : Obs Spec     __ : Synth Spec'
    fac = max(spec)
    plot,xwav,spec/fac,psym=7,/yno,xtit=xtit,ytit=ytit,tit=tit,symsize=1.2
    if nbdpx gt 0 then oplot,[xwav(bdpx)],[spec(bdpx)/fac(bdpx)],ps=6,symsiz=3,co=111
    oplot,xwav,yfit/fac,thick=1.8,co=151
    wait,1
    xip = (findgen(120)-60.)/4.
    if n_elements(info.psf) lt 2 then plot,xip,gpfunc(xip,par,info=info),ps=8,xr=[-4,4] $
    else plot,xip,info.psf,ps=8,xr=[-4,4]
endif

BOMB:                           ;emergency escape from a BOMB condition
if keyword_set(return_resid) then begin
    npix = n_elements(resid)
    case 1 of
        npix eq 80: return, resid
        npix eq 79: return, [resid, resid[78]]
        npix eq 81: return, resid[0:79]
        npix eq 0: return, fltarr(80)
    endcase
    return, resid
endif
RETURN, tpar
END                             ;end whole program

