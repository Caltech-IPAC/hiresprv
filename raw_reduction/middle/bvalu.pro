
;
;  for now assume ideriv = 0
;
;
function bvalu, x, fullbkpt, coeff

     n = n_elements(coeff)
     k = n_elements(fullbkpt) - n
     nx = n_elements(x)
     work = fltarr(nx,k)
     left = fltarr(nx,k)
     right = fltarr(nx,k)

     i = intrv(x, fullbkpt, k)

     imk = i-k+1
     for j=0,k-1 do work[*,j] = coeff[imk+j]

     for j=0,k-1 do begin
       left[*,j] = fullbkpt[i+j+1] - x
       right[*,j] = x - fullbkpt[i-j] 
     endfor
    
     for j=1,k - 1 do begin
       ilo = k-j-1
       for jj=0,k-j-1 do begin
         work[*,jj] = (work[*,jj+1] * right[*,ilo] + work[*,jj] * left[*,jj]) $
                        / (right[*,ilo] + left[*,jj])
         print,ilo
         ilo = ilo - 1
       endfor
     endfor    

      return, work[*,0]
end

