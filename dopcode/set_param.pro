;See: Boas Ch 12, eqn 22.15  or  Arfken Ch 13
pro set_param, param
;common psfstuff,param,psfsig,psfpix,obpix
n = 15                          ;number of terms
nx = 121                        ;number of oversampled points
if n_elements(param) eq 0 then init_param, param
                                
;;;These steps only need to be run once. The values become global
if not param.set then begin
;;;MAKE_HERM computes the Hermite polynomial coefficients
    make_herm,n-1,c,/transpose
    param.coeff = c

    pow = indgen(n)
;;;FUNCTION: FAN(pow,n) = pow#(fltarr(n)+1) = "outer product"
;;;see: ~johnjohn/idl/array_handling/fan.pro
    param.powarr = fan(pow, nx)
    xarr = fan(param.x, n, /transpose)
                                ;create x^0 to x^(n-1) in 2D array form
    param.zarr = xarr^param.powarr

    norm = 1d/sqrt(2d^pow*sqrt(!pi)*factorial(pow))
    param.normarr = fan(norm, nx)
                                ;All done!
    param.set = 1
endif 

;;;Width scale factor
beta = dblarr(nx) + param.wid
betarr = fan(beta, n)^param.powarr
;;;Gaussian part of Gaus-Hermite
gau = exp(-(param.x*beta)^2/2d)
;old = exp(-(param.x*beta)^2/2d)
;gau = jjvoigt(param.x, [1., 0., beta[0], 20, 0])
gauarr = fan(gau, n, /transpose)

;;;Combine all ingredients. Mix thoroughly.
t = param.coeff#(param.zarr*betarr)
param.p = param.normarr * gauarr * t 
end
