pro di, fn, hextek = hextek
;display images and do things

if n_elements(hextek) eq 0 then hextek = ' '

;hd =  headfits(fn)
dum =  mrdfits(fn, 0, hd)
cofhd =  'COFRAW=' + strmid(hd(140), 24, 7)
cafhd =  'CAFRAW=' + strmid(hd(131), 24, 7)
print,cofhd
print,cafhd

hiraw, im, fn
im = im-median(im)
redmed =  median(im(*, 2048*2:*))
im(*, 2048*2:*) = im(*, 2048*2:*) - redmed
;window, 1
;wset, 1
;!p.multi = 0
;display, im, min = 1, max = 1000
;stop
;Remove saturated lines
nrow = n_elements(im(0, *))
ncol =  n_elements(im(*, 0))
im(*,0:30) =  1.   ;get rid of top rows
im(*, nrow-31:nrow-1) =  1.   ;bottom rows
im(0:30, *) =  1   ;left is zerod
im(ncol-30:ncol-1,*) =  1.  ;right

;display, im, min = 2, max = 1000
for j = 2, nrow-3 do begin
  sp =  im(*, j)
  i = where(sp gt 30000., n)
  if n ge 1 then begin
    ind =  where(i ge 5 and i le ncol-6, qq)
    if qq ge 1 then i =  i(ind)
    im([i-8, i-7, i-6, i-5, i-4, i-3, i-2, i-1, i, i+1, i+2, i+3, i+4, i+5, i+6, i+7, i+8], j-28:j+28) =  1.
  endif
end

;Make 9 sub-images
;Set Parameters for
sz =  200 ; subimage dimensions
nsz =  5

;xarr = [800, 1400, 2000, 2600, 3200]  ;columns
;yarr = [5000,4000, 3000, 2000, 1000] ;rows
xarr = [0.1, 0.5,  0.9] * 4096.  ;columns
yarr = [0.5, 0.7, 1.25, 1.7, 2.3, 2.75] * 2048. ;rows
yarr =  reverse(yarr)
nx =  n_elements(xarr)
ny =  n_elements(yarr)
fwhm_arr = fltarr(nx, ny)

scl = 1.5
window, 0, xsize = scl*400, ysize = scl*600, title = fn
!p.multi = [0, nx, ny]
!x.margin =  [5., 1.5]
!y.margin =  [2., 1.]
!x.charsize = 1.
!y.charsize = 1.
!p.background =  !white
!p.color = !black

;Loop through 9 regions
for j = 0, ny-1 do begin    ;rows
  for i = 0, nx-1 do begin  ;col
    x =  xarr[i]                ;col
    y =  yarr[j]                ;row
    subim =  im(x-sz:x+sz, y-sz: y+sz)
    
    ind = where(subim eq max(subim))
    ind = ind(0)
    yint =  ind/(2.*sz+1)
    y =  yint +y-sz
    x = (yint - fix(yint))*(2.*sz+1) + x-sz 
    subim =  im(x-nsz:x+nsz, y-nsz: y+nsz)

;Revised location & FWHM
    mashcol =  total(subim, 1)
    mashrow =  total(subim, 2)
    dum =  max(mashcol, rowloc)  
    dum =  max(mashrow, colloc)  
    xind = indgen(2*nsz+1)

;Find FWHM - using spline
    osamp = 100
    finex =  (1.+findgen(2*nsz*osamp-2))/osamp
    finerow =  spline(xind, mashrow, finex)
    inddum = where(finerow gt 0.5*max(finerow), nfwhm)
    fwhm =  nfwhm/(1.*osamp)
    fwhm_arr(i, j) =  fwhm
    ;Improved center
    x = x + colloc - nsz
    y = y + rowloc - nsz

;    wset, 1
;    oplot, [x], [y], ps = 6, syms = 10
    wset, 0
    subim =  im(x-nsz:x+nsz, y-nsz: y+nsz)
    subim =  subim - median(subim(*, nsz)) ;subtract continuum

    indx =  sort(subim)
    top = subim(indx(n_elements(indx)-2))
    lev =  [0.01, 0.03, 0.1, 0.5, 0.95]*top
    lev =  [0.1, 0.5]*top
     ;    if y lt 2140 then co =  !blue
     ;    if y gt 2140 and y lt 2140*2 then co =  !forest
     ;    if y gt 2140*2 then co =  !red
    co =  !black
    c_c =  [!gray, !black]
    if j eq 0 then !y.margin =  [2., 3.] else !y.margin = [2., 1.]
;    contour, subim, levels = lev, /xsty, /ysty, c_colors = c_c, xra = [0, 10], yra = [0, 10], col = co
    c_ann =  [' ', ' ']
    if j eq 0 and i eq 1 then c_ann =  ['0.1', '0.5']

;    if j eq 0 and i eq 0 then begin
;    contour, subim, levels = lev, /xsty, /ysty, xra =[0, 10], $
;    yra = [0, 10], c_linestyle = [2, 0], c_annotation =  c_ann, /isotropic 
;    endif else begin
;    display, subim,/noerase
    contour, subim, levels = lev, /xsty, /ysty, xra =[0, 10], $
    yra = [0, 10], c_linestyle = [2, 0], c_annotation =  c_ann, /isotropic ; , /overplot ,  /noerase ; , col=co
;    plot, indgen(11), /nodata
;    endelse

    !p.color = !black
    ylab =  nsz*2+0.5
    if i eq 0 and j eq 0 then xyouts, 0.1,ylab ,fn, size = 1.5
    if i eq 1 and j eq 0 then xyouts, -5, ylab,'!6 '+ cofhd, size = 1.3
    if i eq 2 and j eq 0 then xyouts, -10, ylab, '!6 '+ cafhd, size = 1.3
;    if i eq 3 and j eq 0 then xyouts, -0.4, ylab, '!6 Hextek:'+hextek

    !p.color = !white
    !p.color = !black
    xyouts, 0.1, 1.2, '!6 C '+strtrim(string(fix(x)), 2), size = 1.0
    xyouts, 0.05, 0.5, '!6 R '+strtrim(string(fix(y)), 2),  size = 1.0
    ffwhm = fix(fwhm*100.) &  fwhm1 =  ffwhm/100.
    strfwhm =  strmid(strtrim(string(fwhm1), 2),0, 4)
    xyouts, 1.543*nsz, 2.*nsz-1.3, strfwhm
    if j eq 0 and i eq 1 then xyouts, 0.8*nsz, 2.*nsz-1.3, 'FWHM='

  endfor
endfor

    fwhm =  median(fwhm_arr)
print,'Median FWHM = ', fwhm
    ffwhm = fix(fwhm*100.) &  fwhm1 =  ffwhm/100.
    strfwhm =  strmid(strtrim(string(fwhm1), 2),0, 4)

xyouts, 2, 66.3, '!6<FWHM>='+strfwhm, size = 1.8

tvlct, r, g, b, /get
write_png, fn+'.png', tvrd(true = 1), r, g, b
spawn, 'open '+fn+'.png'
end
