pro dop_driver,starname,tag         $
               , absolute_noprint=absolute_noprint $
               , accordion=accordion $
               , allkeck=allkeck    $
               , atlas=atlas        $
               , avpsf=avpsf        $
               , bcin=bcin          $ 
               , cf=cf              $
               , d5=d5              $
               , dsstfiles=dsstfiles $
               , dsstname=dsstname   $ ; relative path : requires bcin keyword, 
               , dsstobnm=dsstobnm   $
               , dsstpath=dsstpath   $
               , dssttag=dssttag     $
               , dopplot=dopplot     $
               , float0=float0       $
               , fourpass=fourpass   $
               , force_avpsf=force_avpsf $
               , force_second=force_second $
               , force_third=force_third $ 
               , frzpsf=frzpsf       $
               , frzw0=frzw0         $
               , fts=fts             $
               , gausspsf=gausspsf   $
               , idepth=idepth       $
               , iodtest=iodtest     $
;               , keckfiber=keckfiber $ 
               , keck2=keck2         $
               , kepler=kepler       $
               , kvel=kvel           $
               , last20=last20       $
               , lowres=lowres       $
               , lowsn=lowsn         $
               , maxchi=maxchi       $
               , medium=medium       $
               , movie=movie         $
               , mncts=mncts         $
               , newpsf=newpsf       $
               , nightly=nightly     $
               , nik=nik             $ 
               , noplotvank=noplotvank $
               , noprint=noprint    $
               , old_psf=old_psf    $
               , oneper=oneper      $
               , overwrite=overwrite $
               , psfin=psfin        $
               , rossiter=rossiter  $
               , run=run            $
               , save_info=save_info $
               , scattered=scattered $
               , simple=simple       $
               , single_run=single_run $
               , specific=specific     $
               , start_ord=start_ord $
               , start_pix=start_pix $
               , tell=tell           $
               , test=test           $    
               , twopass=twopass     $
               , vank=vank           $
               , variable=variable   $
               , vdtag=vdtag        

;+
; NAME:
;		DOP_DRIVER
; PURPOSE:
;
;Purpose:  This is the main driver of the doppler code used at the end of a 
;			night of observing. This can also be used to run a single star, 
;			or a single observation. 
;			
; CATEGORY:	
;			Doppler
;
; INPUT(required): 	STARNAME: string: e.g. '10700'
;					TAG:	  string: e.g. 'ad'
;					These inputs are required and will result in any the ;
;					creation of VDs that do not exist in output directory

; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:

; keyword descriptions update: 9/22/2014. 
;				DSSTTAG: specify a DSST to use when creating VDs. default: TAG
;				VDTAG:   VDs created will have this tag, default is TAG	
;				VARIABLE: does a cross correlation to establish the initial
;							guess of Z. Needed for stars with RV variation
;							greater than ~500 m/s.
;				DOPPLOT: 
;				RUN: 	
;				NOPRINT: reduces output while creating VDs.
;				LICK:    for data taken from the Lick 3m.
;				KECK2:    use this keyword on post-upgrade HIRES data.
;				VANK: 	  Use this keyword to run jjvank.pro after creating
;						  all VDs for the chosen star.
;				CF: 	  specify a CF structure to run dop_driver on a 
;						  specific subset of stars. Default is:
;						  e.g: cf10700_ad.dat  
;				MAXCHI:   passed to jjvank.pro. Keep chunks with chi^2
;							less than this value.
;				OVERWRITE: required to overwrite VDs.
;				BCIN:		input barycentric correction
;				DSSTNAME: Specify a DSST to use. Complete path required.
;				ATLAS: 	  Specify an FTS iodine atlast.
;				DSSTFILES: default defined as environmnet variable.
;				ROSSITER:
;				FRZW0:
;				SPECIFIC:
;				ALLKECK:
;				NIGHTLY:
;				TWOPASS:
;				AVPSF:
;				MOVIE:
;				DSSTPATH:
;				TELL:
;				FORCE_AVPSF:
;				OLD_PSF:
;				FLOAT0:
;				ABSOLUTE_NOPRINT:
;				SINGLE_RUN:
;				DSSTOBNM:
;				NOPLOTVANK:
;				FOURPASS:
;				IDEPTH:
;				SAVE_INFO:
;				GAUSSPSF:
;				MEDIUM:
;				ACCORDIAN:
;				PSFIN:
;				START_ORD:
;				START_PIX:
;				NIK:
;				FTS:
;				MNCTS:
;				KVEL:
;				NEWPSF:
;				IODTEST:
;				SCATTERED:
;				FORCE_THIRD:
;				LOWSN:
;				LAST30:	Use this for stars with >50 obs to run tests.
;				LOWRES:
;				KECKFIBER:
;
; OUTPUTS:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;
; 2 June 2014, HTI changed all calls from 'johnjohn' directory to 'doppler' 	;			directory. The /emu keyword was likely broken due to this change.
;			Beginning documention. Git backup initiated.
;
; todo: change !path =    to an environment variable. 
;-

