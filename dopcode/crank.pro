pro crank,dsst,cfst 		$
          	, absolute_noprint=absolute_noprint $
          	, accordion=accordion $
          	, allkeck=allkeck 		$
          	, avpsf=avpsf	$
          	, dst=dst			$
          	, frzdisp=frzdisp 		$	
          	, frzw0=frzw0 			$
          	, fts_atlas=fts_atlas $
          	, gausspsf=gausspsf		$
          	, idepth=idepth		$
          	, inplab=inplab $
          	, itest=iodtest 	$	
          	, kepler=kepler     $
          	, label=label	$
          	, nik=nik			$
          	, nso=nso		$
          	, noprint=noprint		$
          	, nopsf=nopsf	$
          	, noscat=noscat,frzpar=frzparin $
          	, notelluric=notelluric $
          	, plot_key=plot_key	$
          	, psfin=psfin 		$
          	, psfsig=psfsig	$
          	, psfpix=psfpix	$
          	, rossiter=rossiter		$
          	, save_info=save_info $
          	, smfts=smfts 	$
          	, starname=starname $
          	, start_ord=start_ord	$
          	, start_pix=start_pix $
          	, tellist=tellist 		$
          	, test=test 			$ 
          	, variable=variable		$
          	, vdtag=vdtag		$
          	, wdst=wdst			

;+
; NAME:
;		CRANK
; PURPOSE:
;		Drive the psf and RV analysis, mostly be setting up and calling
;		stargrind
; CATEGORY:	
;			Doppler
; CALLING SEQUENCE:
;
; INPUTS:
;		dsst (input structure) This is the deconvolved, debinned template
;                             star structure
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;		/avpsf     The "avpsf" keyword tells the code to "freeze"
;			      the "point-spread-function".  The code
;			      only allows the "non-psf" parameters
;			      to float.  If the "psf" keyword is
;			      invoked, a previous "vd" guess for
;			      the observation must exist on the disk.
;		/nso  		For use with day sky tests.  Invoking the
;		            "nso" keyword forces the code to use
;		            the NSO atlas as the stellar template.
;		            If the "nso" keyword is called, the dsst becomes a dummy.
;		/nopsf		No PSF for this observation(typically very low S/N case)
;                   use default PSF information (from other observations)
;                   The /avpsf keyword is automatically invoked
;		/variable  Variable Star, can not use BC as input guess for Z
;                           first guess Z found from new "guess_z"  Feb '96 RPB 
;		/notelluric Don't use telluric filter if this is invoked
;
; OUTPUTS:
;		cf   Not needed!  Structure of observations, etc ...
;
; EXAMPLE:
;       Only called from dop_driver.pro. No longer stand alone program.
;
; MODIFICATION HISTORY:
;
;	Created May 8 - 11, 1993  R.P.B.
;   and regularly recreated thereafter, May - August 1993  R.P.B., RIP
;   Fixed small "rk1" Keck problem, 12 Nov 1996, R.P.B.
;   HTI 6/2014,Updated the program so that it works on astro account: 'doppler'
;               isolating all sub-routines and paths to doppler account.
;   HTI 9/2014, established initial guess of psf pars as long term average psf
;               pars, determined by Bstars taken from 2009-2014.
;               Also, now passing pass #1 psf pars into second pass.
;               Formerly, they were being set back to zero after 1st pass.
;               This program is not called by make_vdiod.pro
;
;  todo: change anyfile linked to act_dir to an environmental variable.
;-

;act_dir = '/data/user/doppler/berkeley_homedir/'
act_dir = getenv("IDL_PATH_DOP_BASE") ;

; Files outside path_dop are defined in .cshrc environment:
; Files outside path_dop are defined in .cshrc environment:
files = getenv("DOP_FILES_DIR")
vel_dir = getenv("DOP_RV_OUTDIR")
fa = getenv("DOP_I2_ATLAS") ; FTS iodine spectrum
atlas_dir =getenv("DOP_I2_ATLAS_PATH")
static_dir = getenv("DOP_I2_ATLAS_PATH")

frzpar = frzparin ;;;JJ: protect FZ
cf=cfst
vdiod=0                         ;initially no "fallback" pure quartz Iodine VD
;                               ;    (not a B*/I2)
telesc=strmid(cf(0).obnm,0,2)

; Default for all post-upgrade observaitons
del_ord=1               ;PSF averaging domain for HIRES
del_pix=175             ;PSF averaging domain for HIRES
orddst=130.             ; order distance for Keck
ftsdfn= fa

