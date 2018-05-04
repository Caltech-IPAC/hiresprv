pro  Stargrind, obs, dsst, vd $
                , absolute_noprint=absolute_noprint $
                , accordion=accordion $
                , avpsf=avpsf $
                , obnm=obnm $
                , day=day $
                , del_pix=del_pix $
                , del_ord=del_ord $
                , dst=dst $
                , emu=emu $
                , filter=filter $
                , fitdex=fitdex $
                , fts_atlas=fts_atlas $
                , frzpar=frzpar $
                , idepth=idepth $
                , iod=iod $
                , itest=iodtest $
                , kepler=kepler $ 
                , noprint=noprint $
                , nso=nso $
                , orddist=orddist $
                , order=order $
                , plot_key=plot_key $
                , psf_slide=psf_slide $
                , psfin=psfin $
                , psfsig=psfsig $
                , psfpix=psfpix $
                , rdsst=rdsst $
                , save_info=save_info $
                , smfts=smfts $
                , sm_wav=sm_wav $
                , starname=starname $
                , start_pixel=start_pixel $
                , start_order=start_order $
                , tellist=tellist $
                , test=test $
                , vdpsf=vdpsf $
                , vd_sacred = vd_sacred $ ; HTI added 12/2014. long term avg psf
                , vdtag=vdtag $
                , wdst=wdst 

;+
; NAME:
;		STARGRIND
; PURPOSE:
; 			Determine Specrograph PSF, Wavelength Scale, and Doppler Shifts
; 			simultaneously 
; CATEGORY:	
;			Doppler
; CALLING SEQUENCE:
;
; INPUTS:
;  OBS    fltarr      Observed spectrum (npix,nord)
;  DSST   structure   Deconvolved/Debinned Stellar Structure
;  FILTER fltarr      Array(ncol,norder) = -1 indicating "flawed" pixels
;  VD     structure   PSF param's, wavelength scale, Doppler Z
;  ORDER  scalar/array Spectral orders to be Doppler analyzed
;  FRZPAR fltarr      Vector of indices of those parameters forced to be fixed
;  FTS_ATLAS (keyword string)   FTS I2 atlas used in the analysis.
;                     Now defined as environmental variables.
;  SMFTS  float         Allows one to gaussian smooth the FTS I2 atlas.  
;                      For example: smfts=2.5  smooths the FTS I2 spectrum
;                      with a sigma=2.5 pixel gaussian prior to analysis.
;
; OPTIONAL INPUTS:
;
; OUTPUTS:  
; 		VD structure      "Best Fit" values of PSF, wavelength and Doppler Z
;
; KEYWORD PARAMETERS:
;  		/PSF      Avg. (locally) and Freeze the PSF parameters
;  		/NSO      Use the NSO as the template  (DSST is a dummy)
;  		/IOD      Fit OBS using FTS Iodine only (no star), create VDIOD
;  		/DAY      Fit OBS using NSO atlas only (no iodine)
			
;
; OUTPUTS:
;
; EXAMPLE:
;
; OPERATION:  Go through each order.  At each 40-pixel of observation
;            call STARSOLVE to fit it with a synthetic spectrum.
;
;			STARGRIND is called by VDIOD.pro when making VDIODs. Only the
;			the first pass keywords are enabled in this case.
;
;			STARGRIND is called by STARGRIND for Star + I2 spectra. Each of 
;			three passes(calls to stargrind) use different keywords to specify
;			the passes.
;			1st pass identified by frzpar[13] eq 0
;			2nd pass identifed by frzpar[13] and ~keyword_set(avpsf)
;			3rd pass identified by keyword_set(avpsf), only 2 free pars. 
 
; MODIFICATION HISTORY:
;
;
;Create:  RPB Nov. 1991
;Modify:  GM  Feb 6, 93: employ 7 little gaussians, comments in.
;Modify:  RPB Feb 8, 93: update wc's, get 0-th moment of IP, remove bugs
;Modify:  RPB Apr 27, 93: Adapted for Day-Sky test
;Modify:  RPB May 11, 93: Adapted for Standard Iodine Cell observations
;Modify:  RPB March, 94: Adapted for Keck HiRes
;Modify:  RPB April, 94: Adapted for more PSF flexibilty
;Modify:  GWM Aug 95:    Reorganized
;Modify:  RPB 1998-99:   Universal code, runs Lick, Keck, and AAT
;Modify:  RPB Dec 01:    Add wavelength based telluric filter
;Modify:  RPB Aug 02:    update wavelength based telluric filter
;Modify:  JJ Sep 05:     Nixed common blocks and replaced with INFO structure
;Modify:  HIT Sep 14:    Changed zeroth pass to use initial guess determined
;						 by Bstar averages. Central gaussian no longer varies.
;						 Only W0, disp, Z vary is zeroth pass now. 
;						 This change does not affect (not vdiods).
;Note:   HTI oct 2014	 Note: Entering the third pass, the psf parameters are 
;						averaged using psfav.pro. These averaged psfs are 
;						are passed along, but never saved. 
;
;-

