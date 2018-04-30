pro precession,JD,P,Pdot=Pdot

; Calculate the precession matrix P, and its time derivative, Pdot.
; J2000 coordinates [XYZ] can be mulitplied by P to obtain "of date"
; coordinates, referred to JD.  To perform the reverse opperation,
; use transpose(P).  Pdot is used to transform velocity vectors when high
; precision is needed.  See AA B19. & 1984 AA S19.  Other references:
; Lieske (1979 a&a 73, 282) Standish (1982 a&a 115, 20), AA Supp '92!
;
; INPUT:    JD:   Julian Date of Epoch to Transform to. (eg 2441234.43214d0)
; OUTPUT:    P:   Precession Matrix (3,3)  
;	  Pdot:   Deriv. of Precession Matrix w/ respect to time (in 1/centuries)
;
; CALLING SEQUENCE: precession,jd,P,Pdot=Pdot
;
if n_params() lt 2 then begin
   print,'SYNTAX:  precession,JD,P,Pdot=Pdot
   close,/all & Retall
endif
; 	SET UP A MATRIX OF COEFFICIENTS OF POWERS OF t
  coefs = [ 2306.2181d0,  0.30188d0,  0.017998d0,  $  ; Use 1984 AA S19 with T = 0, 
	    2306.2181d0,  1.09468d0,  0.018203d0,  $  ; More sig figs than B19
	    2004.3109d0, -0.42665d0, -0.041833d0 ]

  coefs = reform(coefs,3,3)
  RADtoSEC = 206264.806247096363d0			;3600*180/pi
  zeta = 0.d & theta = 0.d & z = 0.d & P = dblarr(3,3)	;initialize angles
  dzeta = 0.d & dtheta = 0.d & dz = 0.d	& Pdot = P	;initialize angle-dots
  JD2000 = 2451545.d0					;JDate of Standard Epoch
  century = 36525.000000000d0				;The unit of time.
  t = (JD - JD2000) / century				;Centuries since 2000
  angles = transpose(coefs) # [t,t^2.,t^3.] / RADtoSEC		;
  anglesdot =transpose(coefs) # [1.d,2.d*t,3.d*t^2.]/(RADtoSEC*century)	;Derivative of angles
  zeta = angles(0) & z = angles(1) & theta = angles(2) 		; Parse vectors
  dzeta=anglesdot(0) & dz=anglesdot(1) & dtheta=anglesdot(2)	; dzeta/dt, etc.

; 	CONDENSE NOTATION
  szeta = sin(zeta)   &  czeta = cos(zeta)      	
  sz = sin(z)         &  cz = cos(z)            	
  stheta = sin(theta) &  ctheta = cos(theta)

  A = szeta * sz  &  B = czeta * sz
  C = szeta * cz  &  D = czeta * cz

; 	COMPUTE PRECESSION MATRIX, (See AA B18)
  P = [ D*ctheta - A,    B*ctheta + C,    czeta*stheta, $
       -C*ctheta - B,   -A*ctheta + D,   -szeta*stheta, $
       -stheta*cz,      -stheta*sz,       ctheta ]
  P = reform(P,3,3)

;        COS               and        SIN     DERIVIATIVES
  dczeta  = -szeta*dzeta    &  dszeta  = czeta*dzeta
  dctheta = -stheta*dtheta  &  dstheta = ctheta*dtheta
  dcz     = -sz*dz 	    &  dsz     = cz*dz

; COMPUTE DERIVIATIVE OF PRECESSION MATRIX WRT TIME. (lots of chain rules)
   
 pdot= reform(								 $	
 [dczeta*ctheta*cz+czeta*dctheta*cz+czeta*ctheta*dcz-dszeta*sz-szeta*dsz,$
  dczeta*ctheta*sz+czeta*dctheta*sz+czeta*ctheta*dsz+dszeta*cz+szeta*dcz,$
  dczeta*stheta+czeta*dstheta,	               				 $
 -dszeta*ctheta*cz-szeta*dctheta*cz-szeta*ctheta*dcz-dczeta*sz-czeta*dsz,$
 -dszeta*ctheta*sz-szeta*dctheta*sz-szeta*ctheta*dsz+dczeta*cz+czeta*dcz,$
 -dszeta*stheta-szeta*dstheta,   -dstheta*cz-stheta*dcz,		 $
 -dstheta*sz-stheta*dsz,  dctheta],3,3)

end
