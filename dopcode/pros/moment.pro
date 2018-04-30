;$Id: moment.pro,v 1.1.1.1 2005/11/17 06:11:06 johnjohn Exp $
;
; Copyright (c) 1994-1998, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;       MOMENT
;
; PURPOSE:
;       This function computes the mean, variance, skewness and kurtosis
;       of an N-element vector. IF the vector contains N identical elements, 
;       the mean and variance are computed; the skewness and kurtosis are 
;       not defined and are returned as IEEE NaN (Not a Number). Optionally, 
;       the mean absolute deviation and standard deviation may also be 
;       computed. The returned result is a 4-element vector containing the
;       mean, variance, skewness and kurtosis of the input vector X.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = Moment(X)
;
; INPUTS:
;       X:      An N-element vector of type integer, float or double.
;
; KEYWORD PARAMETERS:
;       DOUBLE: IF set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;       MDEV:   Use this keyword to specify a named variable which returns
;               the mean absolute deviation of X.
;
;       SDEV:   Use this keyword to specify a named variable which returns
;               the standard deviation of X.
;
;       MAXMOMENT:
;               Use this keyword to limit the number of moments:
;               Maxmoment = 1  Calculate only the mean.
;               Maxmoment = 2  Calculate the mean and variance.
;               Maxmoment = 3  Calculate the mean, variance, and skewness.
;               Maxmoment = 4  Calculate the mean, variance, skewness,
;                              and kurtosis (the default).
;
;       NAN:    Treat NaN elements as missing data.
;               (Due to problems with IEEE support on some platforms,
;                infinite data will be treated as missing as well. )
;
; EXAMPLE:
;       Define the N-element vector of sample data.
;         x = [65, 63, 67, 64, 68, 62, 70, 66, 68, 67, 69, 71, 66, 65, 70]
;       Compute the mean, variance, skewness and kurtosis.
;         result = moment(x)
;       The result should be the 4-element vector: 
;       [66.7333, 7.06667, -0.0942851, -1.18258]
;  
;
; PROCEDURE:
;       MOMENT computes the first four "moments" about the mean of an N-element
;       vector of sample data. The computational formulas are given in the IDL 
;       Reference Guide. 
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, August 1994
;       Modified:    GGS, RSI, September 1995
;                    Added DOUBLE keyword. 
;                    Added checking for N identical elements. 
;                    Added support for IEEE NaN (Not a Number).
;                    Modified variance formula.
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision. 
;                    GSL, RSI, August 1997
;                    Added Maxmoment keyword.
;       Modified:    Wed Jan 28 13:28:07 1998, Scott Lett, RSI Added
;                    NAN keyword.
;-
FUNCTION idl_moment_total, Arg, Double = Double

  Type = SIZE(Arg)

  ;If idl_moment_total is called without the Double keyword let the type
  ;of input argument drive the precision of TOTAL.
  IF N_ELEMENTS(Double) EQ 0 THEN $
    Double = (Type[Type[0]+1] EQ 5) OR (Type[Type[0]+1] EQ 9)
    
  ArgSum = TOTAL(Arg, Double = Double)

  IF Type[Type[0]+1] EQ 5 AND Double EQ 0 THEN $
    RETURN, FLOAT(ArgSum) ELSE $
  IF Type[Type[0]+1] EQ 9 AND Double EQ 0 THEN $
    RETURN, COMPLEX(ArgSum) ELSE $
    RETURN, ArgSum

END

FUNCTION Moment, X, Double = Double, Mdev = Mdev, Sdev = Sdev, $
                 Maxmoment = Maxmoment, NaN = nan

  ON_ERROR, 2

  if keyword_set( nan ) then begin


      whereNotNaN = where( finite(X) ne 0, nanCount)

      if nanCount gt 0 then begin

          return, moment( X[whereNotNan], Double = Double, Mdev = Mdev, $
                          Sdev = Sdev, Maxmoment = Maxmoment )
      endif

  endif

  TypeX = SIZE(X)

  ;Check length.
  IF TypeX[TypeX[0]+2] lt 2 THEN $
    MESSAGE, "X array must contain 2 OR more elements."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  IF N_ELEMENTS(Double) EQ 0 THEN $
    Double = (TypeX[TypeX[0]+1] EQ 5 OR TypeX[TypeX[0]+1] EQ 9)

  nX = TypeX[TypeX[0]+2]
  Mean = idl_moment_total(X, Double = Double) / nX

  IF NOT keyword_set( Maxmoment ) THEN Maxmoment = 4

  Var  = !VALUES.F_NAN
  Skew = !VALUES.F_NAN
  Kurt = !VALUES.F_NAN

  IF Maxmoment GT 1 THEN BEGIN  ; Calculate higher moments.
     Resid = X - Mean
   
     ;Mean absolute deviation (returned through the Mdev keyword).

     Mdev = idl_moment_total(ABS(Resid), Double = Double) / nX
    
     Var = idl_moment_total(Resid^2, Double = Double) / (nX-1.0)
       ;Numerically-stable "two-pass" formula.
       ;r2 = idl_moment_total(Resid^2, Double = Double)
       ;Var1 = r2 / (nX-1.0)
       ;Var2 = (r2 - (idl_moment_total(Resid, Double = Double)^2)/nX)/(nX-1.0)
       ;Var =  (Var1 + Var2)/2.0
   
     ;Standard deviation (returned through the Sdev keyword).

     Sdev = SQRT(Var)


     IF Sdev NE 0 THEN BEGIN	;Skew & kurtosis defined
       IF Maxmoment GT 2 THEN $
          Skew = idl_moment_total(Resid^3, Double = Double) / (nX * Sdev ^ 3)
       IF Maxmoment GT 3 THEN $
          Kurt = idl_moment_total(Resid^4, Double = Double) / (nX * Sdev ^ 4) - 3.0

       ;The "-3" term makes the kurtosis value zero for normal distributions.
       ;Positive values of the kurtosis (lepto-kurtic) indicate pointed or
       ;peaked distributions; Negative values (platy-kurtic) indicate flat-
       ;tened or non-peaked distributions.

     ENDIF
  ENDIF
  RETURN, [Mean, Var, Skew, Kurt]
END
