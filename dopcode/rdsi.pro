pro rdsi,ob,obnamin,filter,fdsk,inpdsk=inpdsk,noob=noob,tellist=tellist,plot=plotha, thar=thar,nik=nik
;This code drives the PSF and velocity analysis
;
;ob      (output array)     Observation 
;obname  (input string)     Observation name  i.e. 'rc10.7' or 'ra49.31' or 'rb34.28'
;filter  (output array)     Observation filter
;fdsk    (output string)    files disk name   
;inpdsk  (input keyword string)  input files disk name 
;
;Created June 7, 1994  R.P.B.
;Updated Feb 25, 1996  R.P.B.
;Updated Nov  9, 1998  R.P.B., AAT/UCLES, inpdsk
;

if n_params () lt 2 then begin
    print,' IDL> rdsi,ob,obnam,filter,fdsk'
    return
endif

obnam = obnamin
tp = strmid(obnam,0,2)          ;tape series (i.e. ra,rb,rc,rd,rh,rk,rz,ru,re,rv)
nb = strmid(obnam,2,2)          ;first two digits of tape number
oo = strpos(obnam,'.')
oo=fix(strmid(obnam,oo+1,4))    ;observation number

if n_elements(noob) ne 1 then noob = 0 ;default, noob = 0, return observation
tellist=0                       ;initial default

; Initially assume this is being run on the Berkeley system
fd5 = getenv("DOP_FILES_DIR")   ; output dir
obd5 = getenv("DOP_SPEC_DIR")  ;Keck observation disk

; Keck/HIRES gain and dwr num defined in chip.pro
dwr = chip(obnam,gain)

;if tp eq '' then begin ; No more if statement, this is now default.
fdsk=fd5                    ;Keck post-fix
obdsk=obd5
;endif

if n_elements(inpdsk) eq 1 then obname=inpdsk+obnam $
else obname=obdsk+obnam         ;observation name including directory

if keyword_set(nik) then begin
    rdech, struct, obname 
    ob = (struct.spec*struct.cont)[*, 1:*] * gain
endif else rdsk,ob,obname,1

if tp ne 'em' and 1-keyword_set(nik) then begin
    fixpix,ob,dewar=dwr         ;  smooth over bad pixels
    ob=ob*gain
endif

;get proper filter
if dwr eq 39 then begin         ;The New Dewar #13, thick chip
    filter=ob*0.+1.             ;Used from rb02 through rb68
    filter(1341,24:51)=-1       ;only CCD flaw?
endif
if dwr eq 24 then begin         ;The New Dewar #8, thick chip
    filter=ob*0.+1.             ;High Resistivity CCD
                                ;  filter(1341,24:51)=-1          ;only CCD flaw?
endif          
if dwr eq 999 or dwr eq 171 then begin
    filter = ob*0. + 1
endif
if dwr eq 103 then filter=ob*0.+1. ;New HIRES CCD, August 2004 
if dwr eq 104 then filter=ob*0.+1. ;New HIRES CCD, August 2004 

if n_elements(filter) eq 0 then     filter = ob*0. + 1

return
end
