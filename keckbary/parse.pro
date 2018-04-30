function parse,txt,letters = letters

; A program to parse text into an array of letters OR WORDS
; One line of text at a time please
; NOTE: functionality of parse.pro changed 1/97.  Now it parses
; words by default.  To parse letters use: newtext = parse(text,/letters)

; Opposite: DEPARSE.PRO

if n_elements(txt) ne 1 then begin
    message,'Can only handle 1 element arrays.  Sorry
endif

text=txt(0)   ; should only be one line!

if txt eq '' then return, '' else begin
    if keyword_set(letters) then begin
        letters = strarr(strlen(text))
        for i = 0, strlen(text)-1 do letters(i) = strmid(text,i,1)
        return,letters
    endif else begin
        N = nwrds(text)
        words = strarr(N) 
        for i = 0,N-1 do words(i) = getwrd(text,i)
        return,words
    endelse
endelse
end

