function        dspline,x,y,xn
on_error, 2
;replacement code to avoid the need to call
;spline.so on future, incompatible OS's.


 ;     zfine = fspline(xcut,zcut,xfine)         ;finely sample peak region
  return, spl_interp(x,y,spl_init(x,y),xn,/double) ;IDL internal

end
