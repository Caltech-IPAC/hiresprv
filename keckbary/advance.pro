function advance,radec,epoch0,jdnow, pm,p=p,nov=nov,silent=silent,verbose=verbose

; 2003 version. ADVANCES coordinates from EPOCH0 (usually 2000) to JDNOW
;
; Differs from earlier (~1999-2000) versions:
; --Designed to mesh with new version of bary (which uses fixed EQUINOX=2000)
; --Fixed cos(dec) omission  
; --input PM is in "/YEAR
; --Just corrects for proper motion, not parallax (which is done in (u/k/_)bary.pro)
; --Removed "velocity parallax" calculation previously invoked for
;      close, fast stars.
; --Input variables radvel,pi, * Eb eliminated: not needed: Have only
;      minscule (<0.05m/s) for even close stars like tau ceti
;
; OUTPUT variable:  radecp = [RAprime,DECprime]   
; REFERENCE:      Astronomical Almanac, 1994.  p. B39 (Please read!)
;                 See also Explanatory Supp. to AA, 1992.
;
if n_params() ne 4 then begin
    print,'SYNTAX:  newradec=advance(radec,epoch0,jdnow,pm)
    print,''
    print,'    RADEC:  Initial RA and DEC in decimal  [Hours.hhh,Degrees.ddd]
    print,'   EPOCH0:  Initial Coordinate Epoch in years (usually 2000.0)
    print,"    JDNOW:  Julian Date (double precision scalar) of tonight's observation"
    print,'       PM:  Proper motion of star [MUa,MUd] in *ARC* sec/year
    print,''
    print,'OUTPUT newradec:  [RAprime,DECprime]   '
    retall
endif
;
;       DEFINE CONSTANTS 
constants
common CONSTANTS,autom,automJPL,autokm,cms,ckm,radtosec,pctoAU,$
  yeartosec,yrtos,ltyr,lightyear,pctom,secperday,daytosec,$
  century,precise,ddtor,msun,msung,mearth,mmoon,$
  mmoong,rearth,rearthkm,rsun,rsunkm,Gcgs,G,angstrom

;        CHECK  DOUBLE PRECISION & EPOCH
radec = double(radec) & jdnow = double(jdnow) 
if keyword_set(verbose) then if epoch0 ne 2000.0 then message,/info,$
 'Advancing from: '+strtrim(epoch0,2)+' (not 2000) to present epoch.' ; CHECK


; DEFINE COORDINATES (radians) AND PROPER MOTION (radians/year)
; NOTE: We use radians/year rather than /century
a0 = radec(0)*15.d0*ddtor & d0 = radec(1)*ddtor 
MUra =  (double(pm(0))/PCtoAU)/cos(d0) ; *NOTE COS(Dec) FACTOR*
MUdec =  double(pm(1))/PCtoAU
Vpi = 0.d0   ; V * pi Done for safety (see below)

; FORM COMPONENTS OF CARTESIAN POSITION (q) & SPACE VELOCITY VECTOR, (m)
q = [cos(a0)*cos(d0),sin(a0)*cos(d0),sin(d0)] ; [x,y,z] position unit vector
;
dxdt = -Mura * cos(d0)*sin(a0) -  MUdec * sin(d0)*cos(a0) + Vpi * cos(d0)*cos(a0) 
dydt =  Mura * cos(d0)*cos(a0) -  MUdec * sin(d0)*sin(a0) + Vpi * cos(d0)*sin(a0)
dzdt =        0.d0             +  MUdec * cos(d0)         + Vpi * sin(d0)

m = [dxdt,dydt,dzdt]    ;  Velocity in Radians/ year

;       DETERMINE TIME LAPSE (T) AND NEW STELLAR POSITION
;
jd2yr,jdnow,yearnow             ; convert JDnow to Years
T =  yearnow - Epoch0           ; Lapse in years
P = q + T*m                     ; X1 = X0 + V* dt (barycentric position)
p = unit(P)                     ; Insure p is a unit vector
radecp = polar(p)                               ; Convert to polar coords (radians)

HrDeg = [radecp(0)/(15.d0*ddtor),radecp(1)/ddtor] ; Hours and Degrees
return,HrDeg                    ; Same units as Radec
end

; SAFETY NOTE: IN priciple we should include V*pi into the space
; motion vector, as indicated in the AA p. B38. This accounts for the
; acceleration of the star's tangential velocity due to radial
; velocity trasforming into tangential velocity (and is thus the flip
; side of normal secular acceleration).  However a test showed (as
; expected) that this effect is less than 0.05 m/s over ~10 years for
; all stars on our program (max is GL699 at 0.03 m/s), so it is ignored.
; NO LONGER USED: 
; pi=double(plax/radtosec); Convert parallax to radians; not used
; v = rad_vel*SECperDAY*century/autokm;AU/cent.not used (input was km/s)
;P = q + T*m  - pi * Eb                 ; P.M. + parallax (ie geocentric position)

