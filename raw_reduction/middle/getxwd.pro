function getxwd,im,orc,decker
;Determines the fraction of each order to be mashed during spectral extraction.
; im (input array (# columns , # rows)) image to use in determining spectral
;   extraction width.
; orc (input array (# coeffs , # orders)) coefficients of polynomials 
;   describing order locations.
; xwd (output scalar) fractional extraction width, i.e. percent of each order
;   to be mashed during spectral extraction.
;Calls HAMTRACE
;03-Dec-89 JAV	Create.
;22-Feb-01 JTW  Modified for GM's HIRES extraction stuff: made into a
;                 function, changed how xwd is calculated.
;05Nov-2009 GWM, HTI reset "sky", and overhauled how xwd is found.
;06Dec-2009 HTi, added decker keyword, and C2 section to subtract sky/scattered
				 ;light 
;22Jul-2014 HTI: When C2/B3 is used, extraction width is limited to 14 pixels.
;				 and sky subtraction always occurs, no matter the seeing.

if n_params() lt 2 then begin
  print,'syntax: xwd = getxwd,im,orc'
  retall
end

  trace,25,'GETXWD: Entering routine.'

;Easily changed program parameters.
;  soff = 10					;offset to edge of swath (number of mashed pix)
  soff = 25				 	;offset to edge of swath gm hi 2009 nov 05
  pkfrac = 0.1					;allowable fraction of peak
  offset = -200                                   ;offset from center of image
                                                ;to avoid ink spot

;Define useful quantities.
  ncol = n_elements(im[*,0])			;# columns in image
  nrow = n_elements(im[0,*])			;# rows in image
  ndeg = n_elements(orc[*,0])-1			;degree of poly fit to orders
  nord = n_elements(orc[0,*])			;# orders in orc

;Calculate from orc the location of order peaks in center of image.

  pk = orc[ndeg,*]				;init vector of peak locations
  for i=ndeg-1,0,-1 do begin			;loop down thru coefficients
    pk = orc[i,*] + pk * (ncol/2+offset)	;add all terms of polynomial
  endfor
  pk = pk+0.5				;round peaks to nearest pixel
  if (pk[0] eq pk[1]) then begin
    message,/info,'The "strange problem" has occured - notify Jeff Valenti.'
    excise,pk,0		;fix strange problem
  endif

;Extract swath of columns from center of image. 
  swa = fltarr(nrow)  			        ;sum colums in central swath
  for i = 0,nrow-1 do begin
;change from total to median  gwm hti 2009 nov 5
;    swa[i]=total(im[ncol/2-soff+offset:ncol/2+soff+offset,i])
    swa[i]=median(im[ncol/2-soff+offset:ncol/2+soff+offset,i])
  endfor

;Loop through orders, determining extraction width for each. The 0.5 added to
;  the number of pixels kept (KEEP) corrects for truncation error.
  vxwd = fltarr(nord-1)				;extraction widths at i+0.5
;  for i=20,nord-2 do begin			;loop thru orders
  for i=0,nord-2 do begin			;loop thru orders
    if i gt 0 then range = (pk[i]-pk[i-1])/2.+1 else range = (pk[i+1]-pk[i])/2.+1
;    if range gt 7./0.38 then range = 7./0.38 ; max range is for a 14 arcsec long slit 2009 nov 5

;###hti added 12/2009 hti
	if decker eq 'C2' or decker eq 'B3' then begin ;hti
 	;sky_len is distance to useable edge of sky from peak. only good 4 mid chip
	  sky_len = [12,13,14,14,14,14,14,14,14,14,14,14,14,14,14,14] ;C2/B3 
	  if range gt sky_len[i] then range = sky_len[i]+1 
	endif else begin ;other than C2/B3
		sky_len = fltarr(nord)+14.   ;max range is (3.5/0.38)/2 +1
		if range gt sky_len[i] then range = sky_len[i]+1 	
	endelse
;###
		
    xmin = pk[i]-range                          ;low end in swa
    xmax = pk[i]+range                          ;high end in swa
    prof = swa[xmin:xmax]                       ;extract peak profile
    nprof = fix(xmax)-fix(xmin)+1               ;number of elements in profile
    growth = fltarr(nprof)                      ;curve of growth array
 
;$$$ new section to subtract any scattered light missed by getsky.pro.
;	For C2/B3, this does what getsky would do if it were used if called.
;   This doesn't remove sky from im, only used for determing xwd.

    sky_use = sky_len - 6  ; move six pixels away from center

	mid = max(prof, imid)
	;imid should be the peak position, but if a cosmic is higher, it crashes.
	if imid gt 20 or imid lt 10 then imid =15 ;prevent crashes
	low = imid - sky_len[i]   
	high = imid + sky_len[i] 
	hmax = n_elements(prof)
	lmin = 0
	if high ge hmax then high = hmax-1 ;sets upper limit of high
	if low lt lmin then low = lmin
 	npix = fix (high -low ) +1 
; stop
;	Define regions above and below order with scattered light/ sky.
;print,'i ',i,' low:',low,' high',high, ' imid',imid
	sec1 = prof[low:low+sky_use[i]]
	sec2 = prof[high-sky_use[i]:high]

	sky_val =  ( median(sec1) + median(sec2) ) /2.; sky value to be subtracted 
;	print,'sky value = ',sky_val
	prof = prof - sky_val ; subtract it off.

;	plot,prof , ps = 10  ; show what is subtracted off
;	oplot,intarr(100), co =99  ; zero line
;	oplot, intarr(100)+sky_val, co = 150 ; sky vlaue to subtract.
;  stop 
;$$$  end new section 
 
 
    ;integrate flux between goal posts that successively spread apart by j to fill growth
    for j = 0, nprof-1 do growth[j] = total(prof((0 > range-j/2.):((range+j/2.) < (nprof-1))))

;  !p.multi=[0,1,2]
;  plot, swa(xmin:xmax)
;  oldgrowth=growth

;    Replace next four lines for sky with lowest value in prof Nov 5, 2009
;    sky = indgen(nprof)                         ;num of pixels in COG indices
;    skyregion = growth[nprof-5:nprof-1]         ;region assumed to be only sky
;    skyval = (poly_fit(indgen(5), skyregion, 1))(1) ;baseline from sky
;    growth = growth-sky*skyval                      ;COG:  star only

;  New sky, that handles any length slit, notably B5 or C2:  Nov 5, 2009
   index = sort(prof)
   sky = prof(index(5))  ;choose the 5th lowest point as "sky" level
   growth = growth - sky   

;  vxwd[i] = (where(growth gt 0.99*max(growth)))(0)+1
;   Next 3 lines replace the previous line. gwm 2004dec
;   Next 3 lines replace the previous line. gwm & hti 2009 Nov 5
;    wd95 = (where(growth gt 0.95*max(growth)) )(0) + 1
;    wd97 = (where(growth gt 0.97*max(growth)) )(0) + 1
;    vxwd[i] = wd97 + (wd97 - wd95) ;extrapolate to 99% level

;Do a spline smoothing; gwm hti: 2009 nov 5
x=indgen(nprof)
y=growth
xfine=indgen(nprof*10)/10.
yfine = spline(x,y,xfine)
;plot,xfine,yfine

;    wd68 = (where(growth gt 0.68*max(growth)) )(0) + 1
;    wd90 = (where(growth gt 0.90*max(growth)) )(0) + 1
    wd68 = (where(yfine gt 0.68*max(yfine)) )(0) + 1
    wd90 = (where(yfine gt 0.90*max(yfine)) )(0) + 1
    wd68 = wd68/10.
    wd90 = wd90/10.
    vxwd[i] = wd90 + (wd90 - wd68) ;extrapolate to 100% level

;plot,prof
;wset,0
;plot,growth, ps=10, linestyle=2
;oplot,[wd68,wd68],[0,70000],linesty=2
;oplot,[wd90,wd90],[0,70000],linesty=2
;oplot,[vxwd[i],vxwd[i]],[0,70000],linesty=2
;wset,2 & plot,prof,ps=10
;wset,0
;stop

;  center=(xmax-xmin)/2.
;  left=center-vxwd(i)/2.
;  right=center+vxwd(i)/2.
;  oplot, [left,left], [0,1000000]
;  oplot, [right,right], [0,1000000]
;  plot, oldgrowth, linestyle=2
;  oplot, growth, linestyle=0

;  print, i,vxwd(i)
;  oplot, indgen(n_elements(growth)), replicate(0.99*max(growth),n_elements(growth)), linestyle=3
;  junk=get_kbrd(1)
;stop
;print,'vxwd = ', vxwd[i]
  endfor

  good = where (vxwd gt 0, nvxwd)
  if (nvxwd lt 0) then begin
    trace, 25, 'Cannot determine extraction width, setting to 14 arbitrarily'
    return, 14
  endif
  sig = stdev(vxwd[good])		;standard deviation
  xwd = median(vxwd[good])   ;This is the full width out to 99th percentile of spatial profile

  xwd = fix(xwd+1.) + 1  ;round up and add 1. for safety
  if xwd lt 6 then xwd = 6 	;for safety sake, equals 6*0.38 = 2.3 arcseconds, gm and hi 5 nov 2009

  if decker ne 'C2' and decker ne 'B3' then begin
    if xwd gt 14 then xwd = 14   ; B1/ B5 can never be greater than this
    							 ;  (5.32"*0.38as/pix=14 pix)
  endif else begin
;      if xwd gt 20 then xwd = 14; This will catch outlyers. of c2,b3
		oldxwd = xwd
      if xwd gt 14 then begin 
      	xwd = 14; HTI TEST for large XWD
	  	print,'% GETXWD: Maximum extraction reached. XWD reduced from: ',oldxwd,' to 14 pixels'
	  endif
	endelse
   
   
  trace,5,'GETXWD: Extraction width (xwid) = ' $
    + strtrim(string(xwd,form='(f10.3)'),2)
  trace,5,'GETXWD: Sigma = ' $
    + strtrim(string(sig,form='(f10.3)'),2)
  if(sig gt 3) then trace, 5, 'GETXWD: Poor xwd determined:  orders not determined well?'
;STOP
;  trace,25,'GETXWD: Extraction width determined - returning to caller.'
  trace,25,'GETXWD: Extraction width determined - returning to caller with xwd ='+string(xwd)  ; HTI added output xwd 3 aug 2013
  return, xwd
end