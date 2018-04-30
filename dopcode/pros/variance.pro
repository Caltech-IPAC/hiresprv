;$Id: variance.pro,v 1.10 2005/02/01 20:24:40 scottm Exp $
;
; Copyright (c) 1997-2005, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;       VARIANCE
;
; PURPOSE:
;       This function computes the statistical variance of an
;       N-element vector. 
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = variance(X)
;
; INPUTS:
;       X:      An N-element vector of type integer, float or double.
;
; KEYWORD PARAMETERS:
;       DOUBLE: IF set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;       NAN:    If set, treat NaN data as missing.
;
; EXAMPLE:
;       Define the N-element vector of sample data.
;         x = [65, 63, 67, 64, 68, 62, 70, 66, 68, 67, 69, 71, 66, 65, 70]
;       Compute the mean.
;         result = variance(x)
;       The result should be:
;       7.06667
;
; PROCEDURE:
;       VARIANCE calls the IDL function MOMENT.
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Written by:  GSL, RSI, August 1997
;-
FUNCTION variance, X, Double = Double, NaN = NaN

  ON_ERROR, 2

  RETURN, (moment( X, Double=Double, Maxmoment=2, NaN = NaN ))[1]
END
