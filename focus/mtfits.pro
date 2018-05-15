pro   mtfits,fitsnm,n=n,inpdir=ddir,outstring=outstring,verbose=verbose
;+
;INPUT:  fitsnm   string   name of fits file  ,i.e., 'k110028',
;        for tape k11  image# 0028
;
;        Keyword n = number of successive entries after the one named
;                /cts - print exposure meter counts
;
;EXAMPLE:
;          mtfits,'k170028'
;
;          mtfits,'k170028',n=5      to print next 5
;
;History:  Modified for HIRES Upgrade Aug 12, 2004
;
;      ;2018: Changed format of fitsnm
;       2018: added kewyord outstring
;-   h = headfits('/data/sdata101/hires5/04jun/'+fitsnm+'.fits')
;       datadir ='/s/sdata125/hires1/2011jun13/'
;  Use keyword /verbose to see all warnings and output on screen.

datadir = ''
;***Change data directory on the following line or on the command line***

if keyword_set(ddir) then dir= ddir else dir=datadir

cts = 1  ;turn on printing cts from exposure meter

;filename=dir+fitsnm+'.fits'
filename = dir+fitsnm ; HTI changed 20 apr 2018
   dum = findfile(filename,count=filecnt)       ;Check if file is there

   if filecnt ge 1 then begin
      h = headfits(filename)
   endif else begin
;      if n_elements(n) lt 1 then print,filename+'  not found.'
      return
   endelse

;  EXPOSURE TIME
;   expt=fix(hdrdr(h,'EXPOSURE'))
   expt=fix(hdrdr(h,'ELAPTIME'))
;print, 'elaptime =', expt

; NEW section to rectify names
  ; Generate a key for each 
   lamp = STRCOMPRESS(strlowcase(sxpar(h,'LAMPNAME')),/remove_all)
   deck = STRCOMPRESS(sxpar(h,'DECKNAME'),/remove_all)
   I2in  = SXPAR(h,'IODIN')  ; True/False
   I2out = sxpar(h,'IODOUT') ; True/False
   I2temp= sxpar(h,'TEMPIOD2')
   exp_meter = sxpar(h,'EXM0STA')
   ng3  = STRCOMPRESS(sxpar(h,'LFILNAME'),/remove_all)
   expt = sxpar(h,'EXPTIME')
   obj_hd = sxpar(h,'TARGNAME')
   if lamp eq 'thar2' then lamp = 'thar'
   if lamp eq 'quartz2' then lamp = 'quartz'
   
;   print
;   print,'Lamp:         ',lamp
;   print,'Decker:       ',deck
;   print,'I2(in/out):   ', I2in,I2out
;   print,'I2 temp:      ', I2temp
;   print,'Exposure Mtr: ',exp_meter
;   print,'Ng3 filter:   ',ng3
;   print
   ; Make rules for each calibration
   obj_name = 'ZZZ'
   ; Focus
   if I2in eq 0 and I2out eq 1 and deck eq 'D5' and lamp eq 'thar' $
      then obj_name = 'focus'
   if I2in eq 1 and I2out eq 0 and I2temp gt 50. and lamp eq 'quartz' $
      then obj_name = 'iodine'
   if I2in eq 0 and I2out eq 1 and lamp eq 'thar' and $
      (deck eq 'B5' or deck eq 'B1') $
      then obj_name = 'thar'
   if I2in eq 0 and I2out eq 1 and lamp eq 'quartz' and deck eq 'C1' $
      then obj_name = 'wideflat'
   if I2in eq 0 and I2out eq 1 and lamp eq 'quartz' $
      and (deck eq 'C5' or deck eq 'B5' or deck eq 'B1')  $
      then obj_name = 'flat'
    if expt eq 0 $
      then obj_name = 'bias'
    if obj_name eq 'ZZZ' and lamp eq 'thar' then obj_name = 'thar'; catchall
    if obj_name eq 'ZZZ' and lamp eq 'quartz' then obj_name = 'flat'; catchall    
    if obj_name eq 'ZZZ' then obj_name = obj_hd
    target = obj_name
; end new section to rectify names

;  TARGET NAME
;   target = hdrdr(h,'TARGNAME')
;print,'Targname =', target

;   target = strtrim(target,2)   
;   len = strlen(target)
;   target = strmid(target,1,len-2)
;   target = strtrim(target,2)

