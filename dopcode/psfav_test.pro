pro  psfav_test,vd,order,pixel,osamp,psf,nip $
			, del_ord=del_ord $
			, del_pix=del_pix $
			, plot_key=plot_key  $
			, psfsig=psfsig  $
			, psfpix=psfpix  $
			, xrange=xrange  $
            , orddist=orddist $
            , nodeconv=nodeconv $
            , ipind=ipind $
            , psfwt=psfwt $
            , niporig=niporig  $
            , ghparam=ghparam  $
            , yrange=yrange    $
            , accordion=accordion

;+
;PURPOSE: Construct weighted average PSF within a domain on the echelle format
;INPUT: VD - structure
;       ORDER - order location at which PSF is to be determined
;       PIXEL - pixel location at which PSF is to be determined
;       OSAMP - 4 fine pixels within original
;OUTPUT:
;       PSF   - Final averaged PSF
;       NIP   - Number of IP's used in the domain to make the average
;
;KEYWORDS: 

; Versions: Originated somepoint in the late 20th century
;
;  Updates: 1/2014, HTI, GM, 
;		Changed psfpar.fit to psfpar.ifit. psfav is called during second pass,
;		therefore the chi^2 after the second pass should be used here.

;	Note: the final number of pixels in the psf is 121 oversampled pixels,
;			representing 30 real pixels, +/- 15 real pixels on either side
;			 of the center of the spectral line.
;-

if n_params() lt 1 then begin; 	Error handling
    print,'Syntax:'
    print,'psfav,vd,ordt,pixt,osamp,psf,nip,del_ord=del_ord,' 
    print,'     del_pix=del_pix, plot_key=plot_key, '
    return
end

;HTI TEST:
 del_pix = 00;500	 ; was 175
 del_ord = 1;5	 ; was 1
;HTI END test


tagnam=tag_names(vd)            ;VD tag_names
ordindex=first_el(where(tagnam eq 'ORDER')) ;order_index
;PB, 9 Aug 1998, tie order observation for Lick Obs analyzed with Keck Tem
if ordindex eq -1 then ordindex = first_el(where(tagnam eq 'ORDOB')) ;ORDER or ORDOB?

if n_elements(xrange) ne 2 then xrange=[-7,7] ;plotting region

;if n_elements(plot_key) ne 1 then plot_key=0
; the value 30 refers to the number of pixels that are needed to encompass
;	the wings of any given psf on the HIRES post-upgrade CCD. (HTI 2015)
xpsf=findgen(30*osamp+1)/osamp-15

;del_pix and del_ord are specified in crank.pro. post-upgrade series is 
;	del_pix = 175 and del_ord = 1 by default. 
if n_elements(del_pix) ne 1 then del_pix=100
if n_elements(del_ord) ne 1 then begin
    del_ord=4
    if order le min(vd.(ordindex)) then del_ord=5
    if order ge max(vd.(ordindex)) then del_ord=5
endif
ipind = where(abs(vd.(ordindex)-order) le del_ord and $
              abs(vd.pixt-pixel) le del_pix, nip)
niporig = nip
if nip eq 0 then psfpar = vd[0] else psfpar = vd(ipind)

;psffit = psfpar.fit * sqrt(psfpar.cts) ;HTI 1/2015, changed fit to .ifit
psffit = psfpar.ifit * sqrt(psfpar.cts)
;psffit = psfpar.ifit * 1./( sqrt(psfpar.cts))

;psffit = psfpar.ifit * 1./( psfpar.cts)
; next test:  psffit = psfpar.ifit * 1./(psfpar.cts) ; no sqrt

		; HTI 1/2015 Change from sqrt(counts) to 1./sqrt(counts)
		; will give more weight to the higher signal to noise chunks.
		; Using sqrt(counts) innapropriately gives higher weight to chunks
		; with lower SNR.

if n_elements(psfpar) eq 1 then ipfit=psffit else ipfit =  median(psffit)
ind = where(psffit lt (2.*ipfit), nel)
if nel gt 0 then psfpar = psfpar(ind) else begin
    use = where(finite(psffit), nu)
    if nu gt 0 then psfpar = psfpar[use] else $
      psf = jjgauss(fillarr(0.25, -15, 15), [0.4, 0., 1])
endelse
;psffit = psfpar.fit * sqrt(psfpar.cts) ;HTI 1/2015, changed fit to .ifit
psffit = psfpar.ifit * sqrt(psfpar.cts)
;psffit = psfpar.ifit * 1./( sqrt(psfpar.cts))

;psffit = psfpar.ifit * 1./( psfpar.cts)
; next test:  psffit = psfpar.ifit * 1./(psfpar.cts) ; no sqrt

		; weight = 1/sig^2 = 1/ cnts  ; logic
		; HTI 1/2015 Change from sqrt(counts) to 1./sqrt(counts)
		; will give more weight to the higher signal to noise chunks.
		; Using sqrt(counts) innapropriately gives higher weight to chunks
		; with lower SNR.
 
