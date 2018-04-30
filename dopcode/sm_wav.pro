; dave experiment. have sm_wav modify vd. see test da102805_A
pro  sm_wav,vdin,wc,pord=pord,plot_key=plot_key,simple_slope=simple_slope $
            , no_overwrite=no_overwrite, robust=robust, vdout=vd 
            
;pro  sm_wav,vdin,wc,pord=pord,plot_key=plot_key,simple_slope=simple_slope


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

; dave - comment out original line below for experiment. See test da102605_A
;vd=vdin
vd = vdin ;;JJ: Protect input variable if /no_overwrite

thresh = 1.5                    ;Rejection threshold x Median(fit)
;np = 20.                        ;1/2  number of pixels in chunk
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

if (keyword_set(simple_slope)) then begin
    print, '********* sm_wav using simple slope for wavelength scale smoothing *********'
endif

FOR n = 0,(n_elements(ordr)-1) do begin ;Cycle through orders
    ord=ordr(n)
    vdind=where(vd.(ordindex) eq ord)
    subvd=vd(vdind)             ;vd entries for current order

;  Compute pixel and wavelength at left edge and center of each chunk
    lftpix = subvd.pixob        ;array of left pixels
    lftwav = double(subvd.w0) + double(subvd.wcof(0)) ;left wavel's
    cenpix = lftpix + np        ;center pixels
    cenwav = lftwav + double(np*subvd.wcof(1)) ;center wav's
;  Remove arbitrary, rough straight-line fit
    lincof = double(pl_fit(lftpix,lftwav,1)) ;ref. straight line, arbit. coeff's
    lftwav = lftwav - (lincof(0) + lftpix * lincof(1)) ;subtract line
    cenwav = cenwav - (lincof(0) + cenpix * lincof(1)) ;subtract line

;  Compute Weights for each chunk
;   width=1000.
;   wt=sqrt(subvd.npix/subvd.fit) ;*exp(-((cenpix-400.)/width)^2)
    if max(subvd.fit) eq min(subvd.fit) then begin
        wt=subvd.npix/40.
        medfit=max(subvd.fit)
    endif else begin
        wt = subvd.npix/subvd.fit
        medfit = median(subvd.fit)
    endelse
    dum = where(subvd.fit gt (thresh*medfit),ndum)
    good = where(subvd.fit le (thresh*medfit),ngood)
    if ndum gt 0 then wt(dum)=0.
    wt=wt/total(wt)

;  Weighted Wavelength Fit:
    if keyword_set(robust) and 0 then begin
        cof = robust_poly_fit(cenpix,cenwav,pord,fit,wgt=wt) 
    endif else cof = polyfit(cenpix,cenwav,w=wt,pord,fit)
    
    wvzero = poly_fat(lftpix,cof)
;stop
;  Compute dLam/dx (dispersion) at center of each chunk.
    subvd.wcof(1) = 0.          ;initialize dispersion to 0

    if (~keyword_set(simple_slope)) then begin
        for m=1,pord do subvd.wcof(1)=subvd.wcof(1)+m*cof(m)*cenpix^(m-1.) ;dlam/dx
    endif else begin
                                ; Use a simpler method to calculate slopes, which will guarantee a continuous wavelength soln.
                                ; (Note: the effect of this is that the chunk gaps go from order 10^-5 to order 10^-7, which is a
                                ; big difference for 1m/s accuracy. The 10^-7 gaps are just due to computational precision).
                                ; This is still in testing. dave.
        lft_slope = dblarr(n_elements(subvd))
        lft_slope[*] = 0
        last_index = n_elements(subvd) - 1
        for i=0,last_index-1 do lft_slope[i] = (wvzero[i+1]-wvzero[i]) / (lftpix[i+1] - lftpix[i])
        lft_slope[last_index] = ((wvzero[last_index] + (2*np)*subvd[last_index].wcof[1]) - wvzero[last_index]) / (2*np)
        subvd.wcof[1] = lft_slope
    endelse

                                ; dave - check on continuity
                                ;diff = dblarr(43)
                                ; for i=1,43 do begin
                                ;diff[i-1] = (double(subvd[i].w0) + double(subvd[i].wcof[0])) - (double(subvd[i-1].w0) + double(subvd[i-1].wcof[0]) + ((subvd[i].pixob-subvd[i-1].pixob) * double(subvd[i-1].wcof[1]) ))
                                ;plot, diff
                                ;endfor

                                ;add slope of line back
    subvd.wcof(1) = subvd.wcof(1) + lincof(1)
    
;  Store results back into vd structure.  (Add linear fit back in)
    newwav = wvzero + lincof(0) + lftpix * lincof(1) 
    subvd.w0 = fix(newwav)
    subvd.wcof(0) = newwav - subvd.w0
    subvd.iparam(11) = subvd.wcof(0)
    subvd.iparam(13) = subvd.wcof(1)
    vd(vdind) = subvd

;  Store wavelength coefficients
    wc(0,ord) = lincof(0)       ;insert straight line intercept
    wc(1,ord) = lincof(1)       ;insert straight line slope
    wc(*,ord) = wc(*,ord) + cof ;add the fit to residuals

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
        sigv = 3.e8*sig/mean( lincof(0) )
        sigvst = strcompress( fix(string(sigv)) )
        IF n eq 0 then begin    ;1st time, Draw Header of Table
;            loadct,13
;            !p.charsize=1.5
;            !p.thick=2
            lo=-0.02 & hi=0.02  ;default plot limits in Ang.
        END
        lo = min([diff(good),lo]) & hi=max([diff(good),hi])
        plot,cenpix(good),diff(good),ps=1,xtit=xt,ytit=yt,title=ti, $
             symsize=2,yr=[lo,hi]
        if ndum gt 0 then oplot,cenpix(dum),diff(dum),ps=1,symsize=0.7
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
        wait,1
    ENDIF

ENDFOR
if 1-keyword_set(no_overwrite) then vdin = vd
return
end
