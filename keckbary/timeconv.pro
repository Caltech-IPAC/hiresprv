pro timeconv, UTC, TDT, UT1=UT1, TDB=TDB,silent=silent

; Convert from Coordinated Universal Time (UTC) to 
; Terrestial Dynamic Time (TDT), Barycentric Dynamic Time (TDB)
; and Universal Time (UT1).  
;
; INPUT:   UTC:  Univeral Coordinated Time, in Julian Date,
;
; OUTPUT:  TDT:  Terrestrial Dynamic Time, in JD
;	   TDB:  Barycentric Dynamic Time, in JD [optional]
; 	    UT:  Universal Time, in JD  [optional]
;
; NOTES:   UTC is the basis of our clocks.  
;	   TAI = International Atomic Time (an intermediary)
;	   TAI differs from UTC by an integer number of seconds (27s in '93)
;	   TDT = TAI - 32.184 sec
;	   TBT (Terrestrial Barycentric Time) is the input to the JPL ephemeris
;	       and differs from TDT by at most 0.02 of a second. 
;          UTC and UT are the same to < 1 sec.
; for relations between these quantities, see AA B4, B5, K9 or Exp. Sup. to
; AA (1992)
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; yearleap and monthleap are the Years and months on which leap SECONDS 
; have been added. Taken from AA K9 (1994)  (This has nothing to do w/ leap YEARS!)
; JDleap = JD of dates when Leap Seconds were applied
; These variables should be updated each year, when the new AA comes out....
; For more info, try:  http://tycho.usno.navy.mil/leapsec.html
; The actual list of leap seconds is at: 
; ftp://maia.usno.navy.mil/ser7/tai-utc.dat
; WARNING: This program uses the now obselete timescales TDB and TDT, and thus
;  harbors errors of nanosecond proportions, or worse.  For sub-femtosecond
; precision see: Irwin, A. & Fukushima, T. A&A, 1999
; NOTE: 4/97 CMc Modified yearleap and monthleap to include the June 1997
; leap second as well as 2 other leapseconds which had been overlooked
; Last Update: 1/03 CMc
;		DEFINE CONSTANTS
;

 ddtor=!dpi/180.d0
 secperday=86400.d0                      		;AA L1
 UTCfrac = 0.d0						;Initialize
 SECperDAY = 86400.d0
 J2000 = 2451545.d0 					
 yearleap = [1972, 1972, 1973, 1974, 1975, 1976, 1977, 1978, 1979, 1980,$
             1981, 1982, 1983, 1985, 1988, 1990, 1991, 1992, 1993, 1994,$
             1996, 1997, 1999, 2006, 2009,2012,2015,2017]  ;years having a leapsecond
 monthleap = [1,7,1,1,1,1,1,1,1,1,7,7,7,7,1,1,1,7,7,7,1,7,1,1,1,7,7,1]   ;1=Jan, 7=July
 jdupdate = jdate([2017,1,4,0,0]) ; Date this file was last updated
 N = n_elements(monthleap)  				;Size of table.	
 JDleap = dblarr(N)					;Dates of Leaps secs.
 for i = 0, N-1 do JDleap(i)= jdate([yearleap(i),monthleap(i),1,0.,0.])
 jdUTC = UTC					; Imprecise JD
 if vartype(jdUTC) ne 'DOUBLE' then message,$
   'Input JD (UTC) is not DOUBLE:'+string(jdUTC),/info

;If time is before 1972, don't apply a time correction.
;If time is much after 1997, alert to error of a few seconds

 if jdUTC lt min(JDleap) then begin			;Too early
    message,'Epoch lies before data table',/info
    message,'    No time correction applied.',/info
    TDT = UTC 
 endif else begin


;		COMPUTE TAI and TDT from UTC
;
     if not keyword_set(silent) and  jdUTC gt (5.*365.+JDupdate) then $;Too late
       Message,'Leap Second list has not been updated recently. Expect error of ~> 1 second.',/info   ; HTI changed reminder message to 5*365 from 4*365.
;
;
    UTCint = floor(jdUTC)				; integer
    UTCfrac =  jdUTC- UTCint				; fraction
    sectoadd = 10.d + max(where(jdUTC ge JDleap)) 	;LATEST appropriate correction
    TAIfrac = UTCfrac +  sectoadd/SECperDAY   		;fractional TAI Day
    TDTfrac = TAIfrac + 32.184d0/SECperDAY		;Derived from AA, B5
    TDT = UTCint + TDTfrac 

 endelse

;		COMPUTE TDB  (SEE AA B6 )
;
    g = (357.53d0 + 0.98560028d0 * (jdUTC - J2000))*DDtoR	
    diff =  (0.001658D*sin(g) + 0.000014D*sin(2.d0*g))/SECperDAY
    TDB = TDT + diff 

    if TDT - jdUTC gt 70.d/secperday then $
    message,'Error in time conversion to TDT',/info

;		COMPUTE UT1  (ideally should be done by reading a table)
    UT = UTC						; true to ~1 m/s

 end







