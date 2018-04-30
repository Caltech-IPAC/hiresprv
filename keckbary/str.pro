;+
; NAME: STR
;
;
;
; PURPOSE: 
;   Do what the IDL-native STRING doesn't do well
;
; CATEGORY:
;   String manipulation
;
;
; CALLING SEQUENCE:
;  RESULT = STR( INSTRING, length=, format=, char=, /trail )
;
;
; INPUTS:
;  INSTRING - Input string array to be formatted
;
;
; OPTIONAL INPUTS:
;  
;
;
; KEYWORD PARAMETERS:
;   LENGTH=  Final length of each outpu string.
;   FORMAT=  Normal IDL Format string, passed to STRING()
;   CHAR  =  Single character to be appended to each output string in
;            order to be of length LENGTH
;   /TRAIL=  Set if CHAR is to be appended rather than prepended
;
; OUTPUTS:
;    RESULT - Formated array of length equal to input
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;     IDL> print,str(1)                             
;      1
;      IDL> print,str(1, char='0', length=3)         
;      001
;      IDL> print,str(1, char='*', length=3, /trail)
;      1**
;      IDL> print,str(1.0, format='(f3.1)')
;      1.0

;
; MODIFICATION HISTORY: 
;   Created sometime in 2003 by JohnJohn
;   14 May 2009 - JJ: reduced looping by using HISTOGRAM magic
;
;-

function str,instring,length=length,format=format,trail=trail,char=char
on_error,2
nel = n_elements(instring)                     ;;; How long is the input array?
s = strtrim(string(instring,format=format),2)  ;;; Basic operation
if 1-keyword_set(char) then char = '0'  
if n_elements(length) gt 0 then begin ;;; If keyword length= is set
    ilen = strlen(s)                  ;;; The string length of each INSTRING
    w = where(ilen ne ilen[0], nw)  
    if nw eq 0 then begin ;;; Simple step if all input INSTRINGs have same len
        nz = length-ilen[0]
        if nz gt 0 then s = strjoin(strarr(nz)+char)+s ;;; String trickery
    endif else begin
        nz = length-ilen
        ;;; Histogram trickery ensues
        test = where(nz gt 0, ngood)
        if ngood gt 0 then begin
            h = histogram(nz, bin=1, min=1, reverse_ind=ri)  
            nh = n_elements(h)
            for i = 0,nh-1 do begin ;;; loop through groups of string length
                if ri[i+1] - ri[i] gt 0 then begin ;;; Anything in this bin?
                    ind = ri[ri[i] : ri[i+1]-1]
                    nind = n_elements(ind)
                ;;; String magic
                    addon = replicate(strjoin(strarr(i+1)+char), nind)
                    if keyword_set(trail) then begin
                        s[ind] = s[ind] + addon
                    endif else begin
                        s[ind] = addon + s[ind]
                    endelse
                endif
            endfor
        endif
    endelse
endif
return,s
end
