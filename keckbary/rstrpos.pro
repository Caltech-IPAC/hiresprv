; $Id: rstrpos.pro,v 1.11 2003/02/03 18:14:02 scottm Exp $
;
; Copyright (c) 1993-2003, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

FUNCTION RSTRPOS, Expr, SubStr, Pos
;+
; NAME:
;       RSTRPOS
;
; PURPOSE:
;	This function finds the last occurrence of a substring within
;	an object string. If the substring is found in the expression,
;	RSTRPOS returns the character position of the match, otherwise
;	it returns -1.
;
; CATEGORY:
;	String processing.
;
; CALLING SEQUENCE:
;        Result = RSTRPOS(Expr, SubStr [, Pos])
;
; INPUTS:
;       Expr:	The expression string in which to search for the substring.
;	SubStr: The substring to search for.
;
; OPTIONAL INPUTS:
;	Pos:	The character position before which the search is bugun.
;	      	If Pos is omitted, the search begins at the last character
;	      	of Expr.
;
; OUTPUTS:
;        Returns the position of the substring, or -1 if the
;	 substring was not found within Expr.
;
; SIDE EFFECTS:
;        Unlike STRPOS, Expr and SubStr must be strings.
;
; EXAMPLE:
;	Expr = 'Holy smokes, Batman!'	; define the expression.
;	Where = RSTRPOS(Expr, 'smokes')	; find position.
;	Print, Where			; print position.
;		5			; substring begins at position 5
;					; (the sixth character).
;
; MODIFICATION HISTORY:
;       JWG, January, 1993
;	AB, 7 December 1997, Added check for proper number of arguments
;           and ON_ERROR statement to stop in caller in case of error on
;	    suggestion of Jack Saba.
;	AB, 18 August 1998, Extended original code to allow Expr to be
;	    an array.
;-
  ON_ERROR, 2
  N = N_PARAMS()
  if (n lt 2) then message, 'Incorrect number of arguments.'

  ; Is expr an array or a scalar? In either case, make a result
  ; that matches.
  if (size(expr, /n_dimensions) eq 0) then result = 0 $
  else result = make_array(dimension=size(expr,/dimensions), /INT)
    
  RSubStr = STRING(REVERSE(BYTE(SubStr)))	; Reverse the substring

  for i = 0, n_elements(expr) - 1 do begin
    Len = STRLEN(Expr[i])
    IF (N_ELEMENTS(Pos) EQ 0) THEN Start=0 ELSE Start = Len - Pos

    RString = STRING(REVERSE(BYTE(Expr[i])))	; Reverse the string

    SubPos = STRPOS(RString, RSubStr, Start)
    IF SubPos NE -1 THEN SubPos = Len - SubPos - STRLEN(SubStr)
    result[i] = SubPos
  endfor

  RETURN, result
END