;IODINE
   iodine_in = hdrdr(h,'IODIN')
   iodine_out = hdrdr(h,'IODOUT')
   iodine_in = strtrim(iodine_in,2)
   iodine_out = strtrim(iodine_out,2)
   if iodine_in eq iodine_out and keyword_set(verbose) then begin
     print,'*********************************************'
     print,' IODINE CELL IN + OUT cards are both: ',iodine_in, ' in FITS HEADER'
     print,'i.e., the sensors suggest the cell is both in and out (or neither)'
     print,'*********************************************'
   end
   if iodine_in eq 'T' then iodine_in='y' 
   if iodine_in eq 'F' then iodine_in='n'
;   if iodine_out eq 'T' then iodine_out='y'

;Check Iodine temperature:

	iodine_temp = hdrdr(h,'TEMPIOD2')
	if iodine_temp lt 49 or iodine_temp gt 51 and keyword_set(verbose) then begin
     print,'*************************************************'
	 print,'IODINE CELL TEMPERATURE IS OUTSIDE NOMINAL RANGE'
	 print,' MAKE SURE IODINE HEATER IS TURNED ON!!!!'
	 print,' Iodine temperature is: ', iodine_temp
     print,'*************************************************'     		
	endif

;Check tomake sure the mirror cover is open
  cover_pos = sxpar(h,'C1CVOPEN')
  if cover_pos eq '0'  and keyword_set(verbose) then begin
    print,'**********************************************';
	print,'* THE MIRROR COVERS ARE CLOSED!!!            *'
	PRINT,'* UNLESS THIS IS A DARK, SOMETHING IS WRONG! *'; 
    print,'**********************************************';    
  endif

;BINNING
    bin = hdrdr(h,'BINNING')    
    if strcompress(bin,/remove_all) ne "'3,1'" and keyword_set(verbose) then begin
     print,'*********************************************'
     print,' THE BINNING IS INCORRECT. PLEASE CHECK THE BINNING'
     print,'    BEFORE FURTHER OBSERVING. SHOULD BE: 3X1'
     print,'    CURRENT BINNING IS: ',BIN
     print,'*********************************************'        
    endif

    tv_filt = hdrdr(h,'TVF1NAME')    
    if strcompress(tv_filt,/remove_all) ne "'bg38'" and expt gt 10 and keyword_set(verbose) then begin
     print,'*********************************************'
     print,' THE FILTER ON THE GUIDE CAMERA IS INCORRECT. PLEASE CHECK'
     print,'    BEFORE FURTHER OBSERVING. SHOULD BE: BG38'
     print,'    CURRENT filter IS: ',tv_filt
     print,'*********************************************'        
    endif

    filter1 = hdrdr(h,'FIL1NAME')    
    if strcompress(filter1,/remove_all) ne "'clear'" and keyword_set(verbose) then begin
     print,'*********************************************'
     print,' THE FILTER1 POSITION  IS INCORRECT. PLEASE CHECK'
     print,'    BEFORE FURTHER OBSERVING. SHOULD BE: clear'
     print,'    CURRENT filter IS: ',filter1
     print,'*********************************************'        
    endif

    filter2 = hdrdr(h,'FIL2NAME')    
    if strcompress(filter2,/remove_all) ne "'clear'" and keyword_set(verbose) then begin
     print,'*********************************************'
     print,' THE FILTER2 POSITION  IS INCORRECT. PLEASE CHECK'
     print,'    BEFORE FURTHER OBSERVING. SHOULD BE: clear'
     print,'    CURRENT filter IS: ',filter2
     print,'*********************************************'        
    endif

    ccdgain = hdrdr(h,'CCDGAIN')    
    if strcompress(ccdgain,/remove_all) ne "'low'" and keyword_set(verbose) then begin
     print,'*********************************************'
     print,' THE CCDGAIN VALUE IS INCORRECT. PLEASE CHECK'
     print,'    BEFORE FURTHER OBSERVING. SHOULD BE: low'
     print,'    CURRENT filter IS: ',ccdgain
     print,'*********************************************'        
    endif

    ccdspeed = hdrdr(h,'CCDSPEED')    
    if strcompress(ccdspeed,/remove_all) ne "'fast'" and keyword_set(verbose) then begin
     print,'*********************************************'
     print,' THE CCDSPEED VALUE IS INCORRECT. PLEASE CHECK'
     print,'    BEFORE FURTHER OBSERVING. SHOULD BE: fast'
     print,'    CURRENT filter IS: ',ccdspeed
     print,'*********************************************'        
    endif


