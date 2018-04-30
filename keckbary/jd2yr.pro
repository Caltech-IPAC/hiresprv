pro jd2yr,jd,year

; Converts Julian Dates to Decimal Years
; INPUT: JD      (ie 2451544.5d0)
; OUTPUT: Year   (2000.0d)
; 
; (Replaces jd2year in Buie library by calling "caldate" which is a
; copy of Buie's caldat, not to be confused with IDL's caldat.pro )

caldate, jd, intyear, month, day, hour, minute, second
jd0 = jdate([intyear,1,1,0,0.d0])     ; JD of 1 Jan that year
year = intyear + (jd-jd0)/365.25d0    ; fractional year

end
