FUNCTION AVG,ARRAY,DIMENSION
;+
; NAME:
;       AVG
; PURPOSE:
;       Return the average value of an array, or 1 dimension of an array
; EXPLANATION:
;       Calculate the average value of an array, or calculate the average
;       value over one dimension of an array as a function of all the other
;       dimensions.
;
; CALLING SEQUENCE:
;       RESULT = AVG( ARRAY, [ DIMENSION ] )
;
; INPUTS:
;       ARRAY = Input array.  May be any type except string.
;
; OPTIONAL INPUT PARAMETERS:
;       DIMENSION = Optional dimension to do average over, scalar
;
; OUTPUTS:
;       The average value of the array when called with one parameter.
;
;       If DIMENSION is passed, then the result is an array with all the
;       dimensions of the input array except for the dimension specified,
;       each element of which is the average of the corresponding vector
;       in the input array.
;
;       For example, if A is an array with dimensions of (3,4,5), then the
;       command B = AVG(A,1) is equivalent to
;
;                       B = FLTARR(3,5)
;                       FOR J = 0,4 DO BEGIN
;                               FOR I = 0,2 DO BEGIN
;                                       B(I,J) = TOTAL( A(I,*,J) ) / 4.
;                               ENDFOR
;                       ENDFOR
;
; RESTRICTIONS:
;       Dimension specified must be valid for the array passed; otherwise the
;       input array is returned as the output array.
; PROCEDURE:
;       AVG(ARRAY) = TOTAL(ARRAY)/N_ELEMENTS(ARRAY) when called with one
;       parameter.
; MODIFICATION HISTORY:
;       William Thompson        Applied Research Corporation
;       July, 1986              8201 Corporate Drive
;                               Landover, MD  20785
;       Converted to Version 2      July, 1990
;       Replace SUM call with TOTAL    W. Landsman    May, 1992
;       Converted to IDL V5.0   W. Landsman   September 1997
;-
ON_ERROR,2
S = SIZE(ARRAY)
IF S[0] EQ 0 THEN $
        MESSAGE,'Variable must be an array, name= ARRAY'
;
IF N_PARAMS() EQ 1 THEN BEGIN
        AVERAGE = TOTAL(ARRAY) / N_ELEMENTS(ARRAY)
END ELSE BEGIN
        IF ((DIMENSION GE 0) AND (DIMENSION LT S[0])) THEN BEGIN
                AVERAGE = TOTAL(ARRAY,DIMENSION+1) / S[DIMENSION+1]
        END ELSE $
                MESSAGE,'*** Dimension out of range, name= ARRAY'
ENDELSE
;
RETURN, AVERAGE
END
