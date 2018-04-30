function sum_gauss, x, coef, gaussarray=garr
npix = n_elements(x)
sz = size(coef)
npar = sz[1]
ngau = sz[2]
xarr = rebin(x, npix, ngau)
garr = rebin(coef[0,*], npix, ngau) * $
       exp(-(xarr-rebin(coef[1,*], npix, ngau))^2/ $
           (2.*rebin(coef[2,*], npix, ngau)^2))
return, total(garr, 2)
end
