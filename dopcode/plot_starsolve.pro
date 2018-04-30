pro plot_starsolve, par, spec, yfit, info, niter, chi, ghparam=ghparam
wset, 30
numpix = n_elements(info.obchunk) 
xwav = dindgen(numpix)*par[13]+par[11]+info.w0 ;linear wavelength scale
fac = max(spec)

if par[0] lt 1 then range = 10  else range = 15
if keyword_set(ghparam) then range = 15
xpsf = fillarr(0.25, -range, range)
if 1-keyword_set(ghparam) then begin
    if n_elements(info.psf) lt 2 then begin
        ip = gpfunc(xpsf, par, info=info, /gau, array=gauarr) 
        if n_elements(gauarr) gt 0 then ng = n_elements(gauarr[0,*]) else $
          ng = 0
    endif else begin
        ip = info.psf
        ng = n_elements(gauarr)
    endelse

;    ip = 0
    g = jjgauss(xpsf, [max(ip), 0, info.psfsig[0]])

    plot, xpsf, g, pos=[0.1, 0.75, 0.75, 0.975], yr=[-0.25, max(ip)*1.05] $
          , /ys, lines=2, xticklen=0.08, /nodata, xr=[-10,10]
    oplot, xpsf, g, co=!magenta
    if n_elements(info.psf) lt 2 and ng gt 0 then begin
        for i = 0, ng-1 do oplot, xpsf, gauarr[*,i], lines=2
    endif
;oplot, xpsf, g, co=!gray
    hline, 0, co=!gray, lines=2
    vline, 0, co=!gray, lines=2
    oplot, xpsf, ip, co=!yellow
endif else begin
    if n_elements(info.psf) lt 2 then ip = ghfunc(xpsf, par, param=ghparam, info=info) else ip = info.psf
    g = jjgauss(xpsf, [max(ip), 0, 1.0])
    plot, xpsf, g, pos=[0.1, 0.75, 0.75, 0.975], yr=[-0.05, max(ip)*1.05] $
          , /ys, lines=2, xticklen=0.08, xchars=1d-5, xr=[-10,10]
    hline, 0, co=!gray, lines=2
    vline, 0, co=!gray, lines=2
    oplot, xpsf, ip, co=!yellow
endelse

ymin = min([spec, yfit]) * 0.97/fac
ymax = max([spec, yfit]) /fac
plot, xwav, spec/fac, pos=[0.1, 0.2, 0.75, 0.70],xchars=1d-4 $
      , ytit='Resid. Intensity', yr=[ymin, ymax], /noer, ychars=1.5 $
      , xticklen=0.001, ps=8, syms=0.7
oplot, xwav, yfit/fac, color=!green
bad = where(info.wt eq 0, nbad)
if nbad gt 0 then oplot, xwav[bad], spec[bad]/fac, ps=8, col=!red
resid = (spec-yfit)/fac
rms = stdev(resid)

xyouts, 0.77, 0.95, 'RMS = '+sigfig(rms*100,3)+' %', chars=1.5, /norm
xyouts, 0.77, 0.90, 'Niter = '+str(niter), chars=1.5, /norm
xyouts, 0.77, 0.85, textoidl('\chi = ')+sigfig(sqrt(chi), 3), chars=1.5, /norm
npar = n_elements(par)
yo = 0.8
for i = 0, npar-1 do begin
    if i ne 20 then begin
        if i eq 0 then begin
            xyouts, 0.77, yo, 'Par'+str(i)+'='+sigfig(par[i],3) $
                    , chars=1.5, /norm
        endif else begin
            xyouts, 0.77, yo, 'Par'+str(i)+'='+sigfig(par[i],3) $
                    , chars=1.5, /norm
        endelse
        yo -= 0.04
    endif
endfor
if stregex(info.test,'sine',/bool) then begin
    sine = 1
    xpix = fillarr(1, 0, info.obpix)
    sine = par[14]*sin(2*!pi*xpix/par[18] + par[19])
    resid += sine
endif
step = 0.05

yr = [-1,1]*max(abs(resid))*100
xtit = textoidl('\lambda [Ang]')
plot, /noer, xwav, resid*100, ytit='%', xchars=1.5, xtit=xtit, psym=8 $
      , pos=[0.1, 0.1, 0.75, 0.2], yticks=3, yr=yr, syms=0.7 $
      , xticklen=0.1

if keyword_set(sine) then begin
    oplot, xwav, sine*100, col=!red
endif
if nbad gt 0 then oplot, xwav[bad], resid[bad]*100, ps=8, col=!red
hline, 0, lines=2, co=!gray
wait,0.5
wset, 0
device,copy = [0,0,!d.x_size,!d.y_size,0,0,30]
;stop
end
