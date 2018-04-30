function getflatinfo, body

; Given the body of a logsheet, output FLATTEXT, which is the text
; which goes into part 7. of the reduction batchfile.
flatlist= ['WIDEFLAT','WIDE','WF','W','WIDE-FLAT','WIDE/FLAT','W/F', $
           'WIDEFLATS','WIDES','WFS','WIDE-FLATS','WIDE/FLATS', $
           'WIDE_FLAT','FLAT','FLATS']
iodlist = ['IODINE','I','I2','IOD', 'FLAT_IODINE']
thorlist = ['th-ar','TH-AR','TH_AR','THAR','TH/AR','THORIUM','THORIUM-ARGON']


;DEFINE_KEY, /CONTROL, '^D', /DELETE_CURRENT

nums = getwrds(body,0)
targets = getwrds(body,1)
yn = getwrds(body,2)
times = getwrds(body,3)

; Find wideflats
wfind = [-1]
N = n_elements(body)
for i = 0, N-1 do begin
 if memberof(flatlist,strupcase(targets(i))) then wfind=[wfind,i]
endfor
if n_elements(wfind) gt 1 then begin
    wfind = wfind(where(wfind ne -1))
;    print,'These lines seem to have flats:'
;    print,body(wfind)
    nflatsets = n_elements(wfind)
    flattext0 = 'numsets = '+strtrim(n_elements(wfind),2)
    flattext = strarr(nflatsets)
 	nflat = 0
    for i = 0, nflatsets-1 do begin
        flatnums = nums(wfind(i))
        hyphen = strpos(flatnums,'-')
;        if hyphen(0) eq -1 then message,'no hyphen!'
		nflat = nflat+1 ;redefined in case of bad flat
		if hyphen[0] eq -1 then begin
		    flattext0 = 'numsets = '+strtrim(n_elements(wfind)-1,2)
			nflat = nflat-1
		goto, skipflat
		endif
        firstflat = strmid(flatnums,0,hyphen)
        lastflat = strmid(flatnums,hyphen+1,999)
        if fix(lastflat) lt fix(firstflat) then begin
            print,'; WARNING: Correcting Ambiguous Flat Entry: ',nums(wfind(i))
            lastflat = strmid(firstflat,0,1)+lastflat
        endif
;        flattext(i) = 'flat_set'+strtrim(nflat,2)+' = ['+strtrim(firstflat,2)+$
;          ','+strtrim(lastflat)+']'
       flattext(i) = 'flat_set'+strtrim(nflat,2)+' = ['$
       					+strtrim(firstflat+1,2)+ ','+strtrim(lastflat-1)+']' 		
       					;"+1/-1" removes first/last flat of each set
		
;        print,flattext(i)
		skipflat:  ; jump to here
    endfor

;	if zeroflat ne 0 then 
;stop
	keep = where(flattext ne '',numfsets)
    flattext = flattext[keep]
    flattext0 = 'numsets = '+strtrim(numfsets,2) ;redefine 
    flattext = [flattext0,flattext]
;    print,flattext
; now get nsets and numbers etc.
endif else print,' no wfs!'

return,flattext
end