; HTI doppler code paths are now controlled within the programs
path_dop = getenv("IDL_PATH_DOP")
!path = path_dop

;Active Directory:
act_dir = getenv("IDL_PATH_DOP_BASE") ; /home/doppler/

; Files outside path_dop are defined in .cshrc environment:
baryfile = getenv("DOP_BARYFILE")
files = getenv("DOP_FILES_DIR")
vel_dir = getenv("DOP_RV_OUTDIR")

planets_dir = getenv("DOP_PLANETS_DIR")

fa = getenv("DOP_I2_ATLAS") ; FTS iodine spectrum
;cfname = act_dir+'planets/cf'+strlowcase(starname)+'_'+vdtag+'.dat'
cfname = planets_dir+'cf'+strlowcase(starname)+'_'+vdtag+'.dat'

;shoe_horn_file=act_dir+'dopcode/dsst_override.txt'
shoe_horn_file=getenv("DOP_DSST_OVERRIDE")
fmt ='a,a,f,i' ; format for shoe_horn_file.
keck2 = 1 ; Now keck2 is the default for creating VDs

test = ''
if keyword_set(movie) then test += 'movie|'
if keyword_set(rossiter) then test += 'rossiter|='+rossiter+'='
if keyword_set(lowres) then test += 'lowres|'
if 1-keyword_set(dssttag) then dssttag = tag
if 1-keyword_set(dsstobnm) then dsstobnm = ''
if 1-keyword_set(vdtag) then vdtag = tag
if 1-keyword_set(variable) then variable = 0
if keyword_set(dsstname) and ~keyword_set(bcin) then begin
    print,'% DOP_DRIVER: bcin required with dsstname keyword'
    return
endif

close,/all

if n_elements(psfsig)*n_elements(psfpix) eq 0 then begin
    getpsf, psfpix, psfsig, fz $
    	, keck2=keck2 $
        , float0=float0 $
        , medium=medium $
        , simpl=simple $
        , new=newpsf $
        , scattered=scattered $
        , d5=d5 $
        ,lowsn=lowsn
    if keyword_set(idepth) or keyword_set(accordion) then begin
        q = where(fz ne 19)
        fz = fz[q]
    endif
    if keyword_set(rossiter) then begin
        match, fz, [14, 19], a, b
        if a[0] gt -1 then remove, a, fz
    endif
endif else begin
    nel = n_elements(psfsig)
    if nel lt 11 then fz=[0,indgen(10-nel+1)+nel,14,15,16,17,18,19] else $
      if nel eq 20 then fz = [0, 14] else fz=[0, 14, indgen(16-nel)+nel+4]
endelse

pfilt = fltarr(4021,16)*0+1 ; No filter necessary 
if keyword_set(tell) then begin
rdsk,tellist,act_dir+'dopcode/tellist_valenti.dsk',1
    vactoair, tellist
endif


if keyword_set(frzpsf) then begin
    fz=[indgen(10)+1,indgen(6)+14]
    psfsig[0] = frzpsf
endif

if keyword_set(psfin) then begin
    fz = [indgen(11), indgen(6)+14]
