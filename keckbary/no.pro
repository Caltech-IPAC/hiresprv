function no,question

; Simple function to ask a yes or no question.
; Opposite of yes.pro
; Usage:  if no('Does God Exist?') then print,'Athiest!'

ans = '' & print,question       ; can these 2 lines be combined?
read,'(Y/N): ',ans
if strupcase(strmid(ans,0,1)) eq 'N' then return,1 else return,0

end

