pro make_reduce3, run, night;, file=file

; Purpose: Make the reduce3.batch-j???-? file to drive the raw reduction at the
;			end of an observing night.
; run, night are inputs.
; Date: Jan 2016

;if n_elements(keyword_set) ne 2 then begin
;	print,'Syntax: make_reduce3.batch, run, night'
;	print,' Run: j222, night: 1,2,3'
;	return
;endif

red_dir = '/mir3/reduce/'
reduce3_file = 'reduce3.batch-'+run+'-'+night+'.pro'

openw,1,red_dir + reduce3_file
printf,1,';'
printf,1,'; reduce3.batch'
printf,1,';'
printf,1,'; An IDL batch file runs reductions of iodspec, bluespec, and redspec'
printf,1,'; in series.  A wrapper for hamred batch files.'
printf,1,';'
printf,1,'; THIS VERSION FOR USE ON FORNAX/OWEN. (Marcus, Ian?)/'
printf,1,''
printf,1,'; Instructions'
printf,1,'; ------------'
printf,1,'; Set up hamred-jNN-M files in reduce/, reduce_blue/, or reduce_red/./
printf,1,';   Use hamred-template or hamred-j32-1 or later for the three-chip/
printf,1,';   sequential reduction to work. '
printf,1,'; Copy the nights hamred-jNN-M into the other two directories.'
printf,1,'; Change hamred filenames and output directories (if needed) below./
printf,1,'; IDL> @reduce3.batch'
printf,1,';'
printf,1,'; N.B.This script re-compiles the reduction routines each time to be '
printf,1,'; sure middle, blue, red versions stay separate (blue HIRSPEC is'
printf,1,'; slightly different than red & middle). '
printf,1,';'
printf,1,'; KP / 10 Jul 2006'
printf,1,'; KP&GM 8 Jul 2008 - cp_flats=0printf,1, use addwf, not groupaddwf'
printf,1,';'
printf,1,';Check to see if barylog has been run.'
printf,1,";print, 'Barylog must be run before reducing data '"
printf,1,";print,'    so that S-values can be updated.'"
printf,1,';print'
printf,1,";print,'Have you updated barylog (y/n)"
printf,1,";check = ''"
printf,1,";read, check"
printf,1,";if check ne 'y' then stop"
printf,1,''
printf,1,"; 1) Reduce middle chip.
printf,1,"cd,'/mir3/reduce/',current=start_dir"
printf,1,"print,' Reducing middle chip.  Begun: '+systime(0)"
printf,1,"@precompile"
printf,1,"outdir = '/mir3/iodspec/'"
printf,1,"@hamred-"+run+"-"+night+"            ; <- Update this line."
printf,1,"cp_flats = 0   ; Keep set to 0."
printf,1,"               ; (Setting to 1 links grouped flats from main dir.)"
printf,1,""
printf,1,"; 2) Reduce blue chip."
printf,1,"cd,'/mir3/reduce_blue/',current=main_dir"
printf,1,"print,' '"
printf,1,"print,'**********************'"
printf,1,"print,' Reducing blue chip.  Begun: '+systime(0)"
printf,1,"@precompile_blue"
printf,1,"outdir = '/mir3/bluespec/'"
printf,1,"@hamred-"+run+"-"+night+"             ; <- Update this line."
printf,1,""
printf,1,"; 3) Reduce red chip."
printf,1,"cd,'/mir3/reduce_red/'"
printf,1,"print,' '"
printf,1,"print,'**********************'"
printf,1,"print,' Reducing red chip.  Begun: '+systime(0)"
printf,1,"@precompile_red"
printf,1,"outdir = '/mir3/redspec/'"
printf,1,"@hamred-"+run+"-"+night+"                    ; <-- Update this line."
printf,1,"cd,start_dir"
printf,1,''


; printf,1,"; 4) Run S-value program."
; printf,1,";**********************"
; printf,1,";Calculating S-values,  Begun: "+systime(0)
; printf,1,"cd,'/mir3/sval/',current=main_dir"
; printf,1,"@precompile_svals"
; printf,1,"run = '"+run+"'" 				         ; <- ***UPDATE RUN NUMBER!***
; printf,1,"hk2_keck,updateS=run,/quiet"
; printf,1,"cd,start_dir"
; printf,1,""
; printf,1,"; 5) Automatically create the .thid file ; HTI NEW"
; printf,1,"cd,'/mir3/thid/',current=main_dir"
; printf,1,"@precompile_thid"
; ;printf,1,"cd,'/mir3/thid/'"
; printf,1,"thid_automate,run='"+run+"'"
; printf,1,"cd,start_dir"
; printf,1,""
; printf,1,"; 6) Automatically run the telluric RV program"
; printf,1,"cd,'/mir3/telluric_rv/'"
; printf,1,"dr_chi2,run='"+run+"'"  
; printf,1,""
; printf,1,"; 7) Run the Observation Summary, specifically ReaMatch"
; printf,1,"cd,'/home/doppler/obs_summary_run/'"
; printf,1,"@/mir3/reamatch/precompile_rm"
; printf,1,"kep_summary,update='"+run+"'"
; printf,1,""
; printf,1,"; 8) Move back to the directory where things started."
; printf,1,"cd,'/mir3/reduce/'"
; 
; 
; 
; ;printf,1,"; 4) Move back to the directory where things started."
; ;printf,1,"cd,start_dir"
; ;printf,1,''
; ;printf,1,"; 5) Run S-value program."
; ;printf,1,"@precompile_svals"
; ;printf,1,"run = '"+run+"'				         ; <- ***UPDATE RUN NUMBER!***"
; ;printf,1,"hk2_keck,updateS=run,/quiet "
; printf,1,''
; 
printf,1,";Confirm the same number of reduced spectra exist for each chip."
printf,1,"spawn,'ls /mir3/iodspec/r'+run+'* | wc',numr"
printf,1,"spawn,'ls /mir3/bluespec/b'+run+'* | wc',numb"
printf,1,"spawn,'ls /mir3/redspec/i'+run+'* | wc',numi"

printf,1,"to_print = getwrd(numr[0],0)+'  '+ getwrd(numb[0],0)+'  '+getwrd(numi[0],0)"
printf,1,"print,'Number of Spectra reduced:(iod,blue,red): ' ,to_print"
printf,1,"print,' S-values have been updated as well.'"
printf,1,"print,''"
printf,1,"print,' Finished reductions.  '+systime(0) "


close,1

print,'Done writing /mir3/reduce/reduce3.batch-'+run+'-'+night








end ; program