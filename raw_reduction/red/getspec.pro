pro getspec,im,orc,xwd,spec,sky = sky, cosmics = cosmics, diff = replace, spec = optspec
;Subroutine extracts spectra from all orders described in orc. 
; im (input array (# columns , # rows)) image from which orc and were
;   determined and from which spectrum is to be extracted.
; orc (input array (# coeffs , # orders)) polynomial coefficients (from FORDS)
;   that describe the location of complete orders on the image.
; xwd (input scalar) fractional extraction width (from GETXWD)
; spec (output array (# columns , # orders)) final extracted spectrum from im.
;Calls HAMTRACE, GETARC
;24-Oct-89 JAV	Create.
;01-Nov-89 GBB	Modified to allow no background subtraction.
;10-Nov-89 JAV  Cleaned up background subtraction logic.
;03-Dec-89 JAV	Added fractional extraction width to argument list.
;14-Dec-89 JAV	Fixed checks for swath off edge of spectrum.
;19-Jan-89 JAV	Fixed coefficient calculation in 'Arc Off Edge of Image' tests.
;23-Jan-89 JAV	Really fixed 'Arc Off Edge if Image' tests.
;06-Jun-90 JAV	Added argument to GETARC call so total counts are returned.
;04-Sep-90 JAV	Fixed background subtraction bug; backgd/pixel is subtracted
;		 from spectrum counts/pixel BEFORE conversion to total counts.
;13-Sep-90 JAV	Added user specified extraction width logic ($hamxwd stuff).
;18-Apr-92 JAV	Updated global variable list/interpretations. Changed xwd
;		 logic.
;22-Sep-92 ECW  Added test to determine how to extend orders on high and
;		low ends of image depending on value of xwd.
;12-Jun-01 JTW  Added cosmic ray removal machinery
;
;
;
;
;BUG: IDL will halt with an error if image is indexed with an invalid index.
;     ANA used to return the last element in the array. New logic is needed
;     here to handle orders that are partially off the chip.

@ham.common					;get common block definition

if n_params() lt 4 then begin
  print,'syntax: getspec,im,orc,xwd,spec[,sky[,cosmics]'
  retall
end

;  trace,25,'GETSPEC: Entering routine.'

;Define useful quantities.
im = double(im)
ncol = n_elements(im[*, 0])     ;# columns in image
nrow = n_elements(im[0, *])     ;# rows in image
ncoef = n_elements(orc[*, 0])   ;# polyn. coeffs
nord =  n_elements(orc[0, *])   ;# full orders in orc
ix = findgen(ncol)              ;column indicies
spec = dblarr(ncol, nord)       ;init spectrum
orcend = dblarr(ncoef, nord+2)  ;init extended orcs

;GETARC needs order location coefficients (orc) on both sides of arc swath to 
;  be extracted. In order to extract the lowest and highest orders specified
;  in orc, we need to extend orc one extra order on each end. We shall do so
;  by linearly extrapolating the last two orc on each end.
;Extend orc on the low end. Check that requested swath lies on image.
orclo = 2*orc[*, 0] - orc[*, 1] ;extrapolate orc

coeff = orc[*, 0]               ;central coefficients
y = poly(ix, coeff) - xwd       ;edge of arc

yoff = where(y lt 0, noff)      ;pixels off low edge
if noff gt 0 then begin         ;check if on image
;   GETARC will reference im(j) where j<0. These array elements do not exist.
  trace, 5, 'GETSPEC: Top order off image in columns [' $
    + strtrim(string(yoff[0]), 2) + ',' $
    + strtrim(string(yoff[noff-1]), 2) + '].'
endif

;Extend orc on the high end. Check that requested swath lies on image.
orchi = 2*orc[*, nord-1] - orc[*, nord-2] ;extrapolate orc


coeff = orc[*, nord-1]          ;central coefficients
y = poly(ix, coeff) + xwd       ;edge of arc

yoff = where(y gt nrow-1, noff) ;pixels off high edge
if noff gt 0 then begin			
;   GETARC will reference im(j) where j > ncol*nrow-1. These array elements do
;     not exist.
  trace, 5, 'GETSPEC: Bottom order off image in columns [' $
    + strtrim(string(yoff[0]), 2) + ',' $
    + strtrim(string(yoff[noff-1]), 2) + '].'
endif

;Define an order set (orcend) extended one extra order on either end.
for n = 1, nord do orcend[*, n] = orc[*, n-1]
orcend[*, 0] = orclo
orcend[*, nord+1] = orchi

;Now loop through orders extracting spectrum and maybe subtracting background.

trace, 15, 'GETSPEC: Extracting spectrum.'


;CREATE MASK
;no longer necessary with new CCd.
mask = im*0.+1.                 ;this mask is for the inkspot and known
;mask[950:1050, 530:548] = 0.    ;bad columns on the HIRES chip
;mask[2006:2007, 0:472] = 0.



if keyword_set(cosmics) then begin 
  if n_elements(sky) eq 0 then sky = im*0.
                                ;this shouldn't be necessary, the
                                ;"sky" (actually scattered light) 
                                ;should be found by getksy earlier and 
                                ;passed to getspec.  This line is here
                                ;to prevent crashes.
  remove_cosmics, im, orc, xwd, sky, spec = optspec, cosmics = replace, mask = mask, fwhm = seeing

endif

for onum = 1, nord do begin     ;loop thru orders
  getarc, im, orcend, onum, xwd, arc, pix ;extract counts/pixel
  spec[*, onum-1] = double(arc) * pix ;store total counts
endfor

if keyword_set(cosmics) then begin
  optspec[0] = seeing           ;store the seeing (FWHM in pixels) as the first datum
  spec[0] = seeing 
endif


trace, 25, 'GETSPEC: Spectrum extracted - returning to caller.'


return
end
