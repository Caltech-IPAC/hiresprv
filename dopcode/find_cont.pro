function fc_halfgaus, x
coef = fltarr(3)
coef[0] = 1.
coef[1] = x[0]
coef[2] = (max(x) - x[0])/10.
g = jjgauss(x, coef)
return, g
end

function fc_get_sun, win
w1 = win
vactoair, w1
dsp = w1[1]-w1[0]
rdnso, wsun, sun, w1[0]-dsp, max(w1)+dsp
airtovac, wsun
sol = dspline(wsun, sun, win)
return, sol
end

function find_cont, win, s, percentile=percentile, nogauss=nogauss
if 1-keyword_set(percentile) then percentile = 0.98
w1 = win
w = win
sol = fc_get_sun(w1)
sh = ccpeak(sol, s, ccf=ccf)
wsh = w - sh * (w[1]-w[0]) 
sol1 = fc_get_sun(wsh)
sol1 = sol1/max(sol1)
;cont = where(sol1 ge percentile, nc)
p = 2*percentile-1
h = histogram(sol1, min=p, max=1, bins=0.0005, rev=ri)
nh = n_elements(h)
ncont = total(h)
if ncont gt 0 then begin
    wt = fc_halfgaus(indgen(nh))
    cont = sol1*0+1
    if 1-keyword_set(nogauss) then begin
        for i = 0, nh-2 do begin
            if ri[i] lt ri[i+1] then begin
                cont[ri[ri[i]:ri[i+1]]] = wt[i]
            endif
        endfor
    endif
endif else cont = -1
return, cont
end