act_dir = getenv("IDL_PATH_DOP_BASE") ; /home/doppler/
files_dir = getenv("DOP_FILES_DIR")
dfd = getenv("DOP_I2_ATLAS_PATH") ; FTS iodine spectrum path
static_dir = getenv("DOP_I2_ATLAS_PATH");Static files directory

if 1-keyword_set(test) then test = ''
rossiter = stregex(test, 'ross', /bool)
vdnew=vd
if keyword_set(absolute_noprint) then noprint=1
if keyword_set(test) then test = str(test)
if keyword_set(test) then if stregex(test, 'iod') ge 0 then iod=1

if n_elements(day) ne 1 then day = 0 ;Solar Spectrum or No!
if n_elements(nso) ne 1 then nso = 0 ;Solar Spectrum or No!
if n_elements(iod) ne 1 then iod = 0 ;Don't need a DSST for these cases

;TAG_NAMES - Make old and new ORDER tag_names compatible for both VD and DSST
vdnames = tag_names(vd)                    ;VD tag_names
fitdex = first_el(where(vdnames eq 'FIT')) ;VD fit index
veldex = first_el(where(vdnames eq 'VEL')) ;VD velocity index
pixdex = first_el(where(vdnames eq 'GPIX')) ;VD good pixels index
if pixdex lt 0 then pixdex = first_el(where(vdnames eq 'SP1'))
;wavdex is where updated wavelength coefficients are written
wavdex = first_el(where(vdnames eq 'WCOF')) ;VD wavelength coefficient index
;cofdex is input first guess wavelength coefficients 
cofdex = first_el(where(vdnames eq 'WCOF')) ;VD wavelength coefficient index

if keyword_set(avpsf) then begin
    fitdex = first_el(where(vdnames eq 'IFIT'))
    veldex = first_el(where(vdnames eq 'IVEL'))
    if veldex lt 0 then veldex = first_el(where(vdnames eq 'VEL'))
    wavdex = first_el(where(vdnames eq 'ICOF'))
    if wavdex lt 0 then wavdex = first_el(where(vdnames eq 'WCOF'))
endif
ordex  = first_el(where(vdnames eq 'ORDT')) ;VD template order index
if ordex lt 0 then ordex  = first_el(where(vdnames eq 'ORDER'))
orbex  = first_el(where(vdnames eq 'ORDOB')) ;VD observation order index
if orbex lt 0 then orbex  = first_el(where(vdnames eq 'ORDER'))
if nso ne 1 and iod ne 1 and day ne 1 then begin
    ordsst = first_el(where(tag_names(dsst) eq 'ORDT'))  ;DSST tag_names
    if ordsst lt 0 then ordsst = first_el(where(tag_names(dsst) eq 'ORDER')) 
    ;DSST order index
    pxdsst = first_el(where(tag_names(dsst) eq 'PIX0'))  ;DSST tag_names
    if pxdsst lt 0 then pxdsst = first_el(where(tag_names(dsst) eq 'PIXT'))  
    ;DSST order index
endif

;SET KEYWORDS and DEFAULT INPUTS
if n_elements(nso) ne 1 then nso = 0 ;Use deconv'd star
if n_elements(day) ne 1 then day = 0 ;day=1 --> sun spec only
if n_elements(iod) ne 1 then iod = 0 ;iod=1 --> iod spec only
if n_elements(fts_atlas) ne 1 then fts_atlas = '0' ;=0 --> Use Default Iodine
if n_elements(del_ord) ne 1 then del_ord=3         ;PSFAV parameters
if n_elements(del_pix) ne 1 then del_pix=75        ;PSFAV parameters
if n_elements(frzpar) eq 0 then frzpar=[-1]
if not keyword_set(plot_key) then plot_key=0
if n_elements(smfts) eq 1 then smfts=max([0,float(smfts)]) else smfts=0
if n_elements(filter) eq 0 then filter = fix(obs)*0+1 ;Default: Use all pixels
if n_elements(order) eq 0 then order= $
								 vd(uniq(vd.(orbex),sort(vd.(orbex)))).(orbex)
