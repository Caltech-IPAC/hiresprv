pro hamdord,prefix,ordfname,orc,ome
;Determines and saves to disk the default order locations for a particular
;  spectrograph setting. Defaults are determined using the image (usually a
;  narrow flat) in obsfile'
;
;INPUTS:
;   PREFIX (input string) prefix string output filename containing information common
;     to all observations made with a particular spectrograph setting. A complete
;     filename will be constructed by appending a standardized file extension.
;     The following files will be created by HAMDORD:
;	* prefix.ord - default order location coefficients
;	* prefix.fmt - fractional extraction width, blaze center, base order.
;    ORDFNAME   (input string) Filename of FITS file to be used
;
;OUTPUTS:
;     ORC  (array (# coeffs , # orders))] coefficients from the
;          polynomial fits to the order peaks.
;     OME  (optional output vector (# orders))] each entry gives the mean of the
;           absolute value of the difference between order locations and the polynomial
;           fit to these locations.
;Calls MASKIM, MASKBOX, FORDS, FNDPKS, FALSPK, GETORC
;18-Apr-92 JAV	Updated global variable list/interpretations. Replaced wdsk
;		 /insert flags with /new flags. Converted file extensions to
;		 lowercase.
;29-Apr-92 JAV	Now clip baseline column of FITS images.
;07-May-92 JAV	Changed ".xwd" to ".fmt": includes blaze center, base order.
;04-Jun-92 ECW  Commented out some procedure calls that are not being 
;		used at SFSU at this time.
;02-Feb-01 JTW  Removed extraction width section: now handled by hamspec.pro

@ham.common					;get common block definition

if n_params() lt 2 then begin
  print,'syntax: hamdord,prefix,ordfname[,orc[,ome]].'
  retall
end
narg = n_params()					;save # arguments

  hamset,/silent					;ensure globals set
  print,''
  trace,15,'HAMDORD: Entering routine.'

;Read in and mask image.
rdfits,im,ordfname
     im = float(im)
;
 if ham_id eq 29 then begin    ;seismo images need trimming
     trace,15,'HAMDORD:  Trimming Columns (21:2047+21) off Keck images'
;     im = im(42:2089,*)  ;for oct93 Seismo run

  if ham_bin eq 1 then begin
    nr = n_elements(im[0,*])  ;# rows
    nc = n_elements(im[*,0])  ;#cols
    for j=0,nr-1 do begin     ;Subtract Bias, row by row
;change here for new overscan (jan 7 2000)
;      biaslev = median(im(2200:2299,j))
      biaslev = median(im[21+2047+11:21+2047+11+20,j]) ; bias from 2079:2073+25
      im[*,j] = im[*,j] - biaslev
    end
    im = im[21:2047+21,*]   ;for nov 94 Keck run
  end
  if ham_bin eq 2 then im = im[11:1023+11,*]   ;binned 2x2
  end
	   
;Locate orders and spectral extraction width, if possible. Otherwise return
  dorc = 0						;dorc not yet found
  svdord = ham_dord					;save user's dord value
  ham_dord = 0						;forbid use of default
  getorc,im,dorc,orc		 			;find order locations
  ham_dord = svdord					;restore user's dord
  if not keyword_set(orc) then begin			;Did fords fail?
    message,'Unable to find default order locations - aborting.'
  end else begin
    trace,10,'HAMDORD: Saving order locations to ' + prefix + '.ord'
    comment = 'Order location fit coefficients.'
    wdsk,orc,prefix + '.ord',comment,/new		; no, save ORCs to disk
  endelse

;Determine extraction width, blaze center column, and base order. Save to disk.
  trace,15,'HAMDORD: Default order locations found - returning to caller.'
  return
end
