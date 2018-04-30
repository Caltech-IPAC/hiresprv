function	dimen,ar,nd
; give the number of elements in the ND dimension of ar
; the first dimension is ND=0
	sz=size(ar)
	if sz(0) eq 0 then return,sz(0)
	if nd gt sz(0)-1 then return,0
	nel=sz(nd+1)
return,nel
end
