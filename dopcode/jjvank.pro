pro  jjvank,strnmin,tmptp,lbl,cf1,cf3 $
            , cf=cfout $
            , dircf=dircf $
            , errcut=errcut $
            , err=e1 $
            , exclude=exclude $
            , ifit=ifit $
            , jcorr=jcorr $
            , keck2=keck2 $
            , kvel=kvel $
            , last20=last20 $
            , maxchi=maxchi $
            , mct=mct $
            , meta=meta $
            , mncts=mncts $
            , noplot=noplot $
            , nozero=nozero $
            , noclean=noclean $
            , outfile=outfile $
            , percentile=percentile $
            , ps=ps $
            , reject=reject $
            , run=run $
            , single_order=single_order $
            , title=title $
            , vdarr=vdarr $
            , vels=v1 
            
;+
; NAME:
;		JJVANK
; PURPOSE:
;		Combine VD structures for a single star and produce a final radial 
;		radial velocity structure. Perform quality control of the chunks, and
;		weighted average of the 'good' chunks. Produces VST structure
;
; CATEGORY:	
;			Doppler
; CALLING SEQUENCE:
;
;
;INPUTS:
;		strnm  (string)  '458'    star_name
;		tmptp  (string)  'rd001'   template_tape
;		lbl    (string)  'vdv'    VD label;
;
;PROGRAMS CALLED:
;		-VEL
;			-VDCUBE
;			-VDCLEAN

; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;			; jjvank,'10700','ad'
; MODIFICATION HISTORY:
;
; This is the call to do the detrending:
; The python scripts should be appropriately setup on the Doppler account. 
; path+rvdetrend.py path + vstk01925.dat
;-
;          HTI 8/2014  If statement added for KOI-157.
; 			HTI 8/2014 special maxchi for gl570b.dat hardwired.
;  Raw Counts correction for pre-upgrade removed.
;  Other pre-upgrade capability removed.

act_dir = getenv("IDL_PATH_DOP_BASE") ; 
vel_dir = getenv("DOP_RV_OUTDIR")
planets_dir= getenv("DOP_PLANETS_DIR")
files_dir = getenv("DOP_FILES_DIR")
keck_st = getenv("DOP_KECK_STRUC")
strnm = strlowcase(strnmin)

if n_elements(lbl) eq 0 and n_elements(tmptp) gt 0 then lbl = 'vd'+tmptp
if 1-keyword_set(ifit) then begin
    ifit = 2
endif else if keyword_set(ifit) then if ifit eq 3 then ifit = 0

; cf1  output structure   all velocities
; cf2  output structure    nightly corrected version of cf1
; cf3  output structure    "Raw Counts" corrected version of cf1
; mct  keyword integer     minimum acceptable counts,
;			     overrides the hardwired rules

if 1-keyword_set(maxchi) then begin
	maxchi = 3.5
endif

cfdsk = planets_dir+'cf'
cfnm = cfdsk+(strmid(strnm,0,3)) + $
       strtrim(strlowcase(strmid(strnm,3,20)),2) +'_'+tmptp+'.dat'


if keyword_set(kvel) then begin
    vstdsk = vel_dir
endif else begin
    vstdsk = planets_dir
endelse

vstdsk1 = planets_dir
kecklist = keck_st

restore,kecklist                ;get Keck List Data Structure
keckst=dum                      ;rename Keck List Data Structure 

;HD Star Catalog
catalog = 'HD '  

if keyword_set(dircf) then cfnm = dircf

vstnm   = vstdsk + 'vst'+(strtrim(strlowcase(strnm),2))+'.dat'
vstnm1   = vstdsk1 + 'vst'+(strtrim(strlowcase(strnm),2))+'.dat'
vnm     = strnm

if 1-keyword_set(mncts) then mncts   = 100
if strupcase(strtrim(strnm,2))  eq 'GL876' then mncts=1500 ;faintest HR star
if strupcase(strnm) eq 'GL905' then mncts=1000 
if strupcase(strmid(strnm,0,2)) eq 'BD' then mncts=1000 
if strupcase(strmid(strnm,0,2)) eq 'G2' then mncts=1000 
if strupcase(strtrim(strnm,2))  eq '75732B' then mncts=900 ;faint star
if strupcase(strnm) eq 'GL570B' then maxchi = 10 ; SB, large average chi^2; HTI

;Don't print HD for GLIESE or SAO or HIP or BD stars
; HTI 6/2016 This list for catalog is incomplet and should be revised.
if strupcase(strmid(strnm,0,1)) eq 'G' or $
  strupcase(strmid(strnm,0,1)) eq 'S' or $
  strupcase(strmid(strnm,0,3)) eq 'HIP' or $
  strupcase(strmid(strnm,0,2)) eq 'BD'  or $
  strupcase(strmid(strnm,0,3)) eq 'HTR' or $
  strupcase(strmid(strnm,0,2)) eq 'K0' or $
  strupcase(strmid(strnm,0,2)) eq 'CK' or $
  strupcase(strmid(strnm,0,3)) eq 'KIC' or $  
  strupcase(strmid(strnm,0,4)) eq 'WASP' or $  
  strupcase(strmid(strnm,0,4)) eq 'EPIC'  $  

  then catalog=''

if n_elements(mct) eq 1 then if mct gt 0 then begin
    print,'Using input value for minimum acceptable photons in exposure:  '+strtrim(mct,2)
    mncts=mct
endif

ck_file = check_file(cfnm)

if ck_file[0] ne 0 then begin
	restore,cfnm
endif else begin
    print,'CF file '+cfnm+' not located'
    return
