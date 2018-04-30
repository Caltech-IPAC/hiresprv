Function Starsyn,par,nwght, info=info, ghparam=ghparam, psf=ip


;Purpose: Construct a synthetic observation (stellar * iodine) spectrum:
;   Multiply an FTS I2 spectrum by a debinned-deconvolved star spectrum,
;   and convolving with a PSF.  Than bin the result to original CCD pixels.
;       
;Mar-91 GWM,RPB	Create.
;Apr-92 GWM	Modified.
;May-92 JAV	Renamed from ipfunct, extracted most of the code up one level
;		 to the calling routine (ipsolve), made into function.
;Apr 1993 RPB  Add the NSO (no more recovered iodine)  
;May 1993 RPB  Modify to run with debinned-deconvolved stellar template 
;Aug 1995 GWM  Touched up - no signif. changes
;Dec 2003 RPB  Allow parobolic fit to model    
;2003     JAJ  Gauss-Hermite PSF through ghparam keyword 
;Jun 2005 JAJ  Replaced many variables with INFO structure for debugging
;Jan 2007 JAJ  Added iodine depth adjustment for nights with cool I2 cell
;Feb 2008 JAJ  Added quadratic WLS for LONGFORMAT=1 (long chunks)

;INPUT:
; PAR     fltarr(15)   Input Guesses of Free Parameters.
;   PAR (0:10) = IP parameters (see voigtip.pro, gpjv.pro or gpfunc.pro)
;   PAR(11) = wavelength zero point (decimal part; see w0 for integer part)
;   PAR(12) = Z   (as in vel = cZ)
;   PAR(13) = dLambda/dpix ("dispersion")
; WIOD    fltarr      Wavelengths for fts Iodine spectrum (iodine)
; SIOD    fltarr      Fts spectrum (iodine) --- finely sampled spectrum
; WSTAR   fltarr      Wavelengths of stellar spectrum (deconvolved)
; SSTAR   fltarr      Stellar Spectrum (deconvolved)
; W0      int         integer portion of wavelength of chunk
; OSAMP   int         # of sub-pixels per original pixel (=4)

;OUTPUT:
;  SYNSPEC    Returned: The synthetic spectrum constructed according to PAR
if n_elements(par) eq 0 then par = info.par
check = parcheck(par, info=info) ;Check for Flaws with input parameters:
if check eq -1 then return,-1

;Initialize Wavelength Scales  (I. II. III.)
;I.  Observed Spectrum Chunk 
numpix = n_elements(info.obchunk) ;pixels/chunk
dispobs = par[13]                 ;dispersion, dlambda/dpix 
xpix = dindgen(numpix)
w0obs = double(info.w0)+par[11] ;wavelength zero pt. of obs
wavobs = xpix*dispobs + w0obs   ;wavelength scale of obs

if maxloc(wavobs,/first) eq -1 then return,-1 ;check for Flaws, PB 20Aug98

;II. Star Spectrum (Deconvolved)
wavstar = double(info.wstar) + par(12)*double(info.wstar) ;Doppler shifted wavels

;III.New "Fine" Wavelength Scale  
wiod = info.wiod
;qcond = keyword_set(info.longformat) or keyword_set(info.quadwav)
qcond = 0
if qcond then begin
    wavfine = wavstar
;    print,'Fix this for /LONGFORMAT and /QUADWAV'
;    stop
endif else begin
    w0fine = max([wiod[0],wavstar[0]]) + dispobs     ;"fine" wavel zero pt.
    w1fine = min([max(wiod),max(wavstar)]) - dispobs ;last fine wavelength
    dispfine = dispobs/double(info.osamp)            ;"fine" dispersion
    npixf = (w1fine - w0fine)/dispfine > 1           ;Number of "fine" pixels
    wavfine = w0fine + dindgen(npixf)*dispfine       ;"fine" wavel scale
endelse
check = wavcheck(wavobs,wiod,wavstar,wavfine, info=info) ;Check wavelengths
if check lt 0 then return, -1

                                ;PSF Construction (ip)
nip = 15 * info.osamp
xip = (dindgen(2*nip+1)-nip)/double(info.osamp) ;resampled fine *pixel* scale

IF n_elements(info.psf) lt 2 then begin ;if no inst. prof. explicitly input,
;generate the IP
    if keyword_set(ghparam) then begin
        ip = ghfunc(xip, par, param=ghparam, info=info)
    endif else ip = gpfunc(xip,par,info=info)
;    info.psf = ip ;; JJ: July 1, 2008
;if par[19] ne 1 then stop
    if n_elements(ip) eq 1 then begin
        if 1-keyword_set(info.noprint) then  print,'STARSYN: Bad IP'  
        return,-1
    end
    maxip = maxloc(ip,/first)
    n_xip = n_elements(xip)
    slop = fix(n_xip/4)
    IF (maxip lt slop) or (maxip gt 3*slop) then begin
        if 1-keyword_set(info.noprint) then begin
            print,'Starsyn: IP peak is way off center'
            print,'maxip=',maxip,'  slop=',slop 
        endif
        return,-1
    ENDIF
ENDIF ELSE ip = info.psf        ;Use Input PSF

;Re-Sample the iodine and star spectra onto the "fine" scale
iodfine = fspline(wiod, info.siod, wavfine) ;iodine spec on fine scale

;;; If par[19] used, adjust iodine line depths using psuedo-tau
if info.dstep[19] gt 0 and 1-keyword_set(info.accordion) then begin
    old = iodfine
    tau = -alog(iodfine)
    newtau = tau * par[19]
    iodfine = exp(-newtau)
endif

starfine = fspline(wavstar,info.sstar,wavfine) ;star spec on fine scale

;Synthesize Deconvolved Spectrum
dsp = iodfine*starfine          ;product of iod * star

;Convolve with Instrumental Profile
if info.test eq 'jconv' then jnum_conv,dsp,ip,ytmp, bad=bad else $
  num_conv,dsp,ip,ytmp, bad=bad
if bad then begin
    return,-1
endif
;  ytmp = ytmp/max(ytmp)

;Scattered Light (currently off)
;ytmp=ytmp+par(14)*max(ytmp)

;REBIN to presumed Observed Wavelength Scale, wavobs.
rebin,wavfine,ytmp,wavobs,synspec ;rebin to the "observed" pixels

slpwt = sqrt(info.wt)
ratio = info.obchunk/synspec  
if stregex(info.test, 'sine', /bool) then begin
    sine = par[14]*sin(2*!pi*xpix/par[18] + par[19])
    synspec += sine
;synspec *= median(ratio)
endif

;Force Match of Continuum of Synthetic Spectrum to Observed
;   Enough points to "flatten" spectra?  If not, fudge lowest weights
dumwt=slpwt
wtind = where(slpwt lt (0.2*median(slpwt)),dum)            ;dum is # of poor pixels
if median(slpwt) le 0 then wtind=where(slpwt le 0,dum)     ;most pixels could have zero wt
if dum gt (0.5*numpix) then dumwt(wtind) = 0.2*max(slpwt)  ;half the pixels are poor
if max(dumwt) le 0 then dumwt=dumwt*0.+1.                  ;more than half pixels are 0
pord = 1
cof = polyfitw(findgen(numpix),ratio,dumwt,pord) ;17Dec03 RPB
slope = poly_fat(findgen(numpix),cof) 
synspec = synspec*slope
BOMB: return,synspec
End
