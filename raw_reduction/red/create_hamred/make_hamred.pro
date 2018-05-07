pro make_hamred, logfile_in;, run, star=star

; PURPOSE: Create a hamred file to raw reduce Keck-HIRES data using a logsheet.
; 
; Authors: Howard Isaacson, based on work by Chris McCarthy.
; Date:  Jan 2016
;
; STAR: Optional Keyword to only reduce one star
;
; INPUT:  logfile: eg 'j222.logsheet1' ; assumes /mir3/logsheets/
; OUTPUT:  Creates hamred file and returns run, night'
; KEYWORDs: file: destination of hamred file: eg hamred-j222-1 
;			default dir= '/mir3/reduce/
; NOTE:  H. Isaacson. Removed the journal command to save reduction journals. 1/2018
;        HTI, making stand alone hamred files now.

; CALLS findordfind.pro
;       getstartend.pro
;       gettharinfo.pro
;       getflatinfo.pro

logfile_arg = command_line_args(count=nargs)
if nargs ne 1 then begin
    print,"This program must be run from the command line"
    print," The required input is a logshet name"
    logfile = logfile_in
;    return
endif else BEGIN
    logfile=logfile_arg

endelse
;if ~keyword_set(logfile)  then begin
;	print,'Syntax: make_hamred, logfile, /file'
;	print,' logfile eg: j222.logsheet1,' 
;	print,'  run and night are outputs'
;	return
;endif
;logfile = logfile_in


;logdir = '/mir3/logsheets/'
;batchdir = '/mir3/reduce/'
rawdir = getenv("RAW_RAW")
logdir = getenv("MIR3_LOG")
batchdir=getenv("MIR3_REDUCE")

middir = getenv("RAW_MID")
bludir = getenv("RAW_BLU")
reddir = getenv("RAW_RED")


;middir_out = getenv("RAW_ALL_OUT")
reddir_out = getenv("RAW_ALL_OUT")
;bludir_out = getenv("RAW_BLU_OUT")

bottom_file = getenv("RAW_HAMRED_BOTTOM")

; Choose which directory to write the output files.
;spawn,'pwd',current_dir
;current_dir = strcompress(current_dir,/remove_all)+'/'
;print,'current dir',current_dir
;if current_dir eq middir then $
outdir_hamred = reddir
outdir = reddir_out
preprefix = "'i'"
;if current_dir eq reddir then $
;   outdir = reddir_out
;if current_dir eq bludir then $
;   outdir = bludir_out


if n_elements(logfile) eq 0 then begin
    logfile = ''
    read,' Enter logfile name (eg j999.logsheet1): ',logfile
endif 

logname=logfile
; first assume file is in present directory
if (findfile(logfile))(0) eq ''  then logfile=logdir+logfile 
if (findfile(logfile))(0) eq ''  then $
	message,logfile+' not found'

rf,data,logfile                 
; 'data' is the text of the logsheet, string array.

;pos1 = strpos(logfile,'j')
;pos2 = strpos(logfile,'.')
pos1 = 0
pos2 = 4
run = strmid(logname,pos1,pos2-pos1)
print,"run  = ",run

;night =strmid(logfile,pos2+9,2) ; good for 1-99
night = str(1); always
lin = where(strmid(data,0,4) eq '----' or strmid(data,0,4) eq '____')
Nlin = n_elements(lin) 

head = data(0:10)
body = data(11: n_elements(data)-1)

nums = getwrds(body,0)
targets = getwrds(body,1)
yn = getwrds(body,2)
times = getwrds(body,3)

;file=1
;if keyword_set(file) then begin
outfile = outdir_hamred + 'hamred-'+run+'-'+night
;	rf, dont, '/mir3/automate/bottom_j.txt' ;current as of jan 2010
rf, dont, bottom_file ;current as of apr 2012
openw,1,outfile

print,'outdir=',outfile

