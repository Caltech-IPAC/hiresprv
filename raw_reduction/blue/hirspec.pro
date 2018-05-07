pro hirspec,prefix,spfname,outfname,orc, totwf, thar=thar,nosky=nosky, cosmics = cosmics,xwd_out=xwd_out
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
;06-Nov-09 GM, HI, passed orc and totwf as keywords, no call to any saved files.
;15-May 12,HTI changed lt 0.1 to 0.02 to improve flat fielding of nearly dead pixels.
;02-Oct-13 HTI/KIC, Added call to deblaze.pro, which produces deblazed .fits files.
;				Added delbaze.pro, contf.pro to precompile
; 17-03-18 HTI Output directories now defined by environment variables.

@ham.common					;get common block definition

if n_params() lt 3 then begin
  print,'syntax: hirspec,prefix,spfname,outfname[,thar[,nosky]]'
  retall
end

chipno=1 ;   For blue chip !
ham_id = 29 ; Keck 'rj' ham_id
if ham_id ne 29 then begin
  print, 'This is the HIRES reduction package.  Go find the proper package.'
  stop
end

; Use an environmnet variable to control directory output.
outdir = getenv("RAW_ALL_OUT")
outdir_fits = getenv("RAW_ALL_OUT_FITS")
outdir_fits_db = getenv("RAW_ALL_OUT_FITS_DB")


working_dir = getenv("RAW_BLU") ; Current working directory

hamset, /silent                 ;ensure globals set
print, ''
trace, 15, 'HIRSPEC: Entering routine.'

;READ IMAGE FROM DISK 
hiraw,im,spfname,chip=chipno  ;hires mosaic
dum =  mrdfits(spfname, 0, head)  ;hires mosaic
;target = sxpar(head,'targname'); added hti, nov2009
;exptime = sxpar(head,'elaptime');added hti, nov2009
decker  = strcompress(sxpar(head,'deckname'),/remove_all) ; added hti, Nov 2009
; check binning, if not 3x1, then return
binning = strcompress(sxpar(head,'binning'),/remove_all)
if binning ne '3,1' then begin
  print,'HIRESPEC: Binning is not 3x1.'
  print,    "binning for ",spfname," is:",binning
  print,    "Returning..."
  return
endif

im = double(im)

;BIAS SUBTRACTION
  trace, 10, 'Subtracting bias'
  biaslev = median(im[*,5:13])  ;hires mosaic
    im = im - biaslev

im = nonlinear(im)

;
;ORDER LOCATIONS finding: Use defaults, possibly shifted.
rdsk, dorc, working_dir + 'sacred.ord'   ;hardwire the order locations

;dorc = orc  ;added by gm, hi, nov5 2009, but not needed in blue.
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
  trace, 15, 'HIRSPEC: Reading default order locations from sacred.ord'
  ;hti, changed from j??.ord to sacred.ord. This was already happening, no trace is correct, 7 nov 2009
  orc = dorc                    ; use default order locations
END 
IF ham_dord eq 0 then begin     ;else: find order locs
  trace, 15, 'HIRSPEC: Finding orders from image itself'
  getorc, im, dorc, orc         ; try to find order locations
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
print,orc[0,0]
    xwd = round(getxwd(im, orc,decker)) ;otherwise do this "optimally" 
  endelse
  
END ELSE xwd = 10               ;default to 10 pixels
XWD = 6;  OVERRIDE EXTRACTION WIDTH TO HELP WITH S-VALUES : HTI 11/2015
print,'% HIRESPEC: Overriding with Extraction width equal to 6 pixels'
xwd_out=xwd
;if xwd lt 5 or xwd gt 20 then xwd = 10 ; limits now set in getxwd.pro

;FLAT-FIELDING

trace, 10, 'HIRSPEC: Doing Flat-Fielding'
;rdsk, flt, prefix+'.sum'        ;get the previously determined flat
flt = totwf ;gm, hi , 5 nov 2009

smflt = flt*0.                  ;intialize smoothed flat

for j = 0, nrow-1 do begin      ;row by row
  s = flt[*, j]                         
  ss = median(s, 30)            ;median smooth the rows 	;Original
;  ss = median(s, 50)            ;median smooth the rows	;TEST
  zeroes = where (ss eq 0., nz) ;make sure we don't divide by 0
  if nz ne 0 then ss[zeroes] = 1.       
  smflt[*, j] = ss              ; build smoothed flat              
end

flt = flt/smflt                 ;divide my median smoothed flat to remove low frequencies

;j = where(flt lt 0.1 or flt gt 10, nneg) ;don't let the flat set weird values, they're prob. cosmics
j = where(flt lt 0.02 or flt gt 10, nneg) ;don't let the flat set weird values,
if nneg gt 0 then flt[j] = 1.              

flattenedim = im/flt            ;flat field division

;EXTRACT SPECTRUM
if not keyword_set(thar) then $
  getspec, flattenedim, orc, xwd, spec, sky = sky, cosmics = cosmics, spec = optspec, diff = replace  $
                                ;extract w/o flat or bg subtraction
else getspec, flattenedim, orc, xwd, spec ; ThAR - no cosmic removal

;STORE REDUCED SPECTRUM

;Strip off last 50 columns that are shadowed in camera.
spec = spec(0:4020,*)  ;strip last 50 from 4096

intcon, spec, intspec         ;convert image to format rdsi reads.
  
trace, 10, 'HIRSPEC: Saving extracted spectrum to ' + outdir + outfname
wdsk, intspec, outdir + outfname, 1, /new ;write image to disk
wdsk, head, outdir + outfname, 2
spawn,"chmod g+w " + outdir + outfname

fitsfile = outdir_fits + outfname + '.fits'
sxaddpar,head,'bzero',0
sxaddpar,head,'bscale',1
writefits,fitsfile,intspec,head
spawn,"chmod g+w "+fitsfile
trace,10,'%HIRSPEC: Saving extracted fits file: '+fitsfile

; Save the .fits file with gain included, and blaze function removed.
print,'fitsfile=',fitsfile
; deblaze.pro requires fits name with no directory information.
pos1 = strpos(fitsfile,'/',/reverse_search)
fitsfile_db = strmid(fitsfile,pos1+1,15)
deblaze,file=fitsfile_db
print,'fitsfile_db=',fitsfile_db
return
end
