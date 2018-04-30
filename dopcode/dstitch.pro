;+
;  Stitch together a DST created from DSST or DSST_J. Uses STITCH structure as input. 
;  STITCH created in DSST.pro
;-

function dstitch, dsst, stitch, outfile=outfile, plot=plot, wav=wav, suntest=suntest, lick=lick
if 1-keyword_set(outfile) then outifle = 'dcs.dat'
n_chunk = n_elements(dsst)
ndst = n_elements(dsst[0].dst)
lastord = -1
u = uniq(dsst.ordt)
orders = dsst[u].ordt
nord = n_elements(u)
lastwav = 1d6
for j = 0, nord-1 do begin
    ind = where(dsst.ordt eq orders[j], nchunk)
    w0 = dsst[ind].w0
    x0 = stitch[ind].x0
    a = robust_poly_fit(x0, w0, 4, fit)
    dsst[ind].w0 = fit
    for k = 0, nchunk-1 do begin
        i = ind[k]
        thiswav = dwav(dsst[i]) ; WLS for DSST chunk
        disp = thiswav[1] - thiswav[0]
        ;;; Continuum level of DSST chunk
        cont = stitch_cont(dsst[i], stitch[i], meanx=meanx, meanc=meanc $ 
                           , xcont=xcont)  
        thisspec = dsst[i].dst * cont
        if k eq 0 then begin
            spec = thisspec
            wav = thiswav
            xpix = xcont
            bc = meanc
            xbc = meanx
        endif else begin
            ;;; Find where the right part of the primary spectrum overlaps
            ;;; with the left part of the next chunk
            roverlap = where(wav gt min(thiswav), nro)
            ;;; Find where the left portion of the new chunk overlaps w/
            ;;; the primary spectrum
            loverlap = where(thiswav lt max(wav)+3*disp, nlo)
            comp = where(thiswav gt max(wav))
            if nlo le ndst-2 and nro gt 0 then begin
                leftspec = dspline(thiswav[loverlap],  $
                                   thisspec[loverlap], $
                                   wav[roverlap]       $
                                  )
                x = findgen(nro)
                refine_linear = 0 ; Permanently off for now
                if keyword_set(refine_linear) then begin
                    x1 = x/4. + stitch[i].x0
                    q = spec[roverlap]/leftspec
                    dum = min(x1, imin)
                    dum = max(x1, imax)
                    r = imax-imin+1
                    range = [imin+r*0.1, imax-r*0.1]
                    a = robust_poly_fit(x1[range], q[range], 1, fit) 
                    xnew = findgen(ndst)/4. + stitch[i].x0
                    newcont = poly(xnew, a)
                    thisspec *= newcont
                    leftspec = dspline(thiswav[loverlap],  $
                                       thisspec[loverlap], $
                                       wav[roverlap]       $
                                      )
                    xbc = [xbc, meanx]
                    bc = [bc, poly(meanx, a)*meanc]
                endif else begin
                    xbc = [xbc, meanx]
                    bc = [bc, meanc]
                endelse
                rweight = halfgaus(x, off=0.15)
                low = where(rweight lt 1d-3, nlow)
                if nlow gt 0 then rweight[low] = 0
                lweight = reverse(rweight)
                low = where(lweight lt 1d-3, nlow)
                if nlow gt 0 then lweight[low] = 0
                twt = rweight+lweight
                newleft = (rweight*spec[roverlap] + lweight*leftspec)/twt
                spec[roverlap] = newleft
                spec = [spec, thisspec[comp]]
                wav  = [wav,  thiswav[comp] ]
                xpix = [xpix, xcont[comp]   ]
                if keyword_set(plot) then begin
                    xr = [wav[roverlap[0]]-0.25, thiswav[max(loverlap)]+0.25]
                    yr = [0.95*min([newleft,spec[roverlap]]), $
                          1.05*max([newleft,spec[roverlap]])]
                    plot, wav, spec, xr=xr, yr=yr,/ys
                    oplot, wav[roverlap], spec[roverlap], co=!red
                    oplot, thiswav[loverlap], thisspec[loverlap], co=!green
                    cursor, xdum, ydum, /up
                    if xdum lt !x.crange[0] then stop
                endif
            endif else begin
                if min(thiswav) gt lastwav then begin
                    spec = [spec, thisspec]
                    wav  = [wav, thiswav]
                    xpix = [xpix, xcont]
                endif
            endelse
        endelse
        lastwav = max(thiswav)
    endfor
    spline_fit = bspline_iterfit(xbc, bc, bkspace=200,upper=3,lower=3)
    ordercont = bspline_valu(xpix, spline_fit)
;if keyword_set(yep) then stop
    dum = {x:ptr_new(xpix),      $
           w:ptr_new(wav),       $
           s:ptr_new(spec),      $
           c:ptr_new(ordercont), $
           o:orders[j],          $
           wmean:mean(wav),      $
           wrange:mm(wav)        $
          }
    if j eq 0 then struct = dum else struct = [struct, dum]
endfor
if keyword_set(lick) then struct = struct[reverse(indgen(nord))]
save, struct, file=outfile
for i = 0, nord-1 do begin
    if i eq 0 then begin
        wav = *struct[i].w 
        spec = *struct[i].s/*struct[i].c
    endif else begin
        thisspec = *struct[i].s/*struct[i].c
        thiswav = *struct[i].w
        roverlap = where(wav gt min(thiswav), nro)
        loverlap = where(thiswav lt max(wav)+2*disp, nlo)
        if nlo*nro eq 0 then begin
            wav = [wav, thiswav]
            spec = [spec, thisspec]
        endif else begin
            comp = where(thiswav gt max(wav))
            leftspec = dspline(thiswav[loverlap],  $
                               thisspec[loverlap], $
                               wav[roverlap]       $
                              )
            x = findgen(nro)
            rweight = halfgaus(x, off=0.15)
            lo = where(rweight lt 1d-3, nw)
            if nw gt 0 then rweight[lo] = 0
            lweight = reverse(rweight)
            lo = where(lweight lt 1d-3, nnw)
            if nw gt 0 then lweight[lo] = 0
            twt = rweight+lweight
            newleft = (rweight*spec[roverlap] + lweight*leftspec)/twt
            spec[roverlap] = newleft
            spec = [spec, thisspec[comp]]
            wav  = [wav,  thiswav[comp] ]
        endelse
    endelse
endfor
;;; Clean up pointers
for i = 0, nord-1 do begin
    for q = 0, 3 do ptr_free, struct[i].(q)
endfor
if keyword_set(suntest) then begin
    u = where(wav gt 5100 and wav lt 5200)
    rdnso, wsun, sun, 5100, 5200
    wseg = wav[u]
    sseg = spec[u]
    sun = dspline(wsun, sun, wseg)
    sunconv = convscale(wseg, sun, /set, vscale=vscale)
    specconv = convscale(wseg, sseg, vscale=vscale)
    sh = ccpeak(sunconv, specconv, 1000, ccf=ccf)
    c = 2.99792458d8
    vdisp = vscale[1] - vscale[0]
    vshift = sh*vdisp
    bigz = vshift / (c / 1d3)
    rdnso, wsun1, sun1, min(wav), max(wav)
    npix = n_elements(spec)
    len = 1000
    nchunk = npix/len
    for i = 0, nchunk-1 do begin
        lo = i*len
        hi = lo+len
        plot, wav[lo:hi], spec[lo:hi], /ys
        oplot, wsun1*(1+bigz), sun1, co=!yellow
        cursor, xdum, ydum
        if xdum lt !x.crange[0] then stop
    endfor
endif
return, spec
end
