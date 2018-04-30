function memberof,list,item,w=w
; Checks if the  ITEM is a member of LIST

; Derived from  select.pro (ECW) which unfortuantely would return
; yes for a partially correct answer.  EG: a = ['you','i','myself'] 
; select(a,'my') =1 since my is contained in  myself :(
; OPTIONAL: w: index of matches
;

if n_elements(list) lt n_elements(item) then message,'List Wrong'
if vartype(list) eq 'STRING' or vartype(item) eq 'STRING' then begin
    list = strtrim(list,0)
    item = strtrim(item,0)
endif
w=where(list eq item)
found=w(0) ne -1
return, found
end
