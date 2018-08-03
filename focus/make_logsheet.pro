pro make_logsheet;, logname;,verbose=verbose

; PURPOSE: Create a logsheet based on one nights' worrth of observations.
;          The only input should be the raw files.
; CREADED: Apr 2018
; 
; Keyword: Set verbose to see output on screen. Default is to write to a file.

; Todo:  Somesort of error handling is still needed. Do we need to specificy the lognme?
;        Is logname even needed?

;run = strmid(logname,0,4) ; requires format: d001.logsheet1
raw_dir = getenv('RAW_RAW') ; Location of 2D Echellograms
log_dir = getenv('MIR3_LOG')

;file_list = file_search(raw_dir+run+'*fits') ; if using a run name
file_list = file_search(raw_dir + '*fits',count=nf); if generating a log for all of the files
if nf eq 0 then begin
  print, raw_dir
  print,'MAKE_LOGSHEET: No raw files found.'
  print,'   Check environment variables RAW_RAW'
endif
files = strarr(nf)

fname1 =strsplit(file_list[0],'/',/extract); [-1]
nchar_f1 = n_elements(fname1)
fname2 = fname1[nchar_f1-1]
run = strmid(fname2,0,8)
logname = log_dir+run+'.logsheet1'

hiraw,raw,file_list[0],header,chip=1 ; any chip works
; Generate an output line for every raw file.

; Open a temporary logsheet. Add the header information.
l1 ='                 HIRES Spectrograph Observing Log '
l2 ='__________________________________________________________________________'
;l3 ='Observer: Morton, Howard, Isaacson    Tape: j150 Telescope: KeckI         '
;l4 ='UT Date 26 May 2012            Chip: LincolnLab 4096x3, 15micron          '
l5 ='Windowing:   Cols: 4096        Rows: 2048 (binned)    Binning: 3r x 1c    '
l6 ='Ech: XXXXXXX  X-Dis: XXXXXXX   Slit: B5/C2 (0.86 x 3.5/14 arcsec)         '
l7 ='CAFRAW: 7        COFRAW: 70482   low gain     Filter: clear,KV370 out     '
l8 ='Red Collimator in.   --> FWHM=2.377 (used Th-Ar#2, 10sec, kv370 OUT)      '
l9 ='--------------------------------------------------------------------------'
l10='nn.fits   Object     I2   Mid-Time  Exp.   Comment                        '
l11='number    Name     (y/n)   (UT)     time                                  '



; lines 1, 2,5,9,10,11 are always the same.
;logname = 'temp.txt'
close,1
openw,1,logname
;printf,1,l1
;printf,1,l2

; line 3 requires observers and tape/run name.
observer = strcompress(sxpar(header,'OBSERVER'),/remove_all)
tape = strcompress(sxpar(header,'OUTFILE'),/remove_all)
l3 = 'Observer: '+observer+ ' Tape:'+tape+' Telescope: KeckI'

; line4 requires the date.
for i=0, nf-1 do begin
    head = headfits(file_list[i])
    cts = hdrdr(head,'EXM0SSUM')
    IF cts GT 0 THEN BEGIN
        print, file_list[i]
        date1 = sxpar(head,'DATE-OBS')
        d1 = strsplit(date1,'-',/extract)
        d2 = reverse(d1)
        d3 = strjoin(d2,' ')
        BREAK
    ENDIF
ENDFOR

l4 = 'UT Date '+d3 + '        Chip: LincolnLab 4096x3, 15micron '

; line 6 has the echelle and X-disp. This is only defined after the focus is complete
; Think about this later. same for l7, same for l8

printf,1,l1
printf,1,l2
printf,1,l3
printf,1,l4
printf,1,l5
printf,1,l6
printf,1,l7
printf,1,l8
printf,1,l9
printf,1,l10
printf,1,l11

wf1 = ''
for i=0,nf-1 do begin

   ;separate files from directories
    temp = strsplit(file_list[i],'/',/extract); [-1]
    nt = n_elements(temp)
    file = temp[nt-1]
    dir = '/'+strjoin(temp[0:nt-2],'/')+'/'

   ; Collect the individual lines for the logsheet and print them to a file.
   mtfits,inpdir=dir,file,outstring=outstring;,/verbose

   ; only print out one line for consecutive wideflats.
   if getwrd(outstring,1) eq 'wideflat' then begin ;wf_fix = 1
     obsnm = getwrd(outstring,0)
     obj   = getwrd(outstring,1)
     if wf1 eq '' then wf1 = obsnm
     ; open the next file and see if that one is a wideflat
     IF i LT nf-1 THEN temp1 = strsplit(file_list[i+1],'/',/extract); [-1]
     nt1 = n_elements(temp1)
     file1 = temp1[nt1-1]
     mtfits,inpdir=dir,file1,outstring=outstring1;,/verbose
     outstring1 = outstring1[0]
     obsnm1 = getwrd(outstring1,0)
     obj1   = getwrd(outstring1,1)

     if obj eq 'wideflat' and obj1 ne 'wideflat' then begin
       wf2 = obsnm1 -1
       newnum = str(wf1) + '-'+ str(wf2)
       strput,outstring,str(newnum)
       printf,1,outstring
     endif
      
    endif else printf,1,outstring

endfor




close,1

print, 'MAKE_LOGSHEET.PRO: COMPELTE'
print, '   New logsheet created: ',logname
print, "MAKE_LOGSHEET completed successfully"
end ; program
