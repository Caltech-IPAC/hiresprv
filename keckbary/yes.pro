function yes,question

; Simple function to ask a yes or no question.
; Usage:  if yes('Is there a future?') then print,'Optimist'

if n_elements(question) eq 0 then question = '?'
ans = '' 
read,question+' (Y/N): ',ans
if strupcase(ans) eq 'Y' then return,1 else return,0

end
