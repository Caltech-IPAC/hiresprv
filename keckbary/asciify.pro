pro asciify,asciifile=asciifile,datfile=datfile

; turn a structure bcnew.dat into an ascii file bcnew.ascii

bt = ''; Directory to find these files.
if n_elements(datfile) eq 0 then datfile = bt+'kbcvelnew.dat'
if n_elements(asciifile) eq 0 then asciifile = bt+'kbcvelnew.ascii'
;help,trimpath(asciifile),trimpath(datfile)
dum = '' & read,'<RET> to continue',dum

if asciifile eq datfile then message,'you are crazy'
restore,datfile
if n_elements(bc) eq 0 then bc = bcnew  
;bc = bcnewsa				
N = n_elements(bc)

; Here's the new format for the bcvel.ascii file:
;form = '(A9,3X,A8,1X,D11.3,1X,D12.6,1X,F7.3,1X,A1,1X,A)'
; but this is taken from ubarylog.pro (the original ubcvel.ascii is
; Left justified with the filenames
; this form was used up 3/2003 but it truncated some names:
;form = '(A10,3X,A10,1X,D11.3,1X,D12.6,1X,F7.3,1X,A1)' 
form = '(A10,3X,A15,1X,D11.3,1X,D12.6,1X,F7.3,1X,A1)'

head = 'Filename      Star     BCVel m/s Mod. Jul D.'+$
	'  HrAng. Obtype(i/t/o/u) Comment'

print,'Creating asciifile: ',asciifile
openw,11,asciifile
printf,11,head ;
for i = 0, N-1 do begin
  mjd = bc(i).mjd
  fn = strtrim(bc(i).file,2)
  printf,11,f=form,fn,bc(i).name,bc(i).cz, $
      mjd,bc(i).ha,bc(i).obstype
endfor
close,11

end
 
