function zchi_grid, info, nel, fracz=fracz, chi=bestchi, plot=plot, resid=resid
chi = fltarr(nel)
if 1-keyword_set(fracz) then fracz = 0.0075
z = makearr(nel, info.par[12]+[-1,1]*abs(info.par[12])*fracz)
degf = n_elements(where(info.wt gt 0)) - info.nfltpar - 2 ;degrees of freedom in fit
for i = 0, nel-1 do begin
    par = info.par
    par[12] = z[i]
    yfit = starsyn(par, info=info)
    resid = double(info.obchunk - yfit) ;compute reduced chi-sq
    wtres = info.wt * resid^2.0 ;weighted residuals^2
    chi[i] = total(wtres) / degf ;chi-squared
endfor
use = makearr(nel/2, 0.25*nel, 0.75*nel)
a = polyfit(z[use], chi[use], 2, fit)
zbest = -a[1]/(2*a[2])
bestchi = poly(zbest, a)
par[12] = zbest
resid = starsyn(par, info=info)
if keyword_set(plot) then begin
    plot, z, chi, ps=-8
    oplot, z[use], fit, col=!green
    hline,0.3, col=!gray
    oplot, z, (chi-poly(z, a))*200+0.3, ps=8
endif
return, zbest
end
