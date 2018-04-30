function strchop,text,N

txt = text
; CHopp off N characters from a string.
; If N is negative, chop from rear, else chop frontally
; See also: BEHEAD.pro, which works on array elements

if N lt 0 then begin 
    if n_elements(text) gt 1 then message,'one element at at time'
    N = -N
    l = strlen(txt)
    txt = strmid(txt,0,l-N)
endif else     txt = strmid(txt,N,999)
return,txt
end
