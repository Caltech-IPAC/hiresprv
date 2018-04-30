
pro cafraw_test

; Read in logsheet
readcol,'~/logsheets/j20.logsheet3',num,type,iod,time,exp,cof,caf,fwhm $
 ,format='(i,a,a,a,i,a,a,a)'

; Set up CAFRAW & FWHM vectors.
cafraw = strarr(n_elements(caf))
focus = strarr(n_elements(caf))
for i=0,n_elements(cafraw)-1 do begin
  cres=strsplit(caf[i],'=',/extract)
  fres=strsplit(fwhm[i],'=',/extract)
  cn = n_elements(cres)
  fn = n_elements(fres)
  cafraw[i] = cres[cn-1]
  focus[i] = fres[fn-1]
endfor

; Remove bad files.
good = where(strpos(focus,'?') eq -1)
if (good[0] ne -1) then begin 
  cafraw = cafraw[good]
  focus = focus[good]
endif

; Make our strings into numbers.
cafraw = float(cafraw)
focus = float(focus)
  
; Fit parabola.
A = poly_fit(cafraw,focus,2)
x = findgen(1001)*(ceil(max(cafraw)/1000.)-floor(min(cafraw)/1000.)) + $
  floor(min(cafraw))
y = A[0] + A[1]*x + A[2]*x^2.

; Calculate parabola center.
middle = -A[1]/(2*A[2])

; Plot results.
plot,cafraw,focus,psym=4,xtit='cafraw',ytit='focus',/ynozero $
  ,tit='Parabola midpoint at cafraw = '+strtrim(string(middle),2)
oplot,x,y
plots,middle*[1,1],!y.crange

end