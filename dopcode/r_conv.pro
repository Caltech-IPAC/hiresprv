pro  r_conv,spec,inst,nsp,sm_end=sm_end,zmom=zmom
;numerical convolution, conv.pro does same in fourier space
; this is a stripped down version of num_conv
;   it assumes the instrumental profile has had the
;   fat trimmed (pixel = 0 or pixels ~= 0 have been removed)
;   and the instrumental profile has already been reversed
; this routine is designed to run with zizz.pro
;                                  and pud_sim.pro and pud_simsh.pro
;
;pro  num_conv,spec,inst,nsp,sm_end=sm_end
; Numerical Convolution
; Default: construct artificial smooth ends for spec, to fudge end effects
; Beware: ends of nsp (within 1/2 width of inst) are inherently incorrect.
; SPEC: input spectrum,  INST: instrumental profile,  NSP: Convolved spectrum
;GM and RPB, last revised 6/92
;PB 2/93, updated to use a fast(!) C convolver
;DAF Nov/01 updated to use idl convol 
;
   if n_params() lt 1 then begin
      print,'R_CONV,spectrum,inst,newspec'
      retall & return
   end
   ip=double(inst/total(inst))
   maxip=maxloc(ip,/first)          ;peak location of INST
   n_ip=n_elements(ip)              ;length of INST
   ln=n_elements(spec)              ;length of spectrum
   nsp=dblarr(ln)                   ;nsp intially zero'ed
   if keyword_set(zmom) then begin              ;zero-moment shift of INST 
      psfunc,ip,ship,maxip
      ip=ship 
   endif
;  Ends cosmetically smoothed
      chunk=fix(n_ip/2.)            ; Arb. choice: size of SPEC end to avg.
      l_mean=mean(spec(1:chunk)) & r_mean=mean(spec(ln-chunk:ln-1))
      dum_spec=[dblarr(maxip)+l_mean,double(spec),dblarr(chunk+50)+r_mean]
      dummy=convol(dum_spec,ip)/total(ip)
      nsp=dummy(chunk:n_elements(spec)+chunk-1)
return
end
