pro checkflat, inim, name

  im = rotate(inim, 3)
  cut = im[2000, *]             ;for hires mosaic
  qq = sort(cut)
  medim = cut(qq[0.8*713])      ; 80th percentile 650/713

  trace, 5, '80th percentile Cts = '+strtrim(string(medim), 2)

  if medim lt 10000. then begin
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
pro JADDWF,widefiles,prefix
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
;
@ham.common
trace,15,'ADDWF: Wide flat images being added together, please hold on...'
;
chipno=2   ; Middle chip (iodine)
Nflatsets = 10
f = (findfile(widefiles[0]))[0]
f = ''
im = mrdfits(widefiles[0], 2, h2, /unsigned)
if f ne '' then begin
  numwf = n_elements(widefiles)
  flatsetind = indgen(Nflatsets+1)*numwf/Nflatsets
  nx = n_elements(im[*, 0])
  ny = n_elements(im[0, *])
;  nx = 713
;  ny = 4096
  medflat1 = dblarr(nx, ny)
  medflat2 = dblarr(nx, ny)
  medflat3 = dblarr(nx, ny)
  for i = 0, Nflatsets-1 do begin
    n = flatsetind[i+1]-flatsetind[i]
    f = flatsetind[i]
    flat1 = dblarr(nx, ny, n)
    flat2 = dblarr(nx, ny, n)
    flat3 = dblarr(nx, ny, n)
    for j = 0, n-1 do begin
      im1 = mrdfits(widefiles[j+f], 1, h1, /unsigned)
      im2 = mrdfits(widefiles[j+f], 2, h2, /unsigned)
      im3 = mrdfits(widefiles[j+f], 3, h3, /unsigned)
      if strmid(h1[0], 0, 6) ne 'SIMPLE' then h1 = h1[1:*]
;      im1 = uintarr(nx, ny)+1
;      im2 = uintarr(nx, ny)+1
;      im3 = uintarr(nx, ny)+1
;    hiraw, im, widefiles[j+f], h, chip = chipno ;hires mosaic
      flat1[*, *, j] = 1d*im1/median(im1[*])
      flat2[*, *, j] = 1d*im2/median(im2[*])
      flat3[*, *, j] = 1d*im3/median(im3[*])
      checkflat, im2, widefiles[j+f]
    endfor
    for x = 0, nx-1 do begin
      for y = 0, ny-1 do begin
        medflat1[x, y] = median(flat1[x, y, *])
        medflat2[x, y] = median(flat2[x, y, *])
        medflat3[x, y] = median(flat3[x, y, *])
      endfor
    endfor
    mwrfits, medflat1, 'j12.flat'+strtrim(string(i), 2)+'.1', h1, /create
    mwrfits, medflat2, 'j12.flat'+strtrim(string(i), 2)+'.1', h2
    mwrfits, medflat3, 'j12.flat'+strtrim(string(i), 2)+'.1', h3
  endfor
endif
  im = double(im)
  totwf = im * 0.d0
  stop
  FOR i = 0, nflatsets-1 do begin   ;Loop through wide flats  
    im = mrdfits('j12.flat'+strtrim(string(i),2)+'.1', 2, h)
    im = rotate(im, 3)
;   hiraw, im, widefiles[i], chip = chipno ;hires mosaic
    nc = n_elements(im[*, 0])   ;# cols
    for j = 0, nc-1 do begin    ;Subtract Bias, col by col
      biaslev = median(im[j, 5:13]) ;hires mosaic
      im[j, *] = im[j, *] - biaslev
    endfor
    im = nonlinear(im)
    totwf = totwf + im
  ENDFOR

; STORE the FINAL TOTAL WIDE FLAT
wdsk,totwf,prefix+'.med',/new   ;wdsk store co-added wide flat -gm
trace,15,'ADDWF: Wide Flat images are now summed and stored as: '+prefix+'.sum'

end




