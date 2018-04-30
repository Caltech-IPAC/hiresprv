function strtr, arg, _extra = extra

  return, strtrim(string(arg, _extra = extra), 2)

end

pro checkflat, inim, name

  im = rotate(inim, 3)
  cut = im[2000, *]             ;for hires mosaic
  qq = sort(cut)
  medim = cut(qq[0.8*713])      ; 80th percentile 650/713

  trace, 5, '80th percentile Cts = '+strtr(medim)

  if medim lt 4000. then begin
    print, ' '
    print, 'Too few counts in supposed Wide Flat: '+name
    print, 'It is flawed or not a Flat Field at all.'
    if medim lt 50 then begin
      print, 'Median Counts suggests image is a Th-Ar or Iodine'
    end
    if medim gt 60 and medim lt 400 then begin
      print, 'Median Counts suggests image is an ThAr or Iodine'
    end
    print, 'Stopping Reduction.  Hit CNTRL-c .'
    print, ' '
    stop
  end
end

function looper, chip, widefiles, header = h0
  n = n_elements(widefiles)
  for j = 0, n-1 do begin
    im = mrdfits(widefiles[j], chip, h, /dscale, /silent)
    nc = n_elements(im[0, *])   ;# cols
    rim = (rotate(im, 3))[*, 5:13]
    for c = 0, nc-1 do begin    ;Subtract Bias, col by col
      biaslev = median(rim[c, *]) ;hires mosaic
      im[*, c] = im[*, c] - biaslev
    endfor
    im = nonlinear(im)
    if j eq 0 then begin
      h0 = h
      meanflat = im
    endif else begin
      meanflat = meanflat+im
   endelse
   if chip eq 2 then checkflat, im, widefiles[j]
 endfor

 return, meanflat
end

pro GROUPADDWF,widefiles,prefix, addonly = addonly
;+
;ADD the WIDE FLATS for IODINE REGION (chip = 2)
;This procedure sums either one or two SETS of wide flats.
;Produce a "normalized" wide flat for HIRES.
;'tapename'.sum		ECW
;INPUT:
;       WIDEFILES   string array of filenames of all wide flats
;       PREFIX      string:  the character string preceding FITS files
;OUTPUT:
;	Summed Wideflats are WDSK'd to:  PREFIX.'sum'
;
;Jun-12-92 Eric Williams
;Mar-3-95  Modified for WIDEFILES array and to do Sums here. GWM
;Jun-3-05  Proper bias subtraction for new HIRES CCD mosaic. GWM & JTW
;Nov-18-05 Major overhaul.  Flats are split into 10 groups which are
; medianed separately and saved to disk. If original, raw flats are
; not available, groupaddwf.pro will look for these 10 saved groups
; first in the local directory, then in the directory specified by the
; wideflats input field. JTW
;Aug-25-07 Re-worked so groupaddwf looks for summed flats first, raw 
; wideflat images second. Allows red & blue chips to use the same set
; summed flats.  KP
;
;Jul-6-08 Added "addonly" keyword, to be thrown when groupwf is to skip the time-consuming, "grouping" of flats into sets of 10 if they have already been so grouped.  This is a useful flag to throw if the reduction script crashed but the flats succeeded, preventing the script from re-grouping the flats.
;Jul-8-08  Turned off this routine - it shouldn't be used
;
;-

print,'***********************************************'
print,'In groupaddwf!   Are you sure you want this?! '
print,'Stopping.'
print,'***********************************************'
stop

@ham.common
trace,15,'GROUPADDWF: Wide flat images being added together, please hold on...'
;
Nflatsets = 1      ; Jul 2008: Store all flats in one "group."
w = widefiles[0]
dotpos = strpos(w, '.fits', /reverse_search)
prepos = strpos(w, prefix, /reverse_search)+strlen(prefix)
num = strtr(fix(strmid(w, prepos, dotpos-prepos)))
fraw = (file_search(w))[0]
fgrp = (file_search(prefix+'.'+num+'.flat0.fits'))[0]

; Normally add raw flats. Skip only if grouped flats already exist and
; no flat images exist or if "addonly" is toggled.   This should never happen.
; All three chips have the flats added, again and again, a small price
; to be sure the flats are being added.
if ((fgrp eq '') and (fraw ne '')) or ~keyword_set(addonly) then begin 

  im = mrdfits(widefiles[0], 2, h2, /fscale)
  nx = n_elements(im[*, 0])
  ny = n_elements(im[0, *])
  if nx ne 713 or ny ne 4096 then begin
    print, 'Not a HIRES echellogram!'
    stop
  endif
  numwf = n_elements(widefiles)
  if numwf lt 30 then begin
    print, 'Fewer than 30 flats... treating as one big group'
    Nflatsets = 1
  endif
  flatsetind = indgen(Nflatsets+1)*numwf/Nflatsets
print,' '
print,'Reading raw flat-field fits files - storing in' ,Nflatsets, ' groups of ',numwf/Nflatsets, ' flats each.'
wait,1
print,' '
  for i = 0, nflatsets-1 do begin
    dum = mrdfits(widefiles[flatsetind[i]], 0, h0)
    mwrfits, dum, prefix+'.'+num+'.flat'+strtr(i)+'.fits', h0, /create
    for chip = 1, 3 do begin
      meanflat = looper(chip, widefiles[flatsetind[i]:flatsetind[i+1]-1], h = h)
      mwrfits, meanflat, prefix+'.'+num+'.flat'+strtr(i)+'.fits', h
    endfor
  endfor
endif 

chip = 2  ; Iodine
f = (findfile(prefix+'.'+num+'.flat0.fits'))[0]
if f eq '' then begin
  lastslash = strpos(w, '/', /reverse_search)
  datadir = strmid(w, 0, lastslash+1)
  print, 'Cannot find flats in local directory'
  print, 'Trying '+datadir
endif else datadir = ''
f = (findfile(datadir+prefix+'.'+num+'.flat0.fits'))[0]
if f eq '' then begin
  print, 'Cannot find flats in '+datadir
  print, 'Where are they?'
  stop
endif
print, 'Found grouped flats.  Making summed flat.'
FOR i = 0, nflatsets-1 do begin ;Loop through wide flats  
  im = mrdfits(datadir+prefix+'.'+num+'.flat'+strtr(i)+'.fits', chip, h)
  if i eq 0 then totwf = im*0
  totwf = totwf + im
ENDFOR
totwf = rotate(totwf, 3)
; STORE the FINAL TOTAL WIDE FLAT
wdsk,totwf,prefix+'.sum',/new   ;wdsk store co-added wide flat -gm
trace,15,'GROUPADDWF: Iodine chip wideflat images are now summed and stored as: '+prefix+'.sum'

end


