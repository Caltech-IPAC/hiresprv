function firstchar,strin,Nchars

; return last character of a string or array of strings
; IMPROVE: Allow to grab last N chars
; NOTE: Firstchar already exists (in jhuapl lib) and it doesn't work
; Try print,firstchar('-1')


if n_elements(Nchars) eq 0 then Nchars = 1
N = n_elements(strin)

if N eq 1 then begin
    str = strin(0)
    lc =strmid(str,0,Nchars) 
endif else begin
    lc = strarr(N)
    str = strin
    for i = 0, N-1 do lc(i) = strmid(str(i),0,Nchars)
endelse
return,lc
end
