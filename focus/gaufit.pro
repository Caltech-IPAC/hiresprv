pro gaufit,x,y,g,gpar
;
;Fit a Gaussian to points, (x,y).
;
;INPUT
;  X    input index array
;  Y    input ordinate values
;  GPAR input guesses: a(0)=amp, a(1)=center, a(2) = sigma
;
;OUTPUT
;  G    output Gaussian, evaluated at X
;  GPAR 
;
w=fltarr(n_elements(x)) + 1.
;g=curvefit(x,y,w,gpar)
A=gpar


;FUNCTION CURVEFIT,X,Y,W,A,SIGMAA
; MODIFICATION HISTORY:
;	Written, DMS, RSI, September, 1982.
;-
	ON_ERROR,2		;RETURN TO CALLER IF ERROR
	A = 1.*A		;MAKE PARAMS FLOATING
	NTERMS = N_ELEMENTS(A)	;# OF PARAMS.
	NFREE = (N_ELEMENTS(Y)<N_ELEMENTS(X))-NTERMS ;Degs of freedom
	IF NFREE LE 0 THEN STOP,'Curvefit - not enough data points.'
	FLAMBDA = 0.001		;Initial lambda
	DIAG = INDGEN(NTERMS)*(NTERMS+1) ;SUBSCRIPTS OF DIAGONAL ELEMENTS
;
;	FOR ITER = 1,20 DO BEGIN	;Iteration loop
	FOR ITER = 1,15 DO BEGIN	;Iteration loop
;
;		EVALUATE ALPHA AND BETA MATRICIES.
;
	gausscon,X,A,YFIT,PDER	;COMPUTE FUNCTION AT A.
	BETA = (Y-YFIT)*W # PDER
	ALPHA = TRANSPOSE(PDER) # (W # (FLTARR(NTERMS)+1)*PDER)
;
	CHISQ1 = TOTAL(W*(Y-YFIT)^2)/NFREE ;PRESENT CHI SQUARED.
;
;	INVERT MODIFIED CURVATURE MATRIX TO FIND NEW PARAMETERS.
;
    repcount=0  ;emergency escape from loop
	REPEAT BEGIN
		C = SQRT(ALPHA(DIAG) # ALPHA(DIAG))
repcount=repcount+1
if (min(c) le 0) or (repcount ge 100) then begin   ;escape from loop
   yfit=-1   &   goto,BOMB
endif
		ARRAY = ALPHA/C
		ARRAY(DIAG) = 1.+FLAMBDA
		ARRAY = INVERT(ARRAY)
;Constrain correction by multiplying by .8
		B = A+ 0.8*ARRAY/C # TRANSPOSE(BETA) ;NEW PARAMS
;Constrain B
        if b(2) lt 0. then b(2)=.001
		gausscon,X,B,YFIT		;EVALUATE FUNCTION
		CHISQR = TOTAL(W*(Y-YFIT)^2)/NFREE ;NEW CHISQR
		FLAMBDA = FLAMBDA*10.	;ASSUME FIT GOT WORSE
		ENDREP UNTIL CHISQR LE CHISQ1
;
	FLAMBDA = FLAMBDA/100.	;DECREASE FLAMBDA BY FACTOR OF 10
	A=B			;SAVE NEW PARAMETER ESTIMATE.
;	PRINT,'ITERATION =',ITER,' ,CHISQR =',CHISQR
;	PRINT,A
	IF ((CHISQ1-CHISQR)/CHISQ1) LE .001 THEN GOTO,DONE ;Finished?
	ENDFOR			;ITERATION LOOP
;
	message, 'Failed to converge', /INFORMATIONAL
;
DONE:	SIGMAA = SQRT(ARRAY(DIAG)/ALPHA(DIAG)) ;RETURN SIGMA'S
BOMB:   gpar=a
        g=yfit

return
end;
