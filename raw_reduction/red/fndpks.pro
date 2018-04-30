pro fndpks,swa,pk
;
; DOPPLER-IODINE SECTION inside  (otherwise it's the normal version)
;Finds order peaks (PK) in a column or mashed swath of columns (SWA). Verifies
;  that spacing of peaks is sensible for echelle. If not, PK is returned as a
;  scalar zero.
; swa (input vector (# rows in image)) a column or mashed swath of columns
;  that is to be searched for maxima corresponding to order peaks.
; pk (output vector (# of order peaks) OR scalar) Either a vector containing
;  the row indicies of all identified order peaks OR a scalar set to zero,
;  indicating no sensible order peaks could not be found.
;  ALWAYS CHECK WHETHER RETURNED pk IS A SCALAR, INDICATING TROUBLE.
;Calls HAMTRACE, FALSPK
;18-Apr-92 JAV	Updated global variable list/interpretations.
;05-Mar-95 GWM  New Rejection of low points for HIRES and refurb'd Ham.

@ham.common					;get common block definition

if n_params() lt 2 then begin
  print,'syntax: fndpks,swa,pk.'
  retall
end

  trace,15,'FNDPKS: Entering routine.'

;Define useful quantities.
  mnsp = 4/ham_bin			;min # of downslope pixels near peak
  wid = 10                              ;~order sep for Hamilton
  errlim = 2				;max allowed change in order spacing
  if ham_id eq 29 then begin
    errlim = 14         ;greater tolerance for Keck orders
    wid = 5            ;wider separation for keck (minimum dist bet. orders)
  end
  badlim = 10				;max allowable # of bad peaks to fix
  nrow = n_elements(swa)		;number of rows in image
  nbad = 0
  medswa = median(swa)

;***************************************************************************
;SPECIAL SECTION to HARDWIRE LOCATIONS OF ORDERS FOR IODINE SET-UP
;pk = [41, 60, 79, 97, 116, 137, 157, 179, 198]
;pk = [pk, 220, 242, 267, 290, 314, 337, 363, 389]
;pk = [pk, 416, 444, 471, 501, 529, 561, 591, 624, 657, 692]
;pk = [pk, 727, 763, 801, 840, 880, 920, 964, 1008]

;iodine, chip =2 set of peaks
;pk = [51, 82, 115, 148, 184, 219, 254, 293, 331]
;pk = [pk, 371, 413, 455, 500, 545, 592, 640]

;Red, chip =3 set of peaks
;pk = [50, 106, 163, 224, 282, 347, 415, 484, 560, 633] + 15. ;red ords
;new order locations as of 16 July 2006
pk = [50, 106, 163, 224, 282, 347, 415, 484, 560, 633] - 4. ;red ords

;Look for peak in 2nd to highest order, +- 20 rows, to correct vertical positions

npks = n_elements(pk)
nom_pk = pk[npks-2]
hi_pt = max(swa[nom_pk-20:nom_pk+20],local_pk) ;locate peak (local_pk)
real_pk = local_pk + (nom_pk - 20)             ;actual row # of peak
delta = real_pk -  nom_pk                      ;offset from nominal
pk = pk + delta                                ;offset (correct) all peak locations

for j=0,npks-1 do begin          ;search all peaks for their true position
  hi_pt = max(swa[pk[j]-5:pk[j]+5],real_pk)
  pk[j] = pk[j] + (real_pk - 5)
end

trace,25,'FNDPKS: Found IODINE SET-UP orders in swath - returning to caller.'
return
;END SPECIAL SECTION FOR IODINE SET-UP
;******************************************************************************

;
;Determine positions of order peaks (located where the derivative changes from
;  positive to negitive) in first swath.
  fd_swa = swa[1:nrow-1] - swa[0:nrow-2]	;1st derivative at swa(i+0.5)
  pk = 1 + where(fd_swa[0:nrow-3] gt 0 and fd_swa[1:nrow-2] le 0,npk)
  good = where(pk ge wid and pk lt nrow-wid-1,npk)  ;not near ends
  pk = pk[good]

;Kludge: for initial establishment of HIRES/iodine order locations
plot,swa
oplot,pk,pk*0.+median(swa),ps=4,symsize=2
stop
return
;end kludge
;
;Now check that peaks are "major" ones (cover many pixels)
  gdpk = intarr(npk)				;0=not good, 1=good
  FOR i = 0,npk-1 do begin			;loop thru putative peaks
    if (pk[i]-mnsp ge 0) and (pk[i]+mnsp lt nrow-1) then begin
      bef = fd_swa[pk[i]-mnsp:pk[i]-1]		;derivatives before the peak
      aft = fd_swa[pk[i]+1:pk[i]+mnsp]		;derivatives after the peak
      if min(bef) gt 0 and max(aft) lt 0 then gdpk[i]=1 ;keep broad peaks and those above thresh
    endif
  ENDFOR
  pk = pk[where(gdpk eq 1,npk)]			;keep only good peaks (row locs)

;
;Now keep only Kings among orders  
;  gdpk = intarr(npk)				;0=not good, 1=good
;  For i = 0,npk-1 do begin
;     bef = max(swa(pk(i)-wid:pk(i)-1))       ;max of neighborhood
;     aft = max(swa(pk(i)+1:pk(i)+wid))
;     if swa(pk(i)) gt bef and swa(pk(i)) gt aft then gdpk(i)=1 ; keep kings 
;  ENDFOR
;  pk = pk(where(gdpk eq 1,npk))			;keep only good peaks (row locs)

;
;Rejection of low points (GM)
;Smooth the heights of peaks, some of which are bogus (low)
  minswa = max([min(swa),0])             ;lowest value of swa
  hts = (swa[pk]-minswa)/mean(swa[pk])   ;save poly_fit from high numbers
  smht = smooth(hts,7)               ;7 pt. median replace of peak ht
  coef = poly_fit(pk,smht,2)
  pkfit = coef[0] + coef[1]*pk + coef[2]*pk^2  
  thresh = 0.2                            ;set thresh at 0.2 of typical peak
  pk = pk[where(hts ge thresh*pkfit,npk)]  ;retain those above thresh
;repeat, with improved peak fit, to ensure ridding low ones.
  minswa = max([min(swa),0])             ;lowest value of swa
  hts = (swa[pk]-minswa)/mean(swa[pk])   ;save poly_fit from high numbers
  smht = smooth(hts,7)               ;7 pt. median replace of peak ht
  coef = poly_fit(pk,smht,2,pkfit)
  pkfit = coef[0] + coef[1]*pk + coef[2]*pk^2  
  pk = pk[where(hts ge thresh*pkfit,npk)]  ;retain those above thresh


;  
;Now reject those peaks that are very low
;  typpeak = median(swa(pk)) - medswa
;  thresh = medswa + 0.1*typpeak     ;set thresh at 1/10 typical peak
;  gdpk = intarr(npk)
;
;  for i = 0,npk-1 do begin			;loop thru putative peaks
;    if swa(pk(i)) ge thresh then gdpk(i)=1
;  endfor

;Apply second derivative test. Returns to caller, if peaks are all good.
;Second derivative test. Verify that peak positions have sensible spacing
;  by requiring 2nd derivative to be small (less than errlim).
;if ham_id ne 29 then begin    ;exclude check of weird order spacing for Keck
  fd_pk =    pk[1:npk-1] -    pk[0:npk-2]	;1st derivative at pk(i+0.5)
  sd_pk = fd_pk[1:npk-2] - fd_pk[0:npk-3]	;2nd derivative at pk(i+1)
  badpk = 1 + where(abs(sd_pk) gt errlim,nbad)	;indicies of bad peaks
;endif

  if nbad eq 0 then begin			;true: no bad peaks - done!
    trace,25,'FNDPKS: Found order peaks in swath - returning to caller.'
    return
  endif


;If there are too many bad peaks, give up right now.
  if nbad gt badlim then begin			;true means too many bad peaks
    trace,10,'FNDPKS: Too many bad peaks - returning without order peaks.'
    pk = 0					;scalar zero flags error
;    return
  endif

;Remove single and double false peaks by a fancy filtering technique. See
; subroutine falspk.pro for details.
if ham_id ne 29 then begin   ;do, except for HIRES SEISMO data
  falspk,2,pk,errlim				;remove double false peaks
  falspk,1,pk,errlim				;remove single false peaks
  npk = n_elements(pk)				;number of peaks remaining
end

;Repeat second derivative test. Returns to caller, if peaks are all good.
  fd_pk =    pk[1:npk-1] -    pk[0:npk-2]	;1st derivative at pk(i+0.5)
  sd_pk = fd_pk[1:npk-2] - fd_pk[0:npk-3]	;2nd derivative at pk(i+1)
  badpk = 1 + where(abs(sd_pk) gt errlim,nbad)	;indicies of bad peaks
  if nbad eq 0 then begin			;true: no bad peaks - done!
    trace,25,'FNDPKS: Found order peaks in swath - returning to caller.'
    return
  endif

;We still have a problem, but it may just be the endpoints, which we have not
;  yet checked.  If last peaks are bad, just discard them. This test must come
;  before the test of the first peaks, which may invalidate badpk indicies.
  while badpk[nbad-1] eq npk-2 do begin		;last peak is bad
    trace,20,'FNDPKS: Discarding last peak - probably false.'
    pk = pk[0:npk-2]				;discard last peak
    npk = npk - 1				;update peak counter
    nbad = nbad - 1				;update bad counter
    if nbad eq 0 then begin			;no more bad peaks, so return
      trace,25,'FNDPKS: Found order peaks in swath - returning to caller.'
      return
    endif
  endwhile

;If the first peaks are bad, discard them.
  indx = 0					;loop index
  while badpk[indx] eq indx+1 do begin		;first peak is bad
    trace,20,'FNDPKS: Discarding first peak - probably false.'
    pk = pk[1:npk-1]				;discard first peak
    npk = npk - 1				;update peak counter
    indx = indx + 1				;increment loop index
    nbad = nbad - 1				;update bad counter
    if nbad eq 0 then begin			;no more bad peaks, so return
      trace,25,'Found order peaks in swath - returning to caller.'
      return
    endif
  endwhile

;We still have problems. Time to give up and return with an error condition.
  trace,10,'Peculiar order spacing - returning without order peaks.'
  pk = 0					;scalar zero flags error
  return

end
