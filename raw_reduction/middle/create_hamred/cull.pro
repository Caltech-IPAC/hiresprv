function cull,stringlist,sort=sort,quiet=quiet,keep=keep,silent=silent,dup=dup

;
; Culls a list of strings, removing blank spaces, and, if requested, duplicates
; Default Behavior: Just remove blank spaces.  

; Usage:   clist = cull(list)   ;  list is a string array
; Keywords:
;    SORT:  Will Return A sorted list
;   QUIET:  WIll not report  messages like if duplicates are removed
;  SILENT:  Same as quiet
;    KEEP:  Don't remove blank spaces
;     DUP:  Remove duplicate entries

if keyword_set(silent) or  keyword_set(quiet) then quiet  = 1 else quiet = 0
if keyword_set(keep) then list = stringlist else begin ;aviod changing stringlist
    nonspace = where(strtrim(strcompress(stringlist),2) ne '') ;blank spaces
    if nonspace(0) ne -1 then list = stringlist(nonspace) else $
      list = stringlist         ; remove blank spaces
endelse 
N = n_elements(list)
l = list(sort(list))

if keyword_set(dup) then begin
    for i = 1,N-1 do begin
        if l(i) eq l(i-1) then begin
            if quiet eq 0 then print,'CULL: Removing Duplicate: ',l(i)
            list(min(where(list eq l(i)))) = 'Later Dude!'
            l(i-1) = 'Later Dude!'
        endif
    endfor

    list = list(where(list ne 'Later Dude!'))
    l = l(where(l ne 'Later Dude!'))
endif


if keyword_set(sort) then return,l else return,list

end
