pro hirspec,prefix,spfname,outfname,thar=thar,nosky=nosky, cosmics = cosmics
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
;
;OUTPUT
;   The following file may be created by hirspec:
;	  * spfname.ord - order location coefficients, if they were determined
;         OUTFNAME is the path and filename of the output, reduced spectrum.
;         OUTFNAME.opt -- optimally extracted spectrum from the cosmic
;                         ray removal algorithm.
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

@ham.common					;get common block definition

if n_params() lt 3 then begin
  print,'syntax: hirspec,prefix,spfname,outfname[,thar[,nosky]]'
  retall
end

if ham_id ne 29 then begin
  print, 'This is the HIRES reduction package.  Go find the proper package.'
  stop
end

hamset, /silent                 ;ensure globals set
print, ''
trace, 15, 'HIRSPEC: Entering routine.'

;READ IMAGE FROM DISK 
rdfits,im,spfname,head           		;read spectrum fits file
im = double(im)

oldim = im

;rdsk, dark, 'dark'

;BIAS SUBTRACTION
if ham_bin eq 1 then begin
  nr = n_elements(im[0, *])     ;# rows
  trace, 10, 'Subtracting row bias'
  for j = 0, nr-1 do begin      ;Subtract Bias, row by row
    biaslev = median(im[21+2047+11:21+2047+11+20, j]) ; bias from 2079:2073+25
    im[*, j] = im[*, j] - biaslev
  end
end

;im = im-dark

;TRIMMING
trace, 10, 'HIRSPEC:  Trimming Columns (21:2047+21) off Keck images'

if ham_bin eq 1 then im = im[21:2047+21, *] ;for nov 94 Keck run
; This assumes standard overscan columns of 234 raw columns.
if ham_bin eq 2 then im = im[11:1023+11, *] ;binned 2x2


;
;ORDER LOCATIONS finding: Use defaults, possibly shifted.
rdsk, dorc, prefix + '.ord'     ;restore default order locs

IF (ham_dord eq 2) and (not keyword_set(thar)) then begin ; Use SHIFTED default order locations
  
  shiftorc, im, dorc, orc
  if keyword_set(orc) then begin ; true: found order locations
    trace, 5, 'HIRSPEC: found shifted order locations.'
  end else begin                ; else: no order locs found
    trace, 5, 'HIRSPEC: shiftorc failed finding (SHIFTED) order locations for'+spfname
    return
  endelse
END      
IF (ham_dord eq 1) or (keyword_set(thar)) then begin
  trace, 15, 'HIRSPEC: Reading default order locations from ' + prefix + '.ord'
  orc = dorc                    ; use default order locations
END 
IF ham_dord eq 0 then begin     ;else: find order locs
  trace, 15, 'HIRSPEC: Finding orders from image itself'
  getorc, im, dorc, orc         ; try to find order locations
  if keyword_set(orc) then begin ; true: found order locations
    trace, 15, 'HIRSPEC: Saving order locations to ' + obsfile + '.ord'
    comment = 'Order location fit coefficients.'
    wdsk, orc, obsfile + '.ord', comment, /new ;  save ORCs to disk
  end else begin                ; else: no order locs found
    trace, 15, 'HIRSPEC: Using default order locations for observation!'
    orc = dorc                  ;  give up, use defaults anyway
  endelse
END

sz = size(im)                   ;variable info block
ncol = sz[1]                    ;# columns in image
nrow = sz[2]                    ;# columns in image

IF not keyword_set(nosky) then begin                
  getsky, im, orc, sky = sky    ;determine and subtract sky
END ELSE sky = im*0.

IF not keyword_set(thar) then begin ;true: use getxwd
  
  if (ham_xwid ne 0.) then $
    xwd = ham_xwid $            ;use user-set value
  else begin 
    xwd = round(getxwd(im, orc)) ;otherwise do this "optimally" 
  endelse
  
END ELSE xwd = 10               ;default to 10 pixels


;FLAT-FIELDING

trace, 10, 'HIRSPEC: Doing Flat-Fielding'
rdsk, flt, prefix+'.sum'        ;get the previously determined flat

smflt = flt*0.                  ;intialize smoothed flat

for j = 0, nrow-1 do begin      ;row by row
  s = flt[*, j]                         
  ss = median(s, 30)            ;median smooth the rows
  zeroes = where (ss eq 0., nz) ;make sure we don't divide by 0
  if nz ne 0 then ss[zeroes] = 1.       
  smflt[*, j] = ss              ; build smoothed flat              
end

flt = flt/smflt                 ;divide my median smoothed flat to remove low frequencies

j = where(flt lt 0.1 or flt gt 10, nneg) ;don't let the flat set weird values, they're prob. cosmics
if nneg gt 0 then flt[j] = 1.              

flattenedim = im/flt            ;flat field division

;EXTRACT SPECTRUM
if not keyword_set(thar) then $
  getspec, flattenedim, orc, xwd, spec, sky = sky, cosmics = cosmics, spec = optspec, diff = replace  $
                                ;extract w/o flat or bg subtraction
else getspec, flattenedim, orc, xwd, spec ; ThAR - no cosmic removal

;Fix the blob


l = median(spec[800:949, 21])
r = median(spec[1081:1300, 21])
spec[800+150:800+280, 21] = mean([l, r]) > 0 ;Set the blob to the surrounding level

;

;
;STORE REDUCED SPECTRUM

intcon, spec, intspec         ;convert image to format rdsi reads.
  
trace, 10, 'HIRSPEC: Saving extracted spectrum to ' + outfname
wdsk, intspec, outfname, 1, /new ;write image to disk
wdsk, head, outfname, 2

return
end
