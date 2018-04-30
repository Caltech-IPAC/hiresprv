function offset_corr, cf, return_cf=return_cf

; This function calcultes the velocity offset corrrection 
; between pre- and post-upgrade HIRES velocities.  
; The HIRES upgrade took place in 2004.
; This function takes as input a cf structure that includes all 
; pre-upgrade velocities (and optionally post-upgrade velocities as well).
; The value returned from this function should be added to 
; pre-upgrade velocities.
; This offset correction was found by correlating the 
; pre-upgrade counts (in the cf3 structure) with a best-fit offset
; calculated in calc_offsets.pro.
;
; by Andrew Howard - September, 2008

offset = 0.
prepost=13237.  ;pre/post Julian Date
cf_int = cf
if where(cf_int.jd le prepost) ne [-1] then begin
    cf_pre = cf_int[where(cf_int.jd le prepost)]
    n_pre = n_elements(cf_pre)
    ct80 = (cf_pre.cts[sort(cf_pre.cts)])[floor(n_pre*0.8 )]  ; 80th %ile of counts
    coeff = [ 1.8375474, -3.5136251e-05, 2.0292513e-10 ] ; derived from calc_offsets.pro
    offset = poly(ct80,coeff)
    offset = min([offset,5.])  ; cap offset at 5 m/s
    cf_int[where(cf_int.jd le prepost)].mnvel += offset
endif

if keyword_set(return_cf) then begin
    return, cf_int
endif else begin
    return, offset
endelse

end; function