if n_elements(obs) eq 0 then stop,'OBSERVATION not input!'
if n_elements(dsst) eq 0 and nso eq 0 and iod eq 0 and day eq 0 then stop,'DSST not input!'
if n_elements(vd) eq 0 then stop,'VD not input!'
if ~keyword_set(vd_sacred) then vd_sacred=0

;INITIALIZE SOME CONSTANTS
c =  2.99792458d8               ;speed of who?
npix = median(vd.npix)          ;# pixels in chunk
osamp = 4
order = [fix(order)]            ;force order to be array
n_order = n_elements(order)
;length in pixels of dsst
if n_elements(dsst) gt 0 then starlen = n_elements(dsst[0].dst) 
floormat='(I4,I8,F11.5,F9.2,F6.2,F9.1,F8.2,f6.3)' ;,f6.3)' ;printing standard

;Print Unusual Intentions
if 1-keyword_set(absolute_noprint) then begin
    if nso eq 1 then print,'Using NSO Atlas as deconvolved star' 
    if iod eq 1 then print,'Fitting FTS Iodine to a PURE Iodine Obs. (no star)'
    if day eq 1 then begin
        nso=1 & print,'Fitting NSO Atlas to a Pure Day-Sky (no iodine)'
    endif
endif
;FROZEN and FLOATING PARAMETERS ESTABLISHED  
if keyword_set(avpsf) then begin
    if keyword_set(idepth) then nn = 4 else nn = 5
    if keyword_set(sine) then nn = 3
    frzpar = [frzpar,indgen(11),indgen(nn)+15] ;force psf par's frozen $
    if n_elements(vdpsf) eq 0 then vdpsf=vd    ;use vdpsf in constructing PSF
endif
if day eq 1 then frzpar = [frzpar,12] ;no Doppler shift
if iod eq 1 then frzpar = [frzpar,12] ;no Doppler shift
frzpar = frzpar(rem_dup(frzpar))      ;Remove Duplicates & Sort
;
if where(frzpar eq 13) ge 0 or keyword_set(avpsf) then begin ;frozen dispersion
    wavdex = first_el(where(vdnames eq 'ICOF'))         ;write wave cofs to icof
    if keyword_set(avpsf) then wavdex = first_el(where(vdnames eq 'SCOF'))
    if wavdex lt 0 then wavdex = first_el(where(vdnames eq 'WCOF'))
    cofdex = first_el(where(vdnames eq 'ICOF')) 
    		;get first guess wave cofs from icof
    if cofdex lt 0 then cofdex = first_el(where(vdnames eq 'WCOF'))
    fitdex = first_el(where(vdnames eq 'IFIT'))
    if keyword_set(avpsf) then fitdex = first_el(where(vdnames eq 'SFIT'))

    if fitdex lt 0 then fitdex = first_el(where(vdnames eq 'FIT'))
    veldex = first_el(where(vdnames eq 'IVEL'))
    if keyword_set(avpsf) then veldex = first_el(where(vdnames eq 'SVEL'))    
    if veldex lt 0 then veldex = first_el(where(vdnames eq 'VEL'))
endif

fltpar = indgen(20)             ;floating par's
cond = 1-keyword_set(rossiter)

remove,frzpar,fltpar            ;remove frozen from fltpar
nfltpar = n_elements(fltpar)    ;# floating parameters
req_pix = fix(nfltpar+8)        ;minimum req. good pixels


;FTS IODINE ATLAS SELECTION
if day ne 1 then begin
    iodfile = strtrim(fts_atlas,2)             ;Else Use Keyword Iod Atlas
    if 1-keyword_set(absolute_noprint) then print,'FTS Iodine Atlas: ', iodfile
endif                           ;day ne 1

;SMOOTH the FTS IODINE SPECTRUM  (testing purposes only)
IF smfts gt 0 then begin
    gausscon,findgen(100),[1.,50.,smfts],gausip
    indx = where(gausip gt 0.001*max(gausip),n_indx) ;Use only non-zero INST
    lft = max([indx(0)-1,0])                         ;1st such element
    rit = min([indx(n_indx-1)+1,99])                 ;last such element
    gausip = gausip(lft:rit)                         ;Strip the INST
    gausip = double(reverse(gausip)/total(gausip))   ;reverse and re-normalize
    if 1-keyword_set(absolute_noprint) then  $
    		print,'WARNING:  USING SMOOTHED FTS I2 SPECTRUM IN ANALYSIS!'
