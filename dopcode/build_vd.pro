pro build_vd,dsst,ob,z,vdin,vdout,plot_key=plot_key,bookend=bookend
;This code carries out the set-up and construction
; of a first guess "vd" velocity data structure

;
;dsst     (input structure) appropriate "dsst' (deconvolved stellar structure) for
;	              the observation
;vd       (input/output structure) "vd" structure for observation.  This "vd" should
;		      be matched to the observation, as from an iodine from the same
;                     night.  As input, it must carry a reasonably accurate (better
;                     0.5 pixel) wavelength scale.
;                     As output it is the appropriate set_up "vd" for the observation
;                     described by the "cf" structure.
;
;Created April/May, 1995  R.P.B.

;Isolate file paths
files= getenv("DOP_FILES_DIR")

tags = tag_names(dsst)
w = where(tags eq 'WCOF', nw)
if nw eq 0 then begin
    dsst = jjadd_tag(dsst, 'WCOF', dblarr(4), /arr)
    dsst.wcof[0] = dsst.w0
    dsst.wcof[1] = dsst.w1
endif

tagnam=tag_names(vdin)
ordindex=(where(tagnam eq 'ORDER'))[0]
if ordindex eq -1 then ordindex=(where(tagnam eq 'ORDOB'))[0]

tagnam=tag_names(dsst)
ordsst=(where(tagnam eq 'ORDER'))[0]
if ordsst eq -1 then ordsst=(where(tagnam eq 'ORDT'))[0]
pxdsst=(where(tagnam eq 'PIX0'))[0]
if pxdsst eq -1 then pxdsst=(where(tagnam eq 'PIXT'))[0]
wtdsst=(where(tagnam eq 'WEIGHT'))[0]
if wtdsst eq -1 then wtdsst=(where(tagnam eq 'SLOPE'))[0]

osamp=4
if n_elements(plot_key) ne 1 then plot_key=0
ndsst=n_elements(dsst)
dsstlen=40.0                    ;assume 40 pixel DSST chunks
if n_elements(dsst[0].dst) gt 260 then dsstlen=50.0 ;50 pixel chunks
if n_elements(dsst[0].dst) gt 300 then dsstlen=55.0 ;55 pixel chunks
if n_elements(dsst[0].dst) gt 320 then dsstlen=80.0 ;80 pixel chunks

npix = n_elements(ob[*,0])      ;# of pixels per order
nord = max(vdin.(ordindex))     ;# of orders in observation
xx   = dindgen(npix)
wav  = dblarr(npix,nord+1)

;set up wavelength scale for the observation
jjsm_wav,vdin,wc,pord=6 ;Iodine wavelengths
for n = 0, nord do if wc[0,n] gt 0 then wav[*,n] = poly_fat(xx, wc[*,n])

;construct the VD structure to match the DSST
dum = {ordt:0,ordob:0,pixt:0,pixob:0,w0:5000,wcof:fltarr(4) $
       ,icof:fltarr(4),scof:fltarr(4),cts:long(0),scat:0.,z:0.,errz:0. $
       ,fit:0.,ifit:0.,sfit:0.,$
       npix:0,gpix:0,vel:0.,ivel:0.,svel:0.,weight:0.,depth:0.,sp1:0.,sp2:0.,$
       spst:'?',iparam:fltarr(20)}
nvdi = n_elements(vdin)
vdout         = replicate(dum,ndsst) ;Define vd structure based on DSST

vdout.ordt    = dsst.(ordsst)
vdout.ordob   = dsst.(ordsst)
vdout.pixt    = dsst.(pxdsst)
vdout.pixob   = dsst.(pxdsst)
if nvdi eq ndsst then vdout.fit = vdin.fit
if nvdi eq ndsst then vdout.cts = vdin.cts
if keyword_set(longformat) then begin
    neldst = n_elements(dsst[0].dst)
    npixvd = vdin[0].npix
    pad = (neldst/osamp - npixvd)/2
    vdout = vdin
    vdout.npix = neldst/osamp - pad*2
    if 0 then begin
        wcof = dsst.wcof * fan([1,osamp,osamp^2,0], ndsst)
        w0 = dblarr(ndsst)
        for k = 0, ndsst-1 do w0[k] = poly(pad, wcof[*,k])
        vdout.w0 = fix(w0)
        vdout.wcof[0] = w0 - fix(w0)
        vdout.wcof[1] = wcof[1]
        vdout.wcof[2] = wcof[2]
    endif
    vdout.z = z
    vdout.weight = dsst.(wtdsst)
    u = where(tagnam eq 'SVEL', nu)
    if nu eq 0 then vdout = jjadd_tag(vdout, 'SVEL', 0.)
