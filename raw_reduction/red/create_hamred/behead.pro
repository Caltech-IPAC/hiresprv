pro behead,array,N

; Behead an array, ie remove its first N elements
; NOTE: ARRAY is changed by this program!!
; If N is negative, behead from the rear, ouch.
; See also: strchop

if n_elements(N) eq 0 then N = 1

Ntot = n_elements(array)
if Ntot eq 1 then begin
;    print,'Nothing left'
    array = ''
endif else begin
    if N lt 0 then begin 
        array = array(0:Ntot-1+N)
    endif else begin
        array = array(N:Ntot-1)
    endelse
endelse
end
