pro sumwf,sttapen,numwf,wftapen1,wftapen2,wf1,wf2
;This procedure determines whether to sum two seperate wide flat 
;arrays or just one.  If two then the summed results of each are
;in turn summed together to give the final summed wide flat file:
;'star tapename'.sum		ECW
;input:
;	sttapen-> star image tapename
;	numwf -> number of wide flat arrays (1 or 2)
;	wftapen1/2 -> wide flat tapenames for set 1 and 2 respectively
;	wf1/2 -> arrays of wide flat image identifier numbers
;
;output:
;	file with star tapename plus suffix '.sum'
;Jun-12-92 Eric Williams
;
@ham.common
;
trace,15,'SUMWF: Wide flat images being added together, please hold on...'
tempfile = 'temp.'+sttapen
if numwf eq 1 then begin
  imadd,wftapen1,wf1,im,head			;add wide flat images

;*******Kludge for ra01.41 reduction. Header problems?*******
wdsk,im,sttapen+'.sum'

;  wtfits,im,sttapen+'.sum',head			;fits store added wf.
endif else begin
  imadd,wftapen1,wf1,im,head			;add first set of wide flats	
  wtfits,im,tempfile+'.1',head		;fits store first set
  imadd,wftapen2,wf2,im,head			;add second set of wide flats
  wtfits,im,tempfile+'.2',head		;fits store second set
  imadd,tempfile,[1,2],im,head			;add both sets of wide flats
  wtfits,im,sttapen+'.sum',head			;fits store final summed wf.
  send = 'rm '+tempfile+'.?'
  spawn, send   			;delete temporary files
endelse
trace,15,'SUMWF: Wide Flat images are now summed.'
sumean='SUMWF: Mean of summed wide flat image is '$
      +strtrim(string(mean(im)),2)
trace,20,sumean
return
end
