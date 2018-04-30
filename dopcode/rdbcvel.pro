pro rdbcvel, starname $
		   , cf       $
		   , obdsk     $
		   , logfile=logfile $
		   , noprint=noprint $
		   , obdsk=obdsk1 $
           , nik=nik  $
           , psfpix=psfpix $ 
           , psfsig=psfsig
           
if keyword_set(obdsk1) then obdsk = obdsk1
;This code reads bcvel and constructs a cf data structure with the
; necessary information
;
;starname (input string)    examples: '509' or '4983' or 'GL897'
;logfile (keyword string)   This allows on-line observation log sheets
;			      other that the default (bcvel.ascii)
;			      to be searched.

;Created Aug 5, 1993  R.P.B.
;

obd5 = getenv("DOP_SPEC_DIR") ; environment variable. Spec kept here.
obdsk= getenv("DOP_SPEC_DIR")

if 1-keyword_set(logfile) then begin
    starname=strtrim(starname,2) ;trim blanks from starname
;online log sheet file
    n_logs=n_elements(logfile)                    ;number of logfiles
endif
n_logs=n_elements(logfile)      ;number of logfiles
logfile=[logfile]
bnum=0                          ;counter
;internal bookeeping struct
dum={obnm:'?',iodnm:'?',bc:0d,z:0d,jd:0d,dewar:0,gain:2.5, $
     cts:long(0),mnvel:0d,mdvel:0.,med_all:0.,errvel:0.,mdchi:0.,nchunk:0, $
     mdpar:fltarr(20),mnpar:fltarr(20),sp1:0.,sp2:0.,spst:'?',phase:0., $
     psfpix:[0.00,-2.40,-2.10,-1.60,-1.10,-0.60, 0.60, 1.10, 1.60, 2.10, 2.40, 0.00, 0.00, 0.00,0.00],$
     psfsig:[0.40, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.30, 0.00, 0.00, 0.00,0.00]}

if keyword_set(psfpix) then begin
    dum.psfpix = psfpix
    dum.psfsig = psfsig
endif

cf=replicate(dum,3000)                             ;  "         "         "
dum='?'                                            ;string dummy
obtype='o'
if starname eq 'iod' then starname='iodine'
if starname eq 'iodine' then obtype='i'

;This section of code reads the log sheet, creates a list of
;   observations to be analyzed, and makes sure that each
;   observation can be found on disk
tstamp = systime(1)
for n=0,(n_logs-1) do begin
    outfile = 'deleteme-'+str(tstamp, format='(D0.0)')
;    spawn,'\rm deleteme'
    spawn,'\rm '+outfile+' >& /dev/null'
;    spawnst='grep -i '+starname+' '+strtrim(logfile(n),2)+ ' >  deleteme'
    spawnst='grep -i '+starname+' '+strtrim(logfile(n),2)+ ' > '+outfile
    spawn,spawnst
;stop
;    close,4 & openr,4,'deleteme'                   ;open bary log sheet file
    close,4 & openr,4,outfile                   ;open bary log sheet file

    qq=0                        ;current log file has not been read
    dum='?'
    while (eof(4) eq 0) do begin ;begin reading log
        readf,4,dum
	    spawn,'\rm '+outfile + ' >& /dev/null'
        
;target star?

; obtnum is word location of obtype in logfile, 
;    old style obtnum = 7, new style obtnum = 5
        if strlowcase(strtrim(getwrd(dum,1),2)) eq strlowcase(starname) $
          and qq eq 0 then begin
            if nwrds(dum) eq 7 then obtnum=nwrds(dum)-2 else obtnum=nwrds(dum)-1
            qq=1
        endif

        if qq gt 0 then if strlowcase(strtrim(getwrd(dum,1),2)) eq strlowcase(starname) and $ 
          strtrim(getwrd(dum,obtnum),2) eq obtype then begin ;if so, begin
            if not keyword_set(noprint) then print,dum                     
            cf(bnum).obnm=strtrim(getwrd(dum,0),2) ;observation
;what are the two following lines doing?   PB Oct. 28, 1994
            cf(bnum).bc=float(strtrim(getwrd(dum,2),2))     ;bary correction
            cf(bnum).jd=double(strtrim(getwrd(dum,3),2))    ;julian date
            if cf(bnum).jd lt 2440000 then cf(bnum).jd = cf(bnum).jd + 2440000d0
            cf(bnum).dewar=chip(cf(bnum).obnm,gain)         ;which CCD?
            if cf(bnum).dewar eq -1 then begin              ;CCD not found!
                print,'Unable to find chip # for observation: ' $
                      +cf(bnum).obnm
                print,'Assuming Dewar #6 is appropriate.'
                print,'   Use Control C if you wish to bail out now!'
                cf(bnum).dewar=6
            endif
            cf(bnum).gain=gain
;change the PSF description for pre-fix observations
            if (cf(bnum).dewar eq 1) or (cf(bnum).dewar eq 2) or $
              (cf(bnum).dewar eq 6) or (cf(bnum).dewar eq 8) or $
              (cf(bnum).dewar eq 13) or (cf(bnum).dewar eq 98) or $
              (cf(bnum).dewar eq 99) then begin
                cf(bnum).psfpix = [0.00,-5.00,-4.00,-3.00,-2.00,-1.00, 1.00, 2.00, 3.00, 4.00, 5.00, 0.00, 0.00, 0.00, 0.00]
                cf(bnum).psfsig = [0.85, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.60, 0.00, 0.00, 0.00, 0.00]
            endif

            dsknm=obdsk+cf(bnum).obnm ;Obs. disk name
            dum=first_el(findfile(dsknm)) ;Obs. on disk?
            dork=0  &  if dum ne dsknm then dork=1
            if dork eq 0 then bnum=bnum+1 else begin
                if obtype eq 'i' then talk='Iodine: '
                if obtype eq 'o' then talk='Observation:'
                talk=talk+dsknm+'  was not found on disk!'
                print,talk
                print,'   Use Control C if you wish to bail out now!'
            endelse
        endif
    endwhile
    close,4                     ;Close log file
endfor
if bnum le 0 then cf=cf(0) else cf=cf(0:bnum-1) ;Bookeeping structure
;End of the bookeeping/log reading section 

return
end


