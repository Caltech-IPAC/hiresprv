pro gettrof,im,orc,trof
;Determines the minimum count levels in the interorder troughs.
; im (input array (# columns , # rows)) image inwhich to find trough levels.
; orc (input array (# coeffs , # orders)) coefficients of polynomial fits to
;   order locations.
; trof (output array (# columns in im , # orders - 1)) count levels in the
;   troughs between the orders whose locations are given in orc.
;Calls TRACE
;23-Oct-89 JAV	Create.
;18-Apr-92 JAV	Removed common block definition. Changed trace logic.
;04-Mar-95 GWM  Use median near minimum of trough, NOT minimum.

if n_params() lt 3 then begin
  print,'syntax: gettrof,im,orc,trof.'
  retall
end

  trace,25,'GETTROF: Entering routine.'

;Define useful quantities.
  ncol = n_elements(im[*,0])				;# columns in image
  nrow = n_elements(im[0,*])				;# rows in image
  nord = n_elements(orc[0,*])				;# orders in image
  trof = fltarr(ncol,nord-1)				;init array
  ix = findgen(ncol)					;column indicies

;Check that lowest order is fully contained on image.
  y = long(poly(ix,orc[*,0]))				;row numbers in order
  if min(y) lt 0 or max(y) gt nrow - 1 then message, $	;check if beyond limits
    'Image does not contain lowest order - aborting.'

;Check that highest order is fully contained on image.
  y = long(poly(ix,orc[*,nord-1]))			;row numbers in order
  if min(y) lt 0 or max(y) gt nrow - 1 then message, $	;check if beyond limits
    'Image does not contain highest order - aborting.'

;Assume then that image contains all orders.  Look between each pair of orders
;  for the minimum in each column. Assume this minimum value corresponds to the
;  counts in the interorder troughs.
  trace,20,'GETTROF: Finding counts in troughs between orders. Be patient....'
  yhi = long(poly(ix,orc[*,0]))				;init for loop entry
  for i=1,nord-1 do begin				;loop thru orders
    if (i-1) mod 10 eq 0 then begin
      trace,20,'GETTROF:   Finding trough counts between orders ' $
	  + strtrim(string(i-1),2) + ' and ' + strtrim(string(i),2)
    endif
    ylo = yhi						;old ylo is now yhi
    yhi = long(poly(ix,orc[*,i]))			;row # in low order
    bad = where(yhi-ylo le 0,nbad)			;are orders overlapping?
    if nbad gt 0 then message,'Order location fits overlap - aborting.'
    for j=0,ncol-1 do begin				;loop thru columns
      col = im[j,ylo[j]:yhi[j]]  		        ;column cts
      ind = sort(col)                                   ;sort cts
      trof[j,i-1] = col[ind[1]]                        ;2nd lowest in column
    endfor
  endfor
  if (i-2) mod 10 ne 0 then begin			;check for tracing
    trace,20,'GETTROF:   Finding trough counts between orders ' $
      + strtrim(string(nord-2),2) + ' and ' + strtrim(string(nord-1),2)
  endif
  trace,10,'GETTROF: Mean counts in background = ' $
    + strtrim(string(mean(trof),form='(f10.2)'),2)

  trace,25,'GETTROF: Counts determined for troughs - returning to caller.'
return
end
