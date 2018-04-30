function memberof,list,item
; Checks if the  ITEM is a member of LIST

; Derived from  select.pro (ECW) which unfortuantely would return
; yes for a partially correct answer.  EG: a = ['you','i','myself'] 
; select(a,'my') =1 since my is contained in  myself :(
;
w=where(list eq item)
found=w(0) ne -1
return, found
end