;  UT TIME
;   dum=hdrdr(h,'UT')
   dum=hdrdr(h,'UTC') ;New for HIRES upgrade Aug 2004
;print, 'UTC = ', dum
   hr=fix(strmid(dum,1,2))
   mn=fix(strmid(dum,4,2))
   sc=fix(strmid(dum,7,2))
   hr2=hr
   mn2=mn
   sc2=sc

;Add half the exposure time
   sc=sc+(expt/2.)
   if sc ge 60 then begin
      mnadd=fix(sc/60.)
      sc=sc-60.*mnadd
      mn=fix(mn+mnadd)
   endif
   if mn ge 60 then begin
      hradd=fix(mn/60.)
      mn=fix(mn-60.*hradd)
      hr=fix(hr+hradd)
   endif

;Add the exposure-meter flux-weighted mid-time
; Duration to flux-weighted midpoint (fwmp)
    fwmp=fix(hdrdr(h,'EXM0FWMP'))

;print, 'EXMOFWMP = ', fwmp
;print, ' '
; Add the FWMP time
   sc2=sc2+fwmp
   if sc2 ge 60 then begin
      mnadd=fix(sc2/60.)
      sc2=sc2-60.*mnadd
      mn2=fix(mn2+mnadd)
   endif
   if mn2 ge 60 then begin
      hradd=fix(mn2/60.)
      mn2=fix(mn2-60.*hradd)
      hr2=fix(hr2+hradd)
   endif

;  DECKER NAME
   decker = hdrdr(h,'DECKNAME')

   decker = strtrim(decker,2)   
   decker = strmid(decker,1,2)  ;get rid of ticky
;   len = strlen(decker)
;   decker = strmid(decker,1,len-2)
;   decker = strtrim(decker,2)

; COUNTS
   counts=round(hdrdr(h,'EXM0SSUM')/1000.)  ; in units of 1000 Exposure meter counts


;Exposure meter on?
 exposer_on = hdrdr(h, 'EXM0STA')  ; = 'Ready   '    ?
 exposer_on = strtrim(exposer_on,2)
   if exposer_on ne  '''Ready   '''  then begin
;     print,'*********************************************'
;     print,'Exposure Meter is not on'
;     print,'*********************************************'
     exposer_on = 'n'
   end

geotime = hr*3600. + mn*60. + sc  ;in sec
hr=strtrim(string(hr),2)
if strlen(hr) eq 1 then hr=' '+hr
min=strtrim(string(mn),2)
if mn lt 10 then min = '0'+min
sec=strtrim(string(fix(sc)),2)
if sec lt 10 then sec = '0'+sec

midtime = hr2*3600. + mn2*60. + sc2
hr2=strtrim(string(hr2),2)
if strlen(hr2) eq 1 then hr2=' '+hr2
min2=strtrim(string(mn2),2)
if mn2 lt 10 then min2 = '0'+min2
sec2=strtrim(string(fix(sc2)),2)
if sec2 lt 10 then sec2 = '0'+sec2

;print,'geotime=',geotime,'  midtime=',midtime

deltat=strtrim(string(fix(expt)),2)
len = strlen(deltat) 
if len eq 2 then deltat = '  '+deltat  ;add space
if len eq 3 then deltat = ' '+deltat

underscore_loc = strpos(fitsnm, "_")
rec=strmid(fitsnm, underscore_loc+1, 4)   ;remove the leading "knn" from filename
;;; JJ CHANGE: 09/25/2010, added a digit for J100 era
for j=0,2 do begin           ;remove the leading zeros
  len=strlen(rec)
  firstchar = strmid(rec,0,1)
  if firstchar eq '0' then rec = strmid(rec,1,len-1)
end
len=strlen(rec)
if len eq 1 then rec = '   '+rec  ;right justify
if len eq 2 then rec = '  '+rec
if len eq 3 then rec = ' '+rec