psflot=fltarr(n_elements(xpsf),n_elements(psfpar)) ;2D Array to contain all PSF's

;   Vertical Dist.; ~15 pxl/order for Lick, 65 pxl/order for Keck (pre-upgrade)
;					100 pxl/order for Keck (post-upgrade)
if not keyword_set(orddist) then orddist=15 ;Lick default (65 for Keck/I2)
;					(orddist= 130 for Keck post-upgrade)
;ordist = (abs(order-psfpar.(ordindex)))*orddist ;HTI changed name of ordist
fullordist = (abs(order-psfpar.(ordindex)))*orddist 
pxdist = fix( abs(pixel-psfpar.pixt) )
ordwt = 1. / sqrt(fullordist/40.+1)  ;40-->80 
pxwt =  1. / sqrt(pxdist/40.+1)		; 40-->80
;ordwt = 1. / sqrt(fullordist/80.+1)  ;40-->80 
;pxwt =  1. / sqrt(pxdist/80.+1)		; 40-->80
;ordwt = 1. / sqrt(fullordist/300.+1)  ;40-->80 ;HTI 1/2015 
;pxwt =  1. / sqrt(pxdist/300.+1)		; 40-->80 ;HTI 1/2015
;ordwt = 1. / sqrt(fullordist/1000.+1)  ;40-->80 ;HTI 1/2015 
;pxwt =  1. / sqrt(pxdist/1000.+1)		; 40-->80 ;HTI 1/2015


;   WEIGHT for IP averaging
;PSFFIT=1;HTI TESTING, tag iu
psfwt = ( 1./psffit ) * ordwt * pxwt  
psfwt=psfwt/total(psfwt)

;HTI plotting begin, show that the psffit should not be dependent on the 
;						vd.ifit value.
;!p.multi=[0,1,2]
;plot,psfpar.cts,psffit, ps=8, xtitle = 'COUNTS', ytit='PSFFIT'
;plot,psfpar.cts,psfwt,ps=8,xtitle='COUNTS',ytit='PSFWT 
; stop
;HTI plotting end

inpr=xpsf*0.                    ;zero the reference psf
numpsf = n_elements(psfwt)

basewid = vd[0].iparam[0]

;    CENTER PROFILES AND LOAD INTO PSFLOT (Reject misaligned ones)
;		Loop over all psfs that will be used in final psf determination.
FOR qq = 0,numpsf-1 do begin
    if keyword_set(ghparam) then begin
        info = {psfpix:-1, psfsig:-1, test:''}
        dumpsf = ghfunc(xpsf,float(psfpar(qq).iparam), param=ghparam, info=info)
    endif else begin ; Else statement is the default
        info = {psfpix:psfpix, psfsig:psfsig, test:''}
        dumpsf = gpfunc(xpsf,float(psfpar(qq).iparam) $
        				 , psfpix=psfpix $
        				 , psfsig=psfsig $
        				 , info=info)
    endelse
;            Fit parabola to 5 pixels around x = 0. --- Force centering.
    hm = 0.5 * max(dumpsf)      ;half max
    ind  = where(dumpsf ge hm and abs(xpsf) lt 2.,np) ;Use Peak
    IF np ge 3 then begin             
        coef = pl_fit( xpsf(ind), dumpsf(ind), 2)
        cent = -0.5*coef(1)/coef(2) ;& print,cent       ;PSF Center
        if abs(cent) lt 1.2*basewid then begin ;Shift PSF; Toss mis-centered PSF's
            if 1-keyword_set(ghparam) then begin
                if 1-keyword_set(info) then $
                  info = {psfpix:psfpix, psfsig:psfsig, test:''}
                dumpsf = gpfunc(xpsf + cent, float(psfpar(qq).iparam) $
                                , psfpix=psfpix,psfsig=psfsig, info=info)
            endif
        endif else begin 
            if 1-keyword_set(ghparam) then begin
                psfwt(qq)=0. 
                dumpsf=xpsf*0.
            endif;print, keyword_set(ghparam)
        endelse
        ENDIF
;            Toss horrible PSF's and prevent BOMBS,  Nov. 18, 1995
        if n_elements(dumpsf) ne n_elements(xpsf) then begin
            psfwt(qq)=0.  
            dumpsf=xpsf*0.
        endif
        psflot(*,qq) = dumpsf   ;load profiles into psflot
    ENDFOR

;   for i=0,numpsf-1 do print,psfpar(i).fit,sqrt(psfpar(i).cts),psfpar(i).cts,psffit(i),psfwt(i)
;   stop
;HTI plotting section begin

