PRO seeing, inpfile, SeeVal=SeeVal, silent=silent
!EXCEPT=0
!quiet=1

IF NOT keyword_set(silent) THEN silent=0

t1 = systime(1)
imarr = readfits(inpfile,exten_no=2,/SILENT)
t2 = systime(1)
IF NOT silent THEN print, "Read image in "+string(t2-t1)+" seconds."

t1 = systime(1)
rotim = rot(imarr, 0.55,/interp)
t2 = systime(1)
IF NOT silent THEN print, "Rotated image in "+string(t2-t1)+" seconds."
;tv, rotim

pixscale = 0.37

shape = size(imarr)
;print, shape
ncols = shape[1]
nrows = shape[2]

xwidth = 30
rowspace = 512
colspace = 90

fwhm = [0.]
S = [0.]
chi = [0.]

col = 90
count = 0
t1 = systime(1)
WHILE col LT ncols-xwidth DO BEGIN
   row = 256
   WHILE row LT nrows-rowspace DO BEGIN
      slice = rotim[col:col+xwidth,row]
      ;IF max(slice) LT 10000 THEN BEGIN
      ;   row += rowspace
      ;   CONTINUE
      ;ENDIF

      ;print, row, col
      x = findgen(n_elements(slice))
      x -= mean(x)
	
      yfit = gaussfit(x,slice,pars,nterms=4)

      thisfwhm = 2 * sqrt(2*alog(2))*pars[2]
      thisS = thisfwhm * pixscale
      thischi = total(((yfit-slice)/sqrt(abs(slice-pars[0])))^2)/(n_elements(slice)-n_elements(pars)-1)

      ;print, thisfwhm, thisS, thischi
      fwhm = [fwhm, thisfwhm]
      S = [S, thisS]


      ;p = plot(x, slice,'ko-')
      ;p = plot(x, yfit, 'b-',/overplot)
         
      row += rowspace
      count += 1
   ENDWHILE
   col += colspace
ENDWHILE
t2 = systime(1)
IF NOT silent THEN print, "Fit "+string(count, format="(4I)")+" gaussians in "+string(t2-t1)+" seconds."

order = sort(S)
S = S[order]
S = S[0.159*n_elements(order):0.851*n_elements(order)]

IF n_elements(S) GT 1 THEN errseeing = stdev(S)/sqrt(n_elements(S)) ELSE errseeing=0
medseeing = median(S)

SeeVal = medseeing
IF NOT SILENT THEN print, inpfile+": seeing = "+string(medseeing,format='(F5.3)') +" +/- "+string(errseeing,format='(F5.3)') +" arcseconds"

END

































































































