ENDIF

;INITIALIZE PSF Gaussian widths and positions for gpfunc.pro
ghpsf=0

IF (n_elements(sigpsf) eq 1) then if sigpsf le 0 then begin
    print,'********* GHPSF INVOKED **********'
    psfsig = -1
    psfpix = -1
    ghpsf=1
ENDIF 

;FIT Parameter Established (Chi-Sq "fit" parameter)
if iod eq 1 then begin          ;Analyze pure iodine spectrum
    vd.sfit=0. & vd.ifit=0. & vd.weight=1.
end

;DIFFERENTIAL STEPS
dstep = dblarr(20) + 0.01d0  ;  search step sizes for params
dstep[0:10] = 0.01d0         ;  Bigger PSF steps
dstep[12]  = 20.d0/c         ;  doppler Z
dstep[15:18]= 0.01d0         ;  Bigger PSF steps
q = where(fltpar eq 19, nq)
if nq eq 0 then dstep[19] = 0. ;  Unused parameter
if keyword_set(accordion) then dstep[19] = 0.1
if keyword_set(rossiter) then begin
    dstep[14] = 0.002 ;;; RM flux decrement [fractional]
    dstep[19] = 0.5   ;;; RM sub-planet velocity [m/s]
endif else begin
    w = where(frzpar eq 14, nw)
    if nw gt 0 then dstep[14] = 0 else dstep[14] = 0.001
endelse
;;JJ: DSTEPS 11 and 13 set up below...

if where(frzpar eq 13) ge 0 then dstep[13]=0.     ;frozen dispersion
if keyword_set(psf_slide) then dstep[19]= 0.002d0 ;PSF slide 

if (day eq 1) or (iod eq 1) then begin
    dstep[12] = 0.                 ;single spectrum, turn off Z
    vd.iparam[12] = 0. & vd.z = 0. ;No Doppler shift
    if 1-keyword_set(absolute_noprint) then print,'Freezing: Z = 0.0'
endif
;
;INPUT VD MODIFIED  (I., II., III.)
;I.  WAVELENGTH SCALE SMOOTHED

IF keyword_set(sm_wav) THEN BEGIN ;;JJ modified
    if n_elements(fltpar) eq 1 then vd = jjsmwav(vd,wc,pord=6) else $
      jjsm_wav,vd,wc,pord=6
END ELSE Begin
	  jjsm_wav,vd,wc,pord=6,/no_overwrite 
               ;no VD update, get coefs (WC) only
ENDELSE

; Wavelength based telluric filter
;    assumes input wavelength guess is very good
;    to better than 0.5 of a pixel, so updated that IPCF!!!!
if n_elements(tellist) ge 2 then begin
    print,'Telluric Filter Invoked'
    wavsc = obs * 0.
    tfilt = fix(filter)*0 + 1
    pix_ord = n_elements(obs(*,0)) ;number of pixels in an order
    for qq=min(order),max(order) do $
    						 wavsc(*,qq)=poly_fat(findgen(pix_ord),wc(*,qq))

    for qq=0,n_elements(tellist(0,*))-1 do begin
        badwav=where(wavsc ge tellist(0,qq) and wavsc le tellist(1,qq),nbadwav)
        if nbadwav gt 0 then begin
            tfilt(badwav) = 0
            badwav = [badwav[0]-2,badwav,badwav[nbadwav-1]+2]
        endif
    endfor
endif

vd.scat = 0.

if 1-keyword_set(absolute_noprint) then begin
    print,' '
    print, $
    '               DETERMINATION of '+strtrim(nfltpar,2)+' FREE PARAMETERS '
endif
t0 = systime(1)                 ;clock time (not cpu) in sec

if 1-keyword_set(start_order) then start_order = order[0]
;start_order=1

nchunkall = n_elements(vd)
infoarr = replicate(ptr_new(), nchunkall) ;JJ create pointer array for info structures

;HTI TEST BEGIN:
		; These need a value for every chunk, used to polish chi^2
		better = fltarr(n_elements(vd))
		chisq_test1 = fltarr(n_elements(vd))
		RV_test1 = fltarr(n_elements(vd))
		RV_diff = fltarr(n_elements(vd))
;HTI TEST END:

;, restore saved psf distributions. ;	opens as bstar_all_pars_c2_b5
restore,static_dir+'bstar_all_pars_c2_b5_jan2015.dat';[942,20,718],

