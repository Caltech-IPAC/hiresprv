pro barystruct,observatory=observatory

; Observatory is assumed to be keck
barydir = getenv("MIR3_BARY")
asciifile = getenv("DOP_BARYFILE")
baryfile  = getenv("DOP_BARYFILE_STRUC")

;if strlowcase(observatory) eq 'keck' then begin
;    asciifile='kbcvel.ascii'
;    baryfile='kbcvel.dat'
;endif

openr,1,asciifile

line=' '
count=0l
;first find out how big to set the array
while ~ eof(1) do begin
	readf,1,line
	count=count+1l
end
close,1

bcat={obsnm:'?', objnm:'?', bc:0.0d, jd:0.0d, ha:0.0, obtype:'?'}
bcat=replicate(bcat,count-1l) ; HTI 2/2015, changed bc, jd to double

;stop
openr,1,asciifile
readf,1,line  		  ; throw away the first line
readf,1,line  		  ; throw away the 2nd line
readf,1,line  		  ; throw away the 3rd line

for i=0d,count-4 do begin ;30000-1 do begin  ;because first line dropped
	readf,1,line
	bcat(i).obsnm=getwrd(line,0)
	bcat(i).objnm=getwrd(line,1)
	bcat(i).bc=double(getwrd(line,2))
	bcat(i).jd=double(getwrd(line,3))
	bcat(i).ha=float(getwrd(line,4))
	bcat(i).obtype=getwrd(line,5)
end

;addnum=count-30000l

;for i=0d,addnum-2l do begin  ;because first line dropped
;	readf,1,line
;	bcat(i+30000l).obsnm=getwrd(line,0)
;	bcat(i+30000l).objnm=getwrd(line,1)
;	bcat(i+30000l).bc=double(getwrd(line,2))
;	bcat(i+30000l).jd=double(getwrd(line,3))
;	bcat(i+30000l).ha=float(getwrd(line,4))
;	bcat(i+30000l).obtype=getwrd(line,5)
;end


close,1
save,bcat,file=baryfile
end
