function find_halpha, obs, vd, wav=wav, magellan=magellan $
                    , keck=keck, lick=lick, plot=plot
sz = size(obs)
npix = sz[1]
sm_wav, vd, wc
if 1-keyword_set(wav) then $
  dum = expand_wc(wc, wav, nord=nord, /wav, npix=npix)

case 1 of
    keyword_set(magellan): begin
        hord = 23
        prange = indgen(1000)+500
    end
    keyword_set(lick): begin
        hord = 27
        prange = indgen(1000)+500
        iodoffset = 20
    end
    else: begin
        print,'FIND_HALPHA: Assuming Lick'
        hord = 27
        prange = indgen(1000)+500
    end
endcase
wha = wav[prange,hord]
wio = wav[prange,hord + iodoffset]

rdnso, wsun, sun, min(wha)-0.1, max(wha)+0.1
rdfts, wfts, sfts, min(wio)-0.1, max(wio)+0.1
s = dspline(wsun, sun, wha)
iod = dspline(wfts, sfts, wio)
imin = hord-4
imax = hord+4
pk = fltarr(imax-imin+1)
for i = imin,imax do begin
    ind = i - imin
    contf, obs[prange,i], cs, nord=5
    oh = obs[prange,i]/max(obs[prange,i])
    contf, obs[prange,i+iodoffset], ci, nord=5
    oi = obs[prange,i+iodoffset]/ci
    sh = ccpeak(s, oh, 200,ccf=ccfh)
    sh = ccpeak(iod, oi, 200,ccf=ccfi)
    pk[ind] = max(ccfi)+max(ccfh)
    if keyword_set(plot) then begin
        plot, ccfh, title='order '+str(i), chars=2
        oplot, ccfi, co=!red
        print, pk[ind]
        cursor, xdum, ydum, /up
        if xdum lt !x.crange[0] then stop
    endif
endfor
dum = max(pk, imx)
return, imx+imin
end
