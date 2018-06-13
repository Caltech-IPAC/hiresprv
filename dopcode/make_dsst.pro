pro make_dsst, star, dtag, run $
               , atlas=atlas $
               , b1=b1 $
               , bval=bval $
               , c2ok = c2ok $
               , d5=d5 $
               , dtcrit=dtcrit $
			   , nodeconv=nodeconv $
			   , gausspsf=gausspsf $
               , jjhip=jjhip $
               , maxchi=maxchi_in $
               , makestitch=makestitch $
               , maxiter=maxiter_in $
               , medium=medium $
               , movie=movie $
               , narrow=narrow $
               , nbstars=nbstars $
               , new_deconv=new_deconv $
               , ngrid=ngrid $
               , nostitch=nostitch $
               , nso=nso $
               , outfile=outfile $
               , obnm=obnm $ ;potentially conflicting with specin
               , parsm=parsm $
               , plot=plot $
               , psfin=psfin $
               , sigma=sigma $
               , specin=specin $
               , tape=tape $
               , vchi=vchi $
               , vdarr=vdarr $
               , vdtag=vdtag 

; Creation: Likely before you were born.
; Update;HTI 6/2014 All instances of calls to /o/johnjohn changed to /o/doppler
;					All routines in doppler code now isolate to doppler account
;					at UCB.
;UPDATE: HTI 10/2014 variable ngrid is not properly specified for Kepler stars.
;		 formerly, hip.dat was searched for the value of B-V. Now, if the hip
;		structure does not have the star, the Keck structure is searched.
;       HTI 10/2014. Now 6 bookend Bstars are required unless VDARR is used
;		HTI 1/2014. Search for high intensity cosmic rays and remove them.
;       HTI 1/2018. Added c2ok keyword. Allows creation of dsst with c2 decker.

;	KEYWORDS: 	NGRID: determined by B-V color of the star
; Example: make_dsst,'k00116','ha','rj97', vdtag='ha'
;
;  todo: move jjhip_v2 to a data directory.

; Example of how to specify Bstars with keyword vdarr:
; Notes on running DSST's  for two recon style spectra: 
; rj275.119          EPIC248777106   29258.909 18066.080424  -3.510 t   TEMPLATE
; rj275.63                  HR7446       0.000 18065.676586   0.000 o   BSTAR1
; rj275.145                 HR3799       0.000 18066.165000   0.000 o   BSTAR2
; First make vdiods from the Bstars at the beginning and end of the night:
; IDL> make_vdiod,'rj275.63',run='ad'
; IDL> make_vdiod,'rj275.126',run='ad'
; 
; Next use the vdarr keyword in the make_dsst.pro call:
; IDL>  f1 = dir+'vdiod3799_rj275.145.ad
; IDL> restore,f1
; IDL> vd1=vd
; IDL>  f2 = dir+'vdiod7446_rj275.63.ad
; IDL> restore,f2                              
; IDL> vdarr=[vd1,vd]
; IDL> make_dsst,'EPIC248777106','ad','rj275',vdarr=vdarr

; Setup IDL PATHS FROM .BASHRC
path_dop = getenv("IDL_PATH_DOP")
!path = path_dop

act_dir = getenv("IDL_PATH_DOP_BASE") ; /home/doppler/ 
baryfile = getenv("DOP_BARYFILE")
files = getenv("DOP_FILES_DIR")
vel_dir = getenv("DOP_RV_OUTDIR")
iodfitsdb_dir = getenv("DOP_SPEC_DB_DIR") 
iodspec=getenv("DOP_SPEC_DIR")
jjhip_file = getenv("DOP_JJHIP")
 
keck2 =1 ; default for down stream data products
 
if ~keyword_set(star) then begin
	print,'make_dsst.pro, syntax error: >make_dsst,star,tag,run,vdtag=vdtag'
	return
endif
 
t = strmid(run,0,2)
new = 1 ;;; NEW is the new default. Use chi^2 deconvolution scheme


;;; 2/22/2010 JAJ: DSSTINFO structure stored in dsstpath for use in dop_driver
;					Dsstinfo also helpful for diagnostics.
dsstinfo = {obnm:'' $
            , run:run $
            , decker:'' $
            , psfpix:fltarr(15) $
            , psfsig:fltarr(15) $
            , bstar:'' $
            , dt: [0., 0.] $
            , ngrid:0 $
            , maxiter: 0 }

