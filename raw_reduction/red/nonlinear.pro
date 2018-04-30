function nonlinear, inx, chip = chip
;Warning:  This is a swapped version: 11 Sept 2006, JTW,GWM
                                ;given the counts reported by chip#2
                                ;on hires, returns the counts that
                                ;would be reported if the chip were
                                ;linear.  Bias and dark should be
                                ;subtracted before implementing this
                                ;function.  

  a = [  -83.475357,    15.299625,   -0.63372780,     0.012301111]

  r = double(inx)
  g = where(r gt 500, ng) ;function is linear near 0.  Warnings / bad things happen for small and negative inputs 


  if ng gt 0 then begin
    x = r[g]/1d3                ;function works on kilocounts

    e = exp(a[0]/x)
    p = poly(x, a[1:*])

    r[g] = r[g]+(e*p)*1d3   ;add in nonlinearity correction

  endif

  return, r   ;return counts
  
end
