function ghfunc,x,par,ipro=ipro,plot_key=plot_key,param=param,info=info

;common psfstuff,param,psfsig,psfpix,obpix
;+
; Gaus-Hermite-based function to model "arbitrarily wingy" instrumental
; profiles. 
;
; x (input vector) pixel offsets at which to evaluate function.
; par (input vector) profile function parameters as described below
;
; Returns the normalized profile function evaluated at each point in x.
;
; Modified 10/10/2002 by JohnJohn: Now uses make_herm to initialize
; GH coeffs. Other speed-based modifications made as well.
; up to 15 Gauss Hermite components used plus par[0] = width = 1/beta.
;-
if 1-keyword_set(info) then info = {psfsig:-1, psfpix:-1, test:''}
if 1-keyword_set(param) then init_param, param
if n_params() lt 2 then begin
    print,'syntax: ghfunc(x,par)'
    retall
endif

;;;param.x = x ;This is here only because to preserve the interface that
                                ;GPFUNC had. With GHFUNC, x (param.x) is global
;amp = fan([1d,par[1:10],par[15:18]],121)
if info.psfsig[0] gt 0 then amp = fan([1d,par[1:10],intarr(4)],121) else $
  amp = fan([1d,par[1:10],par[15:18]],121)

;;;No need for fancy mathematics if the width parameter doesn't change.
;;;SET_PARAM makes changes to param.p. Amplitudes can be adjusted
;;;without SET_PARAM
;;;if param.plotpsf then print,str(par[0])+' '+str(param.oldwid)
if par[0] ne param.oldwid then begin
    param.wid = par[0]
    set_param, param
    param.oldwid = par[0]
end 

ipro = total(amp*param.p,1)
ipro1 = ipro

if info.psfsig[0] gt 0 then begin
    psfpix = info.psfpix
    psfsig = info.psfsig
    ngau = n_elements(psfpix)
    for i = 0, ngau-1 do begin
        gau = jjgauss(param.x, [par[15+i], psfpix[i], psfsig[i]])
        ipro += gau
    endfor
endif
;;; Force centering, JJ: turned off, doesn't matter since num_conv
;;; trims zeros off of ends, leaving same shape no matter what.
if info.test eq 'jconv' then center = 1
if keyword_set(center) then begin
    com = int_tabulated(param.x, param.x*ipro)/int_tabulated(param.x, ipro)
    disp = param.x[1] - param.x[0]
;    if abs(com) gt 0.1 then stop
    ipro = shift_interp(ipro, -com/disp)
endif
return,ipro / int_tabulated(param.x,ipro) ;return normalized profile
end





