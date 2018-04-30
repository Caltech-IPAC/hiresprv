pro ADDWF,widefiles,prefix, totwf
;
;ADD the WIDE FLATS for Iodine Region (chip = 2)
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
;Jun-3-05  Proper bias subtraction for new HIRES CCD mosaic. GWM & JTW
;Jul-7-08  Checked for consistency with groupaddwf.pro before reverting
;          to this version for use in hamred.  GWM & KMP
;Nov-6-09 GM and HI pass totwf out to hamred, instead of saving as ???.sum
;Jan-11-10 HI now header is read and checked for C1 decker.
;May-2012, HTI, test to see if median averaging is better. commented out.

@ham.common
trace,15,'ADDWF: Wide flat images being added together, please hold on...'
;

chipno=2   ; Middle chip (iodine)
numwf = n_elements(widefiles)
hiraw,im,widefiles[0],chip=chipno  ;hires mosaic
;im=double(im)
;xdim= 4096	;HTI 5/2012, testing
;ydim=713	;HTI 5/2012, testing
;med_flt = dblarr(xdim,ydim);HTI 5/2012,testing
;all_flt = dblarr(numwf,xdim,ydim);HTI 5/2012,testing
totwf = im * 0.d0

for i=0,numwf-1 do begin        ;Loop through wide flats  
;    hiraw,im,widefiles[i],chip=chipno ;hires mosaic
    hiraw,im,widefiles[i],chip=chipno,head ;hires mosaic
	decker = sxpar(head,'DECKNAME')
	if strcompress(decker,/remove_all) ne 'C1' and $
		strcompress(decker,/remove_all) ne 'B2'  and $
	   strmid(widefiles[0],10,3) ne 'j01' then begin
		trace,5,' DECKER IS DIFFERENT THAN C1 or B2, ABORTING...'
		trace,5,' Bad File: '+string(widefiles[i])+' decker= '+string(decker)
		STOP	
	endif ;hti jan2010
;    im=double(im)
            nc = n_elements(im[*,0]) ;# cols
            for j=0,nc-1 do begin ;Subtract Bias, col by col
                biaslev = median(im[j,5:13]) ;hires mosaic
                im[j,*] = im[j,*] - biaslev
            endfor
    
    cut = im[2000,*]  ;for hires mosaic
    qq=sort(cut)
    medim = cut(qq[0.8*713])  ; 80th percentile 650/713

    im=nonlinear(im)

    trace,5,'************************** 80th percentile Cts = '+strtrim(string(round(medim)),2)
    trace,5,' '

    if medim lt 4000. then begin
        print,' '
        print,'Too few counts in supposed Wide Flat: '+widefiles[i]
        print,'It is flawed or not a Flat Field at all.'
        if medim lt 50 then begin
          print,'Median Counts suggests image is a Th-Ar or Iodine'
        endif
        if medim gt 60 and medim lt 400 then begin
           print,'Median Counts suggests image is an ThAr or Iodine'
        endif
        print,'Stopping Reduction.  Hit CNTRL-c .'
        print,' '
        stop
    endif

    totwf = totwf + im

;	all_flt[i,*,*] = im	;HTI 5/2012, testing

endfor ;wf loop
;stop ; save wideflat for quick_reduce.pro
;HTI testing median
;for i=0,xdim-1 do begin
; for j=0,ydim-1 do begin
; med_flt[i,j] = median(all_flt[*,i,j])
; 
; endfor ;i=0
;endfor ;j=0
;totwf=med_flt
;stop
;HTI testing median


; STORE the FINAL TOTAL WIDE FLAT
;wdsk,totwf,prefix+'.sum',/new   ;wdsk store co-added wide flat -gm
trace,15,'ADDWF: Wide Flat images are now summed and have been passed along as a keyword. NO run.sum file is stored.'

end