endif else begin
					;11.75 pixels of slop in DSST
    vdout.w0      = fix(dsst.w0 + 11.75*osamp*dsst.w1) 
    vdout.wcof(0) = ( dsst.w0 + 11.75*osamp*dsst.w1 ) - vdout.w0
   ; This vd.wcof are not passed through to stargrind. HTI 9/2014
    vdout.wcof(1) = dsst.w1*osamp ;DSST is 4x oversampled
    vdout.weight  = dsst.(wtdsst)
;vdout.npix    = 40                            ;Initially assume 40 pixel chunks
    vdout.npix    = dsst(1).pixt-dsst(0).pixt ;initially assume DSST pixel chunk size
    vdout.z       = z           ;Z guess from bcvel.ascii
endelse

if n_elements(bookend) ne 1 then bookend = 0
if bookend ne 1 then begin
    twav = vdout.w0 + vdout.wcof[0] ;template wavelength chunks
    twav = twav + twav * z      ;Z-shifted observed wavelength chunks
    kludgetrack=0
    lastord = -10

    if kludgetrack eq 0 then begin
        for n = 0,(ndsst-1) do begin ;loop over chunks
;old-style (800 pixel) observations, order offsets from DSST
;Keck (2048 pixel) observations, order offsets from DSST
;   if (npix lt 801) or (npix gt 2000) then begin ;old 800 pixel format + Keck
            if (npix lt 801) or (npix eq 2048) then begin ;old 800 pixel format + Keck
                ind = minloc(abs(wav - twav(n)),/first)
                ordob=fix(ind/npix)
                pixob=ind - ( fix(ind/npix) * npix )
            endif 
            if (npix eq 1851) and (max(dsst.pixt) lt 1851) then begin ;Lick 1851 pixel format
;Hamilton "big-chip" observation, kludge (npix = 1851)
                ordob = vdout(n).ordt
                pixob = minloc(abs(wav(*,ordob) - twav(n)),/first)
            endif
            if (npix eq 2496) and (max(dsst.pixt) ge 2400) then begin ;AAT 2496 pixel format
;Both Observation and DSST are MIT/LL, kludge (npix = 2496)
                ordob = vdout(n).ordt
                pixob = minloc(abs(wav(*,ordob) - twav(n)),/first)
            endif
            if (npix eq 2047) and (max(dsst.ordt) eq 19) then begin ;AAT MITLL 2027 pixel seismology format
;Both Observation and DSST are MIT/LL, kludge (npix = 2047)
                ordob = vdout(n).ordt
                pixob = minloc(abs(wav(*,ordob) - twav(n)),/first)
            endif
            if (npix eq 2746) and (max(dsst.pixt) gt 2600) then begin ;AAT/EEV 2746 pixel format
;Both Observation and DSST are EEV, kludge (npix = 2746)
                ordob = vdout(n).ordt
                pixob = minloc(abs(wav(*,ordob) - twav(n)),/first)
            endif
            if (npix eq 4096) or (npix eq 4100) and (max(dsst.pixt) gt 3900) then begin ;SUBARU
                ordob = vdout(n).ordt
                pixob = minloc(abs(wav(*,ordob) - twav(n)),/first)
            endif
            if (npix eq 2496) and (max(dsst.pixt) gt 2600) then begin ;AAT/MITLL obs analz. with AAT/EEV DSST
;Observation is npix=2496 MITLL and DSST is npix 2746 EEV
                ordob = vdout(n).ordt
                pixob = minloc(abs(wav(*,ordob) - twav(n)),/first)
                wavmax = wav(pixob,ordob) + dsstlen*dsst(n).w1*osamp
                pixmax=minloc(abs(wav(*,ordob) - wavmax),/first)
                vdout(n).npix=pixmax-pixob
            endif

;Both Observation and DSST are Post-Fix HIRES, kludge (npix = 4021)
            if (npix eq 4021) and (max(dsst.ordt) lt 15) then begin 
                ;Keck New CCD, YES THIS IS USED.
                ordob = vdout[n].ordt
                pixob = minloc(abs(wav[*,ordob] - twav[n]),/first)
            endif

;Observation is npix=4021 Post-Fix HIRES and DSST is npix Pre-Fix HIRES
            if (npix eq 4021) and (max(dsst.ordt) gt 20) then begin ;analz. with Keck Pre-Fix DSST
                ordob = vdout(n).ordt - 20
                vdout(n).ordob=ordob
                pixob = minloc(abs(wav(*,ordob) - twav(n)),/first)
                wavmax = wav(pixob,ordob) + dsstlen*dsst(n).w1*osamp
                pixmax=minloc(abs(wav(*,ordob) - wavmax),/first)
                vdout(n).npix=pixmax-pixob
            endif

