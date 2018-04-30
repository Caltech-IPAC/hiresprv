pro getorc,im,dorc,orc
;Searches for order locations in image and compares them to default order
;  locations. If the order locations seem valid they are returned.
; im (input array (# columns , # rows)) image in which orders are to be
;   located.
; dorc (input array (# coeff , # orders)) coefficients (from PIT) of polynomial 
;   fit to default locations of orders.
; orc (output array (# coeff , # orders) OR scalar) If array, then contains
;   coefficients (from PIT) of polynomial fit to locations of orders in image.
;   If scalar, then valid order locations were not found. ALWAYS CHECK WHETHER
;   RETURNED ORC IS A SCALAR, INDICATING THAT ORDER LOCATIONS WERE NOT FOUND.
;Call HAMTRACE, FORDS, FNDPKS, FALSPK,
;  (These subroutines and others are compiled by ana$ham:HAMSUBS)
;13-Dec-89 JAV	Create.
;14-Dec-89 JAV	Stripped out all references to extraction width.
;18-Nov-90 JAV	Fixed bug in too many/few orders found logic.
;18-Apr-92 JAV	Updated global variable list/interpretations.

@ham.common					;get common block definition

if n_params() lt 3 then begin
  print,'syntax: getorc,im,dorc,orc'
  retall
end

;  trace,25,'GETORC: Entering routine.'

;Define useful quantities.
;  swid = 32    old value	;# of column in fords swath
  swid = 200		;new value  ; of column in fords swath
  orc = 0					;scalar orc flags error

;If ham_dord eq 1, then just use default order locations.
  if ham_dord eq 1 then begin		;true = always use defaults
    trace,5,'GETORC: Using default order locations - returning to caller.'
    return					;return without orcs
  end

;Find order locations, if possible. Otherwise use defaults.
  fords,im,swid,orc				;find order location coeffs
  if not keyword_set(orc) then begin		;Did fords fail?
    trace,5,'GETORC: Unable to find order locations - using defaults.'
    return
  endif
  if keyword_set(dorc) then begin		;don't check if finding default
    if n_elements(orc[0,*]) lt n_elements(dorc[0,*]) then begin
      trace,5,'GETORC: Some orders not found - using defaults.'
      orc = 0					; yes, scalar flags failure
    endif
    if n_elements(orc[0,*]) gt n_elements(dorc[0,*]) then begin
      trace,5,'GETORC: Extra orders found - using defaults.'
      orc = 0 					; yes, scalar flags error
    endif
  endif

  trace,25,'GETORC: Returning to caller.'
  return

end