if 1-keyword_set(ngrid) then begin
	if n_elements(jjhip) eq 0 then restore,jjhip_file
    star = strlowcase(star)
    if strmid(star,0,3) eq 'hip' then begin
        num = strmid(star,3,20)
        let = where(stregex(num, '[a-b]', /bool), nlet)
        if nlet gt 0 then num = strmid(num, 0, strlen(num)-1)
        w = where(jjhip.num eq num, nw)
    endif else begin
        num = star
        let = where(stregex(num, '[a-b]', /bool), nlet)
        if nlet gt 0 then num = strmid(num, 0, strlen(num)-1)
        w = where(jjhip.hd eq num, nw)
    endelse
    if nw gt 0 then bv = jjhip[w].bv ; HTI 20/2014 moved from below

    if nw gt 0 then begin
        case 1 of 
            bv gt 0.9: begin
                ngrid = 80
                maxiter = 25
            end
            bv gt 0.8 and bv le 0.9: begin
                ngrid = 70
                maxiter = 25
            end
            bv gt 0.7 and bv le 0.8: begin
                ngrid = 60
                maxiter = 20
            end
            bv gt 0.6 and bv le 0.7: begin
                ngrid = 50
                maxiter = 20
            end
            else: begin
                ngrid = 40
                maxiter = 15
            end
        endcase
    endif else begin
        if strmid(star,0,2) eq 'gl' then ngrid = 80 else ngrid = 50
    endelse
endif
dsstinfo.ngrid = ngrid
if keyword_set(maxiter_in) then begin
    dsstinfo.maxiter = maxiter_in
    maxiter = maxiter_in
endif

if keyword_set(b1) then maxchi = 1.4 else maxchi = 1.3

if keyword_set(maxchi_in) then maxchi=maxchi_in

; Check to make sure NOT to overwrite a previously good DSST. 
;	If obs is B5/C2 and no iodine, AND previous B1/B3 DSST exists, then 
;   simply return without calculating new dsst. (infinite loop?)
print,'MAKE_DSST.PRO: '
print,'  Templates obs for DSST creation:'
; lines will print with barylook call.

barylook, star $  ; This call to barylook replaces 4 old calls below.
		,lines = lines $
		, grep = run $
		, /temp

;;; Use barylook to find template observations, grep = run
if keyword_set(specin) then begin
    spec = specin
endif else begin
    print, 'Template Observations for '+star
    if keyword_set(obnm) then begin
        nel = n_elements(obnm)
        for i = 0, nel-1 do begin
            spawn, 'grep " '+obnm+' " '+baryfile, lines
            rdsi, s, obnm[i]
            if i eq 0 then spec = s else spec = [[[spec]],[[s]]]
				rdsk,header,iodspec+obnm[i],2
            decker = str(fxpar(header,'DECKNAME'))
        endfor
            if decker eq 'B5' or decker eq 'C2' then begin
                b5 = 1
                print
                print, 'Using PSF model for B5 Decker'
                print
            endif else b5 = 0
            if decker eq 'B1' or decker eq 'B3' then begin
                b1 = 1 
                print
                print, 'Using PSF model for B1 Decker'
                print
            endif else b1 = 0
            if decker eq 'E2' then begin
                narrow = 1 
                print
                print, 'Using PSF model for E2 Decker, /narrow'
                print
            endif else narrow = 0
    endif else begin ; else is for obnm keyword NOT set.
        if n_elements(lines) gt 10 then lines = lines[0:10]
        tape = str(strmid(lines[0], 0, 20))
        ;;; Send lines to JJ_ADDSPEC
        if lines[0] eq '' then begin
            print, 'No template observation found for '+str(star)
            return
        endif
        if keyword_set(keck2) then begin
            rdsk, header, iodspec+str(strmid(lines[0], 0, 20)), 2
            decker = str(fxpar(header,'DECKNAME'))
            if decker eq 'B5' or decker eq 'C2' then begin
                b5 = 1
                print
                print, 'Using PSF model for B5 Decker'
                print
            endif else b5 = 0
            if decker eq 'B1' or decker eq 'B3' then begin
                b1 = 1 
                print
                print, 'Using PSF model for B1 Decker'
                print
            endif else b1 = 0
            if decker eq 'E2' then begin
                narrow = 1 
                print
                print, 'Using PSF model for E2 Decker, /narrow'
                print
            endif else narrow = 0
        endif
        if n_elements(lines) gt 1 then begin
				; if consecutive observations were taken, add them together.
            spec = jj_addspec(lines, bc=bc, /noadd)
        endif else begin
            obnm = str(strmid(lines, 0, 20))
            rdsi, spec, obnm
        endelse ; n_elements(lines) gt 1
    endelse 
