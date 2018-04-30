pro  gausscon,x_arr,gpar,fnct,pder
;x-arr is independent input array
;gpar is a 3 element array consisting of the gaussian parameters
;fnct is the function constructed from gpar
;pder is an optional array of the partial derivatives from gpar
;(pder is needed in curvefit)

if n_elements(gpar) lt 3 then $
        stop,'Not enough parameters to specify a Gaussian (in gausscon)!'
if n_elements(gpar) gt 4 then $
        stop,'Too parameters to specify a Gaussian (in gausscon)!'

z=(x_arr-gpar(1))/gpar(2)
fnct=gpar(0)*exp(-z*z/2)
if n_elements(gpar) eq 4 then fnct=fnct+gpar(3)

if n_params() eq 4 then begin
   pder=fltarr(n_elements(x_arr),n_elements(gpar))
   pder(*,0)=fnct/gpar(0)
   pder(*,1)=(x_arr-gpar(1))*fnct/gpar(2)/gpar(2)
   pder(*,2)=(x_arr-gpar(1))^2*fnct*(1./gpar(2))^3
   if n_elements(gpar) eq 4 then pder(*,3)=1.
endif   ;n_params

return
end;