if 1-keyword_set(absolute_noprint) then begin
    print,'**** Keck Observations ****'
    print,'*** HARDWIRED: Keck Post-Fix PSF description ***'
endif

;List of initial guess VD files. opens as ipguess
 restore,static_dir+'ipguess_k2_2015.dat' ; default tag: 'ae' 
  
ipcfnm0 = files
ftsdsk  = atlas_dir
;HTI OPEN THIS WHEN TESTING INITIAL GUESSES, 9/2014
; This file has the structure of a VD.	Variable is named after file.
restore,static_dir+'median_bstar_b5_c2_pars.dat'

; HTI 6/2014, restrict all input guesses to 'ad'  and 'ac' tag names.
; HTI 10/2015. Only use vdtags: 'ae' ; contained in ipguess_k2_2015.dat
;   ipguess = ipguess[  $
;               where(strmid(ipguess.name,1,2,/reverse_offset) eq 'ad' $
;               or strmid(ipguess.name,1,2,/reverse_offset) eq 'ac')]


c = 2.99792458d8                ;speed of who?
bnum=0                          ;counter
if n_elements(label) ne 1 then label='vd' else label=strtrim(label,2)
if n_elements(frzpar) lt 1 then frzpar=[-1]
if n_elements(avpsf) ne 1 then avpsf=0
if n_elements(frzdisp) ne 1 then frzdisp=0
if n_elements(smfts) ne 1 then smfts=0
if n_elements(nopsf) ne 1 then nopsf=0
svname=label+'_'

if n_elements(nso) ne 1 then nso=0 ;Use the NSO atlas as the
                                ; stellar template?
if nso eq 1 then print,'Using NSO Solar Atlas as Template!'
if n_elements(noscat) eq 1 then begin
;    print,'No Scattered Light!'
;    frzpar=[frzpar,14]
endif else noscat=0 

if n_elements(plot_key) ne 1 then plot_key=0

;Do Observations Only from 19 Nov 1994 Onward (Postfix Era)
ddd=cf.jd
if min(ddd) gt 2440000 then ddd=ddd-2.44d6
ind=where(ddd gt 9675,nind)
if nind gt 0 then cf=cf(ind) else $
  stop,'No Post-Fix Observations to Analyze'
if nind lt n_elements(ddd) then $
  print,'***Old PRE-FIX Observations Not Reduced***'


if keyword_set(avpsf) then begin ;frozen PSF?
    case 1 of
        keyword_set(idepth): frzpar=[frzpar,indgen(11),indgen(4)+15] 
        ;pars 0-10, 15-18 are PSF 
        keyword_set(sine): frzpar=[frzpar,indgen(11),indgen(3)+15]
        else: frzpar=[frzpar,indgen(11),indgen(5)+15] ;pars 0-10, 15-19 are PSF
    endcase
endif else avpsf=0

if keyword_set(nopsf) then begin
    if 1-keyword_set(absolute_noprint) then begin
        print,'Using nopsf option, getting PSF guess from disk.'
        print,'Must have guesed VD on disk.'
        print,'Using a "frozen averaged" PSF'
    endif
    frzpar=[frzpar,indgen(11),indgen(5)+15] ;pars 0-10, 15-19 are PSF
    avpsf=1
endif

bnum=n_elements(cf)             ;number of observations

;This section actually grinds through each observation.
;  A first guess "vd" structure is created for the observation,
;  then the observation is pumped through "stargrind".
for n=0,(bnum-1) do begin       ;bnum = # of observations
    if 1-keyword_set(absolute_noprint) then begin
        print,' '
        print,'---------------------------------------------------------'
        ; print relevant info from CF
        date = jd2date(long(cf(n).jd+.5))
        if strmid(strtrim(date,2),2,1) eq '-' then date=' '+date
        print,' Obs Name: '+cf(n).obnm
        print,' Obs Date:'+date
        dum=(cf(n).jd-long(cf(n).jd))*24. - 12. ;UT time in hours
        if dum lt 0 then dum=dum+24             ;fix time screw ups
        if dum gt 24 then dum=dum-24            ;fix time screw ups
        hour=fix(dum) & dum=(dum-hour)*60.
        mnt=fix(dum)  & dum=(dum-mnt)*60.  &  sec=fix(dum)
        if hour lt 10 then hour='0'+strtrim(hour,2) else hour=strtrim(hour,2)
        if mnt lt 10 then mnt='0'+strtrim(mnt,2) else mnt=strtrim(mnt,2)
        if sec lt 10 then sec='0'+strtrim(sec,2) else sec=strtrim(sec,2)
        print, $
        ' Obs Time:'+strtrim(hour,2)+':'+strtrim(mnt,2)+':'+strtrim(sec,2)+' U.T.'
        print,' Obs Labl: '+strtrim(svname+cf(n).obnm,2)
        print,' Observation #'+str(n+1)+' out of '+str(bnum)
    endif

    if keyword_set(inplab) then begin ;Retrieve opens the spectrum
        retrieve,cf[n],ob,iod,filter,fdsk,vdinplab,vdname=inplab, nik=nik
        if n_elements(vdinplab) eq 1 then if vd eq 0 then begin
            cf[n].dewar=-1
            print,'Unable to find: '+inplab+' '+cf[n].obnm
        endif 
        if 1-keyword_set(absolute_noprint) then $
            print,' Obs IPVD: '+inplab+'_'+cf[n].obnm

    endif else begin            ;getting the observation
        retrieve,cf[n],ob,iod,filter,fdsk, nik=nik
