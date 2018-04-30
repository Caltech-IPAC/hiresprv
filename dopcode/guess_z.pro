pro guess_z,dsst,ob,ipcff,z,vdin,ftsdsk=ftsdsk,ftsdfn=ftsdfn
;common psfstuff,param,psfsig,psfpix,obpix

;This code carries out the set-up and construction
; of a first guess "vd" velocity data structure

;
;dsst     (input structure) appropriate "dsst' (deconvolved stellar structure) for
;	              the observation
;vdin     (input/output structure) "vd" structure for observation.  This "vd" should
;		      be the best match "vd" for the night of the observation from the
;	              IPCF. It is used to get approximate PSF parameters for the observation.
;ipcff    (input/structure) the singular IPCF structure that best matchs the observation
;                     used only to get the PSF description for the observation
;z        (output/float)  best guess Z
;ftsdsk   (input/string)  name of fts atlas subdirectory
;ftsdfn   (input/string)  name of fts atlas 
;                             i.e. ftsdfn='ftskeck50.bin' or 'ftseso50.bin'
;
;Created Feb, 1996  R.P.B.
;Modified Mar, 2002  R.P.B.  relax pixel range
;

c =  2.99792458d8               ;speed of who?
if n_elements(ftsdsk) ne 1 then begin ;is ftsdsk input?
    print,"% GUESS_Z: FTSDSK IS UNDEFINED...returning"
    return
endif

;PSF description ;;;Changed by JohnJohn. I don't understand why this
;is necessary, and I've replaced IPCF with IPGUESS
;psfsig=ipcff.psfsig
;psfpix=ipcff.psfpix

tagnam=tag_names(vdin)
ordindex=first_el(where(tagnam eq 'ORDER'))
if ordindex eq -1 then ordindex=first_el(where(tagnam eq 'ORDOB'))

tagnam=tag_names(dsst)
ordsst=first_el(where(tagnam eq 'ORDER'))
if ordsst eq -1 then ordsst=first_el(where(tagnam eq 'ORDT'))
pxdsst=first_el(where(tagnam eq 'PIX0'))
if pxdsst eq -1 then pxdsst=first_el(where(tagnam eq 'PIXT'))
wtdsst=first_el(where(tagnam eq 'WEIGHT'))
if wtdsst eq -1 then wtdsst=first_el(where(tagnam eq 'SLOPE'))

;Kludge to deal with HIRES Pre-Fix DSST and Post-Fix Observation 14Jan04 RPB
ordt=vdin.ordt
if min(dsst.(ordsst)) eq 21 and min(vdin.ordt) eq 0 then ordt=ordt+20
if min(dsst.(ordsst)) eq 0 and min(vdin.ordt) eq 21 then ordt=ordt-20

osamp=4
npix = n_elements(ob(*,0))      ;# of pixels per order
nord = max(vdin.(ordindex))     ;# of orders in observation
xx   = findgen(npix)
wav=fltarr(npix,nord+1)
;set up wavelength scale for the observation
dum=vdin
sm_wav,dum,wc
for n=0,nord do if wc(0,n) gt 0 then wav(*,n) = poly_fat(xx,wc(*,n))

;;; JJJJJJJJJJ
cool = 0
ind = 101
while not cool do begin
;ind = 88
    ord = (findel(dsst[ind].w0, wav[*,*,0], /mat))[1]
    ds = fstitch(dsst[ind-2:ind+2], wav=wd)

    vd = vdin
    lo = vd[findel(dsst[ind-2].w0, vd.w0)].pixob
    hi = vd[findel(dsst[ind+2].w0, vd.w0)].pixob
    if lo lt hi then begin
        ws = wav[lo:hi, ord, 0]
        m = where(wd gt min(ws) and wd lt max(ws), ct)
    endif else ct = 0
    if ct gt 5 then cool = 1
    ind = ind+1
endwhile
print
print,'COOL'
print

contf, ob[lo:hi, ord], cont
snorm = ob[lo:hi, ord] / cont
sfine = dspline(ws, snorm, wd[m])
sconv = convscale(wd[m], sfine, /set, vscale=vscale)
dconv = convscale(wd[m], ds[m], vscale=vscale)
sh = ccpeak(dconv, sconv, ct/4., ccf=ccf)

vdisp = vscale[1] - vscale[0]
vshift = sh*vdisp
z = vshift / (c/1d3)

return
;;; JJJJJJJJJJ
minpix=min(dsst.(pxdsst))
maxpix=min([max(dsst.(pxdsst)),max(vdin.pixob)])
;which chunks have: a) lots of weight, and b) sit in the middle of the orders?
pind=where(dsst.(pxdsst) gt (minpix+400) and $
           dsst.(pxdsst) lt (maxpix-400) and $
           dsst.(ordsst) le max(ordt) and $
           dsst.(ordsst) ge min(ordt))
