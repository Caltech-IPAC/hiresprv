;;; Continuum normalize a spectral segment.
function contnorm, specin, spec=specreturn
on_error,2
spec = specin
npix = n_elements(spec)
x = findgen(npix)
for i = 0, 1 do begin
    dum = max(spec[0:npix/3-1], hileft)
    spec[hileft] = 0
    dum = max(spec[0:npix/3-1], hileft)

    lo = 2*npix/3
    hi = npix-1
    dum = max(spec[lo:hi], hiright)
    hiright = hiright + lo
    spec[hiright] = 0
    dum = max(spec[lo:hi], hiright)
    hiright = hiright + lo
    if i eq 0 then begin
        a = polyfit([hileft, hiright], spec[[hileft, hiright]], 1)
        fit = poly(x, a)
        spec = spec - fit 
        oldhl = hileft
        oldhr = hiright
    endif else begin
        if spec[hileft] lt 0 then hileft = oldhl
        if spec[hiright] lt 0 then hiright = oldhr
        a = polyfit([hileft, hiright], specin[[hileft, hiright]], 1)
        cont = poly(x, a)
    endelse
endfor
if keyword_set(specreturn) then return, specin/cont else return, cont
end
