pro vdclean, vdarr,ifit,nchunk $
             , plot=plot $
             , maxchi=maxchi $
             , nozero=nozero $
             , sp2=sp2 $
             , noprint=noprint $
             , percentile=percentile $
             , nofudge=nofudge

;
;  Cleans an array of VD structures, VDCUBE, of "bad" chunk sets.
;  "Bad" chunks are those having:
;   1.  high photon-limited errors
;   2.  high ChiSq, on average over all chunks
;  The underlying idea is that some chunks are bad, due to
;  problems with the DSST (==> chi poor) or poor Doppler information 
;  (small  slopeweight).
;
;INPUT:
;  vdarr    (output structure)  contains an array of VD structures, for 
;                               each observation and chunk within it.
;  fitdex   (integer)           the index of the chisq fit (9 or 10 or ...)
;
;OUTPUT:
; vdarr     (output structure)  contains a "cleaned" array of VD structures .
; nchunk                        revised (reduced) # of chunks
;
;OPTIONAL:
; plot      (keyword)           plots histogram of "goodness" parameter
;

IF n_params () lt 2 then begin
    print,'-------------------------------------------------------------------'
    print,' SYNTAX:'
    print,' '
    print,' IDL> vdclean, vdarr,ifit,nchunk,plot=plot'
    print,'-----------------------------------------------------------------'
    RETURN
ENDIF
;   
;Toss sets with vd.weight lt 0, Bad DSST chunks, PB 6/17/98
if 1-keyword_set(noprint) then print,'VDCLEAN, input n_chunks '+string(n_elements(vdarr(0,*)))
igood = where(vdarr(0,*).weight gt 0)
vdarr = vdarr(*,igood)          ;use good chunk sets only
if 1-keyword_set(noprint) then print,'VDCLEAN, output n_chunks '+string(n_elements(vdarr(0,*)))

;SET CONSTANTS and DEFAULTS
tagnam = tag_names(vdarr)
orignum = n_elements(vdarr(0,*).vel) ;# of chunks in observation #0
numobs = n_elements(vdarr(*,0)) ;# of observations
mdchi = fltarr(orignum)
if not keyword_set(maxchi) then maxchi = 10.
fitdex = first_el(where(tagnam eq 'FIT')) 
veldex = first_el(where(tagnam eq 'VEL')) 
if ifit eq 1 then begin
    fitdex = first_el(where(tagnam eq 'IFIT'))
    veldex = first_el(where(tagnam eq 'IVEL'))
    if veldex lt 0 then veldex = first_el(where(tagnam eq 'VEL'))
endif
if ifit eq 2 then begin
    fitdex = first_el(where(tagnam eq 'SFIT'))
    veldex = first_el(where(tagnam eq 'SVEL'))
    if veldex lt 0 then veldex = first_el(where(tagnam eq 'VEL'))
endif

;Reject chunks having: high photon-limited error, high CHISQ, or both

err = 1./sqrt(vdarr[0,*].weight) ;photon-limited error (m/s)
FOR ch = 0, orignum-1 do begin
    mdchi[ch] = median(vdarr[*,ch].(fitdex)) ;median(chisq) 
    if mdchi(ch) eq 0 then begin
        print,'Observation has fit/ifit/sfit = 0'
        print,'Observation probably has not sucessfully made a second pass' 
;    mdchi(ch)  = median(vdarr(*,ch).fit)  ;insert when one-pass desired
        return
    endif
endfor

ierr = sort(err)   
if 1-keyword_set(percentile) then percentile = 0.99

therr  = err(ierr(percentile*orignum)) ;99 %'ile.
ichi = sort(mdchi) 
thchi = mdchi(ichi(percentile*orignum)) ;99 %'ile
;
if keyword_set(maxchi) then thchi = min([maxchi,thchi])

;NEW WEIGHTS, include median of CHISQ for each chunk-set.
;for ob=0,numobs-1 do vdarr(ob,*).weight = 1./(err^2*mdchi)  ;new weights
;print,'WEIGHTS=1' & for ob=0,numobs-1 do vdarr(ob,*).weight = 1.  ;new weights

