;;;; Use this for Magellan. Kludge. Fix it!
pro make_vdiod_driver, obnm, write=write
nel = n_elements(obnm)
for i = 0, nel-1 do make_vdiod, obnm[i], /nopr, write=write
end

pro make_vdiod, obnm $
				, tag=tag $
				, plot=plot $
				, movie=movie $
                , noprint=noprint $
                , vdout=vd $
                , start_ord=start_ord $
                , start_pixel=start_pixel $
                , atlas=atlas $
                , maxchi=maxchi_in $
                , vdin=vdin $
                , psfpix=psfpixin $
                , psfsig=psfsigin $
                , keck2=keck2 $
                , frzpsf=frzpsf $
                , iodin=iodin $
                , narrow=narrow $
                , b1=b1 $
                , tell=tell $
                , nosave=nosave $
                , absolute_noprint=absolute_noprint $
                , float0=float0 $
                , medium=medium $
                , test=test $
                , twopass=twopass $
                , idepth=idepth $
                , simple=simple $
                , accordion=accordion $
                , nowrite=nowrite $
                , d5=d5 $
                , save_info=save_info $
                , width_simple=width_simple $
                , new=new

;+
; NAME:
;
;PURPOSE: Create VDIOD files from Bstars observations through iodine. The nearly 
;			spectrally featureless, rapidly rotating stars provide an excellent 
;			spectrum of the iodine lines. VDIODs are used in as 
;			initial guesses of dispersion when creating VDs, and in the 
;			deconvolution and psf parameter determination for DSSTs.
;
; CATEGORY:	
;			Doppler
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
; 		Date Created: Probably before you were born.
;	
; 		Update: HTI 6/2014 All references to johnjohn changed to doppler account
; 		Simple example call:  make_vdiod, 'rj123.314',tag='ha',/noprint,/keck2
; 		Note, directly calls stargrind, crank.pro not called by make_vdiod.pro
;-

; Setup IDL PATH
 path_dop = getenv("IDL_PATH_DOP")
!path = path_dop
;Active Directory:
act_dir = getenv("IDL_PATH_DOP_BASE")

; Files outside path_dop are defined in .cshrc environment:

baryfile = getenv("DOP_BARYFILE")
ipg = getenv("DOP_IPGUESS_K2")
vdexample=getenv("DOP_VD_EXAMPLE")
files = getenv("DOP_FILES_DIR")
vel_dir = getenv("DOP_RV_OUTDIR")
;iodfitsdb_dir=getenv("DOP_SPEC_DB_DIR")
iodspec=getenv("DOP_SPEC_DIR")
files = getenv("DOP_FILES_DIR")
fa = getenv("DOP_I2_ATLAS")

if 1-keyword_set(nowrite) then write=1
tel = strmid(obnm[0], 1, 1)
if keyword_set(maxchi_in) then maxchi = maxchi_in else maxchi = 1.1

rdsk, header, iodspec+obnm, 2
decker = str(fxpar(header,'DECKNAME'))
if decker eq 'B1' or decker eq 'B3' then begin
    print
    print, 'Using B1 Decker'
    b1 = 1 
endif else b1 = 0 ;;; This may be a problem (JJ 6/22/11)
if decker eq 'E2' then begin
    print
    print, 'Using E2 Decker, /narrow'
    narrow = 1 
endif else narrow = 0 ;;; This may be a problem (JJ 6/22/11)
getpsf, psfpix, psfsig, fz $
		, /keck2 $
		, narrow=narrow $
        , b1=b1 $
        , float0=float0 $
        , simple=simple $
        , new=new $
        , d5=d5

 if keyword_set(idepth) then begin
    q = where(fz ne 19)
    fz = fz[q]
endif

if n_elements(psfpixin) gt 0 and $
  n_elements(psfpixin) eq n_elements(psfsigin) then begin
    psfpix = psfpixin
    psfsig = psfsigin
    nel = n_elements(psfsig)
    if nel lt 11 then fz=[0,indgen(10-nel+1)+nel,indgen(6)+14] else $
      if nel eq 20 then fz = [0, 14] else fz=[0, 14, indgen(16-nel)+nel+4]
endif

if keyword_set(frzpsf) then begin
    fz = [indgen(10)+1, 12, indgen(6)+14]
