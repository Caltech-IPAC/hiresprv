function minmax,array
;+
; NAME:
;   MINMAX
; PURPOSE:
;   Return a 2 element array giving the minimum and maximum of a vector
;   or array.  This is faster than doing a separate MAX and MIN.
; CALLING SEQUENCE:
;   value = minmax( array )
; INPUTS:
;   array - an IDL numeric scalar, vector or array.
; OUTPUTS:
;   value = a two element vector, 
;           value(0) = minimum value of array
;           value(1) = maximum value of array
; EXAMPLE:
;   Print the minimum and maximum of an image array, im
; 
;         IDL> print, minmax( im )
; PROCEDURE:
;   The MIN function is used with the MAX keyword
; REVISION HISTORY:
;   Written W. Landsman                January, 1990
;-
 On_error,2
 amin = min( array, MAX = amax)
 return, [ amin, amax ]
 end
