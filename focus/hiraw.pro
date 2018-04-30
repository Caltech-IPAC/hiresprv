pro   hiraw,im,fn,h,chip=chip

crap=mrdfits(fn,0,h0)

if n_elements(chip) eq 1 then begin
   if chip eq 1 or chip eq 2 or chip eq 3 then begin
      im=mrdfits(fn,chip,h1,/fscale)
      im=rotate(im,3)
      h=[h0,h1]
   endif
endif

if n_elements(h) lt 2 then begin
   im1=mrdfits(fn,1,h1,/fscale)
   im2=mrdfits(fn,2,h2,/fscale)
   im3=mrdfits(fn,3,h3,/fscale)

   im1=rotate(im1,3)
   im2=rotate(im2,3)
   im3=rotate(im3,3)

   ncol=n_elements(im1(*,0))
   nrow=n_elements(im1(0,*))

   im=fltarr(ncol,3*nrow)
   im(*,0:nrow-1)=im1
   im(*,nrow:2*nrow-1)=im2
   im(*,2*nrow:3*nrow-1)=im3

   h=[h0,h1,h2,h3]
endif

return
end
