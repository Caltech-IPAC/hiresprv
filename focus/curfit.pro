function curfit,x,y,w,a,sigmaa,funct=funct,quiet=quiet, $
    max_its=max_its,accept=accept
;+
; NAME:
;	CURFIT
; PURPOSE:
;	Non-linear least squares fit to a function of an
;	arbitrary number of parameters.
;	Function may be any non-linear function where
;	the partial derivatives are known or can be approximated.
; CATEGORY:
;	E2 - Curve and Surface Fitting
; CALLING SEQUENCE:
;	yfit = curfit(x,y,w,a,sigmaa)
; INPUTS:
;	X = Row vector of independent variables.
;	Y = Row vector of dependent variable, same length as x.
;	W = Row vector of weights, same length as x and y.
;		For no weighting
;		w(i) = 1., instrumental weighting w(i) =
;		1./y(i), etc.
;	A = Vector of nterms length containing the initial estimate
;		for each parameter.  If A is double precision, calculations
;		are performed in double precision, otherwise in single prec.
;
; KEYWORD PARAMTERS:
;	funct = string containing the name of the fitting function.
;	    Default = 'funct'
;	quiet = 1 to suppress printing interation information.
;	max_its = Maximum number of iterations the function will
;		do before giving up. Default=1000.
;	accept = Acceptance criterion for acceptable fit. 
;		This number is equal to the relative change in the
;		ChiSquare statistic from one iteration to the next. 
;		Default=.00001
;
; OUTPUTS:
;	A = Vector of parameters containing fit.
;	Function result = YFIT = Vector of calculated
;		values.
; OPTIONAL OUTPUT PARAMETERS:
;	Sigmaa = Vector of standard deviations for parameters
;		A.
;	
; COMMON BLOCKS:
;	NONE.
; SIDE EFFECTS:
;	The function to be fit must be defined and called FUNCT.
;	For an example see FUNCT in the IDL User's Libaray.
;	Call to FUNCT is:
;	FUNCT,X,A,F,PDER
; where:
;	X = Vector of NPOINT independent variables, input.
;	A = Vector of NTERMS function parameters, input.
;	F = Vector of NPOINT values of function, y(i) = funct(x(i)), output.
;	PDER = Array, (NPOINT, NTERMS), of partial derivatives of funct.
;		PDER(I,J) = Derivative of function at ith point with
;		respect to jth parameter.  Optional output parameter.
;		PDER should not be calculated if parameter is not
;		supplied in call (unless you want to waste some time).
; RESTRICTIONS:
;	NONE.
; PROCEDURE:
;	Copied from "CURFIT", least squares fit to a non-linear
;	function, pages 237-239, Bevington, Data Reduction and Error
;	Analysis for the Physical Sciences.
;
;	"This method is the Gradient-expansion algorithm which
;	compines the best features of the gradient search with
;	the method of linearizing the fitting function."
;
;	Iterations are perform until the chi square changes by
;	only 0.001% or until 1000 iterations have been performed.
;
;	The initial guess of the parameter values should be
;	as close to the actual values as possible or the solution
;	may not converge.
;
; MODIFICATION HISTORY:
;	Written, DMS, RSI, September, 1982.
;	Modified by D.L. Windt, AT&T Bell Labs, March, 1989.
;-
on_error,2				    ;return to caller if error
if keyword_set(funct) eq 0 then funct='funct'	; default function.
if keyword_set(max_its) eq 0 then max_its=1000.	; default iterations.
if keyword_set(accept) eq 0 then accept=.00001	; default acceptance.
a = 1.*a				    ;make params floating.
nterms = n_elements(a)			    ;# of params.
nfree = (n_elements(y)<n_elements(x))-nterms;degs of freedom.
if nfree le 0 then stop,'curfit - not enough data points.'
flambda = 0.1	    			    ;initial lambda.
diag = indgen(nterms)*(nterms+1)	    ;subscripts of diagonal elements.
for iter = 1,max_its do begin		    ;iteration loop.
    ;evaluate alpha and beta matricies....
    st=strtrim(funct,2)+',x,a,yfit,pder'
    e=execute(st)			    ;compute function at a.
    beta = (y-yfit)*w # pder
    alpha = transpose(pder) # (w # (fltarr(nterms)+1)*pder)
    chisq1 = total(w*(y-yfit)^2)/nfree ;present chi squared.
    ;invert modified curvature matrix to find new parameters...
    repeat begin
	c = sqrt(alpha(diag) # alpha(diag))
	array = alpha/c
	array(diag) = 1.+flambda
	array = invert(array)
	b = a+ array/c # transpose(beta)    ;new params.
	st=strtrim(funct,2)+',x,b,yfit'
	e=execute(st)			    ;evaluate function.
	chisqr = total(w*(y-yfit)*(y-yfit))/nfree ;new chisqr
	flambda = flambda*10.		    ;assume fit got worse
	endrep until chisqr le chisq1
    flambda = flambda/100.		    ;decrease flambda by factor of 10
    a=b				;save new parameter estimate.
    if keyword_set(quiet) eq 0 then begin
        print,'iteration =',iter,' ,chisqr =',chisqr 
        print,a 
	endif
    if ((chisq1-chisqr)/chisq1) le accept then goto,done ;finished?
    endfor					    ;iteration loop
print,'curvefit - failed to converge'
done:	sigmaa = sqrt(array(diag)/alpha(diag))	    ;return sigma's
return,yfit					    ;return result
end
