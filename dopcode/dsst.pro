pro dsst,template,vdiod,filter,cf,dsst $ 
         , bval=bval $
		 , dfn=dfn $
         , frz_cont=frz_cont $
         , gausspsf=gausspsf $
		 , index=index $
         , inpsf=inpsf $
         , inp_vdiod=inp_vdiod $
         , keck=keck $
		 , label=label $
         , maxiter=maxiter $
         , movie=movie $
         , new_deconv=new_deconv $
         , ngrid=ngrid $
         , nso=nso $
         , nodeconv=nodeconv $
         , noflat=noflat $
         , noprint=noprint $
         , parsm=parsm $
         , pixpsf=pixpsf $
		 , plot=plot $
         , sigma=sigma $
         , sigpsf=sigpsf $
         , stitch=stitch $
         , vchi=vchi 

;PURPOSE:  This routine builds a data structure, DSST,  that contains the 
;			deconvolved stellar spectrum.
;			This structure (dsst) is used to get stellar
;   		line shifts in the velocity code (stargrind.pro)
;
;KEYWORDS:
;  TEMPLATE:   (input)  Template star 2D array, (800, 25)
;  VDIOD:  (input)  Any appropriate template "vd" structure
;  FILTER: (input)  Array specifying the flawed pixels.  See filt6.dat, etc.
;  CF:     (input structure) observation list of template night observations
;          same structure used to drive "crank" and "wdsst"
;  DSST:   (output) Deconvolved star structure
;  INPSF  (keyword: fltarr)  input_psf is the actuall PSF
;          if invoked, this forces deconvolution to be
;          carried out with input_psf
;  INP_VDIOD  (keyword: on/off) if invoked this uses the "vdiod" as the
;	   vd to carry out the deconvolution, and ignores the cf.
;  NGRID:       

; CREATED: Sometime when Reagan was president
;

; Define paths with environmental variables.
files = getenv("DOP_FILES_DIR")

;hardwire a few values ...
c = 2.99792458d8                ;speed of who?
; len is no longer hardwired, but is read from input VD (vdiod), 15Jun98 PB
;len = 40                             ;n_elements(sp)
if 1-keyword_set(parsm) then parsm=12
osamp = 4                       ;oversampling
contlev = 4.e4                  ;assumed continuum level in obs
sz = size(template, /dim)
splen = sz[0]                   ;pixels per order
if n_elements(sz) gt 2 then nspec = sz[2] else nspec = 1
vd=vdiod  &  oldvd=vdiod
;;; JJ: Smooth the wavelengths for DSST
if keyword_set(keck) then pord = 6
jjsm_wav, vd, wc, pord=pord

vdc = vd
;Deal with both new and old style VD's
tagnam=tag_names(vdiod)                     ;VD tag_names
ordindex=first_el(where(tagnam eq 'ORDER')) ;order_index
if ordindex eq -1 then ordindex = first_el(where(tagnam eq 'ORDT')) ;ORDER or ORDT?

tagnam=tag_names(vdc)                        ;VD tag_names
ordindexc=first_el(where(tagnam eq 'ORDER')) ;order_index
if ordindexc eq -1 then ordindexc = first_el(where(tagnam eq 'ORDT')) ;ORDER or ORDT?

if n_elements(bval) ne 1 then bval=0.97 ;bvalue for Jansson deconvolution 
loord=min(vd.(ordindex))                ;minimum order
hiord=max(vd.(ordindex))                ;maximum order
imnorm=max(template(*,loord:hiord,*))   ;template normalization constant
normstar = contlev * (template/imnorm)  ;normalize template
if n_elements(sigpsf) gt 0 and n_elements(sigpsf) eq n_elements(pixpsf) then begin
    if 1-keyword_set(noprint) then print,'  Note: Using Input PSF Description!'
    psfsig=sigpsf
    psfpix=pixpsf
endif
if n_elements(label) ne 1 then label='vd' else label=strtrim(label,2)

d_pix=70  &  d_ord=3  &  orddst = 15 ;Pixel and order ranges for PSF averaging

