function        fspline,x,y,xn
;replacement code to avoid the need to call
;spline.so on future, incompatible OS's.
; DAF Nov/01 changed

 ;     zfine = fspline(xcut,zcut,xfine)         ;finely sample peak region
  return, spl_interp(x,y,spl_init(x,y),xn,/double) ;IDL internal

end