;Observation is npix=2048 Pre-Fix HIRES and DSST is npix Post-Fix HIRES
            if (npix eq 2048) and (max(dsst.pixt) gt 3800) then begin ;analz. with Keck Post-Fix DSST
                ordob = vdout(n).ordt + 20
                vdout(n).ordob=ordob
                if ordob lt n_elements(wav(0,*)) then begin
                    pixob = minloc(abs(wav(*,ordob) - twav(n)),/first)
                    wavmax = wav(pixob,ordob) + dsstlen*dsst(n).w1*osamp
                    pixmax=minloc(abs(wav(*,ordob) - wavmax),/first)
                    vdout(n).npix=pixmax-pixob
                    if pixob gt (2048 - 60) then vdout(n).sp1=-1 ;Kludge RPB 17Jan05
                    if pixob lt 11 then vdout(n).sp1=-1
                endif else vdout(n).sp1=-1
            endif

            if (pixob gt 10) and (pixob lt (npix - 50)) then begin
                vdout[n].ordob = ordob
                vdout[n].pixob = pixob
                vdout[n].w0 = fix(wav[pixob,ordob])
                vdout[n].wcof[0] = wav[pixob,ordob] - vdout[n].w0
                if keyword_set(longformat) then begin
                    vdout[n].iparam[14] = vdout[n].wcof[2]
                endif else begin
                    vdout[n].wcof[1] = wav[pixob+20,ordob] - wav[pixob+19,ordob]
                endelse
                vdout[n].iparam[11] = vdout[n].wcof[0]
                vdout[n].iparam[13] = vdout[n].wcof[1]
            endif else vdout[n].sp1=-1
        endfor
    endif

;toss "wrap-around" regions in old-style (800 pixel) observations
    nind=-1
    if ( npix lt 801 ) and ( max(dsst.(pxdsst)) gt 1600 ) then begin
        ind=where(vdout.pixt lt 200 or vdout.pixt gt 1400,nind)
        if nind gt 0 then vdout(ind).sp1=-1
    endif
;;    vdout=vdout(where(vdout.sp1 ge 0)) ;toss the bad boys
;;HTI 6/2014 has commented out the previous line because it sometimes causes
;;	a number of chunks not equal to 718. In order for the vank process to work,
;;	every VD for a single star must have the same number of chunks. Removing 
;;	this line ensures that all VDs have 718 chunks for Keck observations.
	if n_elements(vdout) ne 718 then begin
		print,'%BUILD_VD: NUMBER OF CHUNKS IS NOT 718 AS IT SHOULD BE.'
		STOP
	endif	;THIS PATCH IS FOR KECK POST-UPGRADE ONLY
; HTI COMMENTS END

    if (npix gt 2000) and (max(dsst.pixt) lt 1900) or keyword_set(nowrap) then begin
        for n=0,n_elements(vdout)-1 do begin
            ppx=vdout[n].pixob
            odx=vdout[n].ordob
            dum=where(vdout.ordob eq odx and abs(vdout.pixob-ppx) lt 31,ndum)
            if ndum gt 1 then begin
                ind=maxloc(abs(vdout(dum).pixt-1000))
                vdout(dum(ind)).sp1=-1
            endif
                                ; Kludge to fix floating vd.npix,  15Feb99 PB
                                ; DSST's are either 40 pixel or 50 pixel 
            wdsst=wav(ppx,odx)
            ddork=dsst(where(vdout[n].pixt eq dsst.pixt and vdout[n].ordt eq dsst.ordt))
            pixmax=minloc(abs(wav(*,odx)-(wdsst+dsstlen*ddork.w1*osamp)),/first)
            vdout[n].npix=pixmax-ppx+1
        endfor
        vdout=vdout(where(vdout.sp1 ge 0)) ;toss the bad boys
        for n=0,n_elements(vdout)-1 do begin
            dum=where(vdout.ordt eq vdout[n].ordt and $
                      vdout.pixt eq vdout[n].pixt,ndum)
            if ndum gt 1 then begin
                ind=maxloc(abs(vdout(dum).pixob-1000))
                vdout(dum(ind)).sp1=-1
            endif
        endfor
        vdout=vdout(where(vdout.sp1 ge 0)) ;toss the bad boys
        dum=float(vdout.ordob)*npix+float(vdout.pixob)
        ind=sort(dum)
        vdout=vdout(ind)
        for n=0,n_elements(vdout)-1 do begin ;eliminate overlap between chunks
            qq=where(vdout.ordob eq vdout[n].ordob and $
                     vdout.pixob gt vdout[n].pixob,nqq)
            if nqq gt 0 then vdout[n].npix = $
              min([vdout[n].npix,min(vdout(qq).pixob)-vdout[n].pixob])
        endfor                  ;eliminate overlap between chunk sets

    endif ;toss "wrap-around" regions when using Lick DSST to analyze Keck observation
endif                           ;bookend ne 0
for n=0,10 do vdout.iparam(n)=median(vdin.iparam(n))
for n=15,19 do vdout.iparam(n)=median(vdin.iparam(n))
return
end