if n_elements(keck) ne 1 then keck=0 ;KECK OBSERVATION?
if keck eq 1 then begin              ;KECK OBSERVATION?
    d_pix=100  &  d_ord=1            ;Change pixel and order ranges for PSF
     								 ; averaging
    orddst=65.
    dfn = files
    if 1-keyword_set(noprint) then $
    	 print,'Keck observation, d_pix = 100    d_ord=1 '
endif                                  ;if keck eq 1

if keyword_set(inp_vdiod) then begin
    if 1-keyword_set(noprint) then print,'Using input "VDIOD" for deconvolution' 
endif else begin
    n_vd=n_elements(cf)
    for m=0,(n_vd-1) do begin
        vdfn=dfn+label+'_'+strtrim(cf(m).obnm,2)
        restore,vdfn
        if m eq 0 then dum=vd else dum=[dum,vd]
    endfor                      
    vd=dum
endelse

last = n_elements(vdc)-1        ;index of last vd row
vdset = first_el( where(vdc.(ordindex) eq vdc(last).(ordindex) $
                        and vdc.pixt eq vdc(last).pixt) ) 
                        ;1st occurence of last chunk

n_lines = vdset+1               ;# of unique line sets
if keyword_set(index) then n_lines = n_elements(index)
;  New code to deal with arbitrary chunk sizes (40 or 50 pixel), 15Jun98, PB
len=vd(0).npix                  ;assume vd.npix are all the same
dstlen = 256                    ;for 40 pixel chunks
;if osamp eq 8 then dstlen=512   ;for osamp=8 40 pixel chunks
;if len gt 45 then dstlen=296    ;for 50 pixel chunks
;if len gt 51 then dstlen=316    ;for 55 pixel chunks
if len eq 80 then dstlen=416    ;for 80 pixel chunks

dum = {ordt:0, $
       pixt:0, $
       w0:0d, $
       w1:0d, $
       w2:0d, $
       weight:0., $
       dst:fltarr(dstlen), $
       wcof:dblarr(4) $
      }

dsst = replicate(dum,n_lines)   ;Define dsst structure, all rows
dsst.pixt = vdc[0:n_lines-1].pixt 
dsst.ordt = vdc[0:n_lines-1].(ordindex) ;set pixls,ords
xip = fillarr(0.25, -15, 15)
tlen = 100                   
if len gt 45 then tlen = 110 
if dstlen eq 416 then tlen = 140
;if dstlen eq 512 then tlen = 160
;if dstlen gt 800 then tlen = 300
xx = findgen(tlen)              ;useful array

pad = (dstlen/osamp-len)/2. ;;; Padding on end of each chunk
bigpad = (tlen - len)/2

;Stuck here. Need to figure out roles of TLEN, LEN and PAD
;There are *2* paddings. One is the padding in the final DST
;structure. The other is larger and is for the spectral segment sent
;into DECONV. The first used to be 11.75 or 12 or something. The
;second value was hardwired to be 30 and was inmplicit in the
;definition of slop. SLOP = LEN + 2*BIGPAD = LEN + 2*30

;HTI new variables
new_chisq = fltarr(n_lines)
dsst_test = dsst ; fill in with experimental version
shft_init_ang = 0.35; Ang for KOI-157
;shft_init_ang = 0.31;-0.055; Ang for KIC8410697
;shft_init_ang = 0.8 ; 12846t, 60k obs
;shft_init_ang = -0.12 ; k00072, j80 template
shft_init_ang = 0.8; Ang for KOI-351 ??? don't know which value is correct.

;;; STITCH is used in DSTITCH later to put DST together again
stitch = replicate({coef:fltarr(2), x0:0., xcont:[0.,0.]}, n_lines)