printf,1,";*********************************************************************"
printf,1,";       HIRES Echelle CCD Image Reduction Batch File                 *"
printf,1,";*********************************************************************"
printf,1,"; For Keck/HIRES reductions on Cadence, template as of Jan 2018.     *"
printf,1,";*********************************************************************"
printf,1,";",strcompress(strmid(head[3],0,25)), ': '+ run+'-'+night

;printf,1,';0. Update the Journal name'
;journal_line = "'/mir3/reduce/reduce_journals/"+run+"-"+night+"'"
;printf,1,'journal_line='+journal_line  ;Modify journal name
;printf,1,'journal, journal_line'

;printf,1,''
;printf,1,";The User must modify the entries under the following 8 categories."
;printf,1,";Then:  IDL> @hamred-jNN-M"
;printf,1,''
printf,1,";1. Raw CCD-Image Input Directory Path, where Raw Images are stored"
;printf,1,"indir='/mir3/raw/'"
printf,1,'indir="'+rawdir+'"'
;printf,1,'; Input directory determined via environment variables.'
printf,1,''

printf,1,";2.  OUTPUT Directory Path for reduced spectra (Defined in .bashrc)"
;printf,1,"; OUTDIR is now defined in the wrapper reduce3.batch (allows hamred-jNN-N to "
;printf,1,"; be copied between red, iodine, and blue reduce dirs).  Uncomment the"
;printf,1,"; next line to run a reduction independent of said wrapper.  KP/Jul06"
;printf,1,";outdir = '/mir3/iodspec/test/'"
printf,1,';Out directory determined via environment variables.'
printf,1,'outdir = "'+outdir+'"'
printf,1,''

printf,1,";3. Prefix to FITS files:  'k#'nnnn.fits  . i.e., 'k68' or 'hires' (string)"
printf,1,"prefix = '"+run+"'"
printf,1,"preprefix = "+preprefix
printf,1,''

printf,1,";4. Record Numbers of Stellar spectra to reduce  here:"
print,body
if n_elements(star) eq 0 then begin
    getstartend,body,startrec,endrec,avoidtxt 
    printf,1,'startrec = '+startrec
    printf,1,'endrec = '+endrec

endif else begin                ; only reduce one star
    nums = getwrds(body,0)
    stars = getwrds(body,1)
    goodnums = nums(where(stars eq star)) ; there better be one
    goodtxt = strchop(deparse(goodnums+','),-1)
    printf,1,"recint = ["+goodtxt+"]"
endelse
printf,1,''

printf,1,";5. List ThAr, Iodine, and any spectra which get no sky subtraction or"
printf,1,";cosmic ray removal ([-1] for no exceptions): "
printf,1,gettharinfo(body)
printf,1,";threc = [-1]"
printf,1,''


printf,1,";6. Record Numbers to AVOID REDUCING, i.e, to skip (junk, flats, tests)."
printf,1,";   List in brackets, e.g., [35,52], and [-1] for none."
printf,1,avoidtxt
printf,1,''

printf,1,";7. Record number of Well-Exposed Iodine or Any Spectrum Well-Exposed"
printf,1,findordfind(body)

printf,1,''

printf,1,";8. WIDE FLAT INFORMATION (crashes if flat_set1 not defined)."
gfi = getflatinfo(body)
    for i = 0,n_elements(gfi)-1  do printf,1,gfi(i)
printf,1,''



    Ndont = n_elements(dont)  ; write the end part of the batch file
    for j = 0,Ndont -1 do printf,1,dont(j)
    close,1
    print,'Done writing ',outfile
;    spawn,'cp /mir3/reduce/hamred-'+run+'-'+night+ ' /mir3/reduce_red/'
;    spawn,'cp /mir3/reduce/hamred-'+run+'-'+night+ ' /mir3/reduce_blue/'
;    print,'cp '+batchdir+'hamred-'+run+'-'+night+ ' '+reddir
;    spawn,'cp '+batchdir+'hamred-'+run+'-'+night+ ' '+reddir
;    spawn,'cp '+batchdir+'hamred-'+run+'-'+night+ ' '+bludir


;endif

end

