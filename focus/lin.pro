pro lin, fn
;linearity


if n_elements(hextek) eq 0 then hextek = ' '

;hd =  headfits(fn)
dum =  mrdfits(fn, 0, hd)
cofhd =  'COFRAW=' + strmid(hd(140), 24, 7)
cafhd =  'CAFRAW=' + strmid(hd(131), 24, 7)
;      h = headfits(fn)
;expt=fix(hdrdr(hd,'ELAPTIME'))
;expt=hdrdr(hd,'ELAPTIME')
expt=hdrdr(hd,'EXPTIME')

;print,cofhd
;print,cafhd

hiraw, im, fn
;im = im-median(im)
x = 1200
y = 5300
sz = 330
subim = float(im(x - sz:x+sz, y-sz:y+sz))
med = median(subim)
subim =  subim - med

;tot = total(subim)
i = sort(subim)
nel = sz*sz
stop
sz = float(sz)
pk = subim(sz*sz-50)
print, 'peak=', pk

print, 'Exposure Time =', expt
print,'Peak Counts =', pk
display, im, max = 20000, min = 2, /log

oplot, [x-sz, x+sz], [y+sz,y+sz], co = !white
oplot, [x-sz, x+sz], [y-sz,y-sz], co = !white
oplot, [x-sz, x-sz], [y-sz, y+sz], co = !white
oplot, [x+sz, x+sz], [y-sz, y+sz], co = !white
pc =  !p.color
!p.color =  !red
xyouts, x-sz-200, y+sz+200, 'Exp. Time = '+ strtrim(string(expt), 2), size = 3
xyouts, x-sz-200, y+sz+40, 'Total = '+ strtrim(string(tot), 2), size = 3
!p.color =  !white
xyouts, x-sz-210, y+sz+205, 'Exp. Time = '+ strtrim(string(expt), 2), size = 3
xyouts, x-sz-210, y+sz+45, 'Total = '+ strtrim(string(tot), 2), size = 3
 !p.color = pc


;xyouts, 2, 66.3, '!6<FWHM>='+strfwhm, size = 1.8

;tvlct, r, g, b, /get
;write_png, fn+'.png', tvrd(true = 1), r, g, b
;spawn, 'open '+fn+'.png'
end
