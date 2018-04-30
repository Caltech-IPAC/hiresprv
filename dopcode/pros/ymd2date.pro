;-------------------------------------------------------------
;+
; NAME:
;       YMD2DATE
; PURPOSE:
;       Convert from year, month, day numbers to date string.
; CATEGORY:
; CALLING SEQUENCE:
;       date = ymd2date(Y,M,D)
; INPUTS:
;       y = year number (like 1986).                         in
;       m = month number (1 - 12).                           in
;       d = day of month number (1 - 31).                    in
; KEYWORD PARAMETERS:
;       Keywords:
;         FORMAT = format string.  Allows output date to be customized.
;            The following substitutions take place in the format string:
;         Y$ = 4 digit year.
;         y$ = 2 digit year.
;         N$ = full month name.
;         n$ = 3 letter month name.
;         d$ = day of month number.
;         W$ = full weekday name.
;         w$ = 3 letter week day name.
; OUTPUTS:
;       date = returned date string (like 24-May-1986).      out
; COMMON BLOCKS:
; NOTES:
;       Notes:
;         The default format string is 'd$-n$-Y$' giving 24-Sep-1989
;         Example: FORMAT='w$ N$ d$, Y$' would give 'Mon 
; MODIFICATION HISTORY:
;       R. Sterner.  16 Jul, 1986.
;       RES 18 Sep, 1989 --- converted to SUN
;       R. Sterner, 28 Feb, 1991 --- modified format.
;	R. Sterner, 16 Dec, 1991 --- added space to 1 digit day.
;       Johns Hopkins University Applied Physics Laboratory.
;
; Copyright (C) 1986, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	FUNCTION YMD2DATE, Y, M, D, help=hlp, format=frmt
 
	IF (N_PARAMS(0) LT 3) or keyword_set(hlp) THEN BEGIN
	  PRINT,' Convert from year, month, day numbers to date string.'
	  PRINT,' date = ymd2date(Y,M,D)'
	  PRINT,'   y = year number (like 1986).                         in'
	  PRINT,'   m = month number (1 - 12).                           in'
	  PRINT,'   d = day of month number (1 - 31).                    in'
	  PRINT,'   date = returned date string (like 24-May-1986).      out'
	  print,' Keywords:'
	  print,'   FORMAT = format string.  Allows output date to be '+$
	    'customized.'
	  print,'      The following substitutions take place in the '+$
	    'format string:'
	  print,'   Y$ = 4 digit year.'
	  print,'   y$ = 2 digit year.'
	  print,'   N$ = full month name.'
	  print,'   n$ = 3 letter month name.'
	  print,'   d$ = day of month number.'
	  print,'   W$ = full weekday name.'
	  print,'   w$ = 3 letter week day name.'
	  print,' Notes:'
	  print,"   The default format string is 'd$-n$-Y$' giving 24-Sep-1989"
	  print,"   Example: FORMAT='w$ N$ d$, Y$' would give 'Mon "+$
	    "September 18, 1989'"
	  RETURN, -1
	ENDIF
 
	;---- error check -----
	IF Y LT 0 THEN BEGIN
	  PRINT,'Error in ymd2date: invalid year.'
	  RETURN, -1
	ENDIF
	IF Y LT 100 THEN Y = Y + 1900
	IF (M LT 1) OR (M GT 12) THEN BEGIN
	  PRINT,'Error in ymd2date: invalid month.'
	  RETURN, -1
	ENDIF
	IF (D LT 1) OR (D GT MONTHDAYS(Y,M)) THEN BEGIN
	  PRINT,'Error in ymd2date: invalid month day.'
	  RETURN, -1
	ENDIF
 
	;-----  format string  ------
	fmt = 'd$-n$-Y$'
	if keyword_set(frmt) then fmt = frmt
 
	;-----  Get all the allowed parts  -----
	yu = strtrim(Y,2)
	yl = strtrim(fix(y-100*fix(y/100)),2)
	mnames = monthnames()
	mu = mnames(m)
	ml = strmid(mu,0,3)
	dl = strtrim(d,2)
	if strlen(dl) eq 1 then dl = ' '+dl	; Add space to 1 digit day.
	wu = weekday(y,m,d)
	wl = strmid(wu,0,3)
	
	;----  Do substitutions  ------
	date = fmt
	date = stress(date, 'R', 0, 'Y$', yu)	; 4 digit year.
	date = stress(date, 'R', 0, 'y$', yl)	; 2 digit year.
	date = stress(date, 'R', 0, 'd$', dl)	; day of month.
	date = stress(date, 'R', 0, 'N$', mu)	; Full month name.
	date = stress(date, 'R', 0, 'n$', ml)	; 3 letter month name.
	date = stress(date, 'R', 0, 'W$', wu)	; Full weekday name.
	date = stress(date, 'R', 0, 'w$', wl)	; 3 letter weekday name.
 
	RETURN, DATE
 
	END
