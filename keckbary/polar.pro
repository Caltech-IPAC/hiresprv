function polar,car
;
; INPUT: CAR = [x,y,z] cartesian Vector
; OUTPUT: result = [ra,dec] vector in RADIANS!
; I am 99 and 44/100 percent sure that this one works for all cases
; it is the same as polar5.pro
; Supply RA and DEC and distance (a,d,r) for a given vector, x,y,z
; NOTE:  there are two types of atan: atan(y/x)= [-pi/2,+pi/2]
; and atan(y,x) = [-pi,+pi]
; but RA always >0.  Thus add 2 pi and mod 2 pi takes care of this.
;
  x = 0.d0 & y = 0.d0 & z = 0.d0	;initialize to ensure double.
  cart=car*1.d0				;make double precision
  reads,cart,x,y,z
  r=sqrt(total(cart^2))			;r is no problem
;
  if r eq 0 then begin
    print,'POLAR: Get a real vector!  '
    stop
  endif
  twopi = 2.d0 * !dpi
  d=asin(z/r)				;r never =0
;
  if (x eq 0) and (y eq 0) then begin
	print,'POLAR: RA undefined at poles
	a = 0.				;set RA arbitrarily to 0
  endif else begin			;Normal cases
	a = atan(y,x) + twopi
      	a = a mod twopi
  endelse
  result=1.d0*[a,d] 
  return,result
  end
