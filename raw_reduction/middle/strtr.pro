
function strtr,x,_extra=extras

;+
;
; STRTR
; Function to shortcut strtrim(string(X),2)
;
; Call Sequence:
; Result = STRTR(X)
;
; Input: X
; 
; Returns: string containing value of X with leading & trailing blanks
; removed.
;
; Katie Peek / Sept 2005
;
;-

return,strtrim(string(x,_extra=extras),2)
end
