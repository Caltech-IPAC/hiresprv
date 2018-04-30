;;; Best if used to stitch together only 2-4 chunks at a time

function drewav, w, s, wnew, u=u
u = where(wnew gt min(w) and wnew lt max(w))
return,dspline(w, s, wnew[u])
end

function fstitch, dsst, wav=wav, test=test, outfile=outfile, counter=counter
nchunk = n_elements(dsst)

dumwav = [dwav(dsst[0]), dwav(dsst[nchunk-1])]
disp = dumwav[1] - dumwav[0]
wav = fillarr(disp*0.8, mm(dumwav))

spec = wav*0
for i = 0, nchunk-2 do begin
    sl = dsst[i].dst      ; get left spectrum
    wl = dwav(dsst[i])    ; wavelengths
    newsl = drewav(wl, sl, wav, u=ul)  ; rebin left spectrum onto common WLS
    if i eq 0 then begin
        spec[ul] = newsl        ; store left spectrum in SPEC
    endif else begin
        newsl = spec[ul]
    endelse

    sr = dsst[i+1].dst    ; get right spectrum
    wr = dwav(dsst[i+1])

    newsr = drewav(wr, sr, wav, u=ur)
    match,ul,ur,ml,mr,count=ct
    if ct gt 0 then begin
        dif = newsl[ml]-newsr[mr]
        meandif = median(dif)
        x = findgen(ct)
        lweight = poly(x, [1, -1./(ct-1)])
        rweight = 1-lweight

        csr = (newsr + meandif)[mr]
        mnspec = (newsl[ml]*lweight + csr*rweight)/(lweight+rweight)
        spec[ul[ml]] = mnspec
        spec[ur] = newsr + meandif

        if keyword_set(test) then begin
            plot, wav[ul], newsl, yr=[0.,1.1],/ys, ps=8, syms=.5 $
                  , xr=[min(wl),max(wr)]
            oplot, wav[ur], newsr + meandif, co=!red, ps=4
            oplot, wav[ul[ml]], mnspec, co=!magenta, thick=2
            oplot, wav, spec, co=!yellow
            cursor,x1,y,/up
            if x1 lt !x.crange[0] then stop
        endif
    endif else spec[ur] = newsr
endfor
z = where(spec eq 0, nz)
if nz gt 0 then spec[z] = 1.
contf, spec, cont, nord=1
return,spec-cont+1
end

