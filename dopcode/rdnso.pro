Pro  rdnso,w,s,wmin,wmax, arcturus=arcturus, atlas=atlas, spec=spec, wav=wav, dsst=dsst
;Extracts requested portion of solar spectrum from the National Solar
;  Observatory's solar flux atlas. 
; Wmin (input scalar) lowest wavelength to return in w
; Wmax (input scalar) highest wavelength to return in w
; w (output vector) wavelength scale for s
; s (output vector) requested portion of solar spectrum
;Uses the data file NSO.DAT (1536 long words per record) which has format:
;  Record 0:  [word 0] Number of records (Nrec) of atlas spectrum in file.
;	      [word 1,Nrec] First wavelength of each record in angstroms*1e5.
;	      [word Nrec+1] Last wavelength in atlas.
;  Odd records: 1536 wavelengths in angstroms*1e5.
;  Even Records (except 0): 1536 residual intensities*1e5 for preceding
;    wavelength scale from NSO solar atlas.
;03-Aug-90 JAV	Create.
;13-Oct-90 JAV	NSO atlas spectrum returned as double precision.
;12-Aug-90 JAV	Cleaned up Paul Butler's IDL adaptation of the ANA version.
; 2-6-14   HTI  This program was never updated to work on the doppler directory.
;				If keyword atlas or arcturs is on, then BEWARE.
on_error, 2
If N_Params() lt 4 Then Begin
    Message,/Info,'Syntax: RDNSO,w,s,Wmin,Wmax'
    RetAll
EndIf

berknso = getenv("DOP_NSO_ATLAS") ; iodine atlas location

if keyword_set(atlas) then begin
    if 1-keyword_set(spec) or 1-keyword_set(wav) then begin
        case 1 of 
            stregex(atlas, '.dat', /bool) : begin
                cmrestore, atlas, dsst, spec, wav
            end
            stregex(atlas, 'procyon', /bool,/fold) : begin
                dum = readfits(atlas, /sil)
                wav = dum[0,*]
                spec = dum[1,*]
            end
            stregex(atlas, '185144', /bool,/fold) : begin
                dum = readfits(atlas, /sil)
                wav = dum[0,*]
                spec = dum[1,*]
            end
            stregex(atlas, '.fits', /bool) : begin
                dum = readfits(atlas, /sil)
                spec = dum[*,0]
                nel = n_elements(spec)
                wav = makearr(nel, 3000d, 18000d)
            end
        endcase
    endif
    u = where(wav gt wmin and wav lt wmax, nu)
    s = spec[u]
    w = wav[u]
    bad = where(s le 0, nbad)
    if nbad gt 0 then s[bad] = 1.
    return
endif
dummy=first_el(findfile(berknso))
if dummy eq berknso then nsofile=berknso else begin
    dummy=first_el(findfile(sfsunso))
    if dummy eq sfsunso then nsofile=sfsunso else begin
        print,'There is no NSO Atlas at either:'
        print,'   '+berknso
        print,'   '+sfsunso
        stop,'A valid NSO atlas is needed'
    endelse
endelse
;Open atlas file and read wavelength boundaries from first block.
n_st=1073  &  skip=2*n_st
st={sun,wvln:fltarr(1024),spec:intarr(1024)}
OpenR,Unit,/Get_Lun,nsofile,/swap_if_little_endian ;open atlas file

asvar0=assoc(Unit,intarr(n_st))  &  wplus=asvar0(0)
asvar1=assoc(Unit,st,skip)

rec0=where(wplus ge wmin)      &  rec0=rec0(0)-2
rec1=where(wplus le wmax,dum)  &  rec1=rec1(dum-1)
n_rec=rec1-rec0+1
w=dblarr(n_rec*1024L)          &  s=W
for n=rec0,rec1 do begin
    m=long(n-rec0)*1024L
    dum=asvar1(n)
    w(m:m+1023)=double(dum.wvln) + double(wplus(n))
    s(m:m+1023)=double(dum.spec)
endfor

Free_Lun,Unit

;now strip off excess
dum=where(w lt wmin,ndum)
if ndum le 1 then fpix=0  else fpix=dum(ndum-1)-1
dum=where(w gt wmax,ndum)
if ndum le 1 then lpix=n_elements(w)-1 else lpix=dum(0)+1
w=w(fpix:lpix)  &  s=s(fpix:lpix)/30000.

return
end

;Verify requested spectral region is in atlas.
;  if Wmax le Wmin then begin			;null range specified.
;    print1,'RDNSO: Invalid spectral region specification - aborting.'
;    Close,Unit
;    RetAll
;  end
;  if Wmin lt NSOw(0) then begin			;check existence of atlas data
;    type,'RDNSO: Requested spectral region bluer than atlas - aborting.'
;    Close,Unit
;    RetAll
;  end
;  if Wmax gt NSOw(Nrec) then begin		;check existence of atlas data
;    type,'RDNSO: Requested spectral region redder than atlas - aborting.'
;    Close,Unit
;    RetAll
;  end