endelse

;HTI begin change made Jan 2015 to thoroughly remove cosmic rays.
; 	Open the continuum normalized spectrum to identify cosmic rays.

if keyword_set(obnm) then tape = obnm ; HTI Jan 2015, fix for obnm keyword
file_check = file_search(iodfitsdb_dir+tape+'.fits',count=nf) 
flat_spec = readfits(file_check[0])*2.19 ; de-blazed stellar spectrum * gain
									; multiplying by gain is slightly wrong.
									; because the spec has already been 
									; deblazed.
; obnm keyword is not compatible with multiple back to back exposures.

nord = n_elements(flat_spec[0,*]) ; n orders
npix = n_elements(flat_spec[*,0]) ; pix per order
spec_in = spec 					; preserve input spec
num_fixed = 0 					; initialze

for i1 = 0, nord-1 do begin		; Loop over each order

 isrt = sort(flat_spec[*,i1]) ; sort flux pixels
 sorted = flat_spec[isrt,i1]	
 val95 = sorted[npix*0.95] 		; 95th % flux value for the order.
 
 thresh = 1.2 ; 1.3 times normalized flux.
 ifix = where(flat_spec[*,i1] gt thresh*val95,nifix) ; position of pixels with flux 
 						
 if nifix gt 0 then begin
	for i2=0,nifix-1 do begin	; loop over each bad pixel.
	 if ifix[i2] gt 21 and ifix[i2] lt 4000 then begin
		newval = median(spec_in[ifix[i2]-20:ifix[i2]+20,i1])	
 		spec[ifix[i2],i1] = newval
		num_fixed = num_fixed+1		
		; replace cosmic ray with median of 20 pix on either side.
		plotme=0
		if plotme eq 1 then begin
			plot,spec_in[*,i1],/xsty,xtit='Pixel #', Ytit=' Flux ' , $
				Title=' Corrected pixels are marked in red',/nodata

			oplot,spec_in[*,i1],co=!red
			oplot,spec[*,i1]
			oplot,intarr(npix) + val95*thresh 	;; overplot the threshold
			if i2 eq nifix-1 then stop
		endif ; plotme

	 endif ; ifix 
	endfor ;over i2

 endif

endfor
print,' MAKE_DSST: Cosmic rays fixed: ',str(num_fixed)
;HTI end code to remove cosmic rays, change made January2015

if n_elements(obnm) gt 0 then dsstinfo.obnm = strjoin(obnm,', ')
if n_elements(lines) gt 0 then begin
    obnm = str(strmid(lines,0,20))
    dsstinfo.obnm = strjoin(obnm,', ')
endif

if n_elements(decker) gt 0 then dsstinfo.decker = decker

;;; grep for HR obs during that run to find nearby Bstar/iodines
spawn, 'grep -i hr '+baryfile+' | grep '+run+' | grep o', hrlines
;;; parse and find closest bstars within Delta_t of observation
if 1-keyword_set(vdarr) then begin
    nl = n_elements(hrlines)
    btime = dblarr(nl)
    bdeck = strarr(nl)
    if keyword_set(keck2) then begin
        for i = 0, nl-1 do begin
            parts = str(strsplit(hrlines[i], ' ', /ext))
            btime[i] = double(parts[3])
            obnm = parts[0]
            rdsk, h, iodspec+obnm, 2
            bdeck[i] = str(fxpar(h, 'DECKNAME'))
        endfor
    endif
    otime = double((strsplit(lines[0], ' ', /ext))[3])

    dt = abs(otime - btime)
    cool = 0b
    if 1-keyword_set(dtcrit) then dtcrit = 0.25/24 ; was 0.5
	counter =  0
    while not cool do begin
		counter = 1+counter
        u = where(dt lt dtcrit, nvd)

		; Assume that all templates have bookend Bstars, replace above line
        if nvd lt 6 then dtcrit += 0.05/24 else cool = 1b
		;Some DSSTs only have 3 bstars, if you searched, the make 3 be okay.
		if nvd ge 3 and nvd lt 6 and dtcrit gt 2/24. then cool =1b 
        if nvd ge 1  and keyword_set(c2ok) then cool = 1b
        if nvd eq 3 and star eq '62613' then cool = 1b ;KUDGE
		if counter eq 12  and ~keyword_set(c2ok) then begin ; make sure no endless loop
			print,'MAKE_DSST.PRO: No Bstars found for star, obs',star,'  ',tape
			print,'Returning...'
			return
		endif
    endwhile
    hrlines = hrlines[u]
    dtm = dt*24*60.
    dsstinfo.dt = [min(dtm[u]), max(dtm[u])]
