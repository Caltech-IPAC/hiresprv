function jjgauss,x,a,normalize=normalize
on_error,2		;Return to caller if an error occurs
z = ((x - a[1])/a[2])^2
f = fltarr(n_elements(z))
minexp = alog((machar(DOUBLE=double)).xmin)     
w = where(z lt -2*minexp, nw)
if nw gt 0 then f[w] = a[0]*exp( -z[w] / 2 )
if n_elements(a) gt 3 then f = f + poly(x,a[3:*])
if keyword_set(normalize) then f = f/int_tabulated(x, f)
return,f
end

