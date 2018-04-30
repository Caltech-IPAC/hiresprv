pro remove_cosmics, im, orc, xwd, sky, mask = mask, spec = spec, cosmics = replace, fwhm = fwhm, sig = sig
;+
; NAME:remove_cosmics
;
;
;
; PURPOSE: driver for removing cosmic rays from eschelle spectra.
; Designed for the Keck HIRES spectrometer.
;
;
;
; CALLING SEQUENCE: remove_cosmics,im,orc,xwd,sky,[mask=mask,spec=spec,cosmics=cosmics,fwhm=fwhm,sig=sig]
;
; INPUTS:   im:  fltarr(ncol,nrow) the spectrum to be cleaned
;           orc: fltarr(# of coefs, # of orders) the order coefficients desribing the positions of the
;             spectral orders
;           xwd: the extraction width for spectral extraction
;           sky: fltarr(ncol,nrow) image containing background scattered light
;
; OPTIONAL INPUTS: mask: intarr(ncol,nrow) elements set to zero are
;                     ignored when composing the slit function.  
;                  sig:  cosmic ray rejection threshold in units of
;                     sigma.  Note that there are sources of noise
;                     above and beyond photon noise:  the modelled
;                     slit function has some uncertainty, which is
;                     included in the noise model.  5 sigma is good here.
;                
;
; OPTIONAL OUTPUTS: spec: fltarr(ncol, # of orders) optimally
;                     extracted spectrum
;                   cosmics: fltarr(ncol,nrow) image containing cosmic
;                     rays removed
;                   fwhm: float,  FWHM of calculated slit function in pixels 
;                
;
; COMMON BLOCKS:  Uses the old ham common block in ham.common
;
; SIDE EFFECTS:  cosmic rays in im are corrected.  To supress this,
;                get cosmics as an optional output and put them back in.
;
; MODIFICATION HISTORY:  22-Jun-01 JTW: Create based on Jeff Valenti's
;                             optimal extraction code
;
;-

@ham.common

  trace, 10, 'Removing cosmic rays -- this takes a bit'
  
  dims = (size(im))(1:2)        ;dims=[ncol,nrow]
  ncol = dims[0]
  nrow = dims[1]
  nord = n_elements(orc[0, *])  ;# of orders
  spec = fltarr(ncol, nord)     ;initialize output spectrum
  ix = indgen(ncol)             ;x indices
  fwhms = fltarr(nord)          ;initialize fwhm parameter
  replace = im*0.               ;initialize output cosmic ray image
  
  print, format = '(a,$)', 'Now removing cosmics from order '
  
;ORDER BY ORDER REMOVAL OF COSMICS:
  
  for iord = 0, nord-1 do begin
    
    print, format = '(a," ",$)', strtrim(string(iord), 2) ;keep the user up to date

    ycen = poly(indgen(ncol), orc[*, iord])     ;find the orders

    ymin = (ycen - xwd/2.-2) > 0.               ;top and bottom of orders +1 to be safe
    ymax = (ycen + xwd/2.+2) < (nrow - 1)
    

    mkslitf, im, sky, ymin, ycen, ymax, yslitf, slitf, sfunc, bincen, mask = mask, fwhm = my_fwhm
;, plot=(iord eq 24)
;   mkslitf determines the slit function for a given order and returns
;   the fwhm of the function in fwhm.
;   throw the plot flag for diagnostics

    fwhms[iord] = my_fwhm          ;save the fwhm from this order

    nysf = n_elements(yslitf)      ;# of elements in the slitfunction 
    nbin = n_elements(bincen)      ;# of slitfunctions determined for this order

    bincol = -.5+findgen(ncol)/(ncol-1.)*nbin ;column numer at centers of 
                                                          ;slitf bins
    sf = interpolate(slitf, findgen(nysf), bincol, /grid) ;slit function in each col
    sfu = interpolate(sfunc, findgen(nysf), bincol, /grid) ;uncertainty in sf
    osamp = (nysf-1.)/(yslitf[nysf-1]-yslitf[0]) ;calculate oversampling (pix)

    ysfmin = min(yslitf, max = ysfmax)  


    data = fltarr(ceil(xwd+4)+1, ncol)   ;initialize data array for this order
    skyv = fltarr(ceil(xwd+4)+1, ncol)   ;... & the background scattered light
    modl = fltarr(ceil(xwd+4)+1, ncol)   ;... the modelled slit function
    munc = fltarr(ceil(xwd+4)+1, ncol)   ;... its uncertainty
    ibeg = fltarr(ncol)                  ;the bottom of the order at each column
    iend = fltarr(ncol)                  ;... & the top



    ibeg = ceil(ycen-xwd/2.-2) > 0           ;fill ibeg and iend
    iend = floor(ycen+xwd/2.+2) < (nrow - 1)

    for icol = 0, ncol-1 do begin
      data[0:iend[icol]-ibeg[icol], icol] = im[icol, ibeg[icol]:iend[icol]] 
                                ;fill up the data array column-by-column
      skyv[0:iend[icol]-ibeg[icol], icol] = sky[icol, ibeg[icol]:iend[icol]]
                                ;and the sky
      idata = findgen(iend[icol] - ibeg[icol] + 1) + ibeg[icol] - ycen[icol]
                                ;we'll need this for the next 2 lines
      modl[0:iend[icol]-ibeg[icol], icol] = interpolate(sf[*, icol], (idata-ysfmin)*osamp) 
                                ;interpolate between the slitfunction
                                ;bins in case the slitfunction changes
                                ;or drifts across the chip
      munc[0:iend[icol]-ibeg[icol], icol] = interpolate(sfu[*, icol], (idata-ysfmin)*osamp)
                                ;...and keep track of the uncertianty in
                                ;the model
    endfor


   if not keyword_set(sig) then sig = ham_cosmic_sig  ;make sure we have a threshold.


   ;find cosmic rays.
    optordv, data, modl, munc, tot, stot, sky = skyv, changes = ddata, sig = sig


                                ; This function performs the actual
                                ; optimal extraction.  It fits the
                                ; slit function to the actual data,
                                ; determines which pixels are affected
                                ; by cosmic rays, etc., and returns
                                ; any changes it makes in ddata.  It
                                ; needs to know the sky to calculate
                                ; the noise.

    ;store the extracted spectrum for this order
    spec[*, iord] = tot

    ;load cosmic rays into their original placements on the chip
    for icol = 0, ncol-1 do begin
      replace[icol, ibeg[icol]:iend[icol]] = ddata[0:iend[icol]-ibeg[icol], icol]
    endfor
    
    
  endfor


print             ;carriage return to stop order count on screen

fwhm = median(fwhms)  ;call the median the FWHM of the slit function

 im = temporary(im) - replace  ;fix cosmic rays on image

trace,10, 'Cosmics removed'

end


