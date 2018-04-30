function jdate,dvec
;Calculate Julian date from UT.
; dvec (input vector(5)) Date and time specified by a 5 element vector of
;   the form [year,month,day,hour,minutes], e.g. [1993,12,25,16,24.2].
;   The year must be fully specified. Only the minutes may be fractional.
;Returns Julian date as a double precision scalar.
; B. Grundseth	Created.
;18-Jun-93 JAV	Translated into IDL. Changed argument list. Check arguments.

if n_params() lt 1 then begin
  print,'syntax: jd = jdate([year,month,day,hours,minutes])'
  print,'   e.g. jd = jdate([1993,   12, 25,   16,   24.2])'
  retall
endif

;Algorithm relies on integer truncation. (Yuck.)
  iyear = fix(dvec(0))
  imonth = fix(dvec(1))
  iday = fix(dvec(2))
  hours = dvec(3) + dvec(4) / 60d0

;Error checking.
  if (iyear gt 0) and (iyear lt 100) then begin
    message,/info,'Year must be fully specified, e.g. 1993'
    retall
  endif
  if ((iyear mod 1) ne 0) or ((imonth mod 1) ne 0) $
    or ((iday mod 1) ne 0) then begin
    message,/info,'Year, month and day MUST be integral.'
    retall
  endif

;Do it.
  icst = fix(1.2001 - 0.1*imonth)	;1(0)=before(after) possible leap day
  ix = iyear - icst			;modified year for leap calculation
  jdate = 365d0*iyear + double(ix/4 - ix/100 + ix/400 + 2*icst + iday) $
        + fix(30.57*imonth) + 1721028d0 - 0.5d0 + hours/24d0
  return,jdate

end
