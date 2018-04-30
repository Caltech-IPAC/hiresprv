pro getstartend,body,startrec,endrec,avoidtxt

; get the start and end record numbers from a logsheet.
;IODONE is NOT included in here.

; method...to get start rec, start at the beginning and go unti you
; reach the first entry non in the nonobs list...ame with end.  Then
; should check to make sure nect entry is not in banned list also

flatlist= ['WIDEFLAT','WIDE','WF','W','WIDE-FLAT','WIDE/FLAT','W/F', $
           'WIDEFLATS','WIDES','WFS','WIDE-FLATS','WIDE/FLATS', $
           'WIDE_FLAT','WIDEFLAT_C5','FLAT','FLATS','TESTFLAT','IODINED5','IFLAT']
iodlist = ['IODINE','I','I2','IOD','NARROWFLAT','NARROW_FLAT','FLAT_IODINE']
thorlist = ['TH-AR','TH_AR','THAR','TH/AR','THORIUM','THORIUM-ARGON','THNE','TH-NE','THAR_C5']

;nonobs = [iodlist,thorlist,flatlist,'JUNK','TEST','FOCUS'] ; thorlist not included. (is that good?)
nonobs = [iodlist,thorlist,flatlist,$
           'JUNK','TEST','FOCUS','BIAS','DARK','SKY','DAYSKY', 'PINHOLE'] 
; Add Mike Browns Europa and Jupiter observations. 1/2018.
;nonobs = [nonobs,'HR_BROWN-CAL','HR_BROWN-HR5530','HR_BROWN-JUPITER','HR_BROWN-IO',$
;      'HR_BROWN-EUROPA','HR_BROWN-501_2216','HR_BROWN-502_2216','HR_BROWN-5_2216', $
;      'BROWN-EUROPA','BROWN-JUPITER','BROWN-HR5530','BROWN-IO','BROWN-FLAT',$ 
;      'BROWN-BIAS']  ;replaced with check for brown down below

N = n_elements(body)
realobs = intarr(N)+1 ; 0=nonobs 1 = probabbly obs  (default =1)
nums = strarr(N)
objects = strarr(N)

for i = 0, N-1 do begin
    nums(i) = getwrd(body(i),0)
    objects(i) = strupcase(getwrd(body(i),1))
    if memberof(nonobs,objects(i)) then realobs(i)=0
    ; check if prefix is brown, if so, make realobs=0
    if strmid(objects[i],0,5) eq 'BROWN' then realobs[i]=0
endfor
rnums = reverse(nums)
startrec = nums(min(where(realobs eq 1)))
endrec = rnums(min(where(reverse(realobs) eq 1)))

avoid = ['-99']
startind = (where(nums eq startrec))(0)
endind = (where(nums eq endrec))(0)

acom = '          ; '
for i = startind,endind do begin
    if memberof(nonobs,objects(i)) then begin
        if strpos(nums(i),'-') eq -1 then  avoid=[avoid,nums(i)] else $
          avoid=[avoid,numexpand(nums(i))]
        acom=acom+objects(i)+','
    endif
endfor

;if n_elements(avoid) gt 10 then stop

ok = where(avoid ne -99)
if ok(0) eq -1 then atxt='-1' else begin
    avoid=avoid(ok)
    Na = n_elements(avoid)
    atxt = strchop(deparse(strtrim(avoid,2)+','),-1)
endelse

avoidtxt = "skip_rec = ["+atxt+"]"+acom
end






