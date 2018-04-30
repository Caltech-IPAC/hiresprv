function jgrav_red,tjdtdt,obspos,average=average,fast=fast,GRsun=GRsun,$
                   barydir=barydir

; Compute Gravitational Redshift Effect on light waves arriving at
; Earth's Position at time tJDTDT.  GR effect = Sum of GM(i)/r(i) for
; each solar system body i.  See, eg.  Eq. 39 in Lindegren & Dravins,
; 2003, A&A

; INPUT:  TJDTDT: Date, in Julian days, on the TDT timescale.
;         OBSPOS: Geocentric location of Observatory.

; Version of grav_red.pro which uses the IDL implementation of the JPL
; Ephemeris (jplaneteph)
;copy of:  function gravitational_redshift(tjdtdt, dte, ifaverage)
;c	if average = 1, means calculate average effect only.
;if /fast then just do sun, moon,jup
;We do not use the average keyword, just for testing eg. against tempo.

;  CONSTANTS
 clight = 2.99792458d8
 gmsun = 1.32712438d20/clight/clight
 gmmercury = gmsun/6.0236d6
 gmvenus = gmsun/4.085235d5 
 gmmars = gmsun/3.098710d6 
 gmjupiter = gmsun/1.047355d3
 gmsaturn = gmsun/3.4985d3 
 gmuranus = gmsun/2.2869d4 
 gmneptune = gmsun/1.9314d4
 gmearth = 3.986005d14/clight/clight
 gmmoon = gmearth*0.01230002d0

 autom = clight*499.00478364d0
 ajupiter = 5.203d0*autom
 asaturn = 9.522d0*autom
 amars = 1.524d0*autom
 auranus = 19.201d0*autom
 aneptune = 30.074d0*autom
 asun = (1.d0+3.5d-7)*autom
 amoon = 3.845d8		

 jdTDT =tjdtdt   ;string conversion done in planeteph!

; First Earth
; this is(slightly) bad, actually.  It says that if earthpos is not specified, 
; then turn off earth GR.  Shouldn't.  Should just calculate Effect
; w/ lesster precision.  

 distance = sqrt(total(obspos^2))*autom
 if distance gt 0.d0 then GRearth = gmearth/distance else GRearth = 0.d0

  if keyword_set(average) then begin		;only Average
    GRsun =  gmsun/asun
    GRmoon =  gmmoon/amoon
    GRjup = gmjupiter/ajupiter
    GRsat = gmsaturn/asaturn
    GRNep = gmneptune/aneptune
    GRUran =  gmuranus/auranus
    GRmars =  gmmars/amars
    GRven =  gmvenus/asun
    GRmerc =  gmmercury/asun
  endif	else begin
    jplaneteph,'Earth','Sun',jdTDT,sunpos,vel,barydir=barydir          ;vel,barydir=barydir's not used 
    jplaneteph,'Earth','Moon',jdTDT,Moonpos,vel,barydir=barydir
    jplaneteph,'Earth','jupiter',jdTDT,Juppos,vel,barydir=barydir
    if not keyword_set(fast) then begin
      jplaneteph,'Earth','saturn',jdTDT,Satpos,vel,barydir=barydir    ;these don't matter much
      jplaneteph,'Earth','Neptune',jdTDT,Neppos,vel,barydir=barydir 
      jplaneteph,'Earth','Uranus',jdTDT,Uranpos,vel,barydir=barydir    
      jplaneteph,'Earth','Mars',jdTDT,Marspos,vel,barydir=barydir
      jplaneteph,'Earth','Mercury',jdTDT,Mercpos,vel,barydir=barydir
      jplaneteph,'Earth','Venus',jdTDT,Venpos,vel,barydir=barydir
    endif

    GRsun = gmsun/(sqrt(total((Sunpos+obspos)^2))*autom)
    GRmoon = gmmoon/(sqrt(total((Moonpos+obspos)^2))*autom)
    GRjup = gmjupiter/(sqrt(total((Juppos+obspos)^2))*autom)
    if keyword_set(fast) then begin
      GRsat = 0. & GRnep = 0 & GRuran=0. & GRmars = 0
      GRven = 0  & GRmerc = 0.
    endif else begin
      GRsat = gmsaturn/(sqrt(total((satpos+obspos)^2))*autom)
      GRnep = gmneptune/(sqrt(total((Neppos+obspos)^2))*autom)
      GRuran = gmuranus/(sqrt(total((Uranpos+obspos)^2))*autom)
      GRmars = gmmars/(sqrt(total((Marspos+obspos)^2))*autom)
      GRven = gmvenus/(sqrt(total((Venpos+obspos)^2))*autom)
      GRmerc = gmmercury/(sqrt(total((Mercpos+obspos)^2))*autom)
    endelse
  endelse

;  print,'Sun,moon,sat,jup,earth,mars,nep,uran,merc,ven'
;  print, GRsun,GRmoon,GRsat,GRjup,GRearth,GRmars,GRnep,GRuran,GRMerc,GRven

  GRtotal = GRsun + GRmoon + GRsat + GRjup + GRearth + GRmars + $
            GRnep + GRuran + GRMerc + GRven
  return,GRtotal
  end
