pro fprint,v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,$
           fmat =fmat,file=file,format=format,verbose=verbose,$
           head=head


; FPRINT loops through each of several variables, printing the ith element
; of each of them on a single line of output, FORMATTED, if desired.
;It also allows for printing to a FILE

; HEAD: A header at the beginning.  (Not Looped over)
; This program is a replacement for the IDL library routine FORPRINT
; FORPRINT is dependant upon !TEXTOUT being set just right and this
; crashes depending on which version of IDL you are running.

if n_elements(fmat) eq 0 and n_elements(format) ne 0 then fmat = format
N = n_elements(V0)
Np =  n_params() 
if Np eq 1 then begin           ; A little wierd but needed for only 1 var.
    Np = 2
    V1 = strarr(N)
endif

vtxt = deparse(',v'+strtrim(sindgen(Np),2)+'(i)')
if keyword_set(fmat) then fextra = ',f=fmat' else fextra = ''

; EITHER PRINT TO SCREEN OR TO FILE
if n_elements(file) eq 0 then begin
    cmd = 'print'+vtxt+fextra  
    if n_elements(head) ne 0 then begin
        Nh = n_elements(head)
        for j = 0, Nh-1 do print,head(j)
    endif

endif else  begin 
    openw,1,file
    if n_elements(head) ne 0 then begin
        Nh = n_elements(head)
        for j = 0, Nh-1 do printf,1,head(j)
    endif

    cmd = 'printf,1'+vtxt+fextra
endelse


if n_elements(file) ne 0  and keyword_set(verbose) then $
  message,/info,'writing to  : '+file
for i = 0.d, N-1 do a = execute(cmd)
close,/all

end
    
