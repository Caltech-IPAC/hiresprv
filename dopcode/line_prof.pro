function line_prof, x, a, prof
npix = n_elements(prof)
;x = findgen(npix)
xpix = findgen(npix) - npix/2
xnew = x/abs(a[2]) - (a[1]*2 - median(x))
newprof = a[0]*dspline(x, prof, xnew)
return, newprof
end