endif
if keyword_set(iodatlas) then fa = iodatlas

if 1-keyword_set(dsstfiles) then dsstfiles=files
if 1-keyword_set(dsstpath) then begin
    if keyword_set(dsstname) then begin
        dsstpath = dsstfiles+dsstname
    endif else begin
        ;hti begin shoe-horn template dsst selection.
;        shoe_horn_file='dsst_override.txt'
;        fmt ='a,a,f,i'
        readcol,shoe_horn_file,v1,v2,v3,v4,comment='#',format=fmt,/silent
        ck_ind = where(strlowcase(starname) eq v1,nmatch)
        ;hti end show-horn template selection
;        if keyword_set(dssttag) then begin
        if keyword_set(dssttag) and nmatch eq 0 then begin
            sn = strlowcase(starname)
            com = 'ls '+dsstfiles+'dsst'+sn+dssttag+'_'+dsstobnm+'*.dat'
            spawn, com, lines
            dum = where(lines ne '', nlines)
            ;;; JJ: modified next lines to locate the latest DSST obnm
            if nlines gt 0 then begin
                dobnm = strarr(nlines)
                for i = 0, nlines-1 do begin
                    dobnm[i] = $
                      (strsplit((strsplit(lines[i],'_',/ext))[1], '.', /ext))[0]
                endfor
                srt = sort(tape(dobnm,/float))
                dsstpath = lines[srt[nlines-1]]
            endif else begin
                com = 'ls '+dsstfiles+'dsst'+sn+'_'+dssttag+'*.dat'
                spawn, com, lines
                ; HTI added specific line for hats579-042, 9/2014
                ; This is a synthetic spectrum produced by BJ Fulton.
                dum = where(lines ne '', nlines)

                if nlines gt 0 then dsstpath = lines[0] else begin
                  message, 'No DSST found, '+com+' failed...'
                    return ; hti removed return statement 9/2014
                endelse ; hti added return statement, 6/2014
            endelse
        endif else dsstpath = dsstfiles+'dsst'+starname+'_'+dssttag+'.dat'
        ;hti begin shoe-horn template dsst selection.
        if nmatch gt 0 then BEGIN
            dsstpath = v2[ck_ind[0]]
            bcin = double(v3[ck_ind[0]])
            variable = v4[ck_ind[0]]
            print,"%DOP_DRIVER:  Using Shoe-horn DSST:"
            print,  " For "+starname+" Template="+dsstpath
        ENDIF
        ;hti end show-horn template selection
    endelse
endif
;stop
if 1-keyword_set(absolute_noprint) then print, 'DSST File: '+dsstpath
restore, dsstpath

if n_elements(dsstinfo) gt 0 then begin
    meta = {dsstpath: dsstpath $
            , dsstobnm: dsstinfo.obnm $
            , dsstdecker: dsstinfo.decker $
            , dsstpix: dsstinfo.psfpix $
            , dsstsig: dsstinfo.psfsig $
            , dsstbstar: dsstinfo.bstar $
            , obspix: psfpix $
            , obssig: psfsig }
endif

prop_filt,pfilt,/zero

cond = n_elements(bcin) eq 0 

if cond then begin
;    morphname = tempfile+'morph_'+dssttag+'_'+starname+'.dat'
;    if check_file(morphname) then begin
;        restore, morphname
;        bccor = obs[0].bary
;    endif else begin 

        if dsstobnm eq '' then begin ; JCG modification 7/2018
           subdirs  = strsplit(dsstpath, '/', /EXTRACT, count=cnt)
           lastarg  = subdirs[cnt-1]
           stripped = strsplit(lastarg, '.', /EXTRACT)
           stripped = stripped[0]
           dsstobnm = strsplit(stripped, '_', /EXTRACT, count=cnt)
           dsstobnm = dsstobnm[cnt - 1]
        endif ; end JCG modification 7/2018

        com = 'grep -i '+starname+' '+baryfile+' | grep t | grep '+dsstobnm
        spawn, com, lines
        dum = where(lines ne '', nlines)
        if nlines gt 0 then begin
            struct = col_struct(lines,['obnm','name','bc'],type=['a','a','d'])
            bccor = mean(struct.bc)
        endif else message, 'Problem with the BC!'
