function color24, r, g, b
;+
; NAME:
;       COLOR24
;
; PURPOSE:
;       Return the 24-bit color index for an RGB triplet.
;
; CALLING SEQUENCE:
;       RESULT = COLOR24(R, G, B)
;
; INPUTS:
;       R - 8-bit red color index.
;       G - 8-bit green color index.
;       B - 8-bit blue color index.
;
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;       RESULT - the 24-bit color index for the RGB triplet.
;
; COMMON BLOCKS:
;       None.
;
; EXAMPLE:
;       Return the 24-bit color index for pure green:
;
;       IDL> print, color24(0,255,0)
;
; MODIFICATION HISTORY:
;   02 Mar 2003  Written by Tim Robishaw, Berkeley
;-

if (N_params() lt 3) $
  then message, 'Syntax: RESULT = COLOR24(r,g,b)'

; DO THE R, G, B VECTORS HAVE THE SAME SIZE...
if not( (N_elements(r) eq N_elements(g)) AND $
        (N_elements(r) eq N_elements(b))) $
  then message, 'r, g, and b vectors must have same size.', /INFO

; RETURN THE 24-BIT COLOR INDEX FOR AN RGB TRIPLET...
return, long(r) + ishft(long(g),8) + ishft(long(b),16)

end; color24
