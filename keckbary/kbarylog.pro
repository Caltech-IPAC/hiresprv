pro kbarylog,logfile,devel

; FUNCTION: Calculate Barycentric Correction for
; 	    Stellar spectra.

;  METHOD: 1.) Obtain Object Name, FLUX-WIEGHTED mean epoch, etc. from
;              online logsheets.
;          2.) Star  positions are stored in: kvel/keck_st.dat,  hip.dat,
;              kother.ascii (ktranslation.dat rarely used to find HIP numbers)
;          3.) Drive kbary.pro, which makes calculation.
;          4.) Append kbcvel.ascii file

; keywords: LOGFILE:  name of logsheet to run through kbarylog.pro
;                   ie j111.logsheet1
;           DEVEL:     Set to 1 for testing, otherwise omit.

;Create: NOV-7-93	ECW
;Modified: JUL-95	CMc.   Modified to Drive New Barycentric Routines 
;Modified; JAN-96       ECW    Modified to get input info from online 
;			       logsheets.  Currently setup to run on 
;                              the machines: hodge,quark,coude.
;Modified; Jan-97       GWM    cleaned up, made identical to Keck version
;Modified; Nov-97       GWM    Auto-read log lines; Invoke hipparcos catalog
;Modified; Nov-01   CMc    To accomodate 1000+ image seismology runs
;                               & general cleanup
;Modified; May-02   CMc    To include remove acc. calc. + other improvements
;Modified; Feb-05   CMc    To execute kbcvel.ascii backups into
;                          kbcvel_backup/ directory
;
; Modified: sep-16  HTI, added auto keyword to automatically create reduce files
; Modified: nov-17 HTI   added devel keyword for testing and isolated all needed
;                       files in the working direcotry.
;                       Removing obsolete keywords: cep=cep,test=test,tyc=tyc
;                       Removing /auto en route to running from unix command line
;                       Call from command line or bash script with:
;                           idl -e "kbarylog" -args j111.logsheet1 1

; Read terminal command line inputs. can only be logfile, devel
invar = command_line_args(count=nargs)
if nargs gt 2  then begin
    print,'% KBARYLOG.PRO: NEW ARGUMENTS ADDED'
    print,'%    CHECK TO MAKE SURE INPUTS ARE COMPATIBLE WITH command_line_args'
    return
ENDIF

;Use command line arguments to allow program to run from unix command line.
; If new keywords are added, this
if nargs gt 0 then begin
    logfile = invar[0]
    if nargs eq 2 then $
        devel = invar[1]
    print,'Using input from terminal: ',invar
endif

;VARIABLE DECLARATION:
noerror=1 & chk='' & du='' & dum=''  &  dummy=''  &  tpname=''  &  req=''  
log='' &  logline='' &  obtype='' & mid=''
year=0  &  month=0  &  day=0  &  hr=0  & sc=0 & epoch=0
if n_elements(logfile) eq 0 then logfile='' 

skiplist= ['WIDEFLAT','WIDE','WF','W','WIDE-FLAT','WIDE/FLAT','W/F', $
           'WIDEFLATS','WIDES','WFS','WIDE-FLATS','WIDE/FLATS', $
           'WIDE_FLAT','FLAT','JUNK', 'WIDEFLAT_E4','WIDEFLAT_D5', $
           'WIDEFLAT_C2','WIDEFLAT_C5','FLATFIELD','SATURATED','SKIP','TEST']
iodlist = ['IODINE','I','I2','IOD','IODINE-B1','I2-B1']
thorlist = ['TH-AR','TH_AR','THAR','TH/AR','THORIUM','THORIUM-ARGON','THNE','TH_NE','TH-NE','FOCUS','THAR_C5']
daylist = ['DAY','DS','DAYSKY','DAY-SKY','DAY_SKY']
skylist = ['SKY', 'DARK','BIAS','narrflat','NARROWFLAT']