FOR cur_ord = start_order, order(n_order-1) do begin ;cycle thru orders
    if 1-keyword_set(noprint) then begin
        print,' '
        print,'                         Current Order: '+strtrim(cur_ord,2)
        print, $
' ___________________________________________________________________________'
        print,' Pixl Photons  Wcen(A)   dvel/dpix Wt      CZ    Chisq   Niter'
        print, $
' ---------------------------------------------------------------------------'
    endif
                                ;VDIND and NCHUNKS
;  modification to allow Lick DSST to run Keck observation, PB 1/1/97
    if keyword_set(start_pixel) then begin
        vdind = where(vd.(orbex) eq cur_ord and vd.pixob ge start_pixel,nchunks)
    endif else vdind = where(vd.(orbex) eq cur_ord,nchunks);# of chunks in order
    if nchunks eq 0 then goto, skip ;stop,'Unable to find VD.order or VD.ordob.'

    ordob=vd[vdind[0]].(orbex)  ;observation order, not template order
    ob = reform(obs[*,ordob])   ;Observed Spectrum Chunk
    fltr = reform(filter[*,ordob]) ;filter of flawed pixels

                                ;WAVELENGTH GUESS
    wvln = poly_fat( findgen(n_elements(ob)), wc[*,ordob] )
    FOR  chunk_ind = 0,nchunks-1 do begin ;cycle thru chunks
        vdr = vd[vdind[chunk_ind]]        ;IP struct. for this region
        pix = vdr.pixob                   ;current pixel
        if chunk_ind ne (nchunks-1) then $
          mpix= vd[vdind[chunk_ind+1]].pixob-pix else $
          mpix = npix           ;npix is default
        if mpix lt 0 then mpix = npix
        if mpix gt (npix + 5) then mpix = npix ;sanity check
        vdr.npix=mpix                          ;length of chunk

        xx=findgen(mpix)
        obchunk = ob[xx + pix]  ;Observed Spectrum
        vdr.cts = long(median(obchunk))

        ;   Weights of Chunks - take into account error from flat fielding
        ;   fract_eps = sqrt( 1/N + eps_fl^2)   fract. errors added in quadrature
        ;   Guess of fractional error due to flat fielding
        eps_fl = 0.002*(1-keyword_set(emu))
        ;;; JJ changed eps_fl = 0 to get realistic chi^2 values for EMU test cases
        wt = (1./obchunk) / (1. + obchunk*eps_fl^2) ;1/sigma(DN)^2
        ;   Fix wacky values of the weight to 0
        badind = where(wt lt 0, nneg) ;Low weight (or bad) pixels
        if nneg gt 0 then wt(badind) = 0.
        badind = where(wt gt 5.*median(wt), nhi) ;max wt = 5*median(wt)
        if nhi gt 0 then wt(badind) = 0.
        ;   Use the input "filter" to establish known "bad" pixels
        dumfilt = fltr(xx + pix)
        badind = where(dumfilt le 0,nbad)
        if nbad gt 0 then wt(badind) = 0.
        ;   Useful Pixels
        good_pix = n_elements(where(wt) gt 0) ;number of good pixels in region
        vdr.(pixdex)=good_pix

        ;INITIALIZE ALL MODEL PARAMETERS: 
        ;   Also See ``INPUT VD MODIFIED'' above:  SM_WAV , median(PSF)
        par = dblarr(20)
        par[0] = psfsig[0]
        par[15:19] = vdr.iparam[15:19] ;IP parameters
        if dstep[19] gt 0 then par[19] = 1.
        if keyword_set(rossiter) then begin
            par[14] = 0.01  ;;; RM Flux decrement, initialize to 1%
            par[19] = 12.5  ;;; RM Sub-planet vel, set to 0 m/s
        endif
        par[1:10]  = vdr.iparam[1:10]         ;IP parameters
        par[11] = vdr.wcof[0]                 ;fract. part of wavel zero pt.
        if keyword_set(avpsf) and dstep[13] le 0 then par[11] = vdr.(cofdex)[0] 
        	;fract. part of wavel zero pt.

        par[12] = vdr.z                    	;doppler Z of template
        par[13] = vdr.(cofdex)[1]          	;dlambda/dpixel (dispersion)
        if keyword_set(avpsf) $
        				and vdr.(wavdex)[0] gt 0 then par(11)=vdr.(wavdex)[0]
        if keyword_set(avpsf) $
        				and vdr.(wavdex)[1] gt 0 then par(13)=vdr.(wavdex)[1]

        w0 = vdr.w0             ;Integer part of wavel zero pt.
        vdr.(fitdex) = 100.     ;Bad Fit until proven otherwise
        dstep[11]  = w0*20./c   ;  wavelength zero point
        dstep[13] =  median([1.6d-4,par[13]*0.01d0,5.d-4]) 
        	;linear dispersion coef (Ang/pxl)
        dstep[frzpar] = 0.      ; Frozen params get dstep=0

