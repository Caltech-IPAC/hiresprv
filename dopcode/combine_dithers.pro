pro combine_dithers, run, obsbeg, obsend, iord, ibeg, iend $
                   , x, y, object=object, ps=ps
;Use undither.pro to produce one combined spectrum of a template star from
; several dithered observations of the template star. The combined spectrum
; is still convolved with the mean instrumental profile and a one-pixel wide
; boxcar function. Deconvolve the combined spectrum to remove the mean
; instrumental profile and the one-pixel wide boxcar function, yielding the
; intrinsic spectrum of the template star.
;
;Input Parameters:
; run (string) observing run prefix , used to construct
;  directory name and rootname of extracted spectrum file.
; obsbeg (integer) number of first dithered observation, used to construct
;  extension of extracted spectrum file.
; obsend (integer) number of last dithered observation, used to construct
;  extension of extracted spectrum file.
; iord (integer) relative order number (starting with 0) to analyze.
; ibeg (integer) first pixel to analyze in the requested order
; iend (integer) last pixel to analyze in the requested order
;
;Optional Input Parameters:
; object= (string) object name, used to label plot
; /ps (switch) sends plot to a postscript file, rather than the screen
;
;Optional Output Parameters:
; x (vector[nx]) fractional pixel scale of smoothed and oversampled spectrum
; y (vector[nx]) smoothed and oversampled spectrum of template star
;
;History:
; 2007 Jul 16 Valenti  Initial coding.
; 2007 Jul 24 Valenti  Made run, obsbeg, obsend, ord, ibeg, iend, and object
;                       input arguments. Changed output postscript filename.
;                       Added a color to handle 9 dithers.

;Syntax.
  if n_params() lt 6 then begin
    print, 'syntax: combine_dithers, run,obsbeg,obsend, iord,ibeg,iend' $
         + ' [,x,y ,object=,/ps]'
    print, "  e.g.: combine_dithers, 'rj40',111,119, 15,2350,2475" $ ; rj used as example
         + ", obj='rj40 L+I!d2!n',/ps" ; rj used as example
    return
  endif

;Internal parameters.
  nfit = 10			;number of subpixel shifts in output spectrum

;Default values of optional parameters.
  if n_elements(object) eq 0 then object = ''

;List of files containing observed spectra (in rdsk format).
  nobs = obsend - obsbeg + 1				;number of observations
  files = run + '.' $
        + strtrim(obsbeg+indgen(nobs), 2)		;spectrum files

;Loop through files, reading each spectrum from disk.
  for iobs=0, nobs-1 do begin
    file = files[iobs]
    rdsi, ech, file

;If this is the first time through the loop, initialize the data cube.
    if iobs eq 0 then begin
      vinfo = size(ech)
      npix = vinfo[1]
      nord = vinfo[2]
      echs = fltarr(npix, nord, nobs)
    endif

;Save current spectrum in data cube.
    echs[*,*,iobs] = ech
  endfor

;Extract segment of observed spectrum to fit.
;Calculate Poisson uncertainties in each observed pixel.
;Generate an unaligned pixel scale for each spectrum.
  nx = iend - ibeg + 1
  xobs = fltarr(nx, nobs)				;init pixel scale
  yobs = reform(echs[ibeg:iend,iord,*])			;observed spectra
  uobs = fltarr(nx, nobs)				;init uncertainties
  for iobs=0, nobs-1 do begin				;loop thru obs
    norm = mean(yobs[*,iobs])			;renormalization
    xobs[*,iobs] = ibeg + findgen(nx)			;generate pixel scale
    uobs[*,iobs] = sqrt(yobs[*,iobs]) / norm		;calculate uncertainty
    yobs[*,iobs] = yobs[*,iobs] / norm			;normalize segment
  endfor

;Determine the mean spectrum, which will be used a cross-correlation template.
  ymean = total(yobs, 2) / nobs

;Use cross-correlation to determine relative shift of each spectrum.
  shifts = fltarr(nobs)					;init relative shifts
  for iobs=0, nobs-1 do begin				;loop thru obs
    xcorl, ymean, yobs[*,iobs], 2.0, shift		;cross-correlate
    shifts[iobs] = shift				;save relative shift
    xobs[*,iobs] = xobs[*,iobs] + shifts[iobs]		;shift pixel scale
  endfor

;Sort the observations into ascending shift order.
  isort = sort(shifts)
  files = files[isort]
  ech = ech[*,*,isort]
  xobs = xobs[*,isort]
  yobs = yobs[*,isort]
  uobs = uobs[*,isort]
  shifts = shifts[isort]

;Construct observed pixel width (in pixels) needed for undither algorithm.
  dxobs = replicate(1.0, nx, nobs)			;obs pixel widths

