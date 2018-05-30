pro endofnight_hires, logsheet

; Purpose: Check the logsheet, Drive kbarylog, make the hamred and reduce3 files
;			then run the raw reduction, and S-values routines.
;			Establish IDL path for each task to eliminate program conflicts.

; Note: Updated 1/2018 to make only hamred, not reduce3.batch file.

logsheet_cmd = command_line_args(count=nargs)
if nargs ne 1  then begin
    print,'% ENDOFNIGHT_HIRES.PRO: PROBLEM WITH ARGUMENTS'
    print,'%    CHECK TO MAKE SURE INPUTS ARE COMPATIBLE WITH command_line_args'
    print,"%  Try running from the command line: :> idl -e endofnight_hires -arg 'j999.logsheet1'"
;    return
ENDIF else begin
    logsheet=logsheet_cmd
endelse

;if ~keyword_set(logsheet) then begin
;	print,"Required syntax: IDL> endofnight_hires,'j???.logsheet?'"
;	return
;endif

run = strmid(logsheet,0,4)
night = strmid(logsheet,13,2)

print,"Making hamred for logsheet:",logsheet
make_hamred, logsheet;,run ;, night, /file ; run, night are outputs

; make_reduce3.batch-j??-? file, including call to S-values.
;make_reduce3, run,night 

;mir3_reduce = getenv("MIR3_REDUCE")
;batch_file = mir3_reduce+'reduce3.batch-'+run+'-'+night+'.pro'
; print,'Running Batchfile...'
; cd,'/mir3/reduce/'
;cmd = "idl -e @"+batch_file
;print,"cmd = ",cmd
;spawn,cmd
;stop

print, "completed successfully"

return
end