dumdsst=dsst(pind)
;generate an ordered list of DSST chunk weights in center of orders
fud=dumdsst(reverse(sort(dumdsst.(wtdsst)))).(wtdsst)
;do about 5 chunks
;pind=where(dsst.(pxdsst) gt 600 and dsst.(pxdsst) lt 1100 and dsst.(wtdsst) ge fud(5),npind)
pind=where(dsst.(pxdsst) gt (minpix+400) and $
           dsst.(pxdsst) lt (maxpix-400) and $
           dsst.(wtdsst) ge fud(5) and $
           dsst.(ordsst) le max(ordt) and $
           dsst.(ordsst) ge min(ordt),npind)
;pind=where(dumdsst.(pxdsst) gt (minpix+400) and $
;     dumdsst.(pxdsst) lt (maxpix-400) and $
;     dumdsst.(wtdsst) ge fud(5) and dumdsst.(ordsst) le max(ordt),npind)
gz=fltarr(2,npind)

for n=0,(npind-1) do begin
    pix=dsst(pind(n)).(pxdsst)  ;Pixel
    ord=dsst(pind(n)).(ordsst)  ;Order
;Kludge to deal with HIRES Pre-Fix DSST and Post-Fix Observation 14Jan04 RPB
    if min(dsst.(ordsst)) eq 21 and min(vdin.ordt) eq 0 then ord=ord-20
    if min(dsst.(ordsst)) eq 0 and min(vdin.ordt) eq 21 then ord=ord+20

;print,'In GUESS_Z:   ORD = '+strtrim(ord,2)+'    PIX = '+strtrim(pix,2)
    psfav,vdin,ord,pix,4,psf    ;Approx. PSF, 4x sampling

;Kludge to deal with HIRES Pre-Fix DSST and Post-Fix Observation 14Jan04 RPB
    px0=max([500,min(vdin.pixt)+400])
    px1=max([1100,max(vdin.pixt)-400])

    ind=where(vdin.ordt eq ord and vdin.pixt gt px0 and vdin.pixt lt px1)
    ordob=median(vdin(ind).(ordindex))
    wavord=reform(wav(*,ordob))
    rdfts,wi,si,min(wavord)-3,max(wavord)+3,dfd=ftsdsk,dfn=ftsdfn
; DSST stellar spectrum, 4x sampling
    spbig=dsst(pind(n)).dst
    spwav=findgen(n_elements(spbig))*dsst(pind(n)).w1+dsst(pind(n)).w0

    pxsrch = 35                 ;search +/- pxsrch pixels
    pxsh = fltarr(2,2*pxsrch+1)
    for q=-pxsrch,pxsrch do begin

;first guess for Z, w0, w1
        zsh=float(q)*2500./c    ;trial and error Z guess
        zspwav=spwav+zsh*spwav  ;Z-shifted wavelength scale of DSST
        w0=minloc(abs(wavord-min(zspwav)),/first)+6 ;beginning pixel, observation
        w1=minloc(abs(wavord-max(zspwav)),/first)-6 ;ending pixel, observation
;iterated guess for Z, w0, w1
        wmid=fix(mean([w0,w1]))
        zsh=float(q)*(wavord(wmid)-wavord(wmid-1))/wavord(wmid) ;improved Z guess
        zspwav=spwav+zsh*spwav  ;wavelength scale
        w0=minloc(abs(wavord-min(zspwav)),/first)+6 ;beginning pixel, observation
        w1=minloc(abs(wavord-max(zspwav)),/first)-6 ;ending pixel, observation

        pxsh(0,q+pxsrch) = zsh  ;record Z-shift
        obb=reform(ob(w0:w1,ordob)) ;observation chunk
        obb=obb/median(obb)     ;normalize observation chunk
        wbb=reform(wav(w0:w1,ordob)) ;cooresponding wavelength
        nobb=n_elements(obb)    ;number of pixels in chunk

;constructing trial and error model
        rebin,wi,si,zspwav,i2big
        mdl=i2big*spbig
        num_conv,mdl,psf,dum
        rebin,zspwav,dum,wbb,mdl

; match model to observation
        ratio = obb/mdl
        cof = pl_fit(findgen(nobb),ratio,1)
        slope = poly_fat(findgen(nobb),cof) 
        mdl = mdl*slope

        pxsh(1,q+pxsrch)=stdev(mdl-obb) ;stdev of model-observation
    endfor                      ;q

    dum = minloc(reform(pxsh(1,*)),/first) ;best fit model
    gz(*,n)=pxsh(*,dum)

endfor                          ;n

;toss the worst fitting models from Z determination
ind = where(reform(gz(1,*)) lt max(gz(1,*)))
gz=gz(*,ind)
z=median(gz(0,*))             ;take median Z from remaining good determinations

return
end
