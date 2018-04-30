pro  psfav_jj,vd,order,pixel,osamp,psf,nip $
			  ,del_ord=del_ord $
			  ,del_pix=del_pix $
              ,plot_key=plot_key $
              ,sigpsf=sigpsf $
              ,pixpsf=pixpsf $
              ,xra=xra $
              ,orddist=orddist $
              ,psfpix=psfpix $
              ,psfsig=psfsig $
              ,nodeconv=nodeconv $
              ,psfarr=psflot

;common psfstuff,psfsig,psfpix,obpix,param
;
;PURPOSE: Construct weighted average PSF within a domain on the echelle format
;INPUT: VD - structure
;       ORDER - order location at which PSF is to be determined
;       PIXEL - pixel location at which PSF is to be determined
;       OSAMP - 4 fine pixels within original
;OUTPUT:
;       PSF   - Final averaged PSF
;       NIP   - Number of IP's used in the domain to make the average
;
; Note: 2/2015, HTI instituted kepler keyword. Uses 7x7 median psf average.
;				Used by dsst.pro when reading in VDIODs used to make DSSST.

if n_params() lt 1 then begin
    print,'Syntax:'
    print,'psfav,vd,ordt,pixt,osamp,psf,nip,del_ord=del_ord,' 
    print,'     del_pix=del_pix, plot_key=plot_key, '
;          psrint,'     sigpsf=sigpsf, pixpsf=pixpsf'
;          print,'i.e.,:'
;          print,'pixpsf=[0.00,-2.00,-1.25,-0.75, 0.75, 1.25, 2.00, 0.00, 0.00,0.00,0.00]'
;          print,'sigpsf=[0.00, 0.50, 0.40, 0.35, 0.35, 0.40, 0.50, 0.00, 0.00,0.00,0.00]'
    return
end
; Establish Kepler keyword to settings for low SNR stars.
kepler = 0  ; TURNING THIS OFF FOR REGULAR DOPPING
;HTI TEST:
if keyword_set(kepler) then begin; Uses 7x7 grid and chooses median psf
 del_pix = 300;500	 ; was 175
 del_ord = 3;5	 ; was 1
endif
;HTI END test


bad = where(1-finite(vd.iparam[15]), nbad) ;JJ kludge for Magellan PSF
if nbad gt 0 then vd[bad].iparam[15] = 0
tagnam=tag_names(vd)            ;VD tag_names
ordindex=first_el(where(tagnam eq 'ORDER')) ;order_index
;if ordindex eq -1 then ordindex = first_el(where(tagnam eq 'ORDT'))   ;ORDER or ORDT?
;PB, 9 Aug 1998, tie order observation for Lick Obs analyzed with Keck Tem
if ordindex eq -1 then ordindex = first_el(where(tagnam eq 'ORDOB')) ;ORDER or ORDOB?

if n_elements(xra) ne 2 then xra=[-4,4] ;plotting region
if n_elements(sigpsf) gt 0 $
  and n_elements(sigpsf) eq n_elements(pixpsf) then begin
;	     print,'Using a non-standard PSF in PSFAV'
    psfsig=sigpsf
    psfpix=pixpsf
endif
if n_elements(plot_key) ne 1 then plot_key=0
xpsf=findgen(30*osamp+1)/osamp-15
if n_elements(del_pix) ne 1 then del_pix=100
if n_elements(del_ord) ne 1 then begin
    del_ord=4
    if order le min(vd.(ordindex)) then del_ord=5
    if order ge max(vd.(ordindex)) then del_ord=5
endif

ipind = where(abs(vd.(ordindex)-order) le del_ord and $
              abs(vd.pixt-pixel) le del_pix and vd.fit ne 100, nind)
if nind eq 0 then begin
    if pixel gt max(vd.pixt, imx) then $
      ipind = where(abs(vd.(ordindex) - order) le del_ord and $
                    vd.pixt gt (vd[imx[0]].pixt - del_pix and $
                                vd.fit ne 100), nind)
endif
if nind eq 0 then begin
    x = fillarr(0.25, -15, 15)
    psf = jjgauss(x, [1., 0, 0.6])
    psf = psf/int_tabulated(x, psf)
    return
endif
psfpar = vd(ipind)

psffit = psfpar.fit * sqrt(psfpar.cts)
if n_elements(psfpar) eq 1 then ipfit=psffit $
else ipfit =  median(psffit)
good = where(psffit lt (2.*ipfit), ngood)
psfpar = psfpar(good)
psffit = psfpar.fit * sqrt(psfpar.cts)

psflot=fltarr(n_elements(xpsf),n_elements(psfpar)) ;2D Array to contain all PSF's

;   Vertical Dist.; ~15 pxl/order for Lick, 65 pxl/order for Keck
if not keyword_set(orddist) then orddist=15 ;Lick default (65 for Keck/I2)
ordist = (abs(order-psfpar.(ordindex)))*orddist
pxdist = fix( abs(pixel-psfpar.pixt) )
ordwt = 1. / sqrt(ordist/40.+1)
pxwt =  1. / sqrt(pxdist/40.+1)

;   WEIGHT for IP averaging

psfwt = ( 1./psffit ) * ordwt * pxwt  

psfwt=psfwt/total(psfwt)
inpr=xpsf*0.                    ;zero the reference psf
numpsf = n_elements(psfwt)

;    CENTER PROFILES AND LOAD INTO PSFLOT (Reject misaligned ones)
FOR qq = 0,numpsf-1 do begin
    ipar = float(psfpar(qq).iparam)
    bad = where(1-finite(ipar), nbad)
    if nbad gt 0 then ipar[bad] = 0
    dumpsf = gpfunc_jj(xpsf,ipar,psfpix=psfpix, psfsig=psfsig)
;            Fit parabola to 5 pixels around x = 0. --- Force centering.
    hm = 0.5 * max(dumpsf)      ;half max
    ind  = where(dumpsf ge hm and abs(xpsf) lt 2.,np) ;Use Peak
    IF np ge 3 then begin             
        coef = pl_fit( xpsf(ind), dumpsf(ind), 2)
        cent = -0.5*coef(1)/coef(2) ;& print,cent       ;PSF Center
        if abs(cent) lt 1.2 then begin ;Shift PSF; Toss mis-centered PSF's
            dumpsf = gpfunc_jj(xpsf + cent, float(psfpar(qq).iparam),psfpix=psfpix, psfsig=psfsig)
        endif else begin 
            psfwt(qq)=0. 
            dumpsf=xpsf*0. 
        endelse
    ENDIF
;            Toss horrible PSF's and prevent BOMBS,  Nov. 18, 1995
    if n_elements(dumpsf) ne n_elements(xpsf) then begin
        psfwt(qq)=0.  
        dumpsf=xpsf*0.
    endif
    psflot(*,qq) = dumpsf       ;load profiles into psflot
ENDFOR
;   for i=0,numpsf-1 do print,psfpar(i).fit,sqrt(psfpar(i).cts),psfpar(i).cts,psffit(i),psfwt(i)
;   stop

;       Extract only the "good" PSF's
igood = where(psfwt gt 0,numpsf)

if numpsf eq 0 then begin
    psfwt=0
    print,'Num psfwt(igood) = 0!'
    goto, jump
endif
psfwt = psfwt(igood)
psflot = psflot(*,igood)


; MEDIAN of good PSF's !!!
FOR i = 0,n_elements(xpsf)-1 do inpr(i) = median(psflot(i,*))

inpr = osamp*inpr/total(inpr)   ;Normalize
median_psf = inpr; HTI, does not disrupt any other variables
				 ; Store median_psf, and use with Kepler keyword


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
    print,'Num psfwt(igood) = 0!'
    goto, jump
endif
psfwt = psfwt(igood)
psflot = psflot(*,igood)

psfwt = psfwt/total(psfwt)

; COMPUTE WEIGHTED MEAN PSF
inpr  = xpsf*0.                 ;zero the psf
nip = n_elements(psflot(0,*))
FOR qq = 0,nip-1 do begin
    inpr = inpr + psflot(*,qq)*psfwt(qq) ;weighted mean
END

inpr = osamp*inpr/total(inpr)   ; FINAL AVERAGE PSF !
IF plot_key eq 1 then begin
    !p.thick=1
    xt = '!5Pixel = '+strtrim(pixel,2)
    tt = '!5Order = '+strtrim(order,2)
    xcen = osamp * 15
    xsc = findgen(osamp*30)/osamp - 15.
    yr=[0.,max(inpr)+.1]
    plot,xsc,inpr,xr=xra,/xsty,symsize=.5,yra=yr,title=tt,xtitle=xt,charsize=1.8

    FOR qq = 0,nip-1 do begin
        oplot,xsc,psflot(*,qq),co=70+qq*20,ps=3,symsize=1 ;good
    ENDFOR                      ; qq

    oplot,xsc,inpr,thick=3
ENDIF                           ;plot_key
;print,inpr
npsf=n_elements(inpr)
; write the best psf array to an ascii file - to be 
; read by gpfunc in place of the "central gaussian"  DFischer apr 2000
;openw,1,'bestpsf.dat'
;for i=0,npsf-1 do printf,1,inpr(i)
;close,1
jump:
psf=inpr

;HTI unweighted median of 7x7 box is used to find final psf.
if keyword_set(kepler) then  psf = median_psf 


if mean(psf) eq 0 and median(psf) eq 0 then begin
    x = fillarr(0.25, -15, 15)
    psf = jjgauss(x, [1., 0, 0.6])
    psf = psf/int_tabulated(x, psf)
endif

return
end






