;    endelse
endif else bccor = bcin
if 1-keyword_set(absolute_noprint) then print,'BC Vel = '+str(bccor)+' m/s'
lbl = 'vd'+vdtag+strlowcase(starname)

if keyword_set(overwrite) then begin
    if check_file(files+lbl+'*') then begin
        ans = ''
        print,'Are you sure you want to overwrite '+files+lbl+'* ?'
        read,ans
        if strmid(strlowcase(ans),0,1) eq 'y' then spawn,'\rm '+files+lbl+'*'
    endif
endif

; cf.pro collects the file names and BCs that will be run.
cf,starname,bccor,cf,logfile=baryfile,obdsk=obdsk, psfpix=psfpix, psfsig=psfsig

if keyword_set(last20) then begin ;htiRun VDs for only the last 20 obs
    ncf = n_elements(cf)          ;
     cf = cf[ncf-20:ncf-1] 
endif 

cfo = cf
tape = strmid(cf.obnm,0,2)
obnm = strmid(cf.obnm,0,4)
use = indgen(n_elements(cf))

;use = where(tape eq 'rj',nuse) ; To be replaced by environment variable.
;cf = cf[use]
; Apr 2018, Change use to use everything, commented out previous two lines.


if keyword_set(single_run) then begin
    n = tape(cf,/num)
    h = histogram(n, bin=1, min=0, rev=ri)
    u = where(h ge 3 and h eq max(h), nu)
    if nu gt 0 then begin
        cf = cf[ri[ri[u[0]]:ri[u[0]+1]-1]] 
    endif else begin
        print,'3+ consecutive observations not found for '+starname
        return
    endelse
endif

if keyword_set(meta) then save,file=cfname,cf,meta else save,file=cfname,cf

if keyword_set(specific) then begin
    match, cf.obnm, specific, a, b
    if a[0] eq -1 then begin
        print, 'Obnms: '+strjoin(specific, ' ')+' Not found'
        return
    endif
    cf = cf[a]
    ncf = n_elements(cf)
endif
if keyword_set(run) then begin
    r = tape(str(run), /float)
    nr = n_elements(r)
    if nr eq 1 then r = [r,r+.5]
    tape = tape(cf, /float)
    use = where(tape ge r[0] and tape le r[1], ct)
    if ct eq 0 then begin
        r = str(r)
        print,'DOP_DRIVER: This star wasnt observed between '+r[0]+' and '+r[1]
        return
    endif
    cf = cf[use]
endif

u = uniq(cf.obnm,sort(cf.obnm))
cf = cf[u]
s = sort(cf.jd)
cf = cf[s]
if keyword_set(test2) then cf = cf[0:2]

if keyword_set(force_avpsf) then begin
    t0 = systime(/sec)
    if keyword_set(nightly) then goto, nightly else goto, avpsf
endif
if keyword_set(force_second) then begin
    t0 = systime(/sec)
    goto, force_second
endif

vdind,cf,lbl,cfind,nik=nik,dsstpath=dsstpath
cf.spst = dsstpath

if cfind(0) gt -1 then begin
    cf=[cf(cfind)]
    ncf = n_elements(cf)
endif else ncf = 0

if keyword_set(oneper) then begin
    run1 = floor(cftape(cf.obnm, /float))
    u = uniq(run1, sort(run1))
    cf = cf[u]
    ncf = n_elements(cf)
endif

;HTI 8/2014
; Begin new section to check cf3 structure, to determine if /variable is needed.
; Stars with RV amplitude of order 1000 m/s need /variable  in order to work
; successfully complete all passes. 
file_check = file_search(vel_dir+'vst'+starname+'.dat',count=nfiles)
if nfiles eq 1 and variable eq 0 then begin
    restore,file_check[0]
    if n_elements(cf3) gt 5 then begin
        RV_variable_check1 = max(cf3.mnvel)
        RV_variable_check2 = min(cf3.mnvel)
        if RV_variable_check1-RV_variable_check2 gt 1000 then begin
            print,'Dop_driver: Setting Variable keyword. RV scatter >1000 m/s'
            variable =1
        endif else variable =0
    endif
