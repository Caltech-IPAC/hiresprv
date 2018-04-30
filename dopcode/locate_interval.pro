pro locate_interval, x, xbeg, xend, ibeg, iend, nadd=nadd, stop=stop
;
;Given a monotonic input vector and two limiting values, return two indexes
;that bracket all data values between the limiting values. Extra data points
;may be included (or discarded from) both ends of the interval.
;
;Inputs:
; x (vector) monotonically increasing or decreasing data values
; xbeg (scalar) one limiting value that defines the data interval
; xend (scalar) the other limiting value that defines the data interval
; [nadd=] (scalar) number of extra data points to include at both ends of
;   the interval (or to discard, if nadd is negative).
; [/stop] (switch) halt execution requested interval is null.
;
;Outputs:
; ibeg (scalar) lower index of data values in the requested interval.
;   return value is -1 if requested interval is null.
; iend (scalar) upper index of data values in the requested interval
;   return value is -1 if requested interval is null.
;
;Notes:
; For large data vectors, this routine is much faster than using where().
; Passing a named variable (x) is faster passing a structure element (d.x).
;
;History:
; 2008-Sep-15 Valenti  Initial coding.

;Check syntax.
  if n_params() lt 5 then begin
    print, 'syntax: locate_interval, x, xbeg, xend, ibeg, iend [,nadd= ,/stop]'
    print, '  e.g.: locate_interval, wave, 5500, 5510, ib, ie, nadd=1, /stop'
    print, '        w = wave[ib:ie] & s = spec[ib:ie] & u = unc[ib:ie]'
    return
  endif

;Default value for optional keyword.
  if n_elements(nadd) eq 0 then nadd = 0

;Search for 
  i = value_locate(x, [xbeg, xend])
  ibeg = (i[0] < i[1]) + 1
  iend = (i[0] > i[1])

;Verify that requested interval overlaps input data range.
  nx = n_elements(x)
  if iend eq -1 or ibeg ge nx then begin
    xmin = min(x, max=xmax)
    rint = '[' + strtrim(xbeg, 2) + ',' + strtrim(xend, 2) + ']'
    xint = '[' + strtrim(xmin, 2) + ',' + strtrim(xmax, 2) + ']'
    if xend lt xmin then begin
      errmsg = 'requested interval less than data range'
      diag, -1, errmsg
      diag, -1, '  ' + rint + ' < ' + xint
    endif else begin
      errmsg = 'requested interval greater than data range'
      diag, -1, errmsg
      diag, -1, '  ' + rint + ' > ' + xint
    endelse
    goto, error
  endif

;Extend or contract domain, but don't exceed valid indexes.
  ibeg = 0 > (ibeg - nadd) < (nx - 1)
  iend = 0 > (iend + nadd) < (nx - 1)

;Verify that extraction interval is not null.
  if iend lt ibeg then begin
    if nadd eq 0 then begin
      errmsg = 'requested interval is between data points'
      diag, -1, errmsg
      diag, -1, '  ' + strtrim(x[iend], 2) + ' < [' $		;iend=ibeg+1
              + strtrim(xbeg, 2) + ',' $
              + strtrim(xend,2) + '] < ' $
              + strtrim(x[ibeg], 2)
    endif else begin
      errmsg = 'null segment after trimming ' $
             + strtrim(-2*nadd, 2) + ' of ' $
             + strtrim(iend-ibeg-2*nadd+1, 2) + ' points'
      diag, -1, errmsg
    endelse
    goto, error
  endif

;Done.
  return

;Error handler.
  error:
  ibeg = -1L							;flag value
  iend = -1L							;flag value
  if keyword_set(stop) then begin
    on_error, 2
    message, /noname, /noprefix, ''
  endif

end
