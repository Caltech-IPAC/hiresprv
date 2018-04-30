function psf_fitter, p, x=x, y=y, psfpix=psfpix, psfsig=psfsig
ip = gpfunc(x, p, psfpix=psfpix, psfsig=psfsig)
resid = y-ip
return, resid
end

pro psffit, psf, fit
psfpix=[0.00,-6.00,-4.80,-3.70,-2.70,-1.80,-1.20,-0.90,0.90,1.20,1.80,2.70,3.70,4.80,6.00]
psfsig=[1.00,0.00,1.00,0.80,0.65,0.50,0.40,0.30,0.30,0.40,0.50,0.65, 0.80,1.00, 0.00]
x = fillarr(0.25, -15, 15)
fa = {x: x, $
      y: psf, $
      psfpix: psfpix, $
      psfsig: psfsig $
     }
fz = [0,1,11,12,13,14,18,19]
cmrestore,'~/emu/psf_par_guess.sav',p0
parinfo = replicate({fixed:0}, 20)
parinfo[fz].fixed = 1
par = mpfit('psf_fitter', p0, func=fa, parinfo=parinfo)
save,par,file='~/emu/psf_par_solution.sav'
fit = gpfunc(x, par, psfpix=psfpix, psfsig=psfsig)
end