FOR n = 0, n_lines-1 do begin                 ;Cycle through chunks
    if n_elements(index) gt 0 then n=index(m) ;don't do all chuncks
    ordr=vd[n].(ordindex)                     ;order of current chunk
    place=vd[n].pixt                          ;pixel of current chunk
    ind=where(vd.pixt gt (place-2) and vd.pixt lt (place+2) $ ;;vd indices of
              and vd.(ordindex) eq ordr,nind)                 ;;same pix, ord

    vdarr = vd[ind]             ;subset of vd, at same pix,ord
    IF nind gt 2 then begin
        medfit = median(vdarr.fit)               ;median of fit
        if max(vdarr.fit) gt (1.5*medfit) then $ ;toss high fit, if too high
          vdarr = vdarr(where(vdarr.fit lt max(vdarr.fit)))
    ENDIF
    wt = float(vdarr.npix)/(vdarr.fit^2.) ;set up weigths (npix/fit^2)
    wt = wt/total(wt)                     ;normalize weights
    if n_elements(wc) gt 1 then begin
        lambda=first_el(double(poly_fat([place],wc[*,ordr]))) 
        dispersion = vd(n).wcof(1) 
    endif else begin
        ind=where(vd.(ordindex) eq vd(n).(ordindex) and vd.pixt eq vd(n).pixt)
        lambda = $ 
          double(vd(n).w0)+total(vd(ind).wcof(0)*vd(ind).fit)/total(vd(ind).fit)
        dispersion = $
          double(total(vd(ind).wcof(1)*vd(ind).fit)/total(vd(ind).fit))
    endelse

    lo = 0 > (place-bigpad)               ;lo pxl  (pixel - pad), pad used to be
    									  ; fixed to 30
    hi = (lo+tlen-1) < (splen-1)          ;hi pxl 
    if hi eq (splen-1) then lo=splen-tlen ;treat case of chunk at end
    filt=reform(filter[lo:hi,ordr])       ;filter
    prop_filt,filt,/zero                   
    filt[0:bigpad/3] = 0. 
    filt[tlen-bigpad/3:tlen-1] = 0. ;Give no weight to ends, obsolete

    xxnow = xx - bigpad         ;[pix-30,pix-29,...pix+40+30]

;;; Need to loop over each template observation, shift w.r.t. first
;;; obs. Coadd after loop
    npix = sz[0]
    specarr = fltarr(npix, nspec)
;    origarr = specarr
    sharr = fltarr(nspec)

    for k = 0, nspec-1 do begin
        spec = reform(template[*,ordr,k]) ;template, one order
;        origarr[0,k] = spec  ;;; faster to use arr[0,k] = new than arr[*,k] = new
        flspec = spec
        npad = 4
        llo = 0 > (place-npad/2*bigpad)
        hhi = (llo+tlen+npad*bigpad-1) < (splen-1)
        llo = hhi - (tlen+npad*bigpad-1)
        longspec = spec[llo:hhi]
        xq = findgen(tlen+npad*bigpad)+llo

;Straight line continuum
        cont = contnorm(longspec)
        flspec[llo:hhi] /= cont
        if k eq 0 then begin
            ref = flspec[llo:hhi] 
            specarr[0, 0] = flspec
            sharr[0] = 0
            carr = fltarr(hhi-llo+1, nspec)
            carr[0, k] = cont   ;faster than carr[*,k]
        endif else begin
            thisspec = flspec[llo:hhi]
            sh = ccpeak(thisspec, ref, ccf=ccf)
            sharr[k] = sh
            shspec = shift_interp(flspec,sh)
            quot = ref/shift_interp(thisspec, sh)
            specarr[0, k] = shspec * median(quot[1:hhi-llo-1])
            carr[0, k] = cont
        endelse 
    endfor
    if nspec gt 1 then begin
        flspec = cmapply('user:median', specarr, 2)
        cont = cmapply('user:median', carr, 2)
        thiscont = carr[*, 0]
    endif else thiscont = cont
    xcont = findgen(n_elements(cont))+llo
    stitch[n].coef = polyfit(xcont, thiscont, 1)
    stitch[n].xcont = mm(xcont)+llo

; New Geoff Marcy section to determine the velocity information in a chunk
;NOW CALCULATE THE ERROR IN THE CHUNK VELOCITY ANALYTICALLY!
;SEE EQUATION (5) IN Geoff Marcy's WRITE-UP FOR ERROR IN THE MEAN.
;SIGMA(MEAN) = 1./SQRT(SUM(1/SIG^2))
    sp   = reform(normstar[place:(place+len-1) < (splen-1),ordr])
    eps  = sqrt(sp)
    thislen = n_elements(sp)
    didp = sp(1:thislen-1) - sp(0:thislen-2) ;slope:   dI/d(pix)
    didv = didp*(lambda/(c*dispersion))      ;slope in real intensity per m/s
    dsst(n).weight = total((didv/eps)^2)     ;EQN 5 in error write up

     ;print,'Error in the Mean for the CHUNK:',sigmean

