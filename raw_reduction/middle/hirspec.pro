pro hirspec,prefix,spfname,outfname, orc_in, totwf,thar=thar,nosky=nosky, cosmics = cosmics, xwd_out = xwd_out
;Reads in image, finds orders, divides by FLAT FIELD.
;  Extracts spectrum and background from each order, subtracts background,
;
;INPUT:
;    PREFIX (input string)   prefix of all file names (i.e., 'dm' for dm112.fits)
;        to all observations made with a particular spectrograph setting. 
;        The following files are expected to exist:
;	 * prefix.sum - Summed flat field (from addwf.pro)
;	 * prefix.ord - default order location coefficients (from hamdord)
;    SPFNAME  (input string) filename of given observation.
;    OUTFNAME (input string) complete path and filename of wdsk'd output.
;    THAR (flag) Throw flag to use default extraction width of 10
;        pixels, default orders locations, no cosmic ray removal, and
;        no integerization for saving (to save dynamic range).  Use
;        for iodines and other non-stellar images
;    NOSKY (flag) Throw flag to supress sky subtraction.  Use for ThAr
;        images or to speed things up if sky subtraction (which is
;        actually a scattered light subtraction) should not be
;        performed.  Do not combine this flag with cosmics, which
;        requires a good bg subtraction
;    COSMICS (flag) Throw this flag to initiate cosmic ray removal.
;
;OUTPUT
;   The following file may be created by hirspec:
;	  * spfname.ord - order location coefficients, if they were determined
;         OUTFNAME is the path and filename of the output, reduced spectrum.
;         OUTFNAME.opt -- optimally extracted spectrum from the cosmic
;                         ray removal algorithm.
;	 XWD_OUT: send out the xwd for analysis
;
;23-Oct-89 JAV	Create.
;18-Apr-92 JAV	Updated global variable list/interpretations. Reenabled maskim
;		 when thar=1.
;29-Apr-92 JAV	Now clip baseline column of FITS images.
;05-Mar-95 GWM  New Flat-field and SKY subtraction for HIRES data
;22-Feb-01 JTW  Allowed xwd of 0 to initiate a call to getxwd
;               ("optimal" extraction width)
;12-Jun-01 JTW  Modified for cosmic ray removal.  Added cosmics flag.
;
;06-Oct-02 JTW  Added treatment for the blob
;06-Nov-09 GM, HI, passed orc and totwf as keywords, no call to any saved files.
;25-Nov-09, HI, added sky subtraction for C2, B3 deckers, calls remove_sky.pro
;3 -Dec-09  HI, removed call to getsky.pro for C2 and B3 deckers.
; 				upper limit to xwd is now 14 pix.
;20-Apr-11 HTI, fits files for all chips are now in outdir_fits
;15-May 12,HTI changed lt 0.1 to 0.02 to improve flat fielding of nearly dead pixels.
;02-Aug-13 HTI, changed keyword orc to orc_in, and dorc=orc to dorc = orc_in
;02-Oct-13 HTI/KIC, Added call to deblaze.pro, which produces deblazed .fits files.
;				Added delbaze.pro, contf.pro to precompile
;15-MAR-18 HTI  No more relative file paths, outputs controlled by environment variable.s

@ham.common					;get common block definition

if n_params() lt 3 then begin
  print,'syntax: hirspec,prefix,spfname,outfname[,thar[,nosky]]'
  retall
end

chipno=2
ham_id=29 ; kludge for quick_reduce.pro
if ham_id ne 29 then begin
  print, 'This is the HIRES reduction package.  Go find the proper package.'
  stop
end

hamset, /silent                 ;ensure globals set
print, ''
trace, 15, 'HIRSPEC: Entering routine.'

; Use an environmnet variable to control directory output.
outdir = getenv("RAW_ALL_OUT")
outdir_fits = getenv("RAW_ALL_OUT_FITS") 
outdir_fits_db = getenv("RAW_ALL_OUT_FITS_DB")

print,"Output directories:"
print,outdir
print,outdir_fits
print,outdir_fits_db
;READ IMAGE FROM DISK 
hiraw,im,spfname,chip=chipno  ;hires mosaic
dum =  mrdfits(spfname, 0, head)  ;hires mosaic, header
;im = double(im)
target = sxpar(head,'targname'); added hti, nov2009
exptime = sxpar(head,'elaptime');added hti, nov2009
decker  = strcompress(sxpar(head,'deckname'),/remove_all) ; added hti, Nov 2009
; check binning, if not 3x1, then return
binning = strcompress(sxpar(head,'binning'),/remove_all)
if binning ne '3,1' then begin
  print,'HIRESPEC: Binning is not 3x1.'
  print,    "binning for ",spfname," is:",binning
  print,    "Returning..."
  return
