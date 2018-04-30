pro  psfav_par,vd,order,pixel,osamp,psf,nip,del_ord=del_ord,del_pix=del_pix, $
               plot_key=plot_key,psfsig=psfsig,psfpix=psfpix,xra=xra $
               ,orddist=orddist, nodeconv=nodeconv, ipind=ipind, psfwt=psfwt $
               ,niporig=niporig,ghparam=ghparam,meanpar=meanpar, pararr=parlot

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
if n_params() lt 1 then begin
    print,'Syntax:'
    print,'psfav,vd,ordob,pixob,osamp,psf,nip,del_ord=del_ord,' 
    print,'     del_pix=del_pix, plot_key=plot_key, '
    return
end

tagnam=tag_names(vd)            ;VD tag_names
ordindex=first_el(where(tagnam eq 'ORDER')) ;order_index
;PB, 9 Aug 1998, tie order observation for Lick Obs analyzed with Keck Tem
if ordindex eq -1 then ordindex = first_el(where(tagnam eq 'ORDOB')) ;ORDER or ORDOB?

if n_elements(plot_key) ne 1 then plot_key=0
xpsf=findgen(30*osamp+1)/osamp-15
if n_elements(del_pix) ne 1 then del_pix=100
if n_elements(del_ord) ne 1 then begin
    del_ord=4
    if order le min(vd.(ordindex)) then del_ord=5
    if order ge max(vd.(ordindex)) then del_ord=5
endif
ipind = where(abs(vd.(ordindex)-order) le del_ord and $
              abs(vd.pixob-pixel) le del_pix, nip)
niporig = nip
if nip eq 0 then psfpar = vd[0] else psfpar = vd[ipind]

psffit = psfpar.fit * sqrt(psfpar.cts)
if n_elements(psfpar) eq 1 then ipfit=psffit else ipfit =  median(psffit)
psfpar = psfpar[where(psffit lt (2.*ipfit), nip)]
psffit = psfpar.fit * sqrt(psfpar.cts)

parlot=fltarr(n_elements(vd[0].iparam),n_elements(psfpar)) ;2D Array to contain all PSF's

;   Vertical Dist.; ~15 pxl/order for Lick, 65 pxl/order for Keck
if not keyword_set(orddist) then orddist=15 ;Lick default (65 for Keck/I2)
ordist = (abs(order-psfpar.(ordindex)))*orddist
pxdist = fix( abs(pixel-psfpar.pixob) )
ordwt = 1. / sqrt(ordist/40.+1)
pxwt =  1. / sqrt(pxdist/40.+1)

;   WEIGHT for IP averaging

psfwt = ( 1./psffit ) * ordwt * pxwt  
psfwt=psfwt/total(psfwt)
inpr=xpsf*0.                    ;zero the reference psf
numpsf = n_elements(psfwt)

basewid = vd[0].iparam[0]
;;; Load up parameters
FOR qq = 0,numpsf-1 do parlot[*,qq] = psfpar(qq).iparam

;       Extract only the "good" PSF's
igood = where(psfwt gt 0,numpsf)
if numpsf eq 0 then begin
    psfwt=0
    if 1-keyword_set(nodeconv) then print,'Num psfwt(igood) = 0!'
    goto, jump
endif
psfwt = psfwt(igood)
parlot = parlot(*,igood)

;;; Compute weighted mean PSF
;medpar = cmapply('user:median',parlot,2)
npar = n_elements(parlot[*,0])
meanpar = fltarr(npar)
for i = 0, npar-1 do meanpar[i] = total(parlot[i,*]*psfwt)/total(psfwt)
if keyword_set(ghparam) then begin
    if n_elements(psfpix) gt 0 then begin 
        info = {psfpix:psfpix,psfsig:psfsig,test:''} 
    endif else info = {psfpix:-1, psfsig:-1, test:''}
    inpr = ghfunc(xpsf, meanpar, info=info, param=ghparam)
endif else begin
    inpr = gpfunc(xpsf, meanpar, psfpix=psfpix,psfsig=psfsig)
endelse

IF plot_key eq 1 then begin
    if n_elements(xra) ne 2 then xra=[-8,8] ;plotting region
;    !p.thick=1
    xt = '!5Pixel = '+strtrim(pixel,2)
    tt = '!5Order = '+strtrim(order,2)
    xcen = osamp * 15
    xsc = findgen(osamp*30)/osamp - 15.
    yr=[-max(inpr)*0.05,max(inpr)*1.05]
    plot,xsc,inpr,xr=xra,/xsty,symsize=.5,yra=yr,title=tt,xtitle=xt,charsize=1.8

    FOR qq = 0,nip-1 do begin
        if keyword_set(ghparam) then begin
            thispsf = ghfunc(xsc, parlot[*,qq], param=ghparam, info=info)
        endif else begin
            thispsf = gpfunc(xsc, parlot[*,qq], psfsig=psfsig, psfpix=psfpix)
        endelse
        oplot,xsc, thispsf, co=!red, ps=8, symsize=.5 ;good
    ENDFOR                      ; qq

    oplot,xsc,inpr
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
return
end






























