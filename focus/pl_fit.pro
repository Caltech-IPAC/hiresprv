function pl_fit,x,y,p_ord
n_e=n_elements(x)
nx=double(x)
xarr=dblarr(fix(p_ord+1),n_e)
for m=0,fix(p_ord) do xarr(m,*)=double(nx^m)
t_xarr=transpose(xarr)
sqmat=xarr # t_xarr
invsqmat=invert(sqmat)
dum=t_xarr # invsqmat
return, y # dum
end;
