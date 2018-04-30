pro jplaneteph,targ,cent,jdt,pos,vel,ephemeris=ephemeris,mks=mks,$
               noclean=noclean,barydir=barydir

; Computes the position and velocity of TARGET with respect to CENTER
; (in AU and AU/DAY) using JPL Planetary Ephemeris.  Drives programs
; JPLEPHREAD & JPLEPHINTERP    ; replaces planeteph.pro   with all IDL version

;IDL>   JPLEPHREAD, 'JPLEPH.200', pinfo, pdata, [2451544D, 2451545D]
;IDL>   JPLEPHINTERP, pinfo, pdata, 2451544.5D, xearth, yearth, zearth, $
;                 /EARTH, posunits='AU'
; Sample jdrange: [2451544D, 2451545D]

target = strupcase(targ) & center = strupcase(cent)
if target  eq 'SSB' then target = 'SOLARBARY'
if center  eq 'SSB' then center = 'SOLARBARY'

ephemeris = getenv("BARY_JEPHEM")
;ephemeris = 'JPLEPH.405'
if (findfile(ephemeris))(0) eq '' then message,ephemeris+' not found. Wrong directory?"
jdrange = [jdt-0.5d0,jdt+0.5d0]   ; Must feed ephem range over which to interp.
jplephread, ephemeris, pinfo, pdata, jdrange

jplephinterp, pinfo, pdata, jdt, xpos, ypos, zpos, Vx, Vy, Vz, objectname = $
   target, center = center,posunits='AU',/velocity,velunits = 'AU/DAY'

pos = [xpos,ypos,zpos]
vel = [Vx, Vy, Vz]

end

;IDL>   JPLEPHINTERP, pinfo, pdata, 2451544.5D, xearth, yearth, zearth, $
;                 /EARTH, posunits='AU'