;Now back to our regularly scheduled DSST stuff
    segment = reform(flspec[lo:hi]) ;100 pixel chunk of flattened template
;Divide by Continuum
;   if not keyword_set(noflat) then cont,str,ncont else ncont=str*0.0+1.
;   if ((max(ncont)-min(ncont)) gt .3) or min(ncont) le 0 then begin
;       print,'Poor job of continuum fitting in DSST.PRO'
;       ncont=str*0.0+1.
;   endif
;   str = (str/ncont)*(1.+scat) - scat       ;reflatten, subt.scattered Lt
;   if max(str(12:tlen-13)) lt 1. then str=str/max(str(12:tlen-13)) ;make cont 1

    wseg = lambda+dispersion*xxnow ;rough wavelength scale
    wv0  = lambda-dispersion*pad

;  Making inst. prof. with next few lines
    case 1 of
        keyword_set(nodeconv): nip = 2
        keyword_set(gausspsf): begin
            if n_elements(psf) eq 0 then begin
                xip = fillarr(0.25, -15, 15)
;                psf = jjgauss(xip, [1., 0, 1.])
                if gausspsf eq 1 then wid = psfsig[0] else wid = gausspsf
                psf = jjgauss(xip, [psfsig[0], 0, wid])
                psf = psf / int_tabulated(xip, psf)
                nip = 2
            endif
        end
        else : begin ; else statement is default for Keck post-upgrade
            psfav_jj,vd,ordr,place,osamp,psf,nip $
                     , del_ord=d_ord $ ;default is 4 or 5
                     , del_pix=d_pix $ ;default is 100
                     , orddist=orddst $
                     , nodeconv=nodeconv $
                     , psfpix=psfpix $
                     , psfsig=psfsig
            if n_elements(nip) gt 0 then begin
                cond1 = ((nip lt 2) or (max(psf) le 0)) 
            endif else begin
                cond1 = 0b	
                nip = 0.
            endelse
            if cond1 and 1-keyword_set(nodeconv) then begin 
                print,'DSST: problems finding good PSF!'
                print,'DSST: increase averaging area, del_pix=100, del_ord=5'
                psfav_jj,vd,ordr,place,osamp,psf,nip $
                         , del_ord=d_ord+1 $
                         , del_pix=d_pix+60 $	
                         , psfpix=psfpix $
                         , psfsig=psfsig
            endif
            if n_elements(inpsf) gt 2 then psf=inpsf ;use "keyword" input psf
            if max(psf) le 0 then stop,'Bad PSF in DSST'
            if max(psf) eq min(psf) then stop,'Bad PSF in DSST'

        end
    endcase

    if n_elements(where(filt gt 0)) lt 20 then begin
        print,'Only '+strtrim(n_elements(where(filt gt 0)),2)+ $
              ' good pixels in this chunk, DSST.WEIGHT = -1'
        dsst(n).weight=-1
        filt=intarr(n_elements(str))*0+1
    endif

    if keyword_set(frz_cont) then begin
        if frz_cont eq 1 then frz_cont = 0.98
        cont = find_cont(wseg, segment, percentile=frz_cont)
    endif

    if 1-keyword_set(maxiter) then maxiter=15

    if keyword_set(vchi) then begin ;;;Voigt functions instead of Gaussians
        deconv_vchi, segment, psf, dspec, quiet=1, max=20, ngr=ngrid $
                     , osamp=osamp, movie=movie
    endif else begin
        deconv_chi, segment, psf, dspec, quiet=1, max=maxiter, ngr=ngrid $
                    , osamp=osamp, movie=movie, sigma=sigma
    endelse

    wspec = findgen(n_elements(dspec)) * (dispersion/float(osamp)) + min(wseg)
    px0 = (where(wspec ge wv0))[0] ;find pixel at 1st lambda
    dspec=dspec[px0:px0+dstlen-1]  ;take 1st "dstlen" osamp pixls
    wspec=wspec[px0:px0+dstlen-1]  ;corresp. wavelengths

