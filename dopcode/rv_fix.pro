function rv_fix, cf, plot=plot
new = cf
a = robust_poly_fit(cf.bc, cf.mnvel, 1, fit)
new.mnvel -= fit
if keyword_set(plot) then begin
    plot, cf.bc, cf.mnvel, ps=8
    xx = makearr(1000, mm(cf.bc))
    oplot, xx, poly(xx, a), co=!red
endif
return, new
end
