function jjsmwav, vdin, wc, pord=pord, ifit=ifit
if 1-keyword_set(pord) then pord = 6
if 1-keyword_set(ifit) then ifit = 0
vd = vdin
tags = tag_names(vd)
ordindex = where(stregex(tags, 'ORDOB', /bool, /fold), nw)
if nw eq 0 then ordindex = where(stregex(tags, 'ORDER', /bool, /fold), nw)

ordr = vd.(ordindex)
if max(ordr) eq min(ordr) then ordr=[ordr(0)] else $
  ordr = where(histogram(ordr) gt 0, norder) + min(ordr)
if n_elements(pord) eq 1 then pord=abs(fix(pord)) else pord=3
wc = dblarr(pord+1,max([max(vd.(ordindex))+1,25])) ;initialize array of wav. coeffs

pixoffset = (vd[1].pixob-vd[0].pixob)/2. ;;offset to center pixel in each chunk
for i = 0, norder-1 do begin
    use = where(vd.(ordindex) eq ordr[i], nu)
    vdu = vd[use]
    wav = vdu.w0 + vdu.iparam[11] + vdu.iparam[13]*pixoffset
    minwav = min(wav)
    wav -= minwav
    wav = double(wav)
    pix = vdu.pixob + pixoffset
    pix = double(pix)
    chi = vdu.(11+ifit)
    if median(chi) gt 0 then begin
        wts = 1./chi
        dum = chauvenet(chi, /iter, nrej=nrej, rej=rej)
        if nrej gt 0 then wts[rej] = 0
    endif else wts = fltarr(nu)+1
    wts /= total(wts)
    a = polyfit(pix, wav, pord, fit, w=wts)
    resid = wav - fit
    g = chauvenet(resid, /iter, nreject=nbad) ;Check for outliers
    if nbad gt 0 then begin ;if there were outliers, re-fit
        a = polyfit(pix[g], wav[g], pord, fit, w=wts[g])
    endif
    wc[*,ordr[i]] = reform(a,pord+1)
    wfit = poly(pix-pixoffset, a)+minwav
    vdu.w0 = fix(wfit)
    vdu.(5+ifit)[0] = wfit-fix(wfit)
    vdu.iparam[11] = wfit-fix(wfit)
    ;; Dispersion is just the derivative of the polyfit to wav(x)
    fpix = [pix, pix[nu-1]+2*pixoffset]-pixoffset ;; add a pixel to the end
    wfit = poly(fpix, a)+minwav ;; bestfit wavelengths
    disp = (wfit-shift(wfit,1))/(fpix-shift(fpix,1))
    vdu.(5+ifit)[1] = disp[0:nu-1]
    vdu.iparam[13] = disp[0:nu-1]
    vd[use] = vdu
endfor
return,vd
end