endif

;;; this is set up for  low-s/n
if keyword_set(force_third) then begin 
    t0 = systime(/sec)
    ncf1 = n_elements(cf)
    for i = 0, ncf1-1 do begin
        thistape = tape(cf[i])
        com = 'grep '+thistape+' '+baryfile
        spawn,com,lines
        s = col_struct(lines, ['obnm','name','bc','jd'],types=['a','a','f','d'])
        cond = 1-stregex(s.name, 'th',/bool,/fold) and 1-stregex(s.name, 'iod',/bool,/fold)
        cond = cond and 1-stregex(s.name,'hr',/bool,/fold)
        cond = cond and 1-stregex(s.name,'k',/bool,/fold)
        cond = cond and 1-stregex(s.name,'htr',/bool,/fold)
        cond = cond and 1-stregex(s.name,'b',/bool,/fold)
        cond = cond and 1-stregex(s.name,'t',/bool,/fold)
        cond = cond and stregex(strmid(s.name,0,1),'[1-9]',/bool)
        cond = cond and strlowcase(s.name) ne strlowcase(starname)
        use = where(cond)
        s = s[use]
        diff = abs(s.jd - (cf[i].jd-2.44d6))
        dum = min(diff, imn)
        usetag = 'ad'
        file = files+'vd'+usetag+strlowcase(s[imn].name)+'_'+s[imn].obnm
        print, file
        cmrestore, file, vdin
        rdsi, ob, cf[i].obnm
        build_vd, dsst, ob, cf[i].z, vdin, vd
        vd.iparam[12] = cf[i].z
        vd.icof = vd.wcof
        vd.ivel = vd.vel

        save, vd, file=files+lbl+'_'+cf[i].obnm
    endfor
    delvarx, vd
    goto, force_third
endif


nightly:
if keyword_set(nightly) then begin
    jd = fix(cf.jd-1d4)
    h = histogram(jd, bin=1, rev=ri)
    nh = n_elements(h)
    nel = (shift(ri,-1)-ri)[0:nh-1]
    for i = 0, nh-1 do begin
        thisn = nel[i]
        if thisn gt 0 then begin
            if thisn eq 1 then begin
                ind = ri[ri[i]]
                if n_elements(new) eq 0 then new = cf[ind] else $
                  new = [new, cf[ind]] 
            endif else begin
                inds = fillarr(1, ri[i], ri[i+1]-1)
                if keyword_set(randomind) then $
                  rind = inds[(sort(randomu(seed, thisn)))[0]] $
                else rind = inds[0]
                if n_elements(new) eq 0 then new = cf[ri[rind]] else $
                  new = [new, cf[ri[rind]]] 
            endelse
        endif
    endfor
    cf = new
    ncf = n_elements(cf)
    if keyword_set(force_avpsf) then goto, avpsf
endif

if 1-keyword_set(absolute_noprint) then begin
    print
    print,'Found '+str(ncf)+' Observations.'
    print
endif

t0 = systime(/sec)

if ncf gt 0 then begin
;;; PASS #1
    crank,dsst,cf 		$
            , label=lbl	$
            , /noscat	$
            , fts_atlas=fa $
            , frzpar=fz $
            , psfsig=psfsig $
            , psfpix=psfpix	$
            , noprint=noprint $
            , variable=variable $
            , plot_key=dopplot	$
            , tellist=tellist	$
            , test=test  		$
            , allkeck=allkeck	$
            , absolute_noprint=absolute_noprint $
            , psfin=psfin		$
            , start_ord=start_ord $
            , start_pix=start_pix $
            , dst=sdst			$
            , wdst=sdstwav		$
            , nik=nik			$
            , itest=iodtest		

    if keyword_set(psfin) then goto, skip
    if keyword_set(frzw0) then begin
        if keyword_set(fourpass) then begin
            crank,dsst,cf	$
                , label=lbl	$
                , /noscat	$
                , fts_atlas=fa $
                , frzpar=fz $
                , psfsig=psfsig $
                , psfpix=psfpix $
                , inplab=lbl	$
                , test=test $
                , noprint=noprint $
                , tellist=tellist $
                , allkeck=allkeck $
                , absolute_noprint=absolute_noprint $
                , /frzdisp	$
                , accordion=accordion $
                , itest=iodtest
        endif
