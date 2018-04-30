pro plotxwd, run, obnm, onum
;plot spatial profile and extraction width from pipeline

;syntax
  if n_params() lt 3 then begin
    print, 'syntax: plotxwd, run, obnm, onum'
    print, "  e.g.: plotxwd, 'j72', 800, 7  ;plot order 7 of j720800.fits"
    return
  endif

;internal parameters
  chip = 2				;1=blue, 2=green, 3=red
  offset = -200				;from getxwd.pro
  soff = 10				;from getxwd.pro

;define global variables for reduction
  hamset, /silent

;code from hirspec.pro that reads and processes image
  rawfile = '/mir3/raw/' + run + string(obnm, form='(i4.4)') + '.fits'
  hiraw, im, rawfile, chip=chip		;read and rotate image
  im -= median(im[*,5:13])		;bias subtraction
  im = nonlinear(im)			;nonlinear response correction

;useful sizes
  ncol = n_elements(im[*,0])		;number of columns
  swacen = ncol/2 + offset		;center of swatch

;code from hirspec.pro that determines order locations
  rdsk, dorc, 'j72.ord'			;default order locations
  shiftorc, im, dorc, orc		;shifted for observation
  nord = n_elements(orc[0,*])		;number of echelle orders

;get nominal extraction width
  xwd = getxwd(im, orc)			;extract width

;diagnostic plot
  display, im, max=100
  xord = findgen(ncol)
  for iord=0,nord-1 do begin
    yord = poly(xord,orc[*,iord])
    oplot, xord, yord, co=c24(2)
    for i=-1,1,2 do oplot, xord, yord+i*xwd, co=c24(3)
  endfor
  for i=-1,1,2 do oplot, swacen+soff*[i,i], !y.crange, co=c24(6)
  print, 'press a key to continue'
  if get_kbrd(1) eq 'q' then retall

;code from getxwd.pro that extracts a vertical swatch and calculates peaks
  swa = total(im[swacen-soff:swacen+soff,*], 1)
  ndeg = n_elements(orc[*,0])-1
  pk = orc[ndeg,*]
  for i=ndeg-1,0,-1 do pk = orc[i,*] + pk*swacen
; pk = pk + 0.5 ; COMMENTED OUT BY JEFF BECAUSE THIS SEEMS WRONG

;code from getxwd.pro to calculate 'curve of growth'
  olo = onum > 1
  range = (pk[olo]-pk[olo-1])/2.+1
  xmin = pk[onum]-range
  xmax = pk[onum]+range
  prof = swa[xmin:xmax]
  xprof = fix(xmin) + findgen(n_elements(prof))

;diagnostic plot
  plot, xprof, prof, /xsty, /ylog, ysty=3, /nodata $
      , xtit='Column Index', ytit='ADU in Swath', chars=2
  oplot, xprof, prof, ps=2, co=c24(8)
  oplot, 2*pk[onum]-xprof, prof, ps=4, co=c24(5)
  oplot, pk[onum]+[0,0], 10^!y.crange, co=c24(2)
  for i=-1,1,2 do oplot, pk[onum]+xwd*[i,i], 10^!y.crange, co=c24(3)
  for i=-1,1,2 do oplot, pk[onum]+0.5*xwd*[i,i], 10^!y.crange, co=c24(3), li=2

end