endif
if keyword_set(nbstars) then begin
    hrlines = hrlines[0:nbstars-1]
    nvd = nbstars
endif
;;; loop through and find only good fits chi^2 < 1.6 and build vdarr
;;; array
if 1-keyword_set(vdarr) then begin
    print,'Restoring VDIODS:'
        forp, hrlines
        if keyword_set(vdtag) then vtag = vdtag else vtag = 'ac'
        if keyword_set(quawav) then vtag = 'q'
        for i = 0, nvd-1 do begin
            bname = str(strmid(hrlines[i], 0, 20))
            cmd = 'ls '+files+'vdiod*'+bname+'.'+vtag
            spawn, cmd, result
            vobnm = bname
            if result eq '' then begin
                print,'Creating VDIOD for '+vobnm
                make_vdiod, vobnm, tag=vtag $
                			, /nopr $
                			, vdout=vd $
                            , /absolute_noprint $
                            , narrow=narrow $
                            , b1=b1 $
                            , atlas=atlas $
                            , d5=d5
            endif else restore, result ; if it exist, open it.
            tags = tag_names(vd)
            fitindex = where(stregex(tags,'fit3',/bool,/fold), nw)
			if i eq 0 then print,'VD name,      Chi^2'
			; open bstar header, check that bstar decker matches template decker
				rdsk,bhead,iodspec+bname,2 
				bdecker = str(sxpar(bhead,'DECKNAME'))
				if ~keyword_set(obnm) then begin ;do not check if obnm is input.
				if bdecker ne decker then begin
					print,'Bstar decker does not match template decker'
					print,'Template decker: ', decker
					print,'Bstar decker:    ', bdecker
					return				
				endif
				endif ; keyword_set(obnm); patch to decker checking section

            print, result+'   '+sigfig(median(vd.fit), 3)
            if i eq 0 then nel = n_elements(vd) 
            if n_elements(vd) eq nel and median(vd.fit) lt maxchi then begin
                if n_elements(vdarr) eq 0 then begin
                    vdarr = vd 
                    dsstinfo.bstar += vobnm
                endif else begin
                    vdarr = [vdarr, vd]
                    dsstinfo.bstar += ', '+vobnm
                endelse
            endif
        endfor
endif else begin
 print,'% MAKE_DSST: Using user specified VDIODS.' ;
 print,'% MAKE_DSST: Default decker is B5, unless keyword /B1 is set'
 wait,1
endelse

;;; Send everything to DSST
getpsf, psfpix, psfsig $
        , b1=b1         $
        , d5=d5			$
		, keck2=keck2  $
        , narrow=narrow $ ; narrow is for E2 decker 
        , prekeck=prekeck 

if keyword_set(dsstinfo) then begin
    dsstinfo.psfpix = psfpix
    dsstinfo.psfsig = psfsig
endif
print,'Creating DSST:'
if 1-keyword_set(bval) then bval = 1.0
if keyword_set(movie) then setcolors,/sys
if keyword_set(psfin) then psf = psfin

; Call dsst.pro to do the deconvolution for every chunk. Spec is the input 
;	observed spectrum.
dsst, spec, vdarr, spec*0+1, cfout, dsst $ 
	  ,	stitch=stitch $
      , /inp_vd  $
      , keck=keck2 $
      , pixpsf=psfpix $
      , sigpsf=psfsig $
      , /nopr $
      , nodec=nodeconv $
      , gausspsf=gausspsf $
      , bval=bval $
      , plot=plot $
      , new_deconv=new_deconv $
      , movie=movie $
      , ngrid=ngrid $
      , nso=nso $
      , parsm=parsm $
      , maxiter=maxiter $
      , vchi=vchi $
      , inpsf=psf $
      , sigma=sigma 

if 1-keyword_set(outfile) then $
  outfile = files+'dsst'+strlowcase(star)+dtag+'_'+run+'.dat'
cond = keyword_set(keck2) or keyword_set(prekeck) or keyword_set(makestitch)
cond = cond and 1-keyword_set(nostitch) 

if cond then begin
    sdst = dstitch(dsst, stitch, wav=sdstwav)
    save,dsst,sdst,sdstwav,stitch,dsstinfo,file=outfile
endif else save, dsst, file=outfile
print, 'Wrote: '+outfile
print, "completed successfully"

end

