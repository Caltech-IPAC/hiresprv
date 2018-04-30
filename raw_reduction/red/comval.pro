function comval, pa, pb, aind, bind

; PROGRAM COMVAL
;
; Finds values common to two arrays, puts them in optional 2nd and 3rd
; arguments, and returns the number of such values; 
;
; USAGE:  nmatches=comval(a,b[,acind[,bcind]])
;
; a,b = 1D arrays
; acind,bcind = 1D arrays containing indices of entries which have
; corresponding values in the other array
;
;
; EXAMPLE:
;
; a=[1,3,5,7,9,11,13,15]
; b=[2,3,5,7,11]
; nmatches=comval(a,b,acind,bcind)
; print, nmatches
;       4
; print, acind
;       1       2       3       5
; print, bcind
;       1       2       3       4



  a = pa
  b = pb
  na = n_elements(a)
  nb = n_elements(b)
  matchval = intarr(nb)
  aind = intarr(na)
  bind = intarr(nb)

  for ind = 0, nb-1 do begin
    matchind = where(a eq b[ind], nmatch)
    if (nmatch gt 0) then begin 
      bind[ind] = 1
      aind[matchind] = 1
      matchval[ind] = 1
    endif
  endfor

  matchind = where(aind eq 1, nmatch)
  if (nmatch gt 0) then aind = (indgen(na))(matchind) else aind = -1
  matchind = where(bind eq 1, nmatch)
  if (nmatch gt 0) then bind = (indgen(nb))(matchind) else bind = -1
  matchind = where(matchval eq 1, nmatch)


  return, nmatch > 0
  
end
