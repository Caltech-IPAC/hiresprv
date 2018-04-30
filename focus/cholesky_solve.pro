function cholesky_solve, a, b

    bw = (size(a))(1)
    n = (size(b))(1) - bw

    kd = bw - 1


;;; first round
   spot = lindgen(kd) + 1
   for j=0,n-1 do begin
     b[j] = b[j] / a[0,j]
     b[j+spot] = b[j+spot] - b[j] * a[spot,j]
   endfor

;;;; second round

   spot = kd - lindgen(kd) 
   for j=n-1,0,-1 do $
     b[j] = (b[j] - total(a[spot,j] * b[j+spot]))/a[0,j] 

return, -1L
end
