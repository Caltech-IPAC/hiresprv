;convert from lambda scale to evenly spaced log(lambda) scale
function convscale,wavin,specin, setvel=setvel, vscale=vscale, invscale=invscale
common specstuff,velscale,delvel
spec = specin
wav = wavin
;common const
vlight = 2.99792d5
npix = n_elements(spec)
logwav = vlight*alog(wav)
if keyword_set(setvel) and 1-keyword_set(invscale) then begin 
    mxlw = max(logwav) 
    mnlw = min(logwav)
    delvel = (mxlw-mnlw)/npix
    trim = delvel*5        ;first step in making VELSCALE a subset of LOGWAVE
    velscale = fillarr(delvel,mnlw+trim,mxlw-trim)  ;evenly spaced log(lambda)
endif else if keyword_set(invscale) then velscale = invscale

;force VELSCALE to be a subset of LOGWAV
if min(logwav) gt min(velscale) then begin
    logwav = [min(velscale),logwav]
    spec = [0,spec]
endif 
if max(logwav) lt max(velscale) then begin
    logwav = [logwav,max(velscale)]
    spec = [spec,0]
endif

rebin,logwav,spec,velscale,newspec

if keyword_set(setvel) then vscale = velscale
return,newspec
end

