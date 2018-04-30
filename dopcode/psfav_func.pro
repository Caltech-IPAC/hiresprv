function psfav_func, infoin, par=par
info = infoin
if keyword_set(par) then info.par = par
vd = {ordob: info.order, pixob: info.pixel, pixt: info.pixel $
      , fit:1, cts:1d4, iparam:info.par}
psfav, vd, info.order, info.pixel, 4, psf $
       , psfpix=info.psfpix, psfsig=info.psfsig
return, psf
end
