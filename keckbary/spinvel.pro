pro spinvel,lat, height, SOLtoSID, sidtime, Vspin, obspos=obspos,Vrot=Vrot

; Compute local spin velocity, Assuming an Oblate Spheriod Earth Surface.
; INPUTS:       lat:    Observatory latitude (in radians) {geocentric lat}
;            height:    Observatory height, in KM
;           sidtime:	Local Apperent Sideal Time, in hours (= LMST+Eq. Eqnxs)
; OUTPUT:     Vspin:    Earth's spin velocity, In the coordinate system
;                       specified by the TRUE equator and equinox of date
;	     obspos:	Observatory (Geocentric) Position (optional)
; NOTE: The true & apperent equator & equinox of date differ by the 
;	Equation of Equinoxes, due to nutation.  Hence the input to this
;	program is LAST, not LMST.  Using LMST could cause errors of
;	30 mm/s, According to A. Irwin. 

; REFERENCES:   AA Supp. '92,  AA p. K11-13, Irwin's earth_rotation.f
;		Older versions of bary.pro
;
if n_params() lt 5 then begin
   print,'SYNTAX: spinvel,lat, height, SOLtoSID, sidtime, Vspin, obspos=obspos
   close,/all
   stop
endif

;       DEFINE CONSTANTS

  f = 1.d0/298.257d0				   ; Flattening Factor: AA K13
  a = 6378.140d0 				   ; Def. of Eq. radius, in km (AA 94)
  J2000 = 2451545.d0  & Century = 36525.d0         ;
  HtoR = !dpi/12.d0                                ; Hours to radians.

;       CALCULATIONS

  h = double(height)                               ; Height should be in KM
  LAST = double(sidtime)*HtoR 			   ; Local Apperent Sidereal Time (in rad)
  sidday = 24.d0*3600.d0/SOLtoSID		   ; Sidereal Day.
  Prot = sidday * 1.000000097093		   ; AA Supp '92 p.48
  aC = a / sqrt(cos(lat)^2.+(1.0d0-f)^2.*sin(lat)^2.) ; a*C
  raxis = (h + aC) * cos(lat)			   ; Distance to axis
;print,' '
;print,'h aC raxis',h,aC, raxis, 'in km'
;print,'lat height',lat,height
;print,' '
  Vrot = 2.d0 * !dpi * raxis / Prot                ; Topocentric vel in KM/s
  Vspin = Vrot*[-sin(LAST),cos(LAST),0.d0]	   ; [x,y,z] Components

; POSITION OF THE OBSERVATORY wrt Vernal Equinox. (in KM)
  obspos=[Raxis*cos(LAST),Raxis*sin(LAST),(h+aC*(1.d0-f)^2)*sin(lat)]

; SOME NOTES
; 1.)  An alternative formula to the one above for a*C is:
;  aC = a/sqrt(1.d0 + (f-2.d0)*f*sin(lat)^2.)   
;  This is mathematically equal, and probably slighty better to use.
;  However they agree to ~1 micrometer, so use formula above from the AA.
; 2.)  Possible Improvement: The above calc. approximates the position of 
;  the Earth's surface (the geoid) as an oblate speriod.  In fact 
;  the geoid deviates by up to 100 meters from an OS.  The difference
;  (N) is called the 'geoid undulation', and is roughtly constant for
;  any point on earth (neglecting small tidal effects).  If we could
;  find N for our observatory, this calcuation could be improved.
; 3.) Prot above is the rotation period of the earth.  NOt the same
;  as the length of the sidreal day! Because sidday = w/ respect to the
;  Equinox which is moving 0.0084 s of RA/day, due to precession
;  (plus a little more or less due to nutation which we ignore)  We want
;  the rotation period w/ respect to the stars, not the moving eqnx.
;  Also Prot above ignores terms of order 10^-12 in Prot.  That is to say
;  the secular change in Prot by 5 microseconds/century has been neglected.
; 4.) We have also neglected in baryrel the deriviative of the equation
;   of equinoxes, EQdot.  Irwin reccomends feeding this routine (spinvel) 
;   with SOLtoSID + EQdot.  Since EQdot is never more than 0.2 "/century I
;   have decided to neglect it.
end
