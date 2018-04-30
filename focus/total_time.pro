pro total_time
;   Read logsheet and report total of exposure times.
; 
;Create: SEPT-97	GWM
print,'     *************************************************************'
print,'     **        THE Exposure-Time Totalling PROGRAM              **'
print,'     **                                                         **'
print,'     *************************************************************'

;
;PROMPT FOR ONLINE LOGSHEET FILENAME
print,' '
;repeat begin
  noerror=1
  print,''
  logfile=' '
  print,'Enter the logsheet filename (i.e., b59.logsheet2)'
  print,'(Assumes path is ~gmarcy/logsheets/)'
  read,logfile
  logfile = '~gmarcy/logsheets/'+logfile
;  if (strmid(logfile,0,1) ne '/') then $
;    logfile=logdir + strcompress(logfile,/remove_all)
;
get_lun,logune
openr,logune,logfile

logline = ' '

;PROMPT FOR STARTING AND FINISHING OBSERVATIONS NUMBERS.
repeat begin
  noerror=1
  print
  read,'Give the starting observation number (5 for b18.5): ',startrec
  read,'Give the ending observation number(13 for b18.13): ',endrec
  if startrec gt endrec then begin
    print,''
    print,'Starting number must be less than the ending number.'
    print,'Please enter again.' & noerror=0
  endif
endrep until noerror
;

startrec=long(startrec)
endrec=long(endrec)

;LOOP THROUGH THE RANGE OF OBSERVATION NUMBERS AND MAKE BC CALCS.
startrec = long(startrec)
endrec=long(endrec)

total_time = 0.
FOR i=startrec, endrec do begin
  skip=0                   ;Reset to NOT skip
  readf,logune,logline
  while (getwrd(logline) ne strcompress(i,/remove_all)) 	$
    do readf,logune,logline
;  obsname=tpname + '.' + getwrd(logline,0)
;  log.object=strupcase(getwrd(logline,1))
;  iodtest=strupcase(getwrd(logline,2))
;  time=getwrd(logline,3)
  exp_time=getwrd(logline,4)
  print,exp_time
  total_time=total_time+exp_time
ENDFOR
close,logune
print,' '
print,'Total Exposure Time = ',total_time, ' sec = ',total_time/3600.,' hr'

end
