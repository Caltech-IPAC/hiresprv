function findordfind,body,lick=lick

;Find a star which is a good orderfinder star, ie bright star.
; METHOD:
;  Search logsheet for a B star (beginning with HR)
;  if not found, give up (for now)
; Prev. used methods, see below
;
;Modified to stop if there is no bstar and ask which file to use for orderfinding

txt = "ord_finder_rec = "
h = getwrds(body,6)
stars = getwrds(body,1)
numb = getwrds(body,0)
; use 1st instance of a bstar
;best =  (where(firstchar(stars,2) eq 'HR' ,nHR))(0) 
stars = strupcase(stars)
best =  (where(firstchar(stars,2) eq 'HR' $ 
         and firstchar(stars,3) ne 'HR_' ,nHR))(0) 
;best =  (where(firstchar(stars,2) eq 'HR' or $
; 			     firstchar(stars,2) eq 'hr',nHR))(0) 

;use 2nd instance of a b star if available.
if nHr ge 2 then best = (where(firstchar(stars,2) eq 'HR' or $
 			                   firstchar(stars,2) eq 'hr',nHR))(1)
if nHR eq 0 then begin

;bst=getiodine(body)
print,"No Star with HR prefix found. Returning. "
return

bst=fix(bst)
return,txt+string(bst)

endif

if nHR ge 1 then begin
    cmt = "                     ;   " + stars(best)  ; comment line
    return,txt+numb(best)+cmt

endif else message,'Couldnt find a B star'
end