endif

;BIAS SUBTRACTION
  trace, 10, 'Subtracting bias: ' + string(median(im[*,5:13]))
  biaslev = median(im[*,5:13])  ;hires mosaic
    im = im - biaslev
im = nonlinear(im)

;ORDER LOCATIONS finding: Use defaults, possibly shifted.

dorc = orc_in ; HTI, aug 3 2013   ; start with original orc for each star
IF (ham_dord eq 2) and (not keyword_set(thar)) then begin ; Use SHIFTED default order locations
  shiftorc, im, dorc, orc ;dorc is input, orc is shift output orders.
; SHIFTORC must be called for routine to function properly!!!!
  	
  if keyword_set(orc) then begin ; true: found order locations
    trace, 5, 'HIRSPEC: found shifted order locations.'
  end else begin                ; else: no order locs found
    trace, 5, 'HIRSPEC: shiftorc failed finding (SHIFTED) order locations for'+spfname
    return
  endelse
END      
IF (ham_dord eq 1) or (keyword_set(thar)) then begin
   trace, 15, 'HIRSPEC: Using default order locations that are passed as keywords.'; gm, hi, 6 nov 2009, use keywords, not save files for orc.
;  trace, 15, 'HIRSPEC: Reading default order locations from ' + prefix + '.ord'
  orc = dorc                    ; use default order locations
END 
IF ham_dord eq 0 then begin     ;else: find order locs
  trace, 15, 'HIRSPEC: Finding orders from image itself'
  getorc, im, dorc, orc         ; try to find order locations
;  if keyword_set(orc) then begin ; true: found order locations
;    trace, 15, 'HIRSPEC: Saving order locations to ' + obsfile + '.ord'   ;commented 
;    comment = 'Order location fit coefficients.'
;    wdsk, orc, obsfile + '.ord', comment, /new ;  save ORCs to disk
;  end else begin                ; else: no order locs found
;    trace, 15, 'HIRSPEC: Using default order locations for observation!'
;    orc = dorc                  ;  give up, use defaults anyway
;  endelse
END

sz = size(im)                   ;variable info block
ncol = sz[1]                    ;# columns in image
nrow = sz[2]                    ;# columns in image

;Sky from getsky is actually scattered light.
;IF not keyword_set(nosky) then begin  ; HTI 3 dec 2009   ;           
IF not keyword_set(nosky) and (decker ne 'C2' and decker ne 'B3') then begin                
  getsky, im, orc, sky = sky    ;determine and subtract sky
END ELSE sky = im*0.

IF not keyword_set(thar) then begin ;true: use getxwd
  
  if (ham_xwid ne 0.) then begin ; begin
  	xwd = ham_xwid             ;use user-set value
	print,'WARNING: HAM_XWD BEING USED, BIZARRE!!!!!!!!'
  end else begin 
;    xwd = round(getxwd(im, orc)) ;otherwise do this "optimally" 
    xwd = round(getxwd(im, orc,decker)) ;this is done except for thar/i2.
  endelse
  
END ELSE xwd = 12.               ;default to 10 pixels for thar/i2
xwd_out = xwd ; for anlaysis in program quick_reduce
;if xwd lt 5 or xwd gt 20 then xwd = 10
;if xwd gt 14 then xwd = 10 ; lower limit is set in getxwd to 8 pix, hti 12/2009
;if xwd gt 14 then xwd = 14 ; lower limit is set in getxwd to 8 pix, hti 07/2011

;SKY SUBTRACTION CODE FOR 14" decker (C2 or B3) ONLY
if (decker eq 'C2' or decker eq 'B3') and ~keyword_set(nosky) then begin
	remove_sky,im, orc, xwd,tot_sky,head
	;HTI 8/2012, now head is passed into remove_sky
    save,tot_sky,file=outdir+outfname+'sky'
endif 

;For troubleshooting, Force extractio width to specific values.
;xwd = 3  ;change after call to remove_sky so that no sky removal is done.

;FLAT-FIELDING
trace, 10, 'HIRSPEC: Doing Flat-Fielding'
flt = totwf 
smflt = flt*0.                  ;intialize smoothed flat

for j = 0, nrow-1 do begin      ;row by row
  s = flt[*, j]                         
  ss = median(s, 30)            ;median smooth the rows, original
  zeroes = where (ss eq 0., nz) ;make sure we don't divide by 0
  if nz ne 0 then ss[zeroes] = 1.       
  smflt[*, j] = ss              ; build smoothed flat              
end

flt = flt/smflt                 ;divide my median smoothed flat to remove low frequencies

j = where(flt lt 0.02 or flt gt 10, nneg) ;don't let the flat set weird values,
if nneg gt 0 then flt[j] = 1. 