;        datdif = cf[n].jd - ipguess.jd
;        datind = sort(abs(datdif))
;         qq = -1             ;counter
;         repeat begin        ;Does IPCF file exist?
;             qq = qq+1
;         endrep until check_file(ipguess[datind[qq]].name)
;         print,'% CRANK.PRO: Using only ae tag input guesses.' ; not working
;         ipcfnm = ipguess[datind[qq]].name ; what is this used for???
        ipcfnm = static_dir+'vdiod3314_rj13.2275.j'

        if 1-keyword_set(absolute_noprint) then print,' Obs IPCF: '+ipcfnm
        restore,ipcfnm          ;get input guess VD from IPCF
        ;HTI test, I attempted to use the long term averages, but they did not
        ;   produce better results than Bstars observed near in time. 10/2014
        ;restore,'Sacred_VD_b5_c2_sep2014.dat' ; opens as VD

        if ~keyword_set(noprint) then print,' Using Sacred VD as starting guess'
			;HTI 6/2014, restrict all input guesses to 'ad'  and 'ac' tag names.
			; 			This is only done on the first pass
;			ipguess = ipguess[ $
;					where(strmid(ipguess.name,1,2,/reverse_offset) eq 'ad' $
;						or strmid(ipguess.name,1,2,/reverse_offset) eq 'ac')]
;			10/2015: Bstars are now all 'ae' tag
;			ipguess = ipguess[ $
;					where(strmid(ipguess.name,1,2,/reverse_offset) eq 'ae') ]

        vdinplab=vd   			;HTI This new ipcfnm needs filtered for 'ad'
;        vpsf=vd
    endelse

    if keyword_set(frzdisp) then begin ; 2nd/3rd pass
        qq=where(stregex(ipguess.name, 'iod_r') ge 0, nqq) ;quartz I2
       if nqq gt 0 then begin ; This is typically not done
            datdif = cf(n).jd - ipguess.jd
            datind = sort(abs(datdif))
            qq = -1             ;counter
            repeat begin        ;Does IPCF file exist?
                qq = qq+1
            endrep until check_file(ipguess[datind[qq]].name)
            if 1-keyword_set(absolute_noprint) then $
            	print,' Obs IPCF-IOD: '+ipguess[datind[qq]].name
            restore,ipguess[datind[qq]].name ;get input guess VD from IPCF
            vdiod=vd   ; This vdiod is NOT related the make_vdiod.pro
        endif else print,'NO Obs IPCF-IOD for wavelength guess'

        ;Smooth the disperion at beginning of 2nd pass, and freeze it.
        sm_disp,vdinplab,nvd,vdiod=vdiod ; ipguess[datind[qq]].name is input      								
                                        ; and smoothed dispersion is output.
                                        ; on second pass vd.icof[1] is populated
                                        ; with the smoothed dispersion.
;        PRINT,'TESTING SMOOTHED DISPERSION FROM PASS 1.'
        vdnames = tag_names(nvd)
        wavdex = first_el(where(vdnames eq 'ICOF')) ;write wave cofs to icof
        if wavdex lt 0 then wavdex = first_el(where(vdnames eq 'WCOF'))
        nvd.iparam(13)=nvd.(wavdex)[1]
        vdinplab=nvd            ; Without sm_disp, then nvd has no vals for 
                                ; nvd.iparam[13], disperion.
        frzpar=[frzpar,13]      ;turn off dispersion 5Jun03
        if 1-keyword_set(absolute_noprint) then $
            print,'******* Frozen Dispersion Invoked *******'
    endif

    if keyword_set(frzw0) then begin
        frzpar=[frzpar,11,13]   ;JJ: turn off dispersion and w0 6oct05
        if 1-keyword_set(absolute_noprint) then $
            print,'******* Frozen Dispersion and WL Zero Point Invoked *******'
    endif

    if n_elements(notelluric) ne 1 then notelluric = 0
    if notelluric eq 1 then begin
        if 1-keyword_set(absolute_noprint) then $ 
            print,'Telluric Filter Not Invoked'
        tellist=0
    endif
    prop_filt,filter,/zero

    if cf(n).dewar gt 0 then begin

        initz = cf[n].z         ;initial guess for input Z
        ;       Is the star a variable?
        ;       If so, the barycentric correction can not be used as an initial 
        ;       guesses for "Z"
        if keyword_set(variable) then begin
            print,'    ***  This star is presumed to vary  ***'
            print,'Input guess for Doppler Z is empirically derived.'
            guess_z,dsst,ob,ipcff,initz,vdinplab,ftsdsk=ftsdsk,ftsdfn=ftsdfn
        endif
        ;set up necessary arrays and structures:
        ; Initial guess VD is established by build_vd on first pass; HTI 9/2014
        ; The Disperion is smoothed within build_vd.pro by jjsm_wav.pro
        ; This causes the dispersion to be smoothed before entering 1st pass.
        if n_elements(inplab) ne 1 or nopsf eq 1 then begin ;need to build a VD
            if nso eq 0 then begin
                build_vd,dsst,ob,initz,vdinplab,vd
            endif else begin    ;Kludge for "NSO" observations
                vd.z=1000./c  
                vd.iparam[12]=vd.z ;This needs to be tweaked
            endelse
        endif else begin
            vd     = vdinplab   ;Use previously stored VD for 2nd,3rd pass
            goodchunk=where(vd.weight gt (0.8*median(vd.weight)) and $
                            vd.fit lt (1.2*median(vd.fit)))
            vd.z = median(vd[goodchunk].z)
            initz = median(vd[goodchunk].z)
            if 1-keyword_set(absolute_noprint) then $
            	print,'Using previously derived VD as input guess to STARGRIND'
        endelse
        if 1-keyword_set(absolute_noprint) then $
            print,'   *** INPUT GUESS VELOCITY = '+strtrim(initz*c,2)+' ***   '

        if nopsf eq 1 then begin ;low S/N observations, use default IPCF PSF
            if 1-keyword_set(absolute_noprint) then $
                print,'Using default IPCF PSF parameters for this observation'
            for m=0,n_elements(vd)-1 do begin ;first guess PSF from vdpsf
                ind=where(vd.ordt eq vdpsf(m).ordt)
                dum=minloc(vd(ind).pixob - vdpsf(m).pixob)
                ind=ind(dum)
                vd(m).iparam(0:10)=vdpsf(ind).iparam(0:10) 
                	;transfer PSF parameters
                vd(m).iparam(15:19)=vdpsf(ind).iparam(15:19) 
                	;transfer PSF parameters
                vd(m).fit=vdpsf(ind).fit                     ;transfer PSF fit
                vd(m).cts=vdpsf(ind).cts                     ;transfer PSF fit
            endfor
        endif

        ;what orders are to be operated on?
        ordr = vd.ordob
        if min(ordr) eq max(ordr) then ordr=[ordr(0)] else $
          ordr = where(histogram(ordr) gt 0) + min(ordr)
        ; store DSST path to VD
        vd.spst = cfst[0].spst
        ;scattered light?
        if noscat eq 1 then begin
            vd.scat = 0.
            vd.iparam(14)=0.
        endif 
        ;Are there any terrible initial guesses for "Z"?
        vd.sp1=0                                       ;Zero out the "special"
        bad=where(vd.fit gt (1.5*median(vd.fit)),nbad) ;Bad initial "Z" guess?
        if nbad gt 0 then vd[bad].z=median(vd.z)       ;If so, fix it!

        ;Which PSF description, gaussian (gpfunc) or gauss-hermite (ghfunc)?
        ghpsf=0
        if n_elements(psfsig) eq 1 then if psfsig le 0 then ghpsf=1

        ;set up pixpsf and sigpsf
        if n_elements(psfsig) gt 0 and n_elements(psfpix) gt 0 then begin
            pixpsf=psfpix       ;use keyword input PSF description
            sigpsf=psfsig       ;use keyword input PSF description
        ;   print,'Using KEYWORD input PSF description.'
        endif else begin
            if ghpsf eq 0 then begin 
                pixpsf=cf(n).psfpix ;use CF PSF description
                sigpsf=cf(n).psfsig ;use CF PSF description
            endif
        endelse

