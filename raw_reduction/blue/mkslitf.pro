pro mkslitf, im, back, ymin, ycen, ymax, yslitf, slitf, sfunc, bincen, plot=plot, mask = mask, fwhm_slitf = fwhm_slitf
;Determines slit function along echelle order
;Input:
; im (array(nrow,ncol)) image containing echelle spectrum
; back  (array(nrow,ncol)) image containing background, already subtracted
; ymin (vector(ncol)) row numbers along bottom of region to map
; ycen (vector(ncol)) row numbers of zero point for slit function
; ymax (vector(ncol)) row numbers along top of region to map
;Output:
; yslitf (vector(nslitf)) subpixel row offsets for slitf
; sflit (array(nslitf,nbin)) subpixel slit functions
; bincen (vector(nbin)) column of bin centers
;History:
;18-Nov-96 Valenti  Wrote.
;21-Nov-97 Valenti  Adapted phx_slitf for use in echelle reduction package
;30-Mar-98 Valenti  Don't use polynomials to fit slit function. Instead
;                    median filter, then bin, then Gaussian smooth.
;05-May-98 CMJ      Back to using polynomials to fit slit function.  Seems
;                    to work OK with 18th order on the binned, median filtered
;                    slit function.
;13-Aug-98 CMJ      Put in logic to calculate both the smoothed medianed
;                    slit function and the polynomial one and choose between
;                    them based on standard deviations, giving the fit
;                    a little extra room for messiness.  I also force 
;                    whatever method is chosen on the first time through to
;                    use throughout.  I have also increased the smoothing
;                    size for high resolution data.
;29-Nov-98 JAV      Check for rspec exactly zero and fudge it to be one,
;                    so as to avoid divide by zero and subsequent badness.
;08-Dec-98 JAV      Added an inital filtering of bad pixels in the oversampled
;                    slit function *before* binning. The rejection threshold
;                    is 3 times the mean absolute value of the difference
;                    between the oversampled (sf) and median filtered (medsf)
;                    slit functions. Indices of the good pixels are contained
;                    in "igd".
;09-Dec-98 CMJ      Added the conditional on binning the slit function back
;                    in to aviod inappropriate referencing of the variables.
;                    The result is some SF bins have no points in them, so
;                    added a later check which interpolates over these bins.
;06-Jun-99 JAV      Increased trace level of slit function type message from
;                    10 to 20 (suppressing the messages by default).
;                   Also kept track of uncertainties in the slit
;                   functon, and fit the function with a spline

@ham.common

if n_params() lt 8 then begin
  print, 'syntax: mkslitf, im, back, ymin, ycen, ymax, yslitf, slitf, bincen [,/plot, mask=mask,fwhm_slitf=fwhm_slitf]'
  retall
endif


if(not keyword_set(mask)) then mask = im*0.+1     
                                ;if no mask, make one with nothing
                                ;masked out.

;Internal program parameters.
nbin = 5                        ;number of slitf along order
nskip = 4.

;Get image size.
sz = size(im)                   ;variable info
ncol = sz[1]                    ;number of columns
nrow = sz[2]                    ;number of rows

;Find columns that contain spectrum.
rspec = fltarr(ncol)            ;init rough spctrum
imin = round(ymin) > 0          ;bottom row of order
imax = round(ymax) < (nrow-1)   ;top row of order
for i = 0, ncol-1 do begin      ;loop over columns
  rspec[i] = total(im[i, imin[i]:imax[i]]) ;mash 1 column
endfor
izero = where(rspec eq 0, nzero) ;look for identically zero
if nzero gt 0 then rspec[izero] = 1.0 ;set to value close to zero

;Calculate boundaries of distinct slitf regions.
ibound = (ncol-1) * findgen(nbin+1) / nbin ;boundaries of bins
ibeg = ceil(ibound[0:nbin-1])   ;beginning of each bin
iend = floor(ibound[1:nbin])    ;end of each bin
bincen = 0.5*(ibeg + iend)      ;center of each bin