igood = where(err lt therr   and $ ;accept low photon errors
              mdchi lt thchi, nchunk) ;accept low CHISQ
;
if nchunk eq 0 then return
vdarr = vdarr[*,igood]          ;use good chunks only

;
IF not keyword_set(nozero) then begin
;;; Add a CONSTANT to the velocities in each chunk set to     
;;; force the median velocity of each chunk set to be ZERO.
;;; This preserves the velocity variation from observaton to observation.
;;; Designed to account for errors in the values of DSST.w0 for each chunk.
;;; Note: This also removes the zero-pt. calibration of the velocity scale.

    if n_elements(sp2) eq 1 then if sp2 eq 1 then veldex = first_el(where(tagnam eq 'SP2'))
    FOR n = 0 , nchunk - 1 do begin ;Loop thru chunks
        vset = vdarr(*,n).(veldex) ;rename vel's of chunk set
        vind = where(vdarr(*,n).(fitdex) lt 99.)
        mnchu = mean(vset(vind)) ;mean vel of chunk set
        vdarr(*,n).(veldex) = vset - mnchu ;shift vels of chunk set
    END
    if 1-keyword_set(noprint) then print,'  VDCLEAN: Set "middle" Velocity of Each Chunk Set to 0'
ENDIF

;Within a chunk set, determine the discrepancy between the velocity 
;of each member and the median velocity of its respective observation. 
;
diff = fltarr(numobs,nchunk)    ;difference: vel - median_obs

FOR ob = 0,numobs-1 do begin
    medvel = median(vdarr(ob,*).(veldex)) ;median Velocity off obs.
    diff(ob,*) = vdarr(ob,*).(veldex) - medvel ;Vel_chunk - median_obs
END

;Find scatter of diff within a chunk set
;The ``sigma'' below measures the SCATTER of chunk set members relative
;to their expected velocity based on the observation median.
sigma = fltarr(nchunk)          ;sigma of vel_chunk - median_obs

if keyword_set(nofudge) then fudgefac = 1. else fudgefac = 2.                   ;No fudge
;fudgefac=1
FOR n = 0,nchunk-1 do begin
    igood = where(vdarr(*,n).(fitdex) lt 99.) ;obs having good fit
    sigma(n) = stdev(diff(igood,n)) ;RMS of vel-median_obsof chunk-set
END

FOR ob = 0,numobs-1 do begin
    const = median( abs(diff(ob,*))/sigma ) ;ratio: actual to typical discrepancy for chunks
    sigmaob = const * sigma * fudgefac ;boost chunk-set sigma by const
    for n=0,nchunk-1 do begin
        vdarr(ob,n).weight = 1./sigmaob(n)^2 ;weights scaled to scatter w/i obs.
    end
;    vdarr(*,n).weight = 1.             ;No weights
; Otherwise, weights based on input (hopefully photon limited errors)
END
if 1-keyword_set(noprint) then print,'  VDCLEAN: CHUNK WEIGHTS ADJUSTED, according to chunk set scatter.'
;
thscat = 0.99                   ;Best 99% kept
isig = sort(sigma)  &  thsigma  = sigma(isig(thscat*nchunk)) ;Best thscat% 'ile
igood = where(sigma lt thsigma, nchunk) ;accept best thscat% sigmas
vdarr = vdarr(*,igood)

titl='!6 Histogram:  Velocity Scatter of Chunk Sets'
                                ;plothist,sigma(igood),title=titl,bin=20 
if 1-keyword_set(noprint) then begin

    print,''
    print,'    Reject chunk-sets having:'
    print,'           Photon-Limited Error >', fix(therr),' m/s'
    print,'           Median CHISQ >', thchi
    print,'           Scatter from median >',thsigma,' m/s'
    print,' Retaining ',strtrim(string(nchunk),2), $
          ' out of ',strtrim(string(orignum),2), ' chunks.'
    print,' '
endif

return
end
