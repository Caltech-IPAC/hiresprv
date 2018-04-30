function deparse,txtarr,nospace=nospace,sepchar=sepchar

; The opposite of parse (see)
; Optional:  /NOSPACE: Result is Cramped
;            SEPCHAR: You pick the separation character
; Example: print, deparse(['physics','sfsu','edu'],sepchar = '.')

if n_elements(sepchar) eq 0 then sepchar = ' ' ; seperate by space or user chosen
if keyword_set(nospace) then sepchar = '' 

N = n_elements(txtarr)

;if N eq 0 then sc = sepchar else sc = replicate(sepchar,N)
if N eq 0 then return, textarr else begin
    sc = replicate(sepchar,N)
    sc(N-1) = ''                ; no sep at the end

    result = ''
    for i = 0,N-1 do result=result+txtarr(i)+sc(i)
    return,result
end
end
 
