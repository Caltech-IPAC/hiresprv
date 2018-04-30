pro Intcon,im,newim,thar=thar
;Scale an image, IM,  to NEWIM (I*2).  
;Each spectral order is scaled to have a median of NEWMEDIAN = 10,000 .
;The multiplicative factor (x1000) is stored in the last column of each order.
;NEWIM(*,ord) = OLDIM(*,ord) * Factor
;To recover images so integerized, multiply each order by: (1000./fac) 
;
;Jun-09-92 ECW  Adapted from ANA to IDL.
;Mar-05-95 GWM  Modified to scale each spectral order
;May-21-95 ECW  Modified to store as floating if obs. counts are too low.
;
@ham.common
;	
if n_params() lt 2 then begin
  print,'SYNTAX:  INTCON,im,newim'
  print,'Scale factors are stored at end of each order'
  return
end
;
;Set Some Parameters
sz = size(im)				;get dimensions of image
ncol = sz[1]  &  nords = sz[2]          ;# columns ,  # orders
Mxval = 32767.	                        ;= 2^15 = 2-byte limit
newmedian = 10000.                      ;New Median for Continuum sources
medarr = findgen(nords)			;Array to store medians of each order

;
FOR i=0,nords-1 do medarr[i]=median(im[*,i]) ;fill array with median
					     ;of each order
num=0
dum=where((medarr lt 600.), num)             ;min. median value allowed to 
					     ;integerize spectrum
if num gt 0 then begin			     ;Define type of array to store
  Newim = fltarr(ncol,sz[2])		     ;result in.
  trace,5,'INTCON: Saving spectrum as floating point.'
endif else begin
  Newim = intarr(ncol,sz[2])
  trace,5,'INTCON: Saving spectrum as integer.'
endelse
;
FOR j=0,nords-1 do begin                ;Loop through Orders
  IF not keyword_set(thar) then begin   ; typical star case (non-Th-Ar)
    negs = where(im[*,j] lt 0.,numnegs)	;Locate negative values 
    if numnegs gt 0 and medarr[j] gt 100 then im[negs,j] = 0 ;set neg values to 0
    Fac = newmedian/medarr[j]             ;MULTIPLICATIVE FACTOR
    ;fudge for H&K lines
    spec = im[*,j]*Fac            ;temporary spectrum, to check for high points
    if (max(spec) gt 32000 and j le 1) then Fac = 1000./medarr[j] ;lower fac for H&K
  end Else begin                          ;TH-AR case
    oldmax = max(im[*,j])               ;maximum strength line (prob. satur.)
    Fac = Mxval/oldmax                  ;force max to be just at 32767
  ENDelse
; MULTIPLY by FACTOR!
    sp = im[*,j]*Fac + 0.5                ;scaled by FAC (0.5 for roundoff)
    toohigh = where(sp ge mxval,numhigh)
    if numhigh gt 0 then sp[toohigh] = mxval
    Newim[*,j] = sp                  ;Scale Image to integer
    Newim[ncol-1,j] = Fac*1000. + 0.5 ;Store (Factor x 1000) in last column  
END    ;end loop through orders
END
