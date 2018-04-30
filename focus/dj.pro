pro dj, fn
;display images ala XEMAX

dum =  mrdfits(fn, 0, hd)
cofraw =  hdrdr(hd, 'COFRAW')
cafraw =  hdrdr(hd, 'CAFRAW')
cofhd =  'COFRAW='+string(cofraw)
cafhd =  'CAFRAW='+string(cafraw)
expt=hdrdr(hd,'EXPTIME')

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

;display, im, min = 2, max = 3000, /log
;stop
for j = 2, nrow-3 do begin
  sp =  im(*, j)
;  i = where(sp gt 30000., n)
  i = where(sp gt 50000., n)
  if n ge 1 then begin
    ind =  where(i ge 5 and i le ncol-6, qq)
    if qq ge 1 then i =  i(ind)
    im([i-8, i-7, i-6, i-5, i-4, i-3, i-2, i-1, i, i+1, i+2, i+3, i+4, i+5, i+6, i+7, i+8], j-28:j+28) =  1.
  endif
end
;End Remove Saturated Lines

;display, im, /log, min = 100, max = 5000
;stop



;Make 9 sub-images
;Set Parameters for
sz =  100 ; subimage dimensions

;xarr = [0.05, 0.5,  0.95] * 4096.  ;columns
;yarr = [2.25,  1.5, 0.5] * 2048. ;rows

xarr = [443., 2050., 3480.]
yarr = [5689., 1.5*2048., 1260.]

xyarr =  fltarr(2, 9)
xyarr(*, 0) = [582, 5808]
xyarr(*, 1) = [1902, 5847]
xyarr(*, 2) = [3580,  5824]
xyarr(*, 3) = [780, 3553]
xyarr(*, 4) = [2049, 3734]
xyarr(*, 5) = [3729, 3522]
xyarr(*, 6) = [817,  1753]
;xyarr(*, 6) = [578.9,  301.8]
xyarr(*, 7) = [2044,  1017]
xyarr(*, 8) = [3712, 845]

xyarr(*, 0) = [600, 5808]
xyarr(*, 1) = [2000, 5847]
xyarr(*, 2) = [3400,  5824]
xyarr(*, 3) = [600, 3000]
xyarr(*, 4) = [2048, 3000]
xyarr(*, 5) = [3400, 3000]
xyarr(*, 6) = [600,  1000]
;xyarr(*, 6) = [578.9,  301.8]
xyarr(*, 7) = [2048,  100]
xyarr(*, 8) = [3400, 1000]


window, 0, xsize = 600 , ysize = 900, title = fn
display, im, min = 50, max = 2000, /log
print, 'Point at 9 positions, reading like a book'
for j = 0, 8 do begin

  oplot, [xyarr(0, j)], [xyarr(1, j)], ps = 6, syms = 4, co = !white
  cursor, xp, yp
  xyarr(*, j) = [xp, yp]
  oplot, [xp], [yp], ps = 6, syms = 4, co = !white
  wait, 1
endfor


;nx =  n_elements(xarr)
;ny =  n_elements(yarr)
nx = 3
ny = 3
;fwhm_arr = fltarr(nx, ny)
nbox = 9
len =  2*sz+1
;catim =  fltarr(nbox*len, len)  ;nbox*len columns
    trim = 80
    lentrim = len-2.*trim
catim =  fltarr(nbox*lentrim, lentrim)  ;nbox*len columns

window, 0, xsize = 9*200 , ysize = 200, title = fn
;!p.multi = [0, nx, ny]
!x.margin =  [5., 1.5]
!y.margin =  [2., 1.]
!x.charsize = 1.
!y.charsize = 1.
!p.background =  !white
!p.color = !black

;Loop through 9 regions
for j = 0, ny-1 do begin        ;rows
  for i = 0, nx-1 do begin      ;col
    ind = i+j*3

;    x =  xarr[i]                ;col
;    y =  yarr[j]                ;row
    x =  xyarr(0, ind)
    y =  xyarr(1, ind)
    if i eq 2 and j eq  0 then x = x+100 ; avoid saturated line
    subim =  im(x-sz:x+sz, y-sz: y+sz)
    subim =  subim - median(subim)
    subim =  float(subim)

;Revised location & FWHM
;    mashcol =  total(subim, 1)
;    mashrow =  total(subim, 2)
;    dum =  max(mashcol, rowloc)  
;    dum =  max(mashrow, colloc)  

;    y =  y + rowloc-sz
;    x =  x + colloc-sz

;    subim =  im(x-sz:x+sz, y-sz: y+sz)
;    subim =  subim - median(subim)
;    xarr(i) = x
;    yarr(j) =  y
 ;End Revision

;    catim(ind*len:(ind+1)*len-1, 0:len-1) =  subim
    subtrim =  subim(trim:len-1-trim, trim:len-1-trim)
    subtrim =  subtrim - median(subtrim) ;subtract backgroun
    pk = max(subtrim)
    topval =  100
    subtrim =  topval*subtrim/pk  ;normalize region to 100
    lentrim =  len-2*trim
    catim(ind*lentrim:(ind+1)*lentrim-1, 0:lentrim-1) =  subtrim
  endfor
endfor
!x.charsize = 0.01
display, catim, max = topval, min = 0.5, /log
for qq = 1, 8 do begin
  col = !gray
 thi = 1
 if qq eq 3 or qq eq 6 then thi =  3
  oplot, [lentrim*qq, lentrim*qq], [0, 2.*sz], co = col, thick = thi
endfor

for j = 0, ny-1 do begin        ;rows
  for i = 0, nx-1 do begin      ;col
    ind = i+j*3
    xx = ind*lentrim
;    x = xarr(i)
;    y = yarr(j)
     x =  xyarr(0, ind)
     y =  xyarr(1, ind)
!p.color = !white
    xyouts, xx, 6, '!6 C '+strtrim(string(fix(x)), 2), size = 1.2
    xyouts, xx, 2, '!6 R '+strtrim(string(fix(y)), 2),  size = 1.2
endfor
endfor
oplot, [0, lentrim*3], [0, 0], col = !red,  thick = 3
oplot, [lentrim*3, lentrim*6], [0, 0], col = !forest, thick = 3
oplot, [lentrim*6, lentrim*9], [0, 0], col = !blue, thick = 3

oplot, [0, lentrim*3], [lentrim, lentrim]-1, col = !red,  thick = 3
oplot, [lentrim*3, lentrim*6], [lentrim, lentrim]-1, col = !forest, thick = 3
oplot, [lentrim*6, lentrim*9], [lentrim,  lentrim]-1, col = !blue, thick = 3

xyouts, 5, lentrim-6, fn,  size = 1.7
xyouts, lentrim+2, lentrim-5, cofhd, size = 1.5
xyouts, lentrim+2, lentrim-10, cafhd,  size = 1.5
tvlct, r, g, b, /get
write_png, fn+'.png', tvrd(true = 1), r, g, b
spawn, 'open '+fn+'.png'

end