endelse

let = strmid(cf.obnm, 0, 2)
if keyword_set(exclude) then begin
    bad = where(stregex(cf.obnm, exclude, /bool), nbad)
    if nbad gt 0 then remove, bad, cf
endif
if keyword_set(run) then begin
    r = str(run)
    r = tape(r,/float)
    if n_elements(r) eq 1 then r = [r,r+0.5]
    ar = tape(cf,/float)
    use = where(ar ge r[0] and ar le r[1], ct)
    if ct eq 0 then begin
        print,'JJVANK: This star wasnt observed during run '+strmid(run[0],0,2)
        return
    endif
    cf = cf[use]
endif
cff=cf

if keyword_set(reject) then begin
    match, cff.obnm, reject, bad, blah
    nbad = n_elements(bad)
    if nbad gt 0 then remove, bad, cff
endif

dd=cff.jd
mindd=min(cff.jd)  
if mindd gt 10200 and mindd lt 2440000 then begin
    mindd=mindd-10200.
    dd=dd-10200.
endif

tape = strmid(cff[0].obnm,0,2)
rdsi,testspec,cff[0].obnm
ncol = (size(testspec,/dim))[0]

;if tape eq '' then begin	; post-upgrade. now only post-upgrade is supported.
ordr=[0, 14]
pixr=[50, 3970]
fildsk = files_dir
;endif

if n_elements(cff) gt 1 then begin
    if n_elements(cff) eq 2 then begin
        restore,fildsk+lbl+strnm+'_'+cff[0].obnm  &   vd0=vd
        restore,fildsk+lbl+strnm+'_'+cff[1].obnm  &   vd1=vd
        cf1=cff
        dumfit=3.*median([vd0.ifit,vd1.ifit])
        dumwt=0.5*median(vd0.weight)
        ind=where(vd0.ifit lt dumfit and vd1.ifit lt dumfit and $
                  vd0.weight gt dumwt and $
                  vd0.pixt gt pixr(0) and vd0.pixt lt pixr(1) and $
                  vd0.ordt ge ordr(0) and vd0.ordt le ordr(1),nchunk)
        ;;; JJ: 12/10/2008 changed from weighted mean to median 
        cf1(0).mnvel=median(vd0.vel)  &  cf1(0).mdvel=median(vd0.vel)
        cf1(1).mnvel=median(vd1.vel)  &  cf1(1).mdvel=median(vd1.vel)
        cf[0:1].mnvel -= mean(cf[0:1].mnvel)
        cf[0:1].mdvel -= mean(cf[0:1].mdvel)
        cf1(0).errvel=robust_sigma(vd0.vel)/sqrt(nchunk-1)
        cf1(1).errvel=robust_sigma(vd1.vel)/sqrt(nchunk-1)
        cf1(0).mdchi=robust_mean(vd0.ifit,3)
        cf1(1).mdchi=robust_mean(vd1.ifit,3)

        cf1(0).nchunk=nchunk
        cf1(1).nchunk=nchunk
        cf1(0).cts=median(vd0.cts)
        cf1(1).cts=median(vd1.cts)
        for n=0,19 do begin
            cf1(0).mnpar(n)=mean(vd0.iparam(n))
            cf1(1).mnpar(n)=mean(vd1.iparam(n))
            cf1(0).mdpar(n)=median(vd0.iparam(n))
            cf1(1).mdpar(n)=median(vd1.iparam(n))
        endfor
        cf1.jd=cf1.jd-2440000.
    endif else begin
    
    if keyword_set(last20) then begin ; keep 20 most recent
		ncf = n_elements(cff) 
    	cff = cff[ncf-20:ncf-1]
; TEMPORARY  for 76445
;        keep = where(cff.jd gt 2.44e6+18141.)
;        ncf = n_elements(keep)
;        cff = cf[keep]
;stop 
		print,'JJVANK: Keeping only 20 most recent RVs.'
    endif
	        vel,vnm,cff,lbl,cf1,vdarr,ordr=ordr,pixr=pixr,mincts=mncts,maxchi=maxchi,ifit=ifit,nozero=nozero,noclean=noclean, noprint=noplot, percentile=percentile, single_order=single_order
    endelse
endif else begin
    print,'Less than two observations'
    return
endelse

if n_elements(cf1) eq 0 then begin
    print,'JJVANK: Returning...'
    return
endif

nqq = 0 ; default for post-upgrade, no raw counts correction.
cf5=cf1
cf3=cf1

cfout=cf3
if keyword_set(meta) then begin
    save,file=vstnm1,cf1,cf3,cf5,meta
endif else save,file=vstnm1,cf1,cf3,cf5 ; VST saved here unless /kvel called

cfj = cf3
cfk=0
print,'%JJVANK: NO pre-upgrade series RVs'

if keyword_set(kvel) then begin
    if keyword_set(meta) then save,file=vstnm,cf1,cf3,cf5,cfj,cfk,meta else $
      save,file=vstnm,cf1,cf3,cf5,cfj,cfk
endif

;velplot,cf3,1./12,d1,v1,e1,tit=catalog+strupcase(strtrim(strnm,2)),$ 
;	errcut=errcut,/yrs,noplot=noplot

;postscript to laser printer?
if keyword_set(ps) then begin
    if 1-keyword_set(outfile) then outfile = 'jjvank.ps'
    psopen,outfile,xs=8,ys=6,/inch
    if 1-keyword_set(title) then title = catalog+strupcase(strtrim(strnm,2))
    velplot,cf3, title,0.6,/yrs,/nocolor,errcut=errcut  
    psclose
endif

return
end