flattenedim = im/flt            ;flat field division

;EXTRACT SPECTRUM
if not keyword_set(thar) then $
  getspec, flattenedim, orc, xwd, spec, sky = sky, cosmics = cosmics, spec = optspec, diff = replace  $
                                ;extract w/o flat or bg subtraction
else getspec, flattenedim, orc, xwd, spec ; ThAR - no cosmic removal

;Fix the blob
;hires mosaic : get rid of blob
;l = median(spec[800:949, 21])
;r = median(spec[1081:1300, 21])
;spec[800+150:800+280, 21] = mean([l, r]) > 0 ;Set the blob to the surrounding level

;------------------------------------------
;Detect obvious cosmic rays in spec
; and replace with median of neighbors, (Except for short exposures)
;if exptime gt 200 and ~keyword_set(thar) then begin
;
;	;location of night sky lines.
;	sky_ord = [ 7,    10,   11, 11,  14,   15,   14  ]
;	sky_pix = [ 2233, 3800, 35, 251, 3683, 1864, 2076 ]
;	nbad = n_elements(sky_ord)	;median of surrounding pixels
;	sp_old = spec
;	for j=0, nbad-1 do begin
;
;		ord = sky_ord[j]
;		pix = sky_pix[j]
;		clip = spec[pix-3:pix+3,ord]
;		mx = max(clip, indm)
;		pix = indm + pix - 3	; find exact peak of line.
;;		plot,spec[pix-20:pix+20,ord ]
;		spec(pix-3:pix+3, ord) = $  ;replace night sky lines.
;			(median(spec[pix-10:pix-4,ord]) + median(spec[pix+4:pix+10,ord]))/2.
;;		oplot,spec[pix-20:pix+20,ord ],co=90
;	endfor
;
;nord = n_elements(spec(0,*))
;for j=0,nord-1 do begin
;;	sp_old =spec(*,j)           ; keep for comparison;
;	sp = spec(*,j)              ;each order
;	med3sp = median(sp,3)        ;3-pixel smoothing
;	med5sp = median(sp,5)        ;5-pixel smoothing
;	med17sp = median(sp,17)       ;17-pixel smoothing for night sky lines
;	smoothsp = median(sp,50)    ;gross smoothing
;
;	ibad3 = where(sp-med3sp gt 0.15*smoothsp,ncosmic) ;find cosmics 
;	if ncosmic ge 1 then sp(ibad3) = med3sp(ibad3)      ;replace
;
;	ibad5 = where(sp-med5sp gt 0.2*smoothsp,ncosmic) ;find cosmics
;	if ncosmic ge 1 then sp(ibad5) = med5sp(ibad5)      ;replace
;
;	ibad17 = where(sp-med17sp gt 0.5*smoothsp,ncosmic) ;find cosmics
;	if ncosmic ge 1 then sp(ibad17) = med17sp(ibad17)      ;replace
;
;	spec(*,j) = sp     ;replace jth order in spec with fixed version
;
;;	print,'ibad9:', ibad9
;;	print,'ibad_sk: ',ibad_sk
;;	plot,sp_old[10:4000,j ]
;;	oplot,spec[10:4000,j ],co=90
;
;;	oplot,smoothsp
;;	oplot,med9sp, co = 70
;
;	print,'Important pixels fixed:' ,$
;			n_elements(where(sp[0:4020]-sp_old[0:4020] ne 0))
;stop
;endfor
;
;endif
;--------------------------------------

;STORE REDUCED SPECTRUM

;Strip off last 50 columns that are shadowed in camera.
spec = spec(0:4020,*)  ;strip last 50 from 4096

intcon, spec, intspec         ;convert image to format rdsi reads.

trace, 10, 'HIRSPEC: Saving extracted spectrum to ' + outdir + outfname
wdsk, intspec, outdir + outfname, 1, /new ;write image to disk
wdsk, head, outdir + outfname, 2
spawn,"chmod g+w "+ outdir + outfname
trace, 10, 'Now saved with wdsk to:'+outdir+outfname

;Write to disk as a fits file
fitsfile = outdir_fits + outfname+'.fits'
sxaddpar,head,'bzero',0
sxaddpar,head,'bscale',1
writefits,fitsfile,intspec,head
spawn,"chmod g+w "+ fitsfile
trace,10,'%HIRSPEC: Saving extracted file with writefits'

; Save the .fits file with gain included, and blaze function removed.
print,'fitsfile=',fitsfile
; deblaze.pro requires fits name with no directory information.
pos1 = strpos(fitsfile,'/',/reverse_search)
fitsfile_db = strmid(fitsfile,pos1+1,15)
deblaze,file=fitsfile_db
print,'fitsfile_db=',fitsfile_db
return
end