;		PSF AVERAGING of INPUT PSFs WITHIN DOMAIN:  New psf is ``PSF''
        if 1-keyword_set(psfin) then psf = 0. else psf = psfin 
        	;default: PSF not averaged, otherwise use PSFIN

		;Average PSF within domain, typically in third pass
        if keyword_set(avpsf) and 1-keyword_set(psfin) then begin 
		; The variable psf is output, sent to info, and ready by starsyn.pro
             psfav,vdpsf,cur_ord,vdr.pixob,osamp,psf $
               	, accordion=accordion $
              	, del_pix=del_pix $
               	, del_ord=del_ord $
               	, ghparam=param   $
				, kepler=kepler $                            
               	, orddist=orddist $
               	, psfsig=psfsig   $
               	, psfpix=psfpix	  
        endif

;		TOO FEW GOOD QUALITY PIXELS IN CHUNK?
        IF good_pix le req_pix and 1-keyword_set(noprint) then begin 
        	;usable pixels < Number params
            messag = '    Too few ('+strtrim(good_pix,2)+') useable pixels.'
            print,format = '(I7,I7,A40)',cur_ord,fix(pix),messag
            vdr.fit = 100.      ;fit=100 when NO FIT occured
            lastchi = 100
        END

;		FTS Iodine spectrum 
		wavobs = dindgen(mpix)*par[13]+wvln[pix]
        wrng = [wavobs[0]-1.5, max(wavobs)+1.5] ;Observed wavel range

        if wrng[0] lt 5000 or wrng[1] gt 6400 then stop,'Obs Wav-Range Bad'
        IF day ne 1 then begin
;			read FTS Iodine

            rdfts,wiod,siod1,wrng[0],wrng[1],dfn=iodfile,dfd=dfd $
                  , cwiod=cwiod, csiod=csiod
            if keyword_set(iodtest) then begin
                old = siod1
                xiip = fillarr(1, -10, 10)
                iip = jjgauss(xiip, [1,0,3,0])
                iip /= int_tabulated(xiip,iip)
                num_conv, siod1, iip, newsiod1
                siod1 = newsiod1
            endif
            if smfts gt 0 then begin ;smoothing FTS I2 atlas
                r_conv,siod,gausip,dum  &  siod=dum 
            endif
            siod = siod1/max(siod1) ;normalise FTS
        ENDIF                   ;day ne 1 

;		Star Spectrum (deconvolved star or solar nso atlas)
        IF nso ne 1 and iod ne 1 then begin ;use the DSST as the template star
;  			modification to allow Lick DSST to run Keck observation, PB 1/1/97
            i = (where(dsst.(ordsst) eq vdr.ordt $
            		and dsst.(pxdsst) eq vdr.pixt, n))[0]
            if n eq 0 then begin
                i = first_el(where(dsst.(ordsst) eq vdr.ordob $
                				and dsst.(pxdsst) eq vdr.pixob, n))
            endif
            wstar = dindgen(starlen)*dsst[i].w1 + dsst[i].w0 
            			;wstar is the star wavelength scale
            sstar = dsst[i].dst  ;sstar is the template star spectrum
            if keyword_set(rossiter) then begin
                rmspec = rdsst[i].dst
                rmwav  = dindgen(starlen)*rdsst[i].w1 + rdsst[i].w0 
                		;RM sub-planet wavelength scale
            endif
        END

        IF nso eq 1 then begin  ;use NSO as template star
            vactoair,wrng       ;NSO has air wavelengths
            rdnso,wstar,sstar,wrng(0),wrng(1) ;get NSO
            airtovac,wstar                    ;convert NSO wavels to vacuum
            sstar = sstar/max(sstar)          ;normalise NSO
        END
;
        IF day eq 1 then begin  ;day sky, no I2
            wiod = wstar        ;fake an Iod wavelength scale
            siod = sstar*0.+1.  ;fake an Iod Spectrum (equal to unity)
        ENDIF    
;
        IF iod eq 1 then begin  ;pure I2, no star
            vd.sfit = 0.  &  vd.ifit = 0.  &  vd.weight = 1.
            wstar = wiod        ;fake a star spectrum
            sstar = siod*0.+1.  ;  equal to unity
        ENDIF

		;STARSOLVE
        oldpar=par
        info = {obchunk: obchunk, $
                wiod:    wiod, $ ; iodine wavelength scale
                siod:    siod, $
                wstar:   wstar, $ ; stellar wavelength scale, from dsst
                sstar:   sstar, $ ; stellar flux, dsst chunk
                w0:      w0,    $
                psf:     psf, $
                par:     par,   $
                osamp:   osamp, $
                wt:      wt,    $
                dstep:   dstep, $
                nfltpar: nfltpar, $
                fltpar:  fltpar, $
                keck:    1, $
                c:       c, $
                psfsig:  psfsig, $
                psfpix:  psfpix, $
                obpix:   npix, $
                order:   vdr.ordob, $
                pixel:   vdr.pixob, $
                noprint: keyword_set(noprint), $
                test:    keyword_set(test) ? test : '', $
                accordion: keyword_set(accordion), $
                rmspec: keyword_set(rmspec) ? rmspec : 0, $
                rmwav: keyword_set(rmwav) ? rmwav : 0 $ ; hti removed vd_sacred because vds  were crashing
;				vd_sacred:   vd_sacred[*,vdind[chunk_ind]] $ ; HTI added 12/2014
               }		; vd_sacred should be a 20 element array
        q = where(fltpar eq 13, nq)
        cond =  1-keyword_set(avpsf) and nq gt 0 

        ;;; JJ Prefit step. Freeze PSF symmetry, allow PSF width, WLS and Z to
        ;;; float to establish refined initial guesses.
        ;	HTI modified this to freeze central gaussian, but fill psf pars with
        ; the long term average of those pars, determined by Bstar obs, instead of zero.
        ;	Bstar calculation not affected.
        if cond then begin 
            tdstep = dstep
            if keyword_set(iod) then begin
              	tfltpar = [0, 11, 13]  ;central gaussian, w0, disp.
				rem = [indgen(10)+1,12,indgen(6)+14]
		        tdstep[0]= .1;HTI ADDED
            endif else begin ; regular star + i2
				tfltpar=[11,12,13]
                rem = [0,indgen(10)+1, indgen(6)+14] ;HTI.IN 
		   endelse

            tdstep[rem] = 0
;HTI out    tdstep[0] = 0.1 ;HTI IS THIS CORRECT?
            xpsf = fillarr(0.25, -15, 15)
            tpsf = jjgauss(xpsf, [1., 0, 1.5], /norm)
            tpar = par

            tinfo = {obchunk: obchunk, $
                     wiod:    wiod, $
                     siod:    siod, $
                     wstar:   wstar, $
                     sstar:   sstar, $
                     w0:      w0,    $
                     psf:     psf, $
                     par:     tpar,   $
                     osamp:   osamp, $
                     wt:      wt,    $
                     dstep:   tdstep, $
                     nfltpar: n_elements(tfltpar), $
                     fltpar:  tfltpar, $
                     keck:    1, $
                     c:       c, $
                     psfsig:  psfsig, $
                     psfpix:  psfpix, $
                     obpix:   npix, $
                     order:   vdr.ordob, $
                     pixel:   vdr.pixob, $
                     param:   1, $
                     noprint: keyword_set(noprint), $
                     test:    '', $
                     accordion: keyword_set(accordion), $
                     rmspec: keyword_set(rmspec) ? rmspec : 0, $
                     rmwav: keyword_set(rmwav) ? rmwav : 0 $
                    }
            modpar = starsolve(tinfo)
			; HTI 9/2014, pass ALL parameters from zeroth to first pass
