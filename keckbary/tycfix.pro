function tycfix,name,fixed=fixed

; Fix a Tycho star name to be in line withh the standard
; convention 4-5-1 ie change: 3009-0603 to 3009-00603-1
; NAME: Bad Tycho Name

fixed = 0
newname = name
hyphchar = strpos(name,'-')     ; search for hyphen
if hyphchar(0) eq -1 then return,name else  begin ; could be tycho
    posthyp = strmid(name,hyphchar+1)
    prehyp = strmid(name,0,hyphchar+1)
    if strlen(posthyp) eq 4 then begin
        newposthyp = '0'+posthyp+'-1'
        newname =prehyp+newposthyp
        fixed = 1
    endif else print,'Not fixing tycho name: ',name
end
return,newname

end
