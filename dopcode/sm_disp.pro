pro  sm_disp,vd,nvd,pord=pord,vdiod=vdiod,plot_key=plot_key, w0=w0

;PURPOSE: Smooth the linear dispersions in a VD structure
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
;  March 31, 2003  RPB
;
; HTI Notes:  The vdiod is only used if the input VD is crummy.
;				Otherwise, vdiod is not used, even when called.

nvd = vd
thresh = 1.5                    ;Rejection threshold x Median(fit)
IF n_elements(plot_key) ne 1 then plot_key=0

tagnam=tag_names(vd)
ordindex=first_el(where(tagnam eq 'ORDER'))
wavdex = first_el(where(tagnam eq 'ICOF'))
if wavdex lt 0 then wavdex = first_el(where(tagnam eq 'WCOF'))
if ordindex eq -1 then ordindex=first_el(where(tagnam eq 'ORDOB'))

ordr=vd.(ordindex)
if max(ordr) eq min(ordr) then ordr=[ordr(0)] else $
  ordr = where(histogram(ordr) gt 0) + min(ordr)
if n_elements(pord) eq 1 then pord=abs(fix(pord)) else pord=3
;if n_elements(pord) eq 1 then pord=abs(fix(pord)) else pord=5
;if max(vd.pixt) gt 3900 then pord=5  ;more flexible for UVES 
FOR n = 0,(n_elements(ordr)-1) do begin ;Cycle through orders
    ord=ordr(n)
    vdind = where(vd.(ordindex) eq ord)
    subvd = vd(vdind)           ;vd entries for current order
    npix = median(subvd.npix)   ;number of pixels in each chunk
    medfit = median(subvd.fit)  ;median fit of chunks in order

;  Compute pixel at left edge and center of each chunk
    cenpix = float(subvd.pixob) + subvd.npix/2. ;center pixels
    if keyword_set(w0) then dsp = subvd.wcof[0]+subvd.w0 else $
      dsp    = subvd.wcof(1)    ;linear dispersion

    if plot_key eq 1 then plot,cenpix,dsp,ps=8,/xsty,/ynoz, $
      title='SM_DISP: Order '+strtrim(ord,2)

;  Weight each chunk
    wt=sqrt(subvd.cts > 1)/subvd.fit
    dum = where(subvd.fit gt (thresh*medfit), ndum) ; or subvd.(pixdex) lt (0.6*npix),ndum)
    if ndum gt 0 then begin
        wt(dum)=0.
        if plot_key eq 1 then oplot,[cenpix(dum)],[dsp(dum)], $
          ps=7,symsize=2, co=!red
    endif
    wt=wt/total(wt)

    if n_elements(vdiod) gt 1 then begin ;backup for input VD, wt or fit=zero
        vdiind = where(vdiod.(ordindex) eq ord)
        subvdi = vdiod(vdiind)  ;vd entries for current order
        npix = median(subvdi.npix) ;number of pixels in each chunk
        medfit = median(subvdi.fit) ;median fit of chunks in order

        cenpixi = float(subvdi.pixob) + subvdi.npix/2. ;center pixels
        dspi    = subvdi.wcof(1) ;linear dispersion

;      if plot_key eq 1 then oplot,cenpixi,dspi,ps=8,co=61,symsiz=0.8

        wti=sqrt(subvdi.cts)/subvdi.fit
        dum = where(subvdi.fit gt (thresh*medfit),ndum) ; or subvdi.(pixdex) lt (0.6*npix),ndum)
        if ndum gt 0 then begin
            wti(dum)=0.
;         if plot_key eq 1 then oplot,[cenpixi(dum)],[dspi(dum)],  $
;             ps=7,symsize=2,thick=2,co=121
        endif
        wti=wti/total(wti)
        dum=where(wt eq 0,ndum)
        if ndum gt 0 then begin	;HTI 9/2014 Note: Only called when wt eq 0
            nwt=wt
            for qq = 0,ndum-1 do begin
;            lpx = max([0,dum(qq)-2])
;            rpx = min([dum(qq)+2,n_elements(wt)-1])
                lpx = max([0,dum(qq)-1])
                rpx = min([dum(qq)+1,n_elements(wt)-1])
                if max(wt(lpx:rpx)) le 0 then begin
                    cpx=dum(qq)
                    cpxi=minloc(abs(cenpixi-cenpix(cpx)),/first)
                    if abs(cenpix(cpx)-cenpixi(cpxi)) lt 25 then begin
                        cenpix(cpx)=cenpixi(cpxi)
                        dsp(cpx)=dspi(cpxi)
                        nwt(cpx)=wti(cpxi)
                    endif
                    if plot_key eq 1 then oplot,[cenpix(dum(qq))],[dsp(dum(qq))],co=!green,ps=4,symsiz=2.,thick=2
                endif
            endfor
            wt=nwt
        endif
    endif                       ;vdiod

;  Weighted Wavelength Fit:
;   wt=wt*0.+1.
;   cof = polyfitw(cenpix,dsp,wt,pord)
    if keyword_set(w0) then qq=where(wt gt 0 and dsp gt 4500, nq) else $
      qq = where(wt gt 0)
    cof = robust_poly_fit(cenpix(qq),dsp(qq),pord)
    disp = poly_fat(cenpix,cof)
;  Store results back into vd structure.  (Add linear fit back in)
    if keyword_set(w0) then begin
        subvd.(wavdex)[0] = disp - floor(disp)
        subvd.w0 = floor(disp)
    endif else subvd.(wavdex)[1] = disp
    nvd(vdind) = subvd

    IF plot_key eq 1 then begin
        oplot,cenpix,disp,co=!green
        xyxxx=max(vd.pixt)-900
        xyouts,xyxxx,0.97*max(dsp),'RMS = '+strtrim(stdev(dsp-disp),2),size=2.5
        wait,1
    endif
;if n gt 8 then stop
endfor

return
end