;Oversampled and pixel scale for fitted spectrum.
;Fitted pixels are still 1 pixel wide, regardless of the specified shift!
  shfit = (findgen(nfit) - 0.5 * (nfit - 1)) / nfit	;fitted pixel shifts
  xfit = fltarr(nx, nfit)				;pixel scale for fit
  for ifit=0, nfit-1 do begin				;loop thru shifts
    xfit[*,ifit] = ibeg + findgen(nx) + shfit[ifit]	;generate pixel scale
  endfor
  dxfit = replicate(1.0, nx, nfit)			;fitted pixel widths

;Calculate fitted spectrum at each pixel shift, using two different algorithms:
;
; Method 0: Split observed pixels at output pixel boundaries, apportioning
;   the counts and the variance according to the fraction of the observed
;   pixel that overlaps the output pixel.
;
; Method 3: Assume the intrinsic spectrum is a histogram and use linear
;   least squares to solve for the optimal height of each pixel in the
;   histogram.
;
;Average the spectra obtained from the two methods, because numerical
; experiments show this works well.
;
  yfit = fltarr(nx, nfit)				;fitted spectra
  for ifit=0, nfit-1 do begin				;loop thru shifts
    undither, xobs, dxobs, yobs, uobs $			;get first estimate of
            , xfit[*,ifit], dxfit[*,ifit] $		; intrinsic spectrum
            , yfit0, uyfit0, nyfit0, method=0		; (method 0)
    undither, xobs, dxobs, yobs, uobs $			;least squares solution
            , xfit[*,ifit], dxfit[*,ifit] $		; assuming intrinsic
            , yfit3, uyfit3, nyfit3, method=3		; spectrum is histogram
    yfit[*,ifit] = 0.5 * (yfit0 + yfit3)		;
  endfor

;Sort the fitted spectra with different shifts into ascending order for plots.
  isort = sort(xfit)
  x = xfit[isort]
  y = yfit[isort]

;Set plot characteristics, depending on whether output is the screen or a file.
  if keyword_set(ps) then begin
    set_plot, 'ps', /interpolate
    file = run $
         + '_' + strtrim(obsbeg, 2) $
         + '_' + strtrim(obsend, 2) $
         + '_' + strtrim(iord, 2) $
         + '_' + strtrim(ibeg, 2) $
         + '_' + strtrim(ibeg, 2) $
         + '.ps'
    print, 'writing ' + file
    device, file=file, /landscape $
          , /color, bits_per_pixel=8, /isolatin
;           red  ora  tan  yel  gre  aqu  blu  pur  vio  bla  whi
    tvlct, [255, 255, 255, 255,  51,  51,   0, 153, 255,   0, 255] $
         , [  0, 153, 204, 255, 255, 255,  51, 102,   0,   0, 255] $
         , [  0,   0, 153,   0,   0, 255, 255, 153, 255,   0, 255]
    clist = indgen(nobs)
    fore = 9
    back = 10
    thick = 3
    font = 0
  endif else begin
    clist = [ 255, 39423, 10079487, 65535, 65331, 16777011 $
            , 16737792, 16738047, 10027161]
    fore = !p.color
    back = !p.background
    thick = 1
    font = -1
  endelse
  charsize = 1.8

;Draw the plot window.
  yr = minmax(yobs)
  plot, xobs[*,0], yobs[*,0], /nodata $
      , /xst, yr=yr, ysty=3 $
      , xtit='Pixel Number' $
      , ytit='Normalized Counts' $
      , xmarg=[7,0.8], ymarg=[3.5,1.5], charsize=charsize $
      , xthick=2*thick, ythick=2*thick $
      , color=fore, background=back, font=font

;Draw the legend.
  xyouts, ibeg+0.05*(iend-ibeg), yr[0]+0.04*(yr[1]-yr[0]) $
        , 'Order ' + strtrim(iord, 2), size=charsize $
        , font=font, color=fore
  xyouts, ibeg+0.95*(iend-ibeg), yr[0]+0.93*(yr[1]-yr[0]) $
        , object, align=1, size=charsize $
        , font=font, color=fore

;List the shifts above the plot window.
  for iobs=0, nobs-1 do begin
    xyouts, ibeg+(iend-ibeg)*(0.5+iobs)/nobs, yr[1]+0.035*(yr[1]-yr[0]) $
          , align=0.5, color=clist[iobs], size=charsize, font=font $
          , strtrim(string(shifts[iobs], form='(f9.2)'), 2)
  endfor

;Draw the observed spectrum points with measured shifts applied.
  for iobs=0, nobs-1 do begin
    oplot, xobs[*,iobs], yobs[*,iobs] $
         , psym=4, symsiz=0.6, thick=thick, color=clist[iobs]
    oplot, xobs[*,iobs], yobs[*,iobs], psym=3, color=clist[iobs]
  endfor

;Draw the fitted spectrum.
  oplot, x, y, color=fore, thick=thick

;Close the output file, if plotting to file.
  if keyword_set(ps) then begin
    device, /close
    set_plot, 'x'
  endif

end
