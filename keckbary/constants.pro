pro constants

; To use this program, first call it w/in your program w/o arguements
; Then put a line in your program identical to the one below:

common CONSTANTS,autom,automJPL,autokm,cms,ckm,radtosec,pctoAU,$
	yeartosec,yrtos,ltyr,lightyear,pctom,secperday,daytosec,$
	century,precise,ddtor,msun,msung,mearth,mmoon,$
	mmoong,rearth,rearthkm,rsun,rsunkm,Gcgs,G,angstrom

; You should probably copy the above line EXACTLY, even if you don't use
; all those constants since they will get confused otherwise.

; 1976 IAU offical constants.

autom = 1.4959787066d11			;AU to meters from de200.
automJPL=149597870.69100d3		;From de403 ephemeris
autokm=autom*1.d-3			;AU to km
cms = 2.99792458d8
ckm=cms*1.d-3				;in km/s
radtosec=206264.81d0			;arc secs in a radian
pctoAU=radtosec				;ya know.
yeartosec=365.25d0*24.d0*3600.d0		;Thats a 'Julian Year'
yrtos=yeartosec
ltyr=cms*yeartosec			;in meters.
lightyear=ltyr
pctom=pctoAU * AUtom			;meters in a pc
secperday=86400.d0			;Of TBT. see AA L1
daytosec=secperday			;for numskulls
century=36525.d0			;Days     ""
precise='(D40.30)'
ddtor=!dpi/180.d0			;duh!

;NOTE: The default for most of these constants is MKS
;these haven't been checked to carefully!

msun=1.9891d30			;kg
msung=msun*1000.d0		;g
mearth=msun/332946.0d0		;AA S7 (kg)
mearthg=mearth*1000.d0		;g
mmoon=mearth*0.01230002d0	;kg
mmoong=mmoon*1000.d0
rearth=6378140.d0		;m
rearthkm=rearth/1000.d0		;kg
rsun=6.95987d8			;m
rsunkm=rsun/1000.d0		;km
Gcgs=6.673231d-8		;dyn cm^2/gm^2
G=6.673231d-11			;N  m^2/kg^2

end