;DEFINE STRUCTURES
maxsize = 9000                  ;  ;was 5000
log = {log, object: '', hour: '', min: '', sec: '', type: ''}
temp = {bcvel, filename:'', object:'', cz:0.d0, mjd:0.d0, bjd:0.d0, ha:0.d0, type:''} ;Temp struct for results;add BJD gm 1Jan2009
temp = replicate(temp[0],maxsize)

;Directory structure
logdir = getenv("MIR3_LOG")
barydir = getenv("MIR3_BARY")
bary_log = getenv("DOP_BARYFILE") ; full path
strucfile = getenv("DOP_KECK_STRUC")

;bf='kbcvel.ascii'  ; this is the normal filename
bf = bary_log
bcfile = barydir+bf 


; if run is d001, then make a new kbcvel.ascii file, if not, then append
head1 ="-----------------------------------------------------------------------"
head2 ="Filename        Star    BCVel(m/s)   BJD-2.444e6  HrAng. Obtype(i/t/o/u)" 
head3 ="-----------------------------------------------------------------------"


bcfile =  bary_log
file_ck = file_search(bcfile,count=nck)
if nck eq 0 then begin ; create new barylog file
  get_lun,une
  openw,une,bcfile
  printf,une,head1
  printf,une,head2
  printf,une,head3   
  close,une
  free_lun,une

endif

tempbcfile = strarr(maxsize)    ;temporary storage of ascii results: 200 lines

print,'     *************************************************************'
print,'     **      THE KECK BARYCENTRIC CORRECTIONS PROGRAM           **'
print,'     **                                                         **'
print,'     ** You input:                                              **'
print,'     **            LOGSHEET filename ,ie., j64.logsheet1        **'
print,'     **            UT DATE of the Observations                  **'
print,'     **                                                         **'
print,'     ** Output to: '  +  bcfile  +      '                       **'
print,'     **                                                         **'
print,'     *************************************************************'

;PROMPT FOR ONLINE LOGSHEET FILENAME
print,' '
;GETLOGSHEET:

print,'Finding logfile automatically'


log_check = file_search(logdir+logfile,count=nlog)
if nlog eq 0 then begin
    print,"% KBARYLOG: Logsheet not found: ",logfile
    return
endif

logfileorig = logfile

period = strpos(logfile,'.')
if period[0] ne -1 then tpname = strmid(logfile,0,period) ; u100 is OK now.


;READ LOGSHEET
print,'reading: ',logfile

spawn, 'cat ' + logdir + logfile , output
output = cull(output)           ; remove any blank lines
logline = (output(where(getwrds(output,0) eq 'UT')))[0] ; 1 element
firstlogline = strmid(logline,0,26) ; first part of line contains UT date

;Apr 2018 need to pull year, mon, day out of the logsheet
day    = getwrd(logline,2)
month  = getwrd(logline,3)
year   = getwrd(logline,4)
; end apr 2018 addition

num = 0
skip = 0                        ;Reset to NOT skip
strindgen = strtrim(string(indgen(maxsize)),2)
print,' '
print,'Filename     Object    I2?  UT      BJD        Bary Corr (m/s)'

print,'--------------------------------------------------------------------'
openr,logune,logdir+logfile,/get_lun
;LOOP THROUGH EACH LINE ON THE LOGSHEET
WHILE eof(logune) eq 0 do begin ;check for end of file (eof = 1)
    readf,logune,logline        ;read one line in the logsheet

;Read the first four entries on the line.
    recnum = strtrim(getwrd(logline[0],0),2) ;record number
    log.object = strtrim(strupcase(getwrd(logline,1)),2) ;object name
    first2 = strmid(log.object,0,2)
    celltest = strtrim(strupcase(getwrd(logline,2)),2) ;Was cell in?
    strtime = strtrim(getwrd(logline,3),2) ;time from logsheet
    linelen = (strlen(logline))[0] ; first element only
    temptest = strpos(strupcase(logline),'TEMP') ; test for word "Template"

;Construct reduced filename
    filename = tpname + '.' + recnum

