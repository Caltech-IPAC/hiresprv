pro  jjsm_wav,vdin,wc,pord=pord,plot_key=plot_key, longformat=longformat $
              , no_overwrite=no_overwrite, robust=robust, vdout=vd $
              , quadwav=quadwav
;pro  sm_wav,vdin,wc,pord=pord,plot_key=plot_key,longformat=longformat


;PURPOSE: Smooth the wavelength scale in a VD structure
;INPUT:
;  VD - Data Structure for Doppler Analysis
;  WC - Wavelength coefficients array (4,25); cubic for each order
;  PORD - The polynomial order to be fit to the wavelenghts. Default=3.
;  PLOT_KEY - keyword to enable diagnostic plotting and printing.
;
;OUTPUT:
;  VD - Wavelength information replaced with "smoothed" values:
;       VD.w0, VD.wcof(0,1), VD.iparam(11), VD.iparam(13)
;
;  August 25, 1993  RPB
;  Modified August 30, 1993 GM
;  Created JJSM_WAV from SM_WAV Feb 2008, JJ

vd = vdin ;;JJ: Protect input variable if /no_overwrite

thresh = 1.5                    ;Rejection threshold x Median(fit)

np = (vd[1].pixob-vd[0].pixob)/2.
IF n_elements(plot_key) ne 1 then plot_key=0

tagnam=tag_names(vd)
ordindex=first_el(where(tagnam eq 'ORDER'))
if ordindex eq -1 then ordindex=first_el(where(tagnam eq 'ORDOB'))

ordr=vd.(ordindex)
if max(ordr) eq min(ordr) then ordr=[ordr(0)] else $
  ordr = where(histogram(ordr) gt 0) + min(ordr)
if n_elements(pord) eq 1 then pord=abs(fix(pord)) else pord=3
wc = dblarr(pord+1,max([max(vd.(ordindex))+1,25])) ;initialize array of wav. coeffs

if keyword_set(longformat) or keyword_set(quadwav) then begin
    chunk_nord = 2 
endif else chunk_nord = 1

FOR n = 0,(n_elements(ordr)-1) do begin ;Cycle through orders
    ord = ordr[n]
    vdind = where(vd.(ordindex) eq ord, nsub)
    subvd = vd[vdind]             ;vd entries for current order

;  Compute pixel and wavelength at left edge and center of each chunk
    lftpix = subvd.pixob        ;array of left pixels
    lftwav = double(subvd.w0) + double(subvd.wcof(0)) ;left wavel's
    cenpix = lftpix + np        ;center pixels
    cenwav = dblarr(nsub)
    for k = 0, nsub-1 do begin
        wcof = subvd[k].wcof
        wcof[0] = lftwav[k]
        cenwav[k] = poly(np, wcof)
    endfor
;    cenwav = lftwav + double(np*subvd.wcof(1)) ;center wav's

;  Compute Weights for each chunk
    if max(subvd.fit) eq min(subvd.fit) then begin
        wt=subvd.npix/40.
        medfit=max(subvd.fit)
    endif else begin
        wt = subvd.npix/subvd.fit
        medfit = median(subvd.fit)
    endelse
    bad = where(subvd.fit gt (thresh*medfit),ndum, comp=good, ncomp=ngood)
    if ndum gt 0 then wt[bad] = 0
    wt /= total(wt)
    
    minwav = min(cenwav)
    y = cenwav-minwav
;  Weighted Wavelength Fit:
    cof = polyfit(cenpix,y,w=wt,pord,fit)
    cof[0] += minwav
    wvzero = poly_fat(lftpix,cof)

;  Compute dLam/dx (dispersion) at center of each chunk.
    subvd.wcof[1] = 0.          ;initialize dispersion to 0

    for k=0, nsub-1 do begin
        x = dindgen(subvd[k].npix) + subvd[k].pixob
        thiswav = poly(x, cof) ;;; calculate WLS for this chunk
        thiscof = reform(polyfit(x, thiswav, chunk_nord)) ;;; Quadratic approx of chunk WLS
        subvd[k].w0 = floor(thiswav[0])
        subvd[k].wcof[0] = thiswav[0] - floor(thiswav[0])
        subvd[k].wcof[1:chunk_nord] = thiscof[1:*]
    endfor

                                ;add slope of line back
;  Store results back into vd structure.  (Add linear fit back in)
    subvd.iparam[11] = subvd.wcof[0]
    subvd.iparam[13] = subvd.wcof[1]
    subvd.iparam[14] = subvd.wcof[2]
    vd[vdind] = subvd

    wc[*,ord] = cof

;  Plot Diagnostics
    IF plot_key eq 1 then begin
        wj = poly_fat(cenpix,cof)
        newcenw = poly_fat(cenpix,cof)
        diff = newcenw - cenwav ;residual
        xt = '!6Pixel'
        yt = '!6Residual to Polynomial Fit ('+ang()+'!6)'
        ti = 'ORDER: '+strcompress(string(ord))
;      plot,cenpix,cenwav,ps=2,xtit=xt,ytit=yt,title='Fit: '+ti
;      oplot,cenpix,wj
;      wait,1
        sig = stdev( diff(good) )
        sigst = strcompress( strmid(string(sig),1,10) )
        if sig lt 1.e-5 then sigst = '0.0000'
        sigv = 3.e8*sig/mean( cenwav )
        sigvst = strcompress( fix(string(sigv)) )
        IF n eq 0 then begin    ;1st time, Draw Header of Table
;            loadct,13
;            !p.charsize=1.5
;            !p.thick=2
            lo=-0.02 & hi=0.02  ;default plot limits in Ang.
        END
        lo = min([diff(good),lo]) & hi=max([diff(good),hi])
        plot,cenpix[good],diff[good],ps=1,xtit=xt,ytit=yt,title=ti, $
             symsize=2,yr=[lo,hi]
        if ndum gt 0 then oplot, cenpix[bad], diff[bad], ps=1, symsize=0.7
        xyouts,400,0.07*lo+0.93*hi,'!7r!6='+sigst+' Ang',size=1.7
                                ;       !p.color=200
        arrow,400,0.11*lo+0.89*hi,1.1*400,0.11*lo+0.89*hi
        xyouts,400,0.12*lo+0.88*hi,' !6  '+sigvst+' m/s',size=1.7
        IF n eq 0 then begin    ;1st time, Draw Header of Table
            print,' '
            print,'          Fitting Polynomial to Wavelengths'
            print,'                in input VD Structure       '
            print,' '
            print,'         ___________________________________'
            print,'         |  ORDER |   RMS RESIDUAL TO FIT  |'
            print,'         |        | (Angstroms) |   (m/s)  |'
            print,'         |________|_____________|__________|'
        ENDIF
        print,format='(A10,I5,A4,F9.5,A5,F9.1,A2)', '         |',ord,' |',sig,'|',sigv,' |'
        print,'         |--------|-------------|----------|'
        wait, 1
    ENDIF

ENDFOR
if 1-keyword_set(no_overwrite) then vdin = vd
return
end
