;+
; NAME:
;       CHAUVENET
;     
; PURPOSE:
;       Given the residuals of a fit, this routine returns the indices
;       of points that pass Chauvenet's criterion.  You can also return
;       the number of points that passed, the indices of the points
;       that failed, the number of points that failed, and a byte mask
;       where 1B represents a passing point and 0B represents a failing
;       point.
;     
; EXPLANATION:
;       Chauvenet's criterion states that a datum should be discarded if 
;       less than half an event is expected to be further from the mean of 
;       the data set than the suspect datum.  You should only use this
;       criterion if the data are normally distributed.  Many authorities
;       believe Chauvenet's criterion should never be applied a second
;       time.  Not me.
;     
; CALLING SEQUENCE:
;       RESULT = CHAUVENET(X [,NPASS][,REJECT=reject][,
;                          NREJECTS=nrejects][,MASK=mask][,/ITERATE])
;     
; INPUTS:
;       baseline : The residuals of a fit to data.
;     
; OUTPUTS:
;       The indices of the data that passed Chauvenet's criterion.
;
; OPTIONAL OUTPUTS:
;       NPASS : The number of data that passed Chauvenet's criterion.
;
; KEYWORDS:
;       /ITERATE : Iterate until there are no data that fail
;                  Chauvenet's criterion.
;
;       REJECT : The indices of data that failed Chauvenet's criterion.
;
;       NREJECTS: The number of data that failed Chauvenet's criterion.
;
;       MASK : A byte mask which is set to 1B where a datum passed
;              Chauvenet's criterion and 0B where a datum failed.
;
; RESTRICTIONS:
;       Only works for IDL versions 5.4 and above!!!
;       (Uses COMPLEMENT keyword for WHERE function.)
;
; PROCEDURES CALLED:
;      INVERF 
;
; EXAMPLE:
;       RESIDUALS is an array with the difference between DATA and
;       a fit to these data.  Find the indices of 
;
;       IDL> passed = chauvenet(RESIDUALS,NPASS,REJECT=failed)
;
;       Plot the data points and highlight the data that failed:
;
;       IDL> plot, DATA, ps=3
;       IDL> oplot, DATA[failed], ps=4
;
; NOTES:
;       See Taylor's Intro to Error Analysis pp 142-144 OR
;       Bevington & Robinson's Data Reduction & Error Analysis for the
;       Physical Sciences p 58.
;
;       Any non-finite values are ignored... rather than throwing
;       them out, the user should think about why they have non-
;       finite values and deal with them on their own terms.
;
;       If the data you are testing are not drawn from a Gaussian
;       parent distribution, then you have no business using this
;       routine!
;
; MODIFICATION HISTORY:
;       Written by Tim Robishaw, Berkeley  Dec 13, 2001
;-

function chauvenet, baseline_in, npass, $
                    REJECT=reject, NREJECTS=nrejects, $
                    ITERATE=iterate, MASK=mask

on_error, 2

; WE ONLY CARE ABOUT FINITE VALUES...
fin = where(finite(baseline_in),Nfinite)
if (Nfinite gt 0) $
  then baseline = baseline_in[fin] $
  else message, 'No finite values in the baseline!'

; HOW MANY ELEMENTS IN THE BASELINE...
N = N_elements(baseline)

; CHECK FOR CASE WHERE THERE'S ONLY ONE DATUM...
; MAKE USER THINK ABOUT DREADFUL MISTAKE...
if (N eq 1) then $
  message, 'Chauvenet''s criterion can''t be applied to only one datum!'

; FASTER THAN MOMENT, MEAN, OR STDDEV...
mean = total(baseline,/double)/N
rms  = sqrt(total((baseline-mean)^2,/double)/(N-1))

; FIND INVERSE ERROR FUNCTION OF (1 - 0.5/N)...
; MAKE A MASK OF POINTS THAT PASSED CHAUVENET'S CRITERION...
mask = abs(baseline-mean) lt $
       1.4142135623730950488d0 * rms * inverf(1d0 - 0.5d0/N)

; DO YOU REALLY WANT TO ITERATE...
; BEVINGTON AND TAYLOR SAY YOU SHOULDN'T...
if keyword_set(ITERATE) then begin
    indx = where(mask eq 1B, Ngood)
    if (Ngood lt N) and (Ngood ne 0) then begin
        useless = chauvenet(baseline[indx], MASK=imask, /ITERATE)
        mask[indx] = mask[indx] AND imask
    endif
endif else return, -1

; RETURN THE INDICES WHERE YOU'VE PASSED CHAUVENET'S CRITERION... 
return, where(mask eq 1B, npass, COMPLEMENT=REJECT, NCOMPLEMENT=NREJECTS)

end; chauvenet


