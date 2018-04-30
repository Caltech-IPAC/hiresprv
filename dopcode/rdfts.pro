pro rdfts,w,s,wmin,wmax,dfn=dfn,dfd=dfd, het=het $
          , cwiod=cwiod, csiod=csiod, ccoefs=ccoefs
;
;  Extract a portion of the FTS Iodine Spectrum
;
;  INPUTS
;     WMIN   minimum wavelength requested
;     WMAX   maximum wavelength requested
;
;  OUTPUTS
;     W    returned vacuum wavelength scale
;     S    returned FTS I2 spectrum
;
;  KEYWORDS
;     DFN  disk_file_name of fts atlas
;     DFD  disk_file_directory of fts atlas
;           Defined as environmental variable
;
; Create: Paul Butler/Geoff Marcy, Jan. 1992
; Modified and updated to handle new sacred fts iodine, Oct 10, 1995  PB
; Modified and updated to UVES and other I2 atlases, 6 July 2002 PB
;
;  To convert to "air" wavelengths: use the following line with vactoair
;     wrange=[wmin+1.,wmax+2.]   
;  Find the FTS atlas
;
;  Todo: change 'dat' and 'sav' if statement to be more robust against file names containing those strings.
; potentially comment out if statement starting on line 39, ending line 87.

if stregex(dfn, 'dat', /bool) or stregex(dfn, 'sav', /bool) then begin
    if 1-keyword_set(cwiod) then begin
        if stregex(dfn, 'sav', /bool) then begin
            read_iodine, 'keck', 'pnnl', 67.3, 0, 1d4, wiod, siod
        endif else begin
            read_iod_p4, wiod, siod, 4801, 6299, pad=0.1
        endelse
        csiod = ptr_new(siod)
        cwiod = ptr_new(wiod)
    endif 
    locate_interval, *cwiod, wmin-0.5, wmax+0.5, ibeg, iend
    if iend eq -1 or ibeg eq -1 then begin
        w = makearr(1000, wmin-0.5, wmax+0.5)
        s = w*0+1.
        return
    endif
    w = (*cwiod)[ibeg:iend]
    s = (*csiod)[ibeg:iend]
    un = uniq(w, sort(w))
    w = w[un]
    s = s[un]
    return
endif
if dfn eq '50test' then begin
    read_iodine, 'keck', 'nso', 50.0, wmin, wmax, w, s
    return
endif
if n_params() lt 4 then begin
    print,'Syntax:  rdfts,w,s,wmin,wmax,dfn=dfn,dfd=dfd'
    return
end

ftsfile=strtrim(dfd,2)+strtrim(dfn,2) ;FTS file
dummy=first_el(findfile(ftsfile))

;Wavelength zero-point and dispersion for the 1993 FTS Atlas run
;   ftskeck, ftseso, fts1-3a, ftslick
wav0=20202.018276018d0 
disp=1.409413936d-2
maxpix=324746

case strtrim(dfn,2) of
    'ftslick1.bin': begin          ;New sacred FTS Atlas
        wav0=20202.030866371d0     ;wavenumber of center of pixel 0 in record 0
        disp=1.312212998d-2        ;dispersion
    end

    'ftsiod.bin': begin         ;Old profane FTS Atlas
        wav0=20202.0323d0       ;wavenumber of center of pixel 0 in record 0
        disp=1.40941396d-2      ;extra digit yields better agreement
    end

    'ftsuves_lamp.bin': begin      ;UVES FTS Atlas
        wav0=20202.015444153d0     ;wavenumber of center of pixel 0 in record 0
        disp=6.67041607d-3         ;extra digit yields better agreement
        maxpix=749579   
    end

     else: begin                 ;All the 1993 FTS Atlas
        wav0=20202.018276018d0
        disp=1.409413936d-2
        maxpix=324746
    end
endcase

wrange=[wmin-0.5,wmax+0.5]   
pix=(-1.d8/wrange+wav0)/disp
pix=[long(pix(0))-1L,long(pix(1))+1L]
if pix(0) lt 0 then pix(0)=long(0)
if pix(1) gt long(maxpix) then pix(1)=long(maxpix)
npix=pix(1)-pix(0)+1L
w=[1.d8/((dindgen(npix)+pix(0))*(-1.*disp)+wav0)]

; The below while loop is the primary reader of the FTS.
cool = 0
while not cool do begin
    openr,4,ftsfile,/swap_if_little_endian,error=error
    if error eq 0 then cool = 1 else begin
        print, '.', form='($,a1)', fifteenb()
        wait, 30
    endelse 
endwhile

a=assoc(4,intarr(npix),2L*pix(0))
sc=double(a(0))
close,4
contf, sc, c
s = sc/c
return
end