next:
        crank,dsst,cf $
            , label=lbl $
            , /nosca 	$
            , fts_atlas=fa $
            , frzpar=fz $
            , psfsig=psfsig $
            , psfpix=psfpix $
            , inplab=lbl $
            , noprint=noprint $
            , tellist=tellist $
            , test=test $
            , allkeck=allkeck $
            , absolute_noprint=absolute_noprint $
            , /frzdisp $
            , /frzw0 $
            , accordion=accordion $
            , dst=sdst $
            , wdst=sdstwav $
            , itest=iodtest
    endif else begin
;;; PASS #2
        force_second:
        crank,dsst,cf $
            , label=lbl $
            , /noscat $
            , fts_atlas=fa $
            , frzpar=fz $
            , psfsig=psfsig $
            , psfpix=psfpix $
            , inplab=lbl $    ; indicates second pass
            , noprint=noprint $
            , tellist=tellist $
            , allkeck=allkeck $
            , absolute_noprint=absolute_noprint $
            , test=test $
            , /frzdisp $		; indicates second pass
            , accordion=accordion $
            , dst=sdst $
            , wdst=sdstwav $
            , nik=nik $
            , itest=iodtest 
    endelse
    if keyword_set(twopass) then goto, skip

        avpsf:
        fz = [0, fz]
        dum = where(fz eq 19, ndum)
        if ndum eq 0 then fz = [fz, 19]
        if keyword_set(idepth) then begin
            u = where(fz eq 19, nu)
            if nu gt 0 then remove, u, fz
        endif
;;; PASS #3
        force_third:
        frzdisp = 1
        crank,dsst,cf $
            , absolute_noprint=absolute_noprint $
            , accordion=accordion $
            , allkeck=allkeck $
            , /avpsf $ 		; indicates third pass
            , dst=sdst $
            , frzdisp=frzdisp $
            , fts_atlas=fa $
            , frzpar=fz $
            , idepth=idepth $
            , inplab=lbl $
            , itest=iodtest $
            , kepler=kepler $
            , label=lbl $
            , nik=nik $
            , noprint=noprint $
            , /noscat $
            , psfsig=psfsig $
            , psfpix=psfpix $
            , save_info=save_info $
            , starname=starname $
            , tellist=tellist $
            , test=test $
            , vdtag=vdtag $
            , wdst=sdstwav 

endif
skip:
tottime = str(systime(/sec) - t0)
case 1 of
    tottime lt 120  : begin
        tt = sigfig(tottime, 5)
        units = 'seconds'
    end
    tottime ge 120  : begin
        tt = sigfig(tottime/60., 5)
        units = 'minutes'
    end
    tottime gt 3600 : begin
        tt = sigfig(tottime/3600., 5)
        units = 'hours'
    end
endcase
at = sigfig(float(tt) / n_elements(cf), 5)
if 1-keyword_set(absolute_noprint) then begin
    print
    print, 'Dop Driver Complete'
    print, 'Total time   = '+tt+' '+units
    print, 'Avg. per obs = '+at+' '+units
    print
endif
if keyword_set(vank) then begin
    if keyword_set(twopass) then ifit=1
    if keyword_set(psfin) then ifit = 1d-6
    if keyword_set(force_avpsf) then ifit = 2
    jjvank, starname, vdtag $
            , cf=cf         $
            , maxchi=maxchi $
            , ifit=ifit     $
            , noplot=noplotvank $
            , mncts=mncts   $
            , keck2=keck2   $
            , kvel=kvel     $
            , run=run       $
            , meta=meta
endif

print, "completed successfully"

end
