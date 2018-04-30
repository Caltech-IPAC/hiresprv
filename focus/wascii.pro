pro    wascii,vname,fname
; This code writes a 1 or 2 dimensional array of numbers (vname) to
; an ascii file called fname.
; Example: wascii,x,'x.dat'
; R. Paul Butler, October 1990
	openw,1,fname
	fdata=size(vname)
	ncol=fdata(1)-1
	if fdata(0) lt 2 then printf,1,vname
	if fdata(0) gt 1 then begin
	   nrow=fdata(2)-1
           for n=0,nrow do printf,1,vname(0:ncol,n)
        endif
	close,1
return
end
