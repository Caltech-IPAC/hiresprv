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
if letters eq 'rh' and numbers ge 16 and numbers lt 21 then dwr=1
if letters eq 'rh' and numbers gt 20 and numbers lt 25 then dwr=2
if letters eq 'rh' and numbers ge 25 then dwr=6
if letters eq 'rh' and numbers eq 86 then dwr=8
if letters eq 'rh' and numbers eq 87 then dwr=8
;
if letters eq 'ra' and numbers lt 11 then dwr=6
if letters eq 'ra' and numbers ge 11 and numbers lt 18 then dwr=13
if letters eq 'ra' and numbers ge 18 then dwr=8
;
if letters eq 'rb' and numbers lt 2 then dwr=8
if letters eq 'rb' and numbers ge 2 then begin
   dwr=39
   if numbers lt 14 then gain=1.33 else gain=2.66
endif
;
if letters eq 'rc' and numbers ge 89 then begin
   dwr=39
   gain=2.66
endif
if letters eq 'rc' and numbers ge 40 and numbers lt 89 then dwr=8
if letters eq 'rc' and numbers le 39 and numbers ge 22 then dwr=98
if letters eq 'rc' and numbers le 21 then dwr=99
;
if letters eq 'rx' then begin
   dwr=39                         ;Dewar #13, New Hamilton!
   gain=1.33
endif
;
if letters eq 'rz' then begin     ;UCLA, Chris McCarthy, Ben Zuckerman
   dwr=39
   gain=2.66
endif
;
if letters eq 'rk' then begin
   dwr=101                        ;Geoff Marcy Keck Hi-Res seismology data
   gain=2.38                      ;Paul guess, get real value!
   if numbers ge 5 then begin
      dwr=102
      gain=4.76                   ;Geoff guess, get real value!
   endif
endif
;
telescope = 'SHANE'
if letters eq 'rk' then telescope = 'KECK'
if letters eq 'rc' then telescope = 'CAT'
if letters eq 'rc' and numbers eq 91 then telescope = 'SHANE'
if letters eq 'rz' then telescope = 'CAT'    ;Chris McCarthy, UCLA
;
if letters eq 'rb' then begin
   if numbers ge  5 and numbers le  9 then telescope = 'CAT'
   if numbers ge 11 and numbers le 13 then telescope = 'CAT'
   if numbers eq 15 then telescope = 'CAT'
   if numbers ge 17 and numbers le 18 then telescope = 'CAT'
   if numbers eq 20 then telescope = 'CAT'
   if numbers ge 22 and numbers le 25 then telescope = 'CAT'
   if numbers eq 27 then telescope = 'CAT'
   if numbers eq 28 then begin
      obs=fix(strmid(tpname,5,3))
      if obs lt 51 then telescope = 'CAT'
      if obs gt 88 then telescope = 'CAT'
   endif
   if numbers eq 29 then telescope = 'CAT'
   if numbers ge 31 and numbers le 32 then telescope = 'CAT'
   if numbers eq 34 then telescope = 'CAT'
   if numbers eq 38 then telescope = 'CAT'
   if numbers ge 40 and numbers le 41 then telescope = 'CAT'
   if numbers ge 43 and numbers le 46 then telescope = 'CAT'
   if numbers ge 55 and numbers le 58 then telescope = 'CAT'
endif
;
if letters eq 'rh' then begin
   if numbers ge 25 and numbers le 29 then telescope = 'CAT'
   if numbers ge 39 and numbers le 49 then telescope = 'CAT'
   if numbers ge 54 and numbers le 59 then telescope = 'CAT'
   if numbers ge 69 and numbers le 72 then telescope = 'CAT'
   if numbers ge 74 and numbers le 76 then telescope = 'CAT'
   if numbers ge 81 and numbers le 83 then telescope = 'CAT'
   if numbers ge 86 and numbers le 87 then telescope = 'CAT'
   if numbers eq 98 then telescope = 'CAT'
endif
;
if letters eq 'ra' then begin
   if numbers ge  4 and numbers le  6 then telescope = 'CAT'
   if numbers ge 23 and numbers le 31 then telescope = 'CAT'
   if numbers ge 33 and numbers le 38 then telescope = 'CAT'
   if numbers ge 43 and numbers le 48 then telescope = 'CAT'
   if numbers ge 52 and numbers le 54 then telescope = 'CAT'
   if numbers ge 57 and numbers le 62 then telescope = 'CAT'
   if numbers ge 64 and numbers le 66 then telescope = 'CAT'
   if numbers ge 72 and numbers le 80 then telescope = 'CAT'
   if numbers eq 87 then telescope = 'CAT'
   if numbers ge 90 and numbers le 97 then telescope = 'CAT'
endif

return,dwr
end

