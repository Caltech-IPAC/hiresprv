pro jnutation,jld,N,pinfo=pinfo,pdata=pdata,Ndot=Ndot,eqeq=eqeq,$
              eqdot=eqdot,barydir=barydir,      deleps=deleps

; REPLACES nuation.pro

; Compute a matrix of nutation, N, and its time derivative, Ndot.  This matrix
; is applied to J2000 [x,y,z] coordinates to obtain coordinates of date (jld)
; Time derivative matrix (Ndot) is used for nutating velocities when high
; precision is needed.  It is in fact superflous at the level of 0.001
; m/s. Nutation in longitude (deltapsi) and in 
; obliquity (deltaeps) are obtained from the JPL Ephemeris, via IDL
; Ephemeris reading programs
;
; INPUT:        JLD:  Julian Date.  Double.  Double(2) for high precision.
; OUTPUTS: 	  N:  3x3 Nutation matrix.  See AA 1989, B20
;  (optional)  NDOT:  3x3 Time Deriv. of N, in units of 1/julian centuries.
;  (optional)  EQEQ:  Equation of Equinoxes, in Hours
;  (opt)    BARYDIR:  Directory in which barycode resides
;
; Tested against previous FORTRAN based nutation.pro to many sig figs.
;References: AA, '89, B18,B20, AA '84 S26 & premat.pro

; Create: CMc 9/94. Ndot (based on nutation.f, A. Irwin) Modified
; 3/95, 5/96 To use etoile-compile fortran programs.  5/2001: To
; generate a random (temporary) file name.  3/2003: To drive IDL
; ephem.  NOTE: Nutation has an 18 year period amplitude= 9".
; Emperical test over entire Keck data string showed the effect of not
; accounting for Nutation is about 0.035 m/s Also, we presently ignore
; EQDOT, a sub-mm/s effect, see Exp.Sup.AA
;
;        ERROR CHECKING
if n_params() lt 2 then begin
    print,'SYNTAX: nutation,JD,N,Ndot=Ndot,eqeq=eqeq,eqdot=eqdot'
    stop                        ; 
endif

N = reform([1,0,0,0,1,0,0,0,1],3,3) ;initiallize
Ndot = dblarr(3,3) & eqeq = 0.d0 & eqDot = 0.d0	;init
ephemeris = getenv("BARY_JEPHEM")
;ephemeris = 'JPLEPH.405'

if vartype(jld) ne 'DOUBLE' then begin
    message,'Julian Date Must be specified DOUBLE precision',/info
    message,'Returning Identity matrix.',/info
    GOTO, FIN					;use 'return' instead?
endif

;  	PRELIMINARY
J2000 = 2451545.d0              ; Equinox 2000 Julian date
jd = double(total(jld))			

if jd lt 2440000.d0 then message,'Strange JD: '+string(jld),/info

RADtoSEC = 206264.806247096363d0 ; Arc Seconds in a Radian
RADtoHR = RADtoSEC / 3600.d0 /15.d0 ; Hours in a radian
c = [84381.448d0,-46.8150d0,-0.00059d0,0.001813d0] ;coefs. see:AA 1984, S26 
century = 36525.d0              ; days per Julian Century
T = (jd - J2000) / century      ; # of Julian Centuries
output = strarr(6)              ; Output of jplnutate (initialize) 
delpsi = 0.d0 & deleps = 0.d0   ; DeltaPsi & DeltaEpsilon
delpsidot = 0.d0 & delepsdot = 0.d0 ; Derivatives.


; 	EPSILON = EXACT OBLIQUITY OF THE ECLIPTIC (~23.5 degrees)
eps = total(c * [1.d0,T,T^2,T^3]/RADtoSEC) ; Power series in T
epsdot = total(c * [0.d0,1.d0,2.d0*T,3.d0*T^2]/(RADtoSEC*century)) ; Deriv. wrt T
;

;   DELEPS & DELPSI
;   The earth nutation angles DELpsi (nutation in longitude) and
;   DELepsilon (nutation in obliquity) are returned in X and Y, in
;   units of radians.  Their time derivatives are returned in VX and
;   VY respectively.  The quantities returned in Z and VZ are
;   undefined.

if n_elements(pinfo) eq 0 or n_elements(pdata) eq 0 then begin
    jdrange = [jd-0.5d0,jd+0.5d0] ; Must feed ephem range over which to interp.
    jplephread, ephemeris, pinfo, pdata, jdrange
endif

jplephinterp, pinfo, pdata, jd, delpsi, deleps, dummy1 , delpsidot, delepsdot, $
  dummy2, objectname = 14  ;  dummy's are always 0

;	 NOW GENERATE NUTATION MATRIX
;
N = [    1.d0,       -delpsi*cos(eps),  -delpsi*sin(eps), $
         delpsi*cos(eps),    1.d0,          -deleps,	    $
         delpsi*sin(eps),   deleps,         1.d0              ] 
N = reform(N,3,3)
;
;	TIME DERIVATIVE OF NUTATION MATRIX (just use chain rule)
;     (this is irrelevant at the 0.001 m/s level)
Ndot = reform([0.d0,-delpsidot*cos(eps)+delpsi*sin(eps)*epsdot, $
               -delpsidot*sin(eps)-delpsi*cos(eps)*epsdot,	  $
               delpsidot*cos(eps)-delpsi*sin(eps)*epsdot,	  $
               0.d0,	-delepsdot,				  $
               delpsidot*sin(eps)+delpsi*cos(eps)*epsdot, 	  $
               delepsdot, 0.d0],3,3)

eqeq =  delpsi * cos(eps + deleps) * RADtoHR ; Eqn of Eqnxs in hours
eqdot = delpsidot * cos(eps + deleps) - delpsi * $ ; & Its derivative. 
  sin(eps + deleps) * (epsdot + delepsdot)
FIN:
end

