Function Transpar,par,toggle
common spectra,obchunk,wfts,sfts,wnso,snso,w0,inpr,osamp,wght,dstep,npar,flind,keck

;Transform from original free parameters (par) to new parameters (newpar).
;The new parameters are linear combinations of the original.
;The NEWPAR are designed to enhance CHI-SQ minimization ---
; they lie parallel or perpendicular to the Chi-Sq valleys.

;INPUT:
;      PAR     fltarr(15)    input parameters
;      TOGGLE  1 or -1       1 (-1) for forward (backward) transformation

;OUTPUT: 
;     The function returns the new parameters, NEWPAR
;     The new DSTEP array is also passed (toggle=1), via the common block
;     
;CAUTION:  DSTEP array is automatically transformed and passed in common
;
;Aug-95 GWM

c = 2.9979d8                        ;speed of light
newpar = par                        ;Initialize newpar

dvel = 20.                          ;20 m/s  = standard velocty unit
dstep(12) = dvel/c                  ;20 m/s achieves lowest Chi-sq

IF toggle ne 1 and toggle ne -1 then begin       ;Verify toggle = 1 or -1
   print,'TRANSPAR:  Error in toggle (+1 or -1)'
END

IF toggle eq 1 then begin           ;Forward Transformation
; Transform pars 11 and 13
  newpar(11) = par(11) + 20.*par(13)       ;wav at pixel = 20
  newpar(13) = par(11) - 20.*par(13)       ;wav at pixel = -20 (!)
  dstep(11) = w0 * dvel/c                  ;new dstep (~ 10 m/s)
  dstep(13) = w0 * dvel/c                  ;new dstep (~ 10 m/s)
ENDIF

IF toggle eq -1 then begin                 ;Transform Back
; De-Transform pars 11 and 13
  newpar(11) = 0.5*(par(11) + par(13))
  newpar(13) = (par(11) - par(13))/40.
ENDIF

return,newpar
end
