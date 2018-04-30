FUNCTION POLY_FIT,X,Y,NDEGREE,YFIT,YBAND,SIGMA,A
;+
; NAME:
;	POLY_FIT
; PURPOSE:
;	Least square polynomial fit with optional error estimates.
;	Old version, uses matrix inversion.  Newer version is SVDFIT
;	which uses SVD and is more flexible but slower.
; CATEGORY:
;	?? - CURVE FITTING.
; CALLING SEQUENCE:
;	COEFF = POLY_FIT(X,Y,NDEGREE [,YFIT,YBAND,SIGMA,A] )
; INPUTS:
;	X = independent variable vector.
;	Y = dependent variable vector, should be same length as x.
;	NDEGREE = degree of polynomial to fit
;
; OUTPUTS:
;	Function result= Coefficient vector, length NDEGREE+1.
;   OPTIONAL PARAMETERS:
;	YFIT = Vector of calculated Y's.  Has error + or - YBAND.
;	YBAND = Error estimate for each point = 1 sigma
;	SIGMA = Standard deviation in Y units.
;	A = Correlation matrix of the coefficients.
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: George Lawrence, LASP, University of Colorado,
;		December, 1981.
;	Adapted to VAX IDL by: David Stern, Jan, 1982.
;
;-
	ON_ERROR,2		;RETURN TO CALLER IF ERROR
	XX = X*1.		;BE SURE X IS FLOATING OR DOUBLE
	N = N_ELEMENTS(X) 	;SIZE
	IF N NE N_ELEMENTS(Y) THEN $
	  message,'X and Y must have same # of elements'
;
	M = NDEGREE + 1			;# OF ELEMENTS IN COEFF VEC.
;
	A = DBLARR(M,M)		;COEFF MATRIX
	B = DBLARR(M)		;WILL CONTAIN SUM Y * X^J
	Z = DBLARR(N)+1.
;
	A[0,0] = N
	B[0] = TOTAL(Y)
;
	FOR P = 1,2*NDEGREE DO BEGIN ;POWER LOOP.
		Z=Z*XX			;Z IS NOW X^P
		IF P LT M THEN B[P] = TOTAL(Y*Z) ;B IS SUM Y*XX^J
		SUM = TOTAL(Z)
		FOR J= 0 > (P-NDEGREE), NDEGREE < P DO A[J,P-J] = SUM
	  END			;END OF P LOOP.
;
	A = INVERT(A)		;INVERT MATRIX.
;
;			IF A IS MULTIPLIED BY SIGMA SQUARED, IT IS THE
;			CORRELATION MATRIX.
;
	C = float(b) # a	;Get coefficients

;
	IF (N_PARAMS(0) LE 3) THEN RETURN,C	;EXIT IF NO ERROR ESTIMATES.
;
	YFIT = FLTARR(N)+C[0]	;INIT YFIT
	FOR K = 1,NDEGREE DO YFIT = YFIT + C[K]*(XX^K) ;FORM YFIT.
;
	IF (N_PARAMS(0) LE 4) THEN RETURN,C	;EXIT IF NO ERROR ESTIMATES.
;
	IF N GT M THEN $
		SIGMA = TOTAL((YFIT-Y) ^ 2) / (N-M) $	;COMPUTE SIGMA
	   ELSE	SIGMA = 0.
;
	A=A* SIGMA		;GET CORREL MATRIX
;
	SIGMA = SQRT(SIGMA)
	YBAND = FLTARR(N)+ A[0,0]	;SQUARED ERROR ESTIMATES
;
	FOR P = 1,2*NDEGREE DO BEGIN
	  Z = XX ^ P
	  SUM = 0.
	  FOR J=0 > (P - NDEGREE), NDEGREE < P DO SUM = SUM + A[J,P-J]
	  YBAND = YBAND + SUM * Z ;ADD IN ERRORS.
	END		;END OF P LOOP
	YBAND = SQRT(ABS(YBAND))	;ERROR ESTIMATES
	RETURN,C
END
