function getwrds, txt, NTH, MTH,last=last,nocull=nocull,delimiter=d
 
 
; just like getwrd but allows a vector input.
; ps. no gaurantees.  NOTE: data are culled of blank lines
; unless requested.  This could produce undesired results like firsts
; = getwrds(data,0) --> firsts will have different n_elements as data
; unless /nocull is specified...

if  keyword_set(nocull) then text = txt else $
  text = cull(txt)

if n_params(0) lt 2 then nth = 0                ; This lets us pass
IF N_PARAMS(0) LT 3 THEN MTH = NTH              ; m to getwrd, regardless
nerd = ''                                

if  keyword_set(last) then blast = 1 else blast = 0
N = n_elements(text)

if N eq 0 then  begin
    if n_elements(delimiter) eq 0 then  $
      wrds = getwrd(text,nth,mth,last=blast)  else $
      wrds = getwrd(text,nth,mth,last=blast,delimiter=d)
endif  else begin    
    wrds = strarr(N)
    for i=0L,N-1L do begin
        if n_elements(delimiter) eq  0 then $
          nerd = getwrd(text(i),nth,mth,last=blast) else $
          nerd = getwrd(text(i),nth,mth,last=blast,delimiter=d)
        wrds(i) = nerd ; werd werd werd! nerd is the werd.
    endfor
endelse
 
return,wrds  

end
