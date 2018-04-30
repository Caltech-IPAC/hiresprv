pro obssite,obs,lat,lon,height

;IMPROVE: add on keck I
;Get  observatory longitude, latitude and height.
;INPUT:    OBS:   Observatory Designation.
;
;OUTPUTS:  LAT:   Latitude of observatory in radians
;	   LON:   Longitude of observatory in radians (- Means West)
;	HEIGHT:   Height in meters

if n_params() ne 4 then begin			;Error check
  print,'SYNTAX: obssite,obs,lat,lon,height'
  print,''
  print,'   OBS:   Observatory, eg. "CFHT"'
  print,'   LAT:   Latitude of observatory in radians
  print,'   LON:   Longitude of observatory in radians
  print,'HEIGHT:   Height in meters
  stop
endif  

  ht = -1                                        ;flag: no observatory yet
  obslc = strlowcase(obs)                        ;force lowercase
  if obslc eq 'lick' or obslc eq 'l3' then begin ;Lick 3-m
    lat = 0.651734547d0                          ; +37 20 29.9
    lon = -2.123019229d0                          ; 121 38 24.15 W
    ht = 1283.d0
  endif
  if obslc eq 'cfht' then begin                   ;CFHT
    lat = 0.346030917d0                           ; +19 49 34
    lon = -2.713492477d0                          ; 155 28 18 W
    ht = 4198.
  endif
  if obslc eq 'kp' then begin                     ;Kitt Peak
    lat = 0.557865407d0                           ; +31 57.8 (1991 Almanac)
    lon = -1.947787445d0                          ; 111 36.0 W
    ht = 2120.
  endif
  if obslc eq 'kitt' then begin                   ;Kitt Peak
    lat = 0.557865407d0                           ; +31 57.8 (1991 Almanac)
    lon = -1.947787445d0                          ; 111 36.0 W
    ht = 2120.
  endif
  if obslc eq 'green' then begin	  	  ; Green Bank
    lat = ten([38,26,45.48d0])*!dtor
    lon = -ten([79,50,54.53d0])*!dtor
    ht = 798.5
  endif
; Anglo-Australian Telescope
;http://www.aao.gov.au/local/www/cgt/obsguide/node5.html#SECTION00230000000000000000
  if strlowcase(obslc) eq 'aao' or strlowcase(obslc) eq 'aat' then begin
    lat = -ten([31,16,37.34d0])*!dtor 
    lon = ten([149,03,57.91d0])*!dtor
    ht = 1164.d0 
  endif

;  ADD YOUR OWN OBSERVATORY HERE:
;  if obslc eq 'My obs' then begin		
;    lat = whatever				; in radians
;    lon = something				; in radians
;    ht = very.					; in m.
;  endif

  if ht eq -1 then begin                        ;unknown observatory
    print,'OBSSITE: Unknown observatory designation: ',obs
    print,'Accepted designations: L3, Lick, CFHT, GREEN, AAT'
    retall
  endif

  height = ht
end