;Initialize arrays.
osamp = 20.                     ;slitf pixels / real pixel
irow = findgen(nrow)            ;indices of all rows
ysfmin = min(ymin - ycen)       ;smallest sf offset
ysfmax = max(ymax - ycen)       ;largest sf offset
nysf = ceil(ysfmax) - floor(ysfmin) + 1	;subpixel range required
;  yslitf0 = ceil(ysfmin)			;minimum value for yslitf
yslitf0 = floor(ysfmin)         ;minimum value for yslitf
;  yslitf1 = floor(ysfmax)			;maximum value for yslitf
yslitf1 = ceil(ysfmax)          ;maximum value for yslitf
ntrunc = yslitf1 - yslitf0 + 1  ;truncated pixel range
nslitf = osamp * (ntrunc - 1) + 1 ;final # of subpixels
yslitf = yslitf0 + findgen(nslitf)/osamp ;final subpixel scale
slitf = fltarr(nslitf, nbin)    ;init final slit function
sfunc = fltarr(nslitf, nbin)    ;init final slit function uncertainty
fwhm_slitf = 0.


;Calculate slit functions within each bin.
for i = 0, nbin-1 do begin      ;loop thru sf regions
  ib = ibeg[i]                  ;left column
  ie = iend[i]                  ;right column
  nc = ie - ib + 1              ;number of columns
  
;Load slit function data into vectors.
  nsf = (nc/nskip + 1) * nysf         ;# slit func points
  sf = fltarr(nsf)-1e6          ;init storage for values
  noise = sf                    ;init storage for noise in values
  ysf = fltarr(nsf)-1e6         ;init storage for rows
  for j = 0, nc-1, nskip do begin     ;loop thru columns in region
    icen = round(ycen[ib+j])    ;row closest to peak
    k0 = floor(icen + ysfmin) > 0 ;lowest row to consider
    k1 = ceil(icen + ysfmax) < (nrow-1)	;highest row to consider
    j0 = j/nskip*nysf                 ;begining of storage area
    j1 = j0 + k1 - k0                         
    sf[j0:j1] = im[ib+j, k0:k1]/rspec[ib+j] ;compute normalized slit func
    ysf[j0:j1] = irow[k0:k1] - ycen[ib+j] ;save subpixel locations
    noise[j0:j1] = sqrt(((im[ib+j, k0:k1] > 0)+back[ib+j, k0:k1])/ham_gain)/rspec[ib+j]
                                ;compute uncertainty in normalized slit func
    masked = where(mask[ib+j, k0:k1] eq 0, nmask)
    if (nmask gt 0) then ysf[j0+masked] = -1e6 
                                ;set masked columns to special value
  endfor
;Sort slit function data by subpixel offset and remove points not
;filled with data
  igd = where(ysf ne -1e6)      ;where the data are
  isort = sort(ysf[igd])        ;determine sort indices
  ysf = ysf[igd[isort]]         ;sort subpixel locations
  sf = sf[igd[isort]]           ;sort slit function values
  noise = noise[igd[isort]]     ;sort noise
  msf = median(sf, 5)           ;smooth the slit function for the spline


;Fit a smooth curve through the data with a spline.

  invvar = sf*0.+1./(0.01)^2    ;set all uncertainties equal.  
                                ;Not correct, but close enough.
                                ;Weighting by flux favors cosmic rays 
                                ;and causes other complications
  
  splinefit = bspline_iterfit(ysf, msf, bkspace = 0.5, outmask = good, invvar = invvar,  upper = 3, lower = 3, /silent) 
  ssf = bspline_valu(yslitf, splinefit)
                                ;fit with smooth spline
  
  
;Spline onto final slit function grid.
  slitf[*, i] = ssf/total(ssf)*osamp ;save slit function
  fit = interpol(ssf, yslitf, ysf)
  sfunc[*, i] = interpol(median(abs(sf-fit), n_elements(ysf)/(max(ysf)*2)), ysf, yslitf)/0.674
                                ;0.674 is the conversion from
                                ;median(abs()) to r.m.s.
;Plot diagnostics.
  if keyword_set(plot) then begin
;    if (ycen[0] gt 230) and (ycen[0] lt 250) then begin
    plot, ysf, sf, ps = 3, /xsty
    oplot, yslitf, ssf, co = 3
    oplot, yslitf, ssf+sfunc, co = 2
    oplot, yslitf, ssf-sfunc, co = 2
    oplot, !x.crange, [0., 0.], co = 4
;      csm = where(abs(sf-fit)/noise gt sig,n)
;      for j=0,n-1 do oplot, [ysf(csm(j)),ysf(csm(j))], sf(csm(j))+[-sig,sig]*noise(csm(j)), color = 2
    junk = get_kbrd(1)
  endif

  fwhm_slitf = fwhm_slitf + fwhm(slitf[*, i])
                                ;average the fwhms from the bins
endfor

fwhm_slitf = fwhm_slitf/nbin

end