;HTI The keyword (NSO) section is currently under construction. Beware.
    if keyword_set(nso) then begin
		;Step # 1 of NSO usage. Open and align chunk of SNO spectru,
		;	and place it on the observed wavlength scale: wspec
		rdnso,wsun,sun,min(wspec)-2,max(wspec)+2; open a chunk of nso spectrum
		;The systemic + barycentric RV is making it difficult to align
		; add 0.35 Ang for KOI-157, based on TRV = -56 km/s

		; If initial shift is added, note how to add it using shift_interp()
;		shft_init_ang = 0.35;Ang for KOI-157, now set above
		shft_init_pix = shft_init_ang / ( wspec[201] - wspec[200]) 

;		ssun     = dspline(wsun,sun,wspec);spline onto dsst wavelength scale,
		sun_shft = shift_interp(sun,shft_init_pix)
		sun = sun_shft

		nso_spl  = dspline(wsun,sun,wspec) ; spline nso onto template wav scale
		shft_pix = ccpeak(nso_spl,dspec,100) ; find the shift and align spectra
;		xcorlb, nso_spl,dspec,100,shft_pix
;		shft_pix = shft_pix * (-1.) ; xorlb and ccpeak give different signs
		nso_shft = shift_interp(nso_spl,shft_pix) ; 
		; once you have the shift, determine the new section of nso atlas to 
		;	extract, and do a more careful cross correlation
		;   This second step is essential.
		
		; shift in Angstroms = shift in pix * Ang /pix
		; By adding shft_pix_init, everything downstram should work.
		shft_ang = shft_pix * (wspec[201] - wspec[200]) +shft_init_ang ;
		shft_pix = shft_pix + shft_init_pix

		print
		print,' 1st Shift in pixels:    ', str(shft_pix-shft_init_pix)
		print,' Shift in Angstroms: ',str(shft_ang-shft_init_ang)
		; Second part of Step #1, Refine the cross correlation.
		rdnso, wsun2, sun2, min(wspec) + shft_ang  - 2, $
							max(wspec) + shft_ang  + 2
		sun2_shft = shift_interp(sun2,shft_pix)
		nso_spl2  = dspline(wsun2,sun2_shft,wspec)
		shft_pix2 = ccpeak(nso_spl2,dspec,20) ; should only be fraction of pix.
		nso_shft2 = shift_interp(nso_spl2,shft_pix2) ; 
		nso_best  = nso_shft2;Track best NSO section with this variable.
		chisq     = total((dspec-nso_best)^2) ;gauge further progress with chi^2

		shft_ang2 = shft_pix2 * (wspec[1] - wspec[0])  ; 
		print,' 2nd shift in pixels:    ', str(shft_pix2)
		print,' 2nd Shift in Angstroms: ',str(shft_ang2)
		;Plot the observed spectra and corresponding NSO section:
;		plot,wspec,dspec, Title = 'White is DSST, yellow is shifted NSO atlas'
;		oplot,wspec,nso_shft2,co=!yellow
;		wait, 0.5 ;stop
;		print,'Chisq after shifting: ' , str(chisq)

		; A third iteration is required to minimize the pour over from side
		; to side that occurs when shift_interp is calculated
		rdnso, wsun3, sun3, min(wspec) + shft_ang+shft_ang2 - 2 $
						  , max(wspec) + shft_ang+shft_ang2 + 2
		sun3_shft = shift_interp(sun3,shft_pix+shft_pix2)
		nso_spl3  = dspline(wsun3,sun3_shft,wspec)
		shft_pix3 = ccpeak(nso_spl3,dspec,10) ; should only be fraction of pix.
		nso_shft3 = shift_interp(nso_spl3,shft_pix3) ; 
		nso_best  = nso_shft3;Track best NSO section with this variable.
		chisq     = total((dspec-nso_best)^2) ;gauge further progress with chi^2
		; After third iteration, the shift is less than one pixel

		shft_ang3 = shft_pix3 * (wspec[1] - wspec[0])  ; 4 for oversampling
		print
		print,' 3nd shift in pixels:    ', str(shft_pix3)
		print,' 3nd Shift in Angstroms: ',str(shft_ang3)
		


