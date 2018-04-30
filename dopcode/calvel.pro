function calvel, cf
new = cf
a = robust_poly_fit(cf.bc, cf.mnvel, 2, fit)
new.mnvel = cf.mnvel - fit
return, new
end
