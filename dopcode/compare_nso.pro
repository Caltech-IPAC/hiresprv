function cn_get_nso, dsst, chunk, bigz, resid=resid, spec=spec, wav=wav
spec = dsst[chunk].dst
xx = indgen(n_elements(spec))
wav = dwav(dsst[chunk])
rdnso, wsun, sun, min(wav)-10, max(wav)+10
airtovac, wsun
rebin, wsun, sun, wav*(1+bigz), sun2
sh = ccpeak(sun2, spec, ccf=ccf)
sun2 = shift_interp(sun2, sh)
q = spec/sun2
a = robust_poly_fit(xx, q, 2, fit)
sun3 = sun2*fit
resid = spec - sun3
return, sun3
end

pro compare_nso, chunk, bigz=bigz, rms=rms, dsstfile=dsstfile, plot=plot, ps=ps, eumu=emu, gv=gv
xs = 9
ys = 7

files = getenv("DOP_FILES_DIR")

if keyword_set(dsstfile) then restore,dsstfile else $
  restore,files+'dsstVESTAn_rj18.dat' ; Is this ever used?
;;; Determine Doppler shift of Vesta
if 1-keyword_set(bigz) then begin
    u = where(sdstwav gt 5500 and sdstwav lt 5550, nu)
    w = sdstwav[u]
    s = sdst[u]
    rdnso, wsun, sun, min(w)-10, max(w)+10
    airtovac, wsun
    rebin, wsun, sun, w, sun1
    vsun = ccs(w, sun1, w, s, 0, 0, allcf=allcf, r=[-200,200])
    bigz = vsun[0]/2.9979246d5
endif
if n_elements(chunk) gt 0 then begin
    sun3 = cn_get_nso(dsst, chunk, bigz, resid=resid, spec=spec, wav=wav)
    yr = [min([sun3,spec])*0.95, 1.1]
    yr2 = max(mm(resid[10:400]))*[-1,1]*1.05
    rms = sigfig(stdev(resid[10:400])*100,2)
    tit = '~/ps/compare_nso_chunk'+str(chunk)+'.eps'
    if keyword_set(ps) then psopen, tit, xs=xs, ys=yx, /inch, /color, /enc
    plot, wav, spec, pos = [0.1, 0.2, 0.95, 0.95], xchars=0.00001 $
          , yr=yr, /ys, title='Chunk # '+str(chunk)
    oplot, wav, sun3, co=!red
    xyouts, min(wav)+0.25, 1.025, 'RMS = '+rms+'%', chars=2
    plot, wav, resid, ps=8, syms=0.5, pos=[0.1, 0.05, 0.95, 0.2] $
          , chars=1.5, /noer, yticks=2, yr=yr2, /nodata, /ys
    hline, 0, lines=2, co=!gray
    oplot, wav, resid, ps=8, syms=0.5
    if keyword_set(ps) then psclose,/color
    if keyword_set(gv) then spawn, 'gv --watch '+tit+' &'
endif else begin
    nchunk = n_elements(dsst)
    rms = fltarr(nchunk)
    for i = 0, nchunk-1 do begin
        if i mod 20 eq 0 then counter, i, nchunk, /per
        sun3 = cn_get_nso(dsst, i, bigz, resid=resid)   
        xx = indgen(n_elements(sun3))
        cont = where(sun3 gt 0.97 and xx gt 10 and xx lt 400, nc, comp=lines)
        rms[i] = stdev(resid[lines])
    endfor
    if keyword_set(plot) then begin
        if keyword_set(ps) then psopen, '~/ps/compare_nso.ps' $
          , xs=xs, ys=ys, /inch
        x = float(dsst.pixt)/max(dsst.pixt) + dsst.ordt
        ytit = textoidl('!6RMS_{NSO - DSST} [%]')
        plot, x, rms*100, ps=8, syms=0.5, yr=[0, 0.05]*100,  $
              chars=2, xtit='!6Order', ytit=ytit, xr=[0,15]
        xyouts, 2, 4, 'Median RMS = '+sigfig(median(rms)*100,2)+' %', chars=2

        if keyword_set(ps) then psclose
    endif
endelse
end