; 		Step #2 Scale both spectra with 75% level. 
;				Change Observed, not NSO section.
		perc = 0.75		; This percentil is negotiable. 75% works pretty well.
		dspec_srt  = dspec[sort(dspec)] 
		dspec_perc = dspec_srt[perc * n_elements(dspec)]
		nso_srt    = nso_shft2[sort(nso_shft2)]
		nso_perc   = nso_srt[perc * n_elements(nso_shft2)]
		norm_fac   = dspec_perc / nso_perc; normalization factor

		; Divide the DSST by the normalization factor to get it closer to nso
		dspec_norm = dspec / norm_fac
		chisq_new  = total((dspec_norm-nso_shft2)^2) ; monitor chi^2

		if chisq_new lt chisq then begin
			dspec_best = dspec_norm ; adopt normalization correction.
			chisq      = chisq_new
		endif else begin
			dspec_best = dspec ; no change
			; chisq unchanged.
		endelse

		; Monitor chisq and plot
;		print,'Chisq after normalizing: ' , str(chisq)
;		plot,wspec,dspec_best, title='White: Scaled DSST, Yellow: NSO'
;		oplot,wspec,nso_shft2,co=!yellow
;		wait,0.5		

		; Step #3 Use rotbro.pro to broaden lines of NSO until chi2 is minimized
		; My test using rotbro performed WORSE than without rotbro, so, the 
		; default will be to leave it off.
		
		nso_in = nso_best;newspec = nso_best

		do_rotbro='no' ; change to yes for rotbro
		if do_rotbro eq 'yes' then begin
		for i=0, 5 do begin; 
				
			nso_rot = rotbro(wspec,nso_in,median(wspec),i+2) ; i+2 is Vsini
			chisq_new = total((dspec_best-nso_rot)^2)
;			spec2shift = test
			if chisq_new lt chisq then begin
				nso_best = nso_rot;overwrite if chi^2 improves
				chisq = chisq_new
				; no change to dspe_best in this step.
			endif ; if chisq is never better, nso_best and chisq are unchanged.
;			print,'Chisq after rotbro: ',str(chisq)
			plot,wspec,dspec_best, title='White: Scaled DSST, Yellow: NSO'
			oplot,wspec,nso_best,co=!yellow

		endfor
		endif ;do_rotbro
;		wait,0.5

;		Step #4a
; 		Try to add a constant, then scale by the same factor.
;		This will have the affect of making the spectral lines of the nso either
;		deeper or shallower.
;		By adding then multiplying, the continum goes down.
;		Try multiplying, then add/subtracting.
;		Also try allowing the iterationt to increast.

		dspec_in = dspec_best
		iterate  = 'yes'
		w_iter   = 0.
		new_nso  = nso_best
		print,' Chi^2 before add/subtract/scale: ',str(chisq)
		while iterate eq 'yes' do begin 
			w_iter = w_iter +1
			; Add them multiply to make lines shallower
;			nso_mod = (new_nso +0.02 *new_nso ) * 0.98
			nso_mod = (new_nso * 0.98 ) + 0.02 ; laternate formulation
;			nso_mod = (new_nso +0.05 *new_nso ) * 0.95
			chisq_new = total((dspec_best-nso_mod)^2)
			if (chisq_new lt chisq) and w_iter lt 20 then begin 
				iterate = 'yes' 
				nso_best = nso_mod
				chisq = chisq_new
				new_nso = nso_mod ; get ready for next iteration
;		  		plot,wspec,dspec_best, $
;					title="White:Scaled DSST, Yellow: scaled NSO (+)"
;				oplot,wspec,nso_best,co=!yellow
			endif else iterate = 'no'
				
			print,'w_iter= ', fix(w_iter)
			print,'Chisq after a (+) scale factor: ',str(chisq)
;			wait,0.5
		endwhile

		; Step #4b
; 		Try to subtract a constant, then scale by the same factor.
;		This will have the affect of making the spectral lines of the nso either
;		deeper or shallower.
		dspec_in = dspec_best ; no change from step 4b.
		iterate2  = 'yes'
		w_iter   = 0
		new_nso2  = nso_best
		while iterate2 eq 'yes' do begin ; Currently only scales one direction.
			w_iter = w_iter +1
			; subtracting and multiplying makes lines shallower