endif else begin
    fz = [fz,12]
    fz = fz[sort(fz)]
endelse

if keyword_set(write) then begin
    restore,ipg
	;HTI 6/2014, restrict all input guesses to 'ad' tag name.
    ipguess = ipguess[where(strmid(ipguess.name,1,2,/reverse_offset) eq 'ad')]
    new = ipguess[0]
endif
if 1-keyword_set(tag) then begin
    tag = 'j'  
    print,'No Tag defined...returning.'
    return
endif

if keyword_set(vdin) then vd=vdin else restore, vdexample

vd.pixob=vd.pixt
vd.iparam[12]=0.
vd.z=0.
vd.iparam[0:10]  = [psfsig[0],0.,0.,0.,0.,0.,0.,0.,0.,0.,0.]
vd.iparam[15:19] = [0.,0.,0.,0.,0.]
nb = n_elements(obnm)
vdold = vd

if keyword_set(coeff) then begin
    offset = poly(vd.ordob, coeff)
    vd.pixob -= offset
endif

for i = 0, nb-1 do begin
    vd = vdold  ;;; Protect original VDEXAMPLE
    spawn,"grep '"+obnm[i]+" ' "+baryfile, lines
    if lines[0] ne '' then begin
        bname = getwrd(lines[0], 1)
        flet = strmid(strlowcase(bname),0,2)
        if flet eq 'hr' then bname = strmid(bname,2)
        if flet eq 'io' then bname = ''
        bstar = 'vdiod'+bname+'_'
        if 1-keyword_set(iodin) then rdsi, iod, str(obnm[i]), filt else begin
            iod = iodin
            filt = iod*0+1
        endelse
          
        filename = files+bstar+obnm[i]+'.'+tag
        print
        print, 'Creating VDIOD: ' + filename
        if keyword_set(movie) then test = 'movie'
        t0 = systime(/sec)
        stargrind,iod,dsst,vd $  ;Creating a VDIOD requires only a single pass.
        		  , filter=filt $
        		  , frzpar=fz   $
        		  , /iod        $
        		  , test=test   $
                  , fts_atlas=fa $
                  , psfsig=psfsig $
                  , psfpix=psfpix $
                  , plot=plot $
                  , noprint=noprint $
                  , start_ord=start_ord $
                  , tellist=tellist $
                  , start_pix=start_pixel $
                  , absolute_noprint=absolute_noprint $
                  , accordion=accordion $
                  , save_info=save_info

        dt = systime(/sec)-t0
        print, 'Time: '+sigfig(dt/60.,3)+' min.'
        if keyword_set(twopass) then begin
            sm_disp,vd,nvd,vdiod=vdiod
            fz = [11, 13, fz]
            test = 'movie'
            noprint = 0
            nvd.iparam[12]=0.
            nvd.z=0.
            nvd.iparam[0:10]  = [psfsig[0],0.,0.,0.,0.,0.,0.,0.,0.,0.,0.]
            nvd.iparam[15:19] = [0.,0.,0.,0.,0.]
            stargrind,iod,dsst,nvd $
                      , filter=filt $
                      , frzpar=fz  $
                      , /iod       $
                      , test=test  $
                      , fts_atlas=fa $
                      , psfsig=psfsig $
                      , psfpix=psfpix $
                      , plot=plot $
                      , noprint=noprint $
                      , start_ord=start_ord $
                      , tellist=tellist $
                      , start_pix=start_pixel $
                      , absolute_noprint=absolute_noprint $
                      , /sm_wav
            vd = nvd
        endif
        medchi = median(vd.fit)
        if medchi lt maxchi and keyword_set(write) then begin
            new.name = filename
            jd = 2.44d6+double(getwrd(lines[0], 3))
            new.jd = jd
            restore,ipg 
            ipguess = [ipguess, new]
            save, ipguess, file=ipg
        endif

        if 1-keyword_set(nosave) then save,file=filename,vd 
        if 1-keyword_set(absolute_noprint) then begin
            print,'Median chi^2 = '+sigfig(median(vd.fit), 3)
            if 1-keyword_set(nosave) then print, 'Finished with '+filename
            print
            print
        endif
    endif
endfor

print, "completed successfully"

end
