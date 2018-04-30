pro badpix,im,row,bad,len
;this routine replaces bad pixel in a 1D spectra with an m-th order
;polynomial (where m is currently equal to 2), using the two points nearest
;the bad point.  len is the number of consecutive bad pixels starting with 
;bad
	m=2 ;parabolic fit to bad points
	x=indgen(4)
	x1=indgen(4+len)
	dum=fltarr(4)
	dum=im(bad-2:bad+1,row)
	x(2)=len+2
	x(3)=len+3
	dum(2)=im(bad+len,row)
	dum(3)=im(bad+len+1,row)
	c=pl_fit(x,dum,m)
	y=poly_fat(x1,c)
	for q=0,len-1 do im(bad+q,row)=y(2+q)
return
end ;end badpix
