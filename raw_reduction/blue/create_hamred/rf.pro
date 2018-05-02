pro rf,data,file,N,nocull=nocull,skip=skip,filter=filter,silent=silent,$
       dup=dup,keep=keep,head=head

; Reads a file into a string variable.  Culls blank lines by default.
; USAGE:  rf,data,file    (note that data comes first, file is optional)
; Similar to but much better than rdfile.pro (which can
; take forever!   skips first few lines if desired

; Keywords:
; SKIP = N   Number of lines to skip
; NOCULL     Same a /KEEP
; KEEP       Keep blank spaces
; DUP        Remove Duplicate entries
; HEAD       Optionally store the lines that were SKIPed.
; 3/00: Modified to be in line with newly improved cull.pro  CMc
; 11/00: Added HEAD keyword

if n_elements(filt) eq 0 then filt = ''
;if  n_elements(file) eq 0 then  file  = pickfile(filter=filter)
;if file(0) eq '' then  message,'Give me a real file'

if keyword_set(nocull) then keep = 1 else keep = 0
if keyword_set(keep) then keep = 1 else keep = 0
if keyword_set(dup) then dup = 1 else dup = 0

spawn, 'cat ' + file , output

N = n_elements(output)
if n_elements(skip) ne 0 then begin
    head = output(0:skip-1)
    output = output(skip:N-1)
end

output = cull(output,keep=keep,dup=dup)  ; this should work.

data = output

end
