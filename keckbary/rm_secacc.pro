function rm_secacc,cz,pm,plx, jd,sa

; Remove secular acceleration (S.A.), ie subtract a slope from  a dataset,
; one point at a time.  This is normally called after a call to bary.

; INPUTS:
;    CZ:   c * z, output from bary
;    pm:   Proper motion in "/year [ra,dec]
;   plx:   Parallax in "
;    jd:   JD - 2440000 for the observation

; Use 2000 as the reference epoch.  Ie, in 2000 the effect of
;    S.A. will be zero
; Checks & Balances:  Must avoid outrageous S.A. induced by spuriously
;    small parallax.  There are only 3 stars in all of the HIPPARCOS
; catalog with S.A. > 15 m/s/year.  Hence if your SA is > 15 something
; must be wrong.
; NOTE: S.A. should already be set to 0. for plx =0 stars anyway.
; NOTE: Could use .secacc tag in structure but use input parallax and p.m.
; 1/2003 Changed to be independent of structure (Lick/Keck/AAT)
; Note: 1 lick star has PM> 10 m/s/year!
minplx = 0.010
maxSA = 15.                     ;   m/s/year 

if jd gt 2440000.d0 then message,'Use JD-2440000.d0'
J2000 = 2451545.0d0    
mjd2000 = J2000 - 2440000.d0


if plx lt minplx then slope = 0.0  else begin
    slope =  0.0458/2. * total(pm*pm)/plx
    slope = slope > 0.0         ; ignore negative slopes
endelse

if slope gt maxSA then begin
    print,'Secular Acceleration Value too Large: ',slope
    print,'Something must be wrong. Resetting SA = 0'
    slope = 0
endif

deltat = (jd  - mjd2000)/365.25d0 ; in years.
sa_effect = slope * deltat
SA = sa_effect
newcz = cz - sa_effect

return,newcz
end