;   print,'    *** PSF DESCRIPTION ***'
;   print,'Pixel Locations:   ',pixpsf
;   print,'Gaussian Widths:   ',sigpsf
;   print,'Frozen Parameters: ',frzpar

;		Initial guess of input PSF parameters
; 		HTI 9/2014 --
;		Bug fix: the psf parameters found in the first pass were not being sent 
;		into the second pass. Instead, they were set to zero in the second pass. 
;		For the first pass, they are now set to the long term average psf 
;		parameters as determined by Bstars observed between 2009 and 2014 with
;		the	B5 and C2 deckers. The psf parameters are now passed from pass #1 to
;		pass #2 and then to pass #3. The beginning of pass #3 uses psfav to
;		improve psf parameters.	--- 9/2014
        vdnames = tag_names(vd)
        veldex = first_el(where(vdnames eq 'VEL'))
        if keyword_set(avpsf) then begin ; HTI is this conditional correct?
            veldex = first_el(where(vdnames eq 'IVEL'))
            if veldex lt 0 then veldex = first_el(where(vdnames eq 'VEL'))
        endif
        if ~keyword_set(frzdisp) then begin ; Do ONLY in first pass.
            ;This should only be called for B5 and C2 deckers.
            vd.iparam(0:10)=median_bstar_b5_c2_pars[0:10,*]
            vd.iparam(15:19)=median_bstar_b5_c2_pars[15:19,*]
            print,' STARGRIND: Using average Bstar psf pars.'
        endif 

        ;different kind of 2nd pass, freeze dispersion only 5Jun03  RPB
        cond = frzdisp eq 1 or keyword_set(frzw0) and n_elements(inplab) eq 1 
        if cond then $
          veldex = first_el(where(vdnames eq 'IVEL'))
        ;3rd pass: frozen dispersion and frozen PSF
        if frzdisp eq 1 and avpsf eq 1 then $
          veldex = first_el(where(vdnames eq 'SVEL'))
        t0 = systime(/sec)
        idcond=0   
        idcond = idcond and 1-keyword_set(idepth)

        if idcond then begin ;;;Force idepth
            idepth = 1
            oldfz = frzpar
            q = where(frzpar ne 19)
            frzpar = frzpar[q]
        endif

        if stregex(test, 'ros', /bool) then begin
            rmfile = (strsplit(test, '=', /ext))[1]
            cmrestore, rmfile, rdsst
        endif

        stargrind,ob,dsst,vd $
            , absolute_noprint=absolute_noprint $
            , accordion=accordion $
            , avpsf=avpsf $ 
            , del_pix=del_pix $ 
            , del_ord=del_ord $
            , dst=dst  $
            , filter=filter $
            , fitdex=fitdex $
            , frzpar=frzpar $ 
            , fts_atlas=fts_atlas $
            , idepth=idepth $
            , itest=iodtest $
            , kepler=kepler     $
            , noprint=noprint $
            , nso=nso $ 
            , obnm=cf[n].obnm $
            , order=ordr $
            , orddist=orddst $ 
            , plot_key=plot_key $
            , psfin=psfin  $
            , psfsig=psfsig $
            , psfpix=psfpix $
            , rdsst=rdsst $
            , save_info=save_info $
            , smfts=smfts $ 
            , sm_wav=frzw0 $
            , starname=starname $
            , start_ord=start_ord $
            , start_pix=start_pix $
            , tellist=tellist $ 
            , test=test $
            , vdtag=vdtag $
            , vd_sacred = median_bstar_b5_c2_pars $
            , wdst=wdst 

        if idcond then begin 
            frzpar = oldfz
            idepth = 0
        endif
        dt = (systime(/sec) - t0)/60.
        print, cf[n].obnm+' completed in '+sigfig(dt, 3)+' minutes'
        medchi = median(vd.(fitdex))
        print, 'Median chi = '+sigfig(medchi, 3)
        vd.(veldex)=vd.(veldex)+cf(n).bc ;Barycentric velocity correction
        if 1-keyword_set(absolute_noprint) then begin
            print,'Saving : '+ svname+cf(n).obnm
            print
            print
        endif
        save,file=fdsk+svname+cf(n).obnm,vd ;Save results to disk
    endif                                   ;if cf(n).dewar ge -1
endfor                                      ;n

return
end
