function jas_shiftspec, s1, s2, plot=plot, lick=lick
nel = 100
sz = size(s1,/dim)
npix = sz[0]
nord = sz[1]
x = findgen(nord)
;x = fillarr(nel*2, nel, npix-nel)
;nx = n_elements(x)
;sh = fltarr(nx)
new = s2
ms = fltarr(nord)
for j = 0, nord-1 do begin
    spec = rmcont(s1[*,j], /cont)
    ref  = rmcont(s2[*,j], /cont)
;    thiswav = wav[*,j]
;    new[*,j] = match_spec(thiswav, ref, spec, lick=lick)
    sh = ccpeak(spec, ref, ccf=ccf)
    ms[j] = sh
endfor
dummy = robust_poly_fit(x, ms, 1, meansh)
for i = 0, nord-1 do begin
    new[*, i] = shift_interp(s1[*, i], meansh[i])
endfor

if keyword_set(plot) then begin
    plot, x, ms, chars=2, xtit='Order', ytit='Shift', ps=-8
    oplot, x, meansh, col=!red, ps=-8
    cursor, xdum, ydum, /up
    if xdum lt !x.crange[0] then stop
endif

return, new
end

function jj_addspec, lines, bc=bc, jd=jd, tape=tape, plot=plot $
                     , noadd=noadd, keck2=keck2, lick=lick, median=median

;Purpose: Called by make_dsst to co-add consecutive template exposures.

nl = n_elements(lines)
for i = 0, nl-1 do begin
    tempnm = (getwrd(lines[i], 0))[0]
    if i eq 0 then begin
        rdsi,s,tempnm  ; open the spectrum
        bc = double((getwrd(lines[i], 2))[0])
        jd = double((getwrd(lines[i], 3))[0])
        npix = n_elements(s[*,0])
        z = where(s eq 0, nz)
        if nz gt 0 then s[z] = 0.1
        sarr = s
    endif else begin
        rdsi,next,tempnm
;;; Just add for now. Still working on the shifting
        z = where(next eq 0, nz)
        if nz gt 0 then next[z] = 0.1
        old = next
        next = jas_shiftspec(old, s, plot=plot, lick=lick)
        sarr = [[[sarr]], [[next]]]
        bc = [bc, double((getwrd(lines[i], 2))[0])]
        jd = [jd, double((getwrd(lines[i], 3))[0])]
    endelse
endfor
if nl gt 1 and 1-keyword_set(noadd) then begin
    if keyword_set(median) then snew = median(sarr, dim=3) else $
      snew = total(sarr, 3)  ; simple co-add of the observed template
endif else snew = sarr
bc = bc[0]
jd = 2.44d6+jd[0]
tape = strmid(str(lines[0]), 0, 4)
return, snew
end
