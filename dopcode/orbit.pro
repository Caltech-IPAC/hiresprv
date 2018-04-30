function orbit,t,par, medt=medt
; result = rv_drive,t,[P,tp,e,om,K]
; Driver for rv.pro.
; Converting from values given, to those used by rv.pro.
;
; Now construct a(relative), i, m1, and m2 from P, e, and K.
; First some assumptions:
; 1) Assume that sin(i)=1

p = double(par[0])    ;period
tp = double(par[1])   ;time of periastron
e = double(par[2])    ;eccentricity
om = double(par[3])   ;little omega
k = double(par[4])    ;Vel amplitude
gamma = double(par[5]) ;center of mass vel
t = double(t)

;Ensure positivity --- even if a kludge
if p le 0. then p = max(t) - min(t)
if tp le 0. then tp = t(0)
if e lt 0. then e = 0.03
if e gt 0.999 then e = 0.99
if k le 0. then k = 10.

i=double(90.0)
sini = 1.d0

; 2) Assume that the mass ratio, (m2/(m1+m2))=0.5
 mrat=0.5d0
;
; Calculate a1
 Ps=P*24.d0*3600.d0	;converting P to seconds
; a1 = abs(K)*abs(Ps)*sqrt(1-e^2)/(2.*!pi*sin(i))
 a1 = abs(K) * Ps * sqrt(1-e^2)/(2.d0*!pi*sini)
; Calculate a(relative)
 a=a1*sini/mrat

; Calculate the sum of the masses
 G=6.6725985d-11			;m^3/(kg*s^2)
 msum=4.d0*!pi^2*a^3/(G*Ps^2)

; Calculate m2
 m2=mrat*msum

; Calculate m1
 m1=msum-m2

; Establish a value for the remaining two variables, bigom and cmvel
 bigom=0.0
 cmvel=.0
;
if m1 le 0 or m2 le 0. then stop
rv,t,P,tp,e,om,a,i,m1,m2,bigom,cmvel,vel

vel = vel+gamma

if n_elements(par) eq 7 and n_elements(t) gt 2 then begin
    if 1-keyword_set(medt) then medt = median(t)
    vel = vel + par[6]*(t-medt)
endif
return,vel
end