;            info.par[11:13] = modpar[11:13] ; HTI OUT, pass only w0,disp,Z
			if keyword_set(iod) then info.par[11:13] = modpar[11:13] $;HTI IN
				else info.par = modpar 				 ; HTI IN
        endif else modpar = par	; second/third pass

        ;;; Find parameters by Chi-Sq
        if n_elements(fltpar) gt 1 then begin ;; use L-M
            oldpar = par

            par = starsolve(info,sigpar,chi,niter $
                            , plot=plot_key $
                            , fit=yfit $
                            , ghparam=param $
                            , resid=resid $
                            , accordion=accordion)
        endif else begin ;JJ: Use brute-force grid search for one free parameter
            par[12] = zchi_grid(info, 20, fracz=0.0075, chi=chi)
            if chi gt 10 then chi = 99
            niter = 20
            nochauv = 1
        endelse

        ;;; JJ: store info structure
        info.par = par
        infoarr[vdind[chunk_ind]] = ptr_new(info)
        ;;; JJ Outlier rejection
        if chi lt 10 and 1-keyword_set(nochauv) then begin
            nt = 1
            good = chauvenet(resid, nreject=nrej, reject=bad, /iterate)
            if nrej gt 0 then cool = 0 else cool = 1
            while not cool do begin
                if 1-keyword_set(noprint) then print, nrej, chi
                info.wt[bad] = 0
                info.par = oldpar
                info.par[11:14] = modpar[11:14]
                par = starsolve(info,sigpar,chi,niter $
                                , plot=plot_key $
                                , fit=yfit $
                                , ghparam=param $
                                , resid=resid) 
                nt++
                resid[bad] = 0
                good = chauvenet(resid, nreject=nrej, reject=newbad, /iterate)
                bad = [bad, newbad]
                if nrej gt 0 and nt lt 4 then cool = 0 else cool = 1
            endwhile
        endif

        if n_elements(niter) eq 0 then niter=0
        if (chi ge 100) and (chunk_ind gt 0) $
        				and (good_pix gt (nfltpar+10)) then begin
            if vd_last.(fitdex) lt 3 then begin
                new_w=double(vd_last.w0)+double(vd_last.wcof(0))
                new_w=new_w+double(vdr.pixob-vd_last.pixob)*vd_last.wcof(1)
                vdr.w0=fix(new_w)
                vdr.wcof(0)=new_w-vdr.w0
                vdr.wcof(1)=vd_last.wcof(1)
                info.par=oldpar
                info.par(11)=vdr.wcof(0)
                info.par(13)=vdr.wcof(1)
                if 1-keyword_set(noprint) then $
                  print,'******  Attempting to Recover from Bad Fit  ******'
                y=starsolve(info, sigpar,chi,niter,ghparam=param)
            endif
        endif

;		Store All Floating parameters
        vdr.iparam[fltpar] = par[fltpar]
        vdr.sfit = 100.
        vdr.sp2=niter           ;number of iterations

;		Store Chi-Sq fit
        vdr.(fitdex) = chi
;		Store WAVELENGTH Zero Pt.
        w0obs = double(info.w0) + par[11]
        dispobs = par(13)                      ;dispersion, dlambda/dpix
        wavobs = dindgen(npix)*dispobs + w0obs ;wavelength scale of obs
;		Update integer wavelength only for 1st pass
        if 1-keyword_set(avpsf) and dstep(13) gt 0 then vdr.w0 = fix(w0obs)
        vdr.(wavdex)(0) = w0obs - vdr.w0
        vdr.iparam(11) = vdr.(wavdex)(0)

;		Store NEW VELOCITY !
        if dstep(12) gt 0. then begin
            vdr.z = par[12]
            vdr.(veldex)  = double(vdr.z) * c 
        end

;		Store DISPERSION/Polynomial coefficients
        if dstep[13] gt 0. then vdr.(wavdex)[1] = par[13]
;        if dstep[14] gt 0. then vdr.(wavdex)[2] = par[14] ;
; 			JJ quadratic WLS, commented out for scattered light test

;		PRINT RESULTS
        wavcen = wavobs[npix/2]
        prntwav = wavcen

        if n_elements(w0obs) eq 0 then w0obs = double(w0) + par[11]
        if 1-keyword_set(noprint) then print, FORMAT=floormat, $
          fix(pix),vdr.cts,prntwav,c*par(13)/w0obs, $
          1,vdr.vel,chi,par[14];fix(niter) ;systime(1)-t0
        t0 = systime(1)            ;mark current time 

        vdnew[vdind[chunk_ind]] = vdr ;ANSWERS STORED
        vd_last=vdr
        skip:
    ENDFOR                      ; numchunks loop  
ENDFOR                          ; order loop

;;; JJ save info structure array
;if keyword_set(avpsf) eq 1 then stop ; HTI for testing
if keyword_set(save_info) then $
	save, infoarr, file=files_dir+'info'+vdtag+starname+'_'+obnm

for i = 0, nchunkall-1 do ptr_free, infoarr[i]
vd=vdnew
if n_elements(cwiod) gt 0 then ptr_free, cwiod
if n_elements(csiod) gt 0 then ptr_free, csiod

end