;print,''
;print,'REC#  Object   I2   MIDTIME   Delta T'  
;THE TWO FINAL TIMES: Center
geo_midtime =  hr  +':'+ min  +':'+ sec    ;geometric midtime of exposure
flux_midtime = hr2 +':'+ min2 +':'+ sec2   ;flux-weighted midtime

warn = ' '  ;no warning
diftime = midtime - geotime  ;in sec
if abs(diftime) gt 20. then begin
  warn = 'Two midpts differ by ' + strtrim(string(fix(diftime)),2) + ' s'
end

;warn = ' '+decker + ' '+warn ;decker and any warning

;print,rec + '   '+target+' '+iodine_in+'    ' + flux_midtime +'  '+deltat+'  (geom:'+ geo_midtime,')'
target=target+'            '
recstring = strtrim(string(rec),2)
recstring = strmid(recstring+'   ',0,4)

; 4/24/18, fix wideflat recnum and outstring to put consecutive wideflats on same line.


;Print Results
outstring = string(recstring, target, iodine_in, flux_midtime, deltat, geo_midtime, decker, $
                    format='(a4,3x,a14,1x,a1,2x,a8,2x,i4,2x,"(",a8,")",a3)')
;if keyword_set(cts) then outstring += string(counts,format='(i4)') + 'k '
if cts eq 1 then outstring += string(counts,format='(i4)') + 'k '

;Calculate seeing added by BJ 7/12/2013
IF counts GT 0 THEN BEGIN
    seeing, filename, SeeVal=SeeVal, /silent
    outstring += string(SeeVal, format='(F4.1)')+'"'
    if SeeVal lt 0.6 then outstring += ' Wow/warning'
ENDIF

if abs(diftime) lt 20 then begin
    outstring += string(warn, format='(a3)')
end else begin
    outstring += string(warn,format='(a28)')
end

if keyword_set(verbose) then print,outstring
IF n_elements(n) eq 1 then begin
  for j=0,n-2 do begin
    len = strlen(fitsnm)
    tail = strmid(fitsnm,len-3,3)
    tailnum=fix(tail)
    newnum = tailnum+1
    newst	 = string(newnum)
    newst = strtrim(newst,2)
    if newnum le 9 then newst = '00'+newst
    if newnum ge 10 and newnum le 99 then newst = '0'+newst
;    fitsnm = strmid(fitsnm,0,4)+newst
    fitsnm = strmid(fitsnm,0,5)+newst
    ;;; JJ CHANGE: 09/25/2010, added a digit for J100 era
;    mtfits,fitsnm,inpdir=ddir,n=1,cts=cts  ;mtfits calls itself! Also, supress 'not found' errors by setting the n parameter
    mtfits,fitsnm,inpdir=ddir,n=1  ;mtfits calls itself! Also, supress 'not found' errors by setting the n parameter
  end	
END

return
end


;Common for all calibration files:
;	- exposure meter off, EXM0STA == “Safe/Off”
;	- lamp filter is ng3, LFILNAME == “ng3”
;
;- Focus:
;	- iodine out, IODIN == “F" and IODOUT == "T"
;	& pinhole decker, DECKNAME == “D5”
;	& thorium-argon lamp on, LAMPNAME contains “ThAr” (case-insensitive)
;
;- Iodine
;	- iodine cell is warm, TEMPIOD2 == 50±1
;	& iodine cell is in the light path, IODIN == “T" and IODOUT == “F”
;	& quartz lamp is on, LAMPNAME contains “quartz” (case-insensitive)
;
;- ThAr
;	- iodine cell is out of the light path, IODIN == “F" and IODOUT == “T”
;	& thorium-argon lamp is on, LAMPNAME contains “ThAr” (case-insensitive)
;	& decker is not pinhole, DECKNAME != “D5”
;
;- Wideflats
;	- iodine cell is out of the light path, IODIN == “F" and IODOUT == “T”
;	& decker is C1, DECKNAME == “C1”
;	& must have at least 5(?) of these files to operate 
;
;- B star
;	- iodine cell is warm, TEMPIOD2 == 50±1
;	& iodine cell is in the light path, IODIN == “T" and IODOUT == “F”
;	& exposure meter on, EXM0STA == “Ready”
;	& target name starts with “HR”, TARGNAME.startswith(“hr”) (case-insensitive)
;	& SNR > 100, EXM0LSUM >= 125k









