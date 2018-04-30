pro  num_conv,spec,inst,nsp,sm_end=sm_end,ip,zmom=zmom, bad=bad
; Numerical Convolution
; Default: construct artificial smooth ends for spec, to fudge end effects
; Beware: ends of nsp (within 1/2 width of inst) are inherently incorrect.
; SPEC: input spectrum,  INST: instrumental profile,  NSP: Convolved spectrum
; Shift = Centroid of INST relative to its central element (if odd-sized)
; keyword, sm_end, is dummy for compatibility with old version
;GM and RPB, last revised 4/92
;PB 2/93, Updated to do actuall convolution with a fast(!) C routine
;PB 11/93, Updated to do zero-moment shift of psf
;DAF Nov/01 eliminate call_external code - convolution now done 
; with idl's fast internal convol
;on_error,2
if n_params() lt 1 then begin
    print,'NUM_CONV,spectrum,inst,newspec'
    retall & return
end
if n_elements(zmom) ne 1 then zmom=0
ip=inst                         ;Normalize for trim below .001
n_ip=n_elements(ip)
;   indx=where(ip gt 0.001*max(ip),n_indx)      ;Use only non-zero INST
indx=where(abs(ip) gt 0.001*max(ip),n_indx) ;Use only non-zero INST, incl (-)
if n_indx eq 0 then begin
    bad = 1
    return
endif else bad = 0
lft=max([indx(0)-1,0])          ;1st such element
rit=min([indx(n_indx-1)+1,n_ip-1]) ;last such element
ip=ip(lft:rit)                  ;Strip the INST
ip=double(reverse(ip)/total(ip)) ;reverse and re-normalize
maxip=maxloc(ip,/first)         ;peak location of INST
if maxip eq 0 then maxip = n_ip/2
n_ip=n_elements(ip)             ;length of INST
ln=n_elements(spec)             ;length of spectrum
nsp=dblarr(ln)                  ;nsp intially zero'ed
if zmom eq 1 then begin         ;zero-moment shift of INST
    psfunc,ip,ship,maxip
    ip=double(ship/total(ship))
endif
;  Ends cosmetically smoothed
chunk=fix(n_ip/2.)              ; Arb. choice: size of SPEC end to avg.
l_mean=mean(spec(1:chunk)) &  r_mean=mean(spec(ln-chunk:ln-1))
dum_spec=[dblarr(maxip)+l_mean,double(spec),dblarr(chunk+50)+r_mean]
;      dummy=Call_External('./c_conv.so','c_conv', $
;         ip,nsp,dum_spec,n_ip,ln)
dummy=convol(dum_spec,ip)/total(ip)  
nsp=dummy(chunk:n_elements(spec)+chunk-1)

return
end



