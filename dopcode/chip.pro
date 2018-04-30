function chip,tpname,gain,telescope,wav_scale,slit,mask
;  this routine figures out which dewar (chip) was used on a 
;  give observation
;  tpname is an input string (i.e.  'rh84.23' ...  'ra25.41')
;  dwr is an output integer (i.e. 1 or 2  or 6 or 8 or 13)
;  wav_scale (output) wavelength scale appropriate for chip

letters=strmid(tpname,0,2)
numbers=fix(strmid(tpname,2,2))
dwr=-1
gain=2.5

; New defaults are Keck, post-upgrade
dwr=103       ;Post-fix HIRES chip
gain=2.19     


if letters eq 'rj' then begin ; default is same as 'rj'
   dwr=103       ;Post-fix HIRES chip
   gain=2.19     
endif

if letters eq 'rk' then begin
   dwr=101                        ;Geoff Marcy Keck Hi-Res seismology data
   gain=2.38                      ;Paul guess, get real value!
   if numbers ge 5 then begin
      dwr=102
      gain=4.76                   ;Geoff guess, get real value!
   endif
   if numbers eq 25 then begin
      obs=fix(strmid(tpname,5,3))
      if obs ge 489 and obs le 496 then gain = 2.38 ;HIRES crash night!
   endif
   if numbers eq 39 then begin
      obs=fix(strmid(tpname,5,3))
      if obs ge 347 and obs le 349 then gain = 2.38 ;High Gain Test!
   endif
   if numbers eq 43 then begin
      obs=fix(strmid(tpname,5,3))
      if obs ge 111 and obs le 114 then gain = 2.38 ;High Gain Test!
   endif
endif
telescope='Keck'


return,dwr
end



