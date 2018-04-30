pro local,tjdut1, olong, xlst, sdd

; calculate local mean sidereal time xlst (hours), and the derivative
; of local mean sidereal time wrt mean solar time = ratio of 
; sidereal to solar time sdd (sidereal time units/solar time units)
; This is basically a copy of local_mean_sidereal_time.f of A. Irwin.
; However I am confident it is accurate.  I agrees w/ our old sidrl.pro
; in all regimes tested.  I have a routine sidereal.pro
; which is based on the Exp. Supp. AA, 92, but presently it is off by
; a time lag.  Working..

;INPUTS
;	tjdut1 = julian day number
;	olong = WEST longitude in degrees.
;OUTPUTS
;	xlst = local mean sidereal time (hours)
;	sdd	sol to sid ratio (almost constant)

;tu is the interval of time measured in Julian centuries of
;36525 days of UT (mean solar days) elapsed since epoch 2000,
;January 1d 12h UT.  From Astronomical Almanac, 1991, B6.
;tu0 is tu evaluated for previous midnight
;dtu = tu-tu0
;NOTE: In most books Tu means what this program calls Tu0 and what
;	most books call T, this prog. calls Tu   :)

century = 36525.000d0
SECperDAY = 86400.d0
SECperCEN = SECperDAY * century
a = 24110.548410d & b = 8640184.812866d0
c = 0.093104d0 & d = -6.2d-6
bprime = 1.0 + b/SECperCEN
cprime = 2.d0*c/SECperCEN
dprime = 3.d0*d/SECperCEN

;dtim is fraction of day beyond 0 UT1.
dtim = (tjdut1-0.50d) mod 1.d0
if dtim lt 0.d0 then dtim = dtim + 1.d0
if dtim ge 1.d0 then dtim = dtim - 1.d0
tu0 = (tjdut1-2451545.0d0-dtim)/century		;Tu
tu = (tjdut1-2451545.0d0)/century		;T
dtu = dtim/century
gmst0 = (a + tu0*(b + tu0*(c + tu0*d)))/SECperDAY ; gmst0 (gst of previous midnight) in days.
sdd = bprime + tu*(cprime + tu*dprime)
dxlst=1.002737909350795d0 + tu*(5.9006d-11 - 5.9d-15*tu)
dxlst2=1.002737909350795d0 + 5.9006d-11*tu - 5.9d-15*tu^2
;the above are the same to machine precision (16 decimals)
;expand differences of various powers of tu and tu0.
;note gst ~ gmst0 + dtim*sdd (old formula).

;GMST1 = GMST0 + dtim * (r')
gst=gmst0+dtu*(SECperCEN + b + c*(tu+tu0) + d*(tu*tu + tu*tu0 + $
	tu0*tu0))/SECperDAY
xlst=gst-olong/360.d0
;convert lst from days to hours.

xlst=(xlst-floor(xlst))*24.0d0				;floor not= fix!!!!
if xlst lt 0.0d0  then xlst = xlst + 24.0d0
if xlst gt 24.0d0 then xlst = xlst - 24.0d0
end
