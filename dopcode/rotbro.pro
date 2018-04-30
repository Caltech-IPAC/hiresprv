function rotbro,dw,s,lcen,vsini_val,eps=eps,nres=nres,kernal=ker
;Broaden a spectrum according to rotational broadening kernel.
; dw (input vector) relative wavelength scale for spectrum to be broadened
; s (input vector) spectrum to be broadened
; lcen (input scalar) central wavelength of line (in Angstroms).
; vsini (input scalar) equatorial velocity of star (km/sec)
; eps (input scalar) limb darkening coefficient
;Returns a rotationally broadened profile.
;Edit History:
;23-Sep-91 JAV	Cleaned up, vectorized. Negligible speed increase.
;05-Jun-92 JAV	Converted to function. Handle nonpositive vsini.
;27-Mar-94 JAV	Ported to Solaris 5.3. Removed single precision logic.

if n_params() lt 4 then begin
  print,'syntax: snew=rotbro(dw,sold,lcen,vsini[eps=,nres=])'
  retall
endif

;Warn user if vsini is negative.
;  if vsini lt 0.0 then $
;    message,/info,'Warning! Forcing negative vsini to zero.'

;Define program parameters.
  vsini = vsini_val
  if n_elements(eps) eq 0 then eps = 0.6	;default limb darkening
  if n_elements(nres) eq 0 then nres = 10	;pts. in broadening kernel
  nresi = long(nres)

;Return input spectrum if vsini is negative or zero.
  if vsini le 0.0 then return,s
  if vsini le 0.4 then vsini = 0.2 + 0.5*vsini  ;ramp to 0.2 ,lowest vsini

;Build convolution wavelength grid. Spline spectrum onto new grid.
  nw = long(n_elements(dw))			;# of points in spectrum
  dwmax = lcen * float(vsini) / 2.9979246d5	;maximum doppler shift (limb)
  dx = dwmax / nresi				;spacing of convolution grid
  nx = long((dw(nw-1) - dw(0)) / dx + 1)	;# of convolution grid points
  dummy = 0L
  x = dw(0) + dx * dindgen(nx)			;convolution wavelength scale
  y = dblarr(nx,/nozero)			;init splined spectrum
  y = fspline(double(dw),double(s),double(x))
; dummy = call_external('/users1/casa/jvalenti/lib/spline.so','spline' $
;   ,nw,double(dw),double(s),nx,x,y)

;Pad ends to insulate spectrum from Fourier ringing.
  npad = nresi + 2				;# of pad pixels on each end
  npad = 3.*npad
  y = [replicate(y(0),npad),y,replicate(y(nx-1),npad)]

;Generate rotational convolution kernel. (See Gray, _Photospheres_, p.398
;  or Gray, _Photospheres 2e_, p.374)
;Note: dwmax is assumed constant over the wavelength range of W.
  c1 = 2.0 * (1.0 - eps) $
     / (!dpi * dwmax * (1.0 - eps/3.0))
  c2 = eps / (2.0 * dwmax * (1.0 - eps/3.0))	;constants of kernel function
  dwfrac = findgen(2*nresi + 1) / nresi - 1.0 	;fraction of max change in W
  z = 1.0 - dwfrac * dwfrac			;precompute for efficiency
  ker = c1 * sqrt(z) + c2 * z			;rotational broadening kernel
  ker = ker / total(ker)			;normalize kernal

;Convolve spectrum with kernel, clip padding, and spline back onto W.
  yout = convol(y,ker)				;do convolution
  yout = double(yout(npad:nx+npad-1))		;clip padding from ends
  sout = dblarr(nw,/nozero)			;init broadened spectrum
  sout = fspline(x, yout, dw)
;  if (size(s))(2) ne 5 then sout = float(sout)	;revert to single precision

  return,sout					;return broadened spectrum

end