; 			nso_mod2 = ( new_nso2 -0.02 *new_nso2 ) * 1.02
			nso_mod2 = ( new_nso2 * 1.02 ) - 0.02 ; alternate formulation
;			nso_mod2 = (new_nso2 -0.05 *new_nso2 ) * 1.05
			chisq_new = total((dspec_best-nso_mod2)^2)
			if (chisq_new lt chisq) and w_iter lt 20 then begin 
				iterate2 = 'yes' 
				nso_best = nso_mod2
				chisq = chisq_new
				new_nso2 = nso_mod2
;		  		plot,wspec,dspec_best, $
;					title="White:Scaled DSST, Yellow: scaled NSO (-)"
;				oplot,wspec,nso_best,co=!yellow
			endif else iterate2 = 'no'
				
			print,'w_iter2= ', fix(w_iter)
			print,'Chisq after a (-) scale factor: ',str(chisq)
;			wait,0.5
		endwhile

 ; 		plot,wspec,dspec_best, $
;				title="White:Scaled DSST, Yellow: scaled NSO, ord: " $
;					 +str(dsst[n].ordt)+" pix: "+str(dsst[n].pixt)
;		oplot,wspec,nso_best,co=!yellow
				if chisq gt 5 then print,'% DSST: Chi^2 > 5, NSO rejected!'

		new_chisq[n] = chisq ; monitor progress with this variable

		dsst_test[n].dst =  nso_best
		;dsst[n].dst = dspec_best

		if new_chisq[n] lt 2 then dspec = nso_best ; OVERWRITE if chi^2 is ok.
		;sometimes the cross correlation fails, chi^2 of 5 will avoid the worst.
		if n eq n_lines-1 then $
			print,'Median of new_chisq: ', str(median(new_chisq) )
	endif ; keyword_set(nso)


;HTI The keyword (NSO) section is currently under construction. Beware.


    dsst[n].dst = dspec         ;deconv'd template!
;    xpix = makearr(140, lo, hi)
    xpix = makearr(n_elements(wseg), lo, hi)
    stitch[n].x0 = dspline(wseg, xpix, wspec[0])

     dsst[n].w1 = double(dispersion)/(double(osamp))
     dsst[n].wcof[1] = dsst[n].w1
     if keyword_set(wc) then dsst[n].w0 = wspec[0] else dsst[n].w0 = wv0
     dsst[n].wcof[0] = dsst[n].w0

;    if n_elements(lastwav) gt 0 then if dsst[n].w0 gt lastwav then stop
;    lastwav = max(dwav(dsst[n]))
    IF keyword_set(plot) then begin
        xt='Wavelength ( '+ang()+' )'
        yt='Residual Intensity'
        ttl='Order '+strtrim(ordr,2)+', Pixel '+strtrim(place,2)
        plot,wspec,dspec,/xsty,/ynoz,xtitle=xt,ytitle=yt,title=ttl,co=!white
        oplot,wseg,segment,co=!red
        oplot,wseg,segment*0.+1.,co=!green
;        wait,1
        cursor, xdum, ydum, /up
        if xdum lt !x.crange[0] then stop
    ENDIF
    IF n eq 0 and 1-keyword_set(noprint) then begin
        print,' '
        print,'                  *  CREATING DSST  *     '
        print,' '
        print,'|--------------------------------------------------------|'
        print,'| Order Pixel  Lambda   dlam/dx  Scat    SLOPE  # PSFs   |'
        print,'|               (A)     (A/pix)           SUM   avg''d    |'
        print,'|--------------------------------------------------------|'
    ENDIF
    if keyword_set(noprint) then begin
        counter, n+1, n_lines, 'Chunk # ',/timeleft,starttime=stt,/clear
    endif else begin
        fmt = '(I5,I6,F10.3,F9.5,F8.3,F8.2,I6)'
        print,format=fmt,ordr,place,lambda,dispersion,0,dsst(n).weight,nip
    endelse
ENDFOR                          ; n=0,(n_lines-1)
vd=oldvd

return
end
