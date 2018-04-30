function nsigma, distin, sig=sig, submed=submed

; measure the n-sigma values of a distribution
; three values are returned: 
; out[0]= center of dist minus sig   :HTI
; out[1]= center of distribution     :HTI
; out[2]= center of dist plus sig    ;HTI
; if keyword(submed) is set, then 
;   out[0] = upper limit minus median
;   out[1] = lower limit minus median
;NOTE: center of distribution is NOT equal to median.

; default is 1-sigma errors.  Use keyword for other errors
if not keyword_set(sig) then sig = 1

; submed --- subract median to get two-sided errors = [+error,-error]

d = distin
d = d[sort(d)]
nel = n_elements(d)

sigval = [(1-erf(sig/sqrt(2.)))/2., 0.5, 1-(1-erf(sig/sqrt(2.)))/2.]
sigind = nel*sigval
sigdist = d[sigind]
out=sigdist

if keyword_set(submed) then begin
    out = [sigdist[2]-sigdist[1],sigdist[1]-sigdist[0]]
endif


return, out

end