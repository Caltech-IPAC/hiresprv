pro kbary,jdUTC,coords,epoch,cz,obs=obs,pm=pm,rad_vel=rad_vel,ha=ha,$
          parlax=parlax,classical = classical,Vxyz=Vxyz,SR=SR,$
          GR=GR,slow=slow,barydir=barydir,ptrans=ptrans

; Barycentric Correction Program   For the Keck
; IMPORTANT NOTE: This program does not by itsself remove secular
; acceleration. That is done by rm_secacc.pro, which is called by (u/k)barylog
; This new version of KBARY accepts coordinates from keck_st.dat,
; with ASSUMED equinox 2000.  EPOCH may of coords vary, but is usually
; 2000.0


;		ERROR CHECK
if n_params() lt 4 then begin
    print,''
    print,'SYNTAX:   kbary,jd,coords,epoch,cz,[obs=],[ha=],'+$
      '[Vxyz=],[pm=],[parlax=],[rad_vel=]'
    print,' '
    print,'INPUT:    jd = julian date (double precision) eg 2448489.3462d0 '
    print,'          coords = RA & DEC, in [hours,degrees] eg. [1.75,-15.9d]'
    print,'          EPOCH = for which coords are valid, eg. 2000.'
    print,'          obs = observatory [optional] (default is CFHT~Keck)'
    print,'          pm = proper motion [ra,dec] in ARCsec/year [optional]'
    print,'          rad_vel = Barycentric Radial Velocity in km/s [optional]'
    print,'          parlax = parallax in arc sec [optional]'
    print
    print,'OUTPUT:   cz = c * z in m/s.  (z = relativistic redshift)'
    print,'          vxyz = [Vx,Vy,Vz] in m/s (z = NCP, etc) [opt.]'
    print,'          ha = hour angle of observation [opt.]'
    print,''
    print,'EXAMPLE: kbary,jdate([1995,7,21,13,55]),[1.75,-15.9],2000,cz'
;  print,'RESULT : cz = 26136.06 m/s'
    return
endif
;
;  DEFINE CONSTANTS	 (From AA Sup '92, p.693)
c       = 2.997924580000d5      ; in km/s 
DtoR    = !dpi/180.d0			; !dtor is not double
constants                       ; Load in constants as a common block
common CONSTANTS,autom,automJPL,autokm,cms,ckm,radtosec,pctoAU,$
  yeartosec,yrtos,ltyr,lightyear,pctom,secperday,daytosec,$
  century,precise,ddtor,msun,msung,mearth,mmoon,$
  mmoong,rearth,rearthkm,rsun,rsunkm,Gcgs,G,angstrom

covec   = coords                ; prevent changing coords
LAST    = 0.d0 &  Vparalax= 0.d0 ; Initialize
if n_elements(parlax) eq 0 then parlax = 0
N = reform([1.d0,0,0,0,1.d,0,0,0,1d],3,3) ; Identity Matrix
Ndot = dblarr(3,3) & eqeq = 0.d0 

if keyword_set(slow) then slow = 1 else slow = 0 ; Can Reduce # of Ephem Calls
if n_elements(barydir) eq 0 then barydir = getenv("MIR3_BARY")

;		MAKE SURE DATE IS DOUBLE PRECISION

if datatype(jdUTC) ne 'DOU' then message,		$
  'JD should be double precision.  Expect Errors of 20 m/s!',/info
jdt = total(jdUTC)              ; jdUTC can be double(2)

;		CALCULATE BARYCENTRIC VELOCITY OF EARTH, in 2000 COORDS.
;
timeconv,jdUTC,jdTDT,TDB=jdTDB  ; Convert to TDT & TDB timescales
jplaneteph,'Earth','SSB',jdTDB,pos,Vorbday,barydir=barydir ; JPL Ephemeris takes TDB
Vorb = Vorbday/secperday        ; Convert to AU/sec
Vorbms = Vorb*autokm*1.d3       ; Convert to m/s 

;		GET OBSERVATORY LATITUDE, LONGITUDE & HEIGHT
;
if n_elements(obs) eq 0 then obs = 'CFHT' else begin ; default site is Keck 10-m
    if strupcase(obs) eq 'KECK' then obs = 'CFHT'
    if strupcase(obs) ne 'CFHT' then message, /info, $
      '**You are running KBARY, but your observatory is: '+obs+' !!'
endelse
obssite,obs,lat,lon,ht			; lat,lon in RADIANS,ht. in m
height = ht/1000.d0				; Convert to km

;  		CALC ROTATION VEL. OF OBSERVATORY, using Loc. App. Sid. Time
;
local,jdt,-lon/!dtor,lmst,soltosid ; Local MEAN sidereal time
LAST = lmst + eqeq				; APPERENT s.t.  (ignorning eeqdot!)
ha = lmst - covec(0)            ;should this be covecp?  (in HOURS, not used in calcs)
spinvel,lat,height,SOLtoSID,LAST,Vrot,obspos=obspos ; Vrot in KM/s obs in KM

;  		COMPUTE MATRICIES OF NUTATION AND PRECESSION (N & P)
;
jnutation,jdTDT,N,Ndot=Ndot,eqeq=eqeq,barydir=barydir
precession,jdTDT,P
R = P ## N				        ; R-matrix (tabulated in AA B47)

;		PRECESS & NUTATE Vrot TO 2000, AND ADD TO Vorb (&convert to meters/s)
;
; Vrotms = (R ## Vrot + Rdot ## obspos/secperday) * 1.d3;infintesimmally mre precise.

Vrotms = (R ## Vrot ) * 1.d3  
Vtot = Vorbms + Vrotms          ; Classical formula OK here
; from now on use these primed quantities (xyzp & covecp)
ra = covec(0) * dtor * 15d0     ; ra is in RADIANS
dec = covec(1) * dtor           ; dec is in RADIANS
xyz = [cos(ra)*cos(dec),sin(ra)*cos(dec),sin(dec)] ; EQNX pos. of star (eg 2000)
xyzold = xyz

; If needed, correct coordinates from barycentric to geocentric (ie
; account for parallax.  Only affects ~10 stars ; (New 8/2002)
if parlax ge 0.3 then begin     ;  if <0.3, (dV < 5 cm/s annual) ignore
    xyzearth = pos              ; in AU; Compute barycentric position of star and earth in AU
    xyzstar = xyz * (1.d0/parlax) * pctoau
    Gxyzstar = xyzstar - xyzearth ; geocentric stellar position
    xyz = unit(Gxyzstar)
    radians = polar(xyz)        
    covec = [radians(0)/!dtor/15.d0 ,radians(1)/!dtor]
endif

xyzp = xyz                      ; initialize [x,y,z]
covecp = covec                  ; init. [ra,dec]

;		CORRECT STAR POSITION FOR PROPER MOTION
if n_elements(pm) ne 0 AND total(abs(pm)) GT 0 then begin
    covecAD = advance(covecp,EPOCH,jdt,pm)
    raAD  = covecAD(0) * dtor * 15d0 ; 'Advanced' position
    decAD = covecAD(1) * dtor        ;  ( in RADIANS)
    xyzAD = [cos(raAD)*cos(decAD),sin(raAD)*cos(decAD),sin(decAD)] 
endif else begin                ; 0 Prop. Motion Case
    xyzAD = xyzp
endelse  
;
;		PROJECT TOTAL VELOCITY ONTO POSITION VECTOR
;
VradialAD = total(vtot*xyzAD)   ; Classical bary. corr.

;		CORRECT DOPPLER SHIFT FOR SPECIAL RELATIVITY
;
Vabs = sqrt(total(Vtot^2))      ; Absolute topocentric vel
Rvabs = Vabs^2/(2.d0*(c*1.d3)^2) ; SR ratio (time dilation)
SR = Rvabs*c*1.d3               ; SR 'cz' in m/s

;		CORRECT DOPPLER SHIFT FOR GENERAL RELATIVITY
;

if slow then Rgr = jgrav_red(jdTDT,obspos/AUtoKM,barydir=barydir) else  $
  Rgr = jgrav_red(jdTDT,obspos/AUtoKM,barydir=barydir,/fast)	
GR = Rgr*c*1.d3                 ; GR 'cz' in m/s

;		ADD RELATIVISTIC & PARALLAX CORRECTIONS TO CLASSICAL DOPPLER SHIFT
;
cz = VradialAD + SR + GR        ; + Vparalax		   ; This is the end.

end

; These Lines removed 1/2002
;dist = sqrt(total((pos*AUtoKM)^2)) ; Earth-SSB Distance in km.
;if n_elements(parlax) eq 0 then parlax = 0.d0 ; Must feed something to
;if n_elements(rad_vel) eq 0 then rad_vel = 0.d0 ;               Advance.
;    TOPOrad_vel = rad_vel       ; Initialize; NOW NOT USED
;    Vparalax = (TOPOrad_vel - rad_vel)*1000.d0 ; Topo - BC radvel, m/s ; IGNORe stellar radial V.
; (IT IS NOW ASSUMED THAT EQUINOX=2000, SO PRECESSION SECTION IS NOT NEEDED ANYMORE)
;		COMPUTE CLASSICAL RADIAL VEL, FOR HISTORIC PURPOSES  NOT USED
;Vradial = total(vtot*xyzp)      ; =~ the old bary.pro   NOT USED
;Rdot = Pdot # N + P # Ndot      ; its time derivative (NOT significant!)
