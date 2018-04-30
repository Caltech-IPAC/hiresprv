function fwhm, dist, x = x
  highs = where(dist ge max(dist)/2., n)

  if (not keyword_set(x)) then x = indgen(n_elements(dist))

  if (n gt 0) then  return, x[highs[n_elements(highs)-1]]-x[highs[0]] else return, 0

end

  