;Guarantee that this is really an observation of something useful
    IF ((celltest eq 'Y' or celltest eq 'N') and $ ;Was cell specified?
        (select(skiplist,log.object) ne 1) and $ ;Not wide flat nor skiplist?
        select(strindgen,recnum)) and $ ;No multiple #'s on line
      (linelen gt 1)  THEN BEGIN ;guarantee some log there 

        if first2 eq 'HD' then $
          log.object = strmid(log.object,2,strlen(log.object)-2)
        if (celltest eq 'Y') then log.type='o' else log.type='t'
        if select(iodlist,log.object) then begin
            log.type='i' & log.object='iodine'
        endif
        if select(thorlist,log.object) then begin
            log.type='u' & log.object='th-ar'
        endif
        if select(daylist,log.object) then begin
            log.type='s' & log.object='day_sky'
        endif
        if select(skylist,log.object) then begin
            log.type = 'u'            
        endif
                                ;
        if temptest[0] ne -1 and log.type ne 't' then begin ; Error Trap
            print,'****WARNING:  Possible Template Detected: '
            print,logline
            print,'But observation type is not "t".  Was I2 cell in?'
            help,log.type
            if no('Continue?') then stop
        endif


;ENTERING TIME RETRIEVAL SECTION
        colon1 = strpos(strtime,':') ;position of first colon
        colon2 = rstrpos(strtime,':') ;postiion of last colon

        strhour = strmid(strtime,0,colon1) ;string version of UT hour of obs.
        strminute = strmid(strtime,colon1+1,colon2-colon1-1) ;UT minute
        strsecond = strmid(strtime,colon2+1,10) ;UT second

        hour = float(strhour)
        minutes = float(strminute) + float(strsecond)/60.d0

        jdUTC = jdate([year,month,day,hour,minutes])
        mjd = jdUTC-2440000.d0  ; modified JD
        bjd = mjd  ;default bjd value, for calibration exposures, until coords available.

; Fix lengths of output strings
        len = (strlen(filename))[0]
        if len lt 9 then for jj=0,9-len-1 do filename = filename + ' '
        obj = log.object
        len = (strlen(obj))[0]
        if len lt 8 then for jj=0,8-len-1 do obj = ' '+obj 
        if strlen(strminute) eq 1 then strminute = '0'+strminute 
        if strlen(strsecond) eq 1 then strsecond = '0'+strsecond 
        strtime = strhour+':'+strminute+':'+strsecond
        len = (strlen(strtime))[0]
        if len lt 9 then for jj=0,9-len-1 do strtime = strtime + ' '
                                ;
        cz = 0.0d0 
        ha = 0.d0
        filename = 'r'+filename

        IF select(['o','t'],log.type) then begin ;need barycentric correction

;       LOOKUP COORDINATES: lookup.pro takes starname (log.object) and finds


            if first2 ne 'HR' AND first2 ne 'BR' then begin ; SKIP B STARS (no B.C. for B*s)
