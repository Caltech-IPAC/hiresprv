pro retrieve,cf,ob,iod,filter,fdsk,vd,vdname=vdname, nik=nik
;This code drives the PSF and velocity analysis
;
;cf       (input structure) Structure of (single) observation, etc ...
;filter   (output array)    Observation night filter
;vd      (output structure) Invoked if "vdname" is called, i.e. vdname='vdl509_'
;
;Created June 7, 1994  R.P.B.
;
files = getenv("DOP_FILES_DIR")

if n_params () lt 2 then begin
    print,' IDL> retrieve,cf,ob,iod,filter,fdsk,vd,vdname=vdname'
    return
endif

;which disk is which?
if cf.iodnm ne '?' then rdsi,iod,cf.iodnm
rdsi,ob,cf.obnm,filter,fdsk, nik=nik     ;bad pixel filter
;if strmid(cf.obnm,0,2) eq '' then fdsk = files
fdsk = files; new default
if n_elements(vdname) eq 1 then begin
    dumnm = fdsk+vdname+'_'+cf.obnm
    dumvd=first_el(findfile(dumnm))
    if dumvd eq dumnm then restore,dumnm else begin
        print,'Requested VD: '+dumnm
        print,'Can not get requested VD from disk!'
        print,'Moving on to the next star!'
        vd = 0
    endelse
endif

return
end
