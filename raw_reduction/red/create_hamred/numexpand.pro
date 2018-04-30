function numexpand,numstr

; convert a - delimited string of numbers into a comma delimited full
;expansion , ie convert '20-22' to '22,21,22'

dash = strpos(numstr,'-')
firstnum = fix(strmid(numstr,0,dash))
lastnum = fix(strmid(numstr,dash+1,999))
bigind = indgen(10000)
list = strchop(deparse(strtrim(bigind(firstnum:lastnum),2)+','),-1)  ;!

return,list
end
