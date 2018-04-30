pro ADDWF,widefiles,prefix
;
;ADD the WIDE FLATS
;This procedure sums either one or two SETS of wide flats.
;Produce a "normalized" wide flat for the Hamilton.
;
;'star tapename'.sum		ECW
;INPUT:
;       WIDEFILES   string array of filenames of all wide flats
;;       BIASLEV     Median of a bias exposure (or 0.0)
;       PREFIX      string:  the character string preceding FITS files

;OUTPUT:
;	Summed Wideflats are WDSK'd to:  PREFIX.'sum'
;
;Jun-12-92 Eric Williams
;Mar-3-95  Modified for WIDEFILES array and to do Sums here. GWM
;
@ham.common
trace,15,'ADDWF: Wide flat images being added together, please hold on...'
;
numwf = n_elements(widefiles)
rdfits,im,widefiles[0]          ;VERY FIRST WIDE FLAT
im=double(im)

    if ham_bin eq 1 then begin
        nr = n_elements(im[0,*]) ;# rows
        for j=0,nr-1 do begin   ;Subtract Bias, row by row

;change here for new overscan (jan 7 2000)
;     biaslev = median(im(2200:2299,j))
      biaslev = median(im[21+2047+11:21+2047+11+20,j]) ; bias from 2079:2073+25

;            biaslev = median(im(2200:2299,j)) ;median bias level in row
            im[*,j] = im[*,j] - biaslev
        end
    end
    medim = median(im[600:800,*])
    trace,5,'Median Cts = '+strtrim(string(medim),2)
    if medim lt 2000 then begin
        print,'Too few counts in supposed Wide Flat: '+widefiles[0]
        print,'It is flawed or not a Flat Field at all.'
        print,' '
        if medim gt 20 and medim lt 50 then begin
          print,'Median Counts suggests image is a Th-Ar'
        end
        if medim gt 100 and medim lt 400 then begin
           print,'Median Counts suggests image is an Iodine'
        end
        print,'Stopping Reduction.  Hit CNTRL-c .'
        print,' '
        stop
    end


totwf = im

;
FOR i=1,numwf-1 do begin        ;Loop through wide flats  
rdfits,im,widefiles[i]
    im=double(im)
    IF ham_id eq 29 then begin  ;HIRES images need trimming
        if ham_bin eq 1 then begin
            nr = n_elements(im[0,*]) ;# rows
            for j=0,nr-1 do begin ;Subtract Bias, row by row

;change here for new overscan (jan 7 2000)
;     biaslev = median(im(2200:2299,j))
      biaslev = median(im[21+2047+11:21+2047+11+20,j]) ; bias from 2079:2073+25
                im[*,j] = im[*,j] - biaslev
            end
        end
    END
    medim = median(im[600:800,*])
    trace,5,'Median Cts = '+strtrim(string(medim),2)

    if medim lt 2000 then begin
        print,' '
        print,'Too few counts in supposed Wide Flat: '+widefiles[i]
        print,'It is flawed or not a Flat Field at all.'
        if medim gt 20 and medim lt 50 then begin
          print,'Median Counts suggests image is a Th-Ar'
        end
        if medim gt 100 and medim lt 400 then begin
           print,'Median Counts suggests image is an Iodine'
        end
        print,'Stopping Reduction.  Hit CNTRL-c .'
        print,' '
        stop
    end

    totwf = totwf + im
END


    trace,10,'ADDWF:  Trimming Columns (21:2047+21) off Keck Wide Flat images'
;    totwf = totwf(42:2089,*)    ;for Vogt's seismology data with 2 amplifiers
    if ham_bin eq 1 then totwf = totwf[21:2047+21,*] ;for nov 94 Keck run
    if ham_bin eq 2 then totwf = totwf[11:1023+11,*] ;binned 2x2
;
; STORE the FINAL TOTAL WIDE FLAT
wdsk,totwf,prefix+'.sum',/new   ;wdsk store co-added wide flat -gm
trace,15,'ADDWF: Wide Flat images are now summed and stored as: '+prefix+'.sum'

end