;PLOT PSFLOT, with the position of the psfs correcly oriented.
nrow = n_elements(where(fullordist eq 0)) ; chunks in same order
ncol = n_elements(pxdist) / nrow			; chunks in adjacent orders
npsf1 = nrow*ncol

;window,0
;!p.multi=[0,nrow,ncol]
;for ii=0, npsf1-1 do begin
	; color middle, highest weight, and for median test, chosen psf.
;	plot,psflot[*,ii];
;	xyouts,5,0.01, sigfig(psfwt[ii],2),/data,size=1.5
;endfor ; ii

;stop
;HTI plotting section end


;stop

;       Extract only the "good" PSF's
    igood = where(psfwt gt 0,numpsf)

    if numpsf eq 0 then begin
        psfwt=0
;        if 1-keyword_set(nodeconv) then print,'Num psfwt(igood) = 0!'
        goto, jump
    endif
    psfwt = psfwt(igood)
    psflot = psflot(*,igood)

; MEDIAN of good PSF's !!!
    FOR i = 0,n_elements(xpsf)-1 do inpr(i) = median(psflot(i,*))
    inpr = osamp*inpr/total(inpr) ;Normalize
	median_psf = inpr; HTI, does not disrupt any other variables

    psfdif = psfwt  * 0.
    diflot = psflot * 0.

    FOR qq = 0,numpsf-1 do begin
        diflot(*,qq) = psflot(*,qq) - inpr
        psfdif(qq) = total(abs(diflot(*,qq)))
;	   psfdif(qq) = max((diflot(*,qq)))      ;rejected Dec. 14 1996
    ENDFOR

    if n_elements(psfdif) eq 1 then medif = psfdif $
    else medif = median(psfdif)
;	   else medif = mean(psfdif)

    igood = where(psfdif lt 1.5*medif, numpsf)
    if numpsf eq 0 then begin
        psfwt=0
;        if 1-keyword_set(nodeconv) then print,'Num psfwt(igood) = 0!'
        goto, jump
    endif
    psfwt = psfwt(igood)
    psflot = psflot(*,igood)

    psfwt = psfwt/total(psfwt) 
;stop
; COMPUTE WEIGHTED MEAN PSF
    inpr  = xpsf*0.             ;zero the psf
    nip = n_elements(psflot(0,*))
    FOR qq = 0,nip-1 do begin
        inpr = inpr + psflot(*,qq)*psfwt(qq) ;weighted mean
    END
    
    inpr = osamp*inpr/total(inpr) ; FINAL AVERAGE PSF !

    IF keyword_set(plot_key) then begin
        !p.thick=1
        xt = '!5Pixel = '+strtrim(pixel,2)
        tt = '!5Order = '+strtrim(order,2)
        xcen = osamp * 15
        xsc = findgen(osamp*30)/osamp - 15.
        if 1-keyword_set(yrange) then yrange = [0.,max(inpr)+.1] 
        plot,xsc,inpr,xr=xrange,/xsty,symsize=.5 $
        	,yra=yrange,title=tt,xtitle=xt,charsize=1.8,/ys

        FOR qq = 0,nip-1 do begin
            oplot,xsc,psflot(*,qq),co=!red,ps=8,symsize=.5 ;good
        ENDFOR                  ; qq

        oplot,xsc,inpr
    ENDIF                       ;plot_key
;stop

;help,igood,psfdif ;hti
;if order eq 5 then begin
;print,'ord,pix',order,pixel
;print,"psfpar[igood].ordob,psfpar[igood].pixob,pxdist[igood],fullordist[igood],ordwt[igood],pxwt[igood],psfpar[igood].ifit,psfpar[igood].cts,(( 1./psffit[igood] ) * ordwt[igood] * pxwt[igood]),psfwt" ; hti
;forprint,psfpar[igood].ordob,psfpar[igood].pixob,pxdist[igood],fullordist[igood],ordwt[igood],pxwt[igood],psfpar[igood].ifit,psfpar[igood].cts,(( 1./psffit[igood] ) * ordwt[igood] * pxwt[igood]),psfwt ; hti
;if pixel gt 2207  and pixel lt 2500 and (order eq 1 or order eq 5) then stop ; hti
;stop
;endif
;print,inpr
    npsf=n_elements(inpr)
; write the best psf array to an ascii file - to be 
; read by gpfunc in place of the "central gaussian"  DFischer apr 2000
;openw,1,'bestpsf.dat'
;for i=0,npsf-1 do printf,1,inpr(i)
;close,1
    jump:

;	inpr = median_psf ;HTI median test: tags: ii and ij, ir,is,it
    psf=inpr

;HTI plotting
;window,1
;!p.multi=0
;!p.multi=[0,2,2]
plot,psf,title='Final psf - 1x1 grid'


;stop
    return
end