;                klookup,log.object,coords,epoch,pm,parlax,radvel,hip=hip,$
;                  barydir=barydir,cat=cat,tyc=tyc

            specfile = getenv("RAW_ALL_OUT_FITS") + filename + ".fits"
            head = headfits(specfile)
            ra_sex = hdrdr(head, "RA")
            dec_sex = hdrdr(head, "DEC")
            ra_sex = strsplit(ra_sex, "'", /extract)
            dec_sex = strsplit(dec_sex, "'", /extract)
            ra_split = strsplit(ra_sex, ':', /extract)
            dec_split = strsplit(dec_sex, ':', /extract)
            inp_ra = ten(ra_split) * 15
            inp_dec = ten(dec_split)
            inpcoords = [inp_ra, inp_dec]

                gaialookup, log.object, inpcoords, coords, epoch, pm, parlax, radvel
                if coords(0) eq 0 or coords(1) eq 0 or abs(coords(0)) gt 24 $
                  or abs(coords(1)) gt 90 then begin
                    print,'Your coords for ',log.object,' look bad: ('+$
                      strmid(coords(0),2)+','+ strmid(coords(1),2)+')'
                    print,'If you continue, WRONG barycentric corrections could be '+$
                      'entered into ',bcfile
                    if no('Do you really want to do that?') then  stop
                endif

                if abs( coords(0)) eq 99.d0 then begin ;Logsheet star not found
                    coords = [0.d0,0.d0] ;force ra and dec = 0. :no object found
                    pm     = [0.d0,0.d0] ;dummy proper motion
                    epoch = 2000.d0 ;dummy epoch
                endif else begin 
                    kbary,jdUTC,coords,epoch,czi,obs='CFHT',pm = pm,$
                      barydir=barydir, ha=ha
                    cz = rm_secacc(czi,pm,parlax,mjd)
                endelse

                ;convert JD to BJD - barycentric JD  ;gm 1jan2009
                inpdate = mjd+40000.d0  ;gm helio_jd needs JD - 2400000 not JD-2440000
                outbjd = helio_jd(inpdate,coords(0)*15.d0,coords(1)) ;gm 1jan2009 note *15 and wants JD-2400000.
                bjd = outbjd - 40000.d0  ;gm 1jan2009, get us back to our jd-2440000.
            endif               ; else print,'Skipping Bstar'
        ENDIF                   ; 

        ;fix ha to near 0 hr
        if ha gt 12. then ha = 24.-ha  ;gm 1jan2009
        if ha lt -12. then ha = 24. + ha ;gm 1jan2009

;Print Status to Screen
;    stcz = strtrim(string(fix(cz)),2)
        stcz = strtrim(string(cz),2)
        stbjd = strtrim(string(bjd),2)
        len = (strlen(stcz))[0]
        if len lt 7 then for jj=0,7-len-1 do stcz = ' '+stcz
        infoline = '|  '+filename+' |  '+obj+' |  '
        infoline = infoline + celltest+'  | '+strtime+' | '+stbjd+' | '+stcz+' |' ;gm 1jan2009 add bjd
        k = (strlen(infoline))[0]-1
        dashln = '-'
         dashln  = '-----------------------------------------------------------'
        forinfo = '(A14, A1,   A14,   A1,  A1, A1, A8, A1, D12.6, A1, F9.2)'
        print, format = forinfo, filename , ' ', obj , ' ', celltest, ' ', strtime, ' ', bjd, ' ', stcz

;Store results to Structure
        temp[num].filename = filename
        temp[num].object = log.object
        temp[num].cz = cz
        temp[num].bjd = bjd  ;gm1jan2009
        temp[num].ha = ha
        temp[num].type = log.type
        temp[num].mjd = mjd ;gm change order
        num=num+1
    ENDIF
END                             ;while

;STORE RESULTS IN KBCVEL.ASCII ?
if ~keyword_set(devel) then begin
    temp = temp[0:num-1]            ;trim temp structure array
    print,' '
    ans = 'Y'
endif else ans = 'N'

if strupcase(ans) eq 'Y' then begin
    get_lun,une                 ;get Logical Unit Number
    openu,une,bcfile,/append    ;open bcvel file for writing
    form = '(A14,3X,A19,1X,D11.3,1X,D12.6,1X,F7.3,1X,A1)' ; changed length of  ob to fit singlge line ; HTI 19Oct2011
    print,'Printing results to '+bcfile+' ...'
    for j=0,num-1 do begin
        fn = temp[j].filename
        ob = temp[j].object
        cz = temp[j].cz
        mjd = temp[j].mjd
        bjd = temp[j].bjd
        ha = temp[j].ha
        type = temp[j].type
        printf,une,format=form,fn,ob,cz,bjd,ha,type  ;  removed mjd
    end
    free_lun,une
    print,'Done with '+logfileorig
    print,' '
    comm=' '
    print,' You observed ',strcompress(num),' stars. '+comm
    print,' '
    print,'It''s been a long night. Go to sleep! Nighty!'
endif else begin
    print,'BCVEL Development Mode.'
    print,'   Not updating kbcvel.ascii'
endelse
free_lun,logune 

print, "completed successfully"

end


