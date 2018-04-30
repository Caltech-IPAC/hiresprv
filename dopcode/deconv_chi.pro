function dc_gauss, x, a
z = ((x - a[1])/a[2])^2
return, a[0]*exp( -z / 2d )
end

function deconv_chi_func, par, wav=wav, spec=specin, psf=psf, node=node $
                   , movie=movie, sig=sig, orig=orig, newspec=spec $
                   , ngrid=ngrid, resid=diff, trim=trim, jjgauss=jjg

spec = specin
wid = par[0]
p = par[1:ngrid]
off = par[ngrid+1:*]
npar = n_elements(p)
npix = n_elements(wav)
for i = 0, npar-1 do begin
    dist = wav - node[i]
    tau = -alog(spec)
    if keyword_set(jjg) then begin
        amp = jjgauss(dist, [p[i], off[i], wid]) + 1 
    endif else amp = dc_gauss(dist, [p[i], off[i], wid]) + 1
    spec = exp(-tau*amp) ;< 1
endfor
num_conv, spec, psf, newconv
diff = newconv - specin
trim = 10
if keyword_set(movie) then begin
;z = where(spec gt 1.5, nz)
;if nz gt 0 then stop
;if stdev(diff[trim:npix-trim-1]) lt 0.002 then stop
    o = 0.2
    plot, wav, specin+o, yr=[-0.2, 2], /ys, ps=8, syms=0.5
    oplot, wav, newconv+o, co=!magenta
    oplot, wav, diff*5, ps=8, syms=0.5
;    oplot, wav, orig, co=!green, ps=8, syms=0.5
    oplot, wav, spec, co=!red
;    oplot, node, node*0+1.4, ps=8
    hline, 1.4, lines=2
    oplot, node+off, node*0+1.4+p*0.1, ps=8, co=!red
    plots, median(wav)+[-1,1]*wid, [0.2, 0.2]
    xyouts, 20, 0.2, textoidl('\sigma = '+sigfig(stdev(diff[trim:npix-trim-1]), 3)), chars=2
;    wait, 0.5
endif

return, diff[trim:npix-trim-1]/sig
end

pro deconv_chi_plot, fcn, par, iter, fnorm, functargs=fa $
                  , parinfo=parifno, quiet=quiet, dof=dof
wset,30
dum = deconv_chi_func(par, wav=fa.wav, spec=fa.spec, psf=fa.psf $
               , sig=fa.sig, node=fa.node, ngrid=fa.ngrid, /movie)

mpfit_defiter, fcn, par, iter, fnorm, FUNCTARGS=fa, $
                   quiet=quiet, parinfo=parinfo, dof=dof
wset,0
device,copy = [0,0,!d.x_vsize,!d.y_vsize,0,0,30]

end

pro deconv_chi, specin, psf, dspec, osamp=osamp, movie=movie, snr=snr $
                , initfac=initfac, lim=lim, two=two, maxiter=maxiter $
                , dsst=dsst, mdwarf=mdwarf, ind=ind, quiet=quiet $
                , stop=stop, ngrid=ngridin, isolate=isolate, test=test $
                , sigma=sigma, jjgauss=jjgauss


if 1-keyword_set(osamp) then osamp = 1
fac = max(specin)+0.1
;fac = 1
spec = specin/fac
npix = n_elements(spec)
;wav = makearr(npix*osamp, 0, npix-1)
;wav = findgen(npix*osamp-(osamp-1))/float(osamp)
wav = makearr(npix*osamp, 0, npix-1./osamp)

convspec = dspline(indgen(npix), spec, wav)
npix *= osamp

if 1-keyword_set(sigma) then sigma = 2.5 ;;; Characteristic width (pixels)

sig = 1 ;;; pixel unc. fix this later!

if keyword_set(ngridin) then ngrid = ngridin else ngrid = 40
if 1-keyword_set(lim) then lim = [2, float(npix)/float(osamp)-3]
;if 1-keyword_set(initfac) then initfac = sigma*1.5

p0 = dblarr(ngrid*2+1)
p0[0] = sigma
npar = n_elements(p0)
if keyword_set(isolate) then begin
    w = where(spec lt 1-0.01, nw)
    if nw gt 0 then begin
        consec, w, lo, hi, ncon
        for i = 0, ncon-1 do begin
            if i eq 0 then node = makearr(ngrid, mm(w[lo:hi]))
        endfor
    endif
endif else node = makearr(ngrid, lim[0], lim[1])

if keyword_set(test) then begin
    stop
endif

fa = {wav:wav,       $
      spec:convspec,     $
      psf:keyword_set(psf) ? psf : fltarr(121)+1,           $
      sig:sig,           $
      node:node,         $
      ngrid:ngrid,       $
      jjgauss:keyword_set(jjgauss) $
     }

parinfo = replicate({fixed: 0b, limited:[0b,0b] $
                     , limits:[0.,0.], relstep: 0. $
                     , tied: '', step:0.}, npar)
parinfo.step = 0.25
parinfo[ngrid+1:*].step = 0.25
parinfo[0].step = 0.5
parinfo[0].limited = [1b, 1b]
parinfo[0].limits  = [sigma*0.5, sigma*5]
parinfo[ngrid+1:*].limited = [1b, 1b]
parinfo[ngrid+1:*].limits = [-1., 1.]*median(abs(node-shift(node,1)))*0.75

if keyword_set(movie) then begin ;initalize movie
    window,30,xs=800,ys=500,/pixmap
    ip = 'deconv_chi_plot'
endif
;save,fa

newpar = mpfit('deconv_chi_func', p0, functa=fa, iterproc=ip, parinfo=parinfo $
               , quiet=quiet, maxiter=maxiter)

dum = deconv_chi_func(newpar, wav=fa.wav, spec=fa.spec, psf=fa.psf $
                      , sig=fa.sig, node=fa.node $
                      , ngrid=fa.ngrid, newspec=dspec, resid=resid)

dspec *= fac
if keyword_set(movie) then wset,0

end
