pro timediff,t,hr=hr,min=min

; Compute the amount of realtime a program took to execute
; Usage:   timediff,t
; run program
; timediff,t
; Optional: hr,min.  Use on 2nd call to determine howmany hours or min
; elapsed

if n_elements(t) eq 0 then t = systime(1) else begin
    tstart = t
    tend = systime(1)
    diff = tend - tstart
    min = diff/60.  & hr = min/60.
    print,'Program took ',strtrim(min,2),' minutes = ',strtrim(hr,2),' hours'
endelse

end

