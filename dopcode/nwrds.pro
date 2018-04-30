;-------------------------------------------------------------
;+
; NAME:
;       NWRDS
; PURPOSE:
;       Return the number of words in the given text string.
; CATEGORY:
; CALLING SEQUENCE:
;       n = nwrds(txt)
; INPUTS:
;       txt = text string to examine.             in
; KEYWORD PARAMETERS:
;       Keywords:
;         DELIMITER = d.  Set delimiter character (def = space).
; OUTPUTS:
;       n = number of words found.                out
; COMMON BLOCKS:
; NOTES:
;       Notes: See also getwrd.
; MODIFICATION HISTORY:
;       R. Sterner,  7 Feb, 1985.
;       Johns Hopkins University Applied Physics Laboratory.
;       RES 4 Sep, 1989 --- converted to SUN.
;
; Copyright (C) 1985, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	FUNCTION NWRDS,TXTSTR, help=hlp, delimiter=delim
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Return the number of words in the given text string.'
	  print,' n = nwrds(txt)'
	  print,'   txt = text string to examine.             in'
	  print,'   n = number of words found.                out'
	  print,' Keywords:'
	  print,'   DELIMITER = d.  Set delimiter character (def = space).'
	  print,' Notes: See also getwrd.'
	  return, -1
	endif
 
	IF STRLEN(TXTSTR) EQ 0 THEN RETURN,0	; A null string has 0 words.
	ddel = ' '			; Default word delimiter is a space.
	if n_elements(delim) ne 0 then ddel = delim ; Use given word delimiter.
	tst = (byte(ddel))(0)			; Delimiter as a byte value.
	X = BYTE(TXTSTR) NE tst			; Locate words.
	X = [0,X,0]				; Pad ends with delimiters.
 
	Y = (X-SHIFT(X,1)) EQ 1			; Look for word beginnings.
 
	N = fix(TOTAL(Y))			; Count word beginnings.
 
	RETURN, N
 
	END
