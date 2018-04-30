function velrepair, cf, coef
;x = (cf.mdpar[1]+cf.mdpar[0])*
;x = cf.mdpar[10] * cf.mdpar[0]
x = cf.mdpar[10] / cf.cts * 1d8
;x -= mean(x)
;if 1-keyword_set(coef) then coef = [0., -1872];-2500.46]
if 1-keyword_set(coef) then coef = [18.8727, -0.197429, 2.47574d-4]
                                    
                                    
fit = poly(x, coef)
new = cf
new.mnvel -= fit
return, new
end
