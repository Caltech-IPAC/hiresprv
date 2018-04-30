function strprecise,jdarr

; This function gets around IDL's lack of precision greater than DOUBLE
; by taking a 2 element double input and converting it to a string, while
; preserving the precision of both elements.  This string can be written to
; a file which is read by FORTAN or C programs.  Written specifically for 
; converting Julian Dates where high precision is needed.  Not really
; intended for other purposes.

; INPUT:  JDARR:  Julian Date Array(2) [Integer,Decimal], (double)
; OUTPUT: JDSTR:  Julian Date String, so 18 decimal places.
; Also converts single element jd to string, but this does not gain
; any precision.

; Example: 
; IDL> jd = [2448489.d0, 0.5841666732499034d0]
; IDL> print, strprecise(jd)
; Create: C. McCarthy  5/95

 if vartype(jdarr) ne 'DOUBLE' then begin
   message,'Input must be of type DOUBLE',/info
   help,jdarr
   bomb
;   retall
 endif

 case n_elements(jdarr) of
   1: JDstr = string(jdarr,f='(D30.20)')
   2: JDstr = string(jdarr(0),f='(D8.0)') + 	    $   ; Combine integer part
      strmid(string(jdarr(1),f='(D16.14)'),2,16)   	; With Decimal part
   else: begin
     message,'Input must have 1 or 2 elements',/info 
     help,jdarr
     stop
   end
 endcase

 return,JDstr

end
