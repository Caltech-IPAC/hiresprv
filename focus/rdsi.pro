pro rdsi,ob,obnam,filter,fdsk
;This code drives the PSF and velocity analysis
;
;ob      (output array)     Observation 
;obname  (input string)     Observation name  i.e. 'rc10.7' or 'ra49.31' or 'rb34.28'
;filter  (output array)     Observation filter
;fdsk    (output string)    files disk name   i.e. '/mir1/files/' or '/d4/cepheid/files/'
;
;Created June 7, 1994  R.P.B.
;Updated Feb 25, 1996  R.P.B.
;



if n_params () lt 2 then begin
  print,' IDL> rdsi,ob,obnam,filter,fdsk
  return
endif

; Initially assume this is being run on the Berkeley system
       fd0='/mir1/files/'                         ;files disk
       fd1='/mir1/paul/exfiles/'                  ;files disk
       fd5='/mir3/files/'                         ;keck files disk
       obd0='/mir1/iodspec/'                      ;observation disk
       obd1='/mir1/paul/cepspec/'                 ;observation disk
       obd5='/mir3/iodspec/'                      ;keck observation disk
       fldsk0='/mir1/files/'                      ;filter disk
       fldsk1='/mir1/paul/exfiles/'               ;filter disk

; Directories for SFSU
; Check to see if this is being run on the SFSU system
       sfsufts='/d4/atlas/ftsiod.bin'             ;SFSU NSO Atlas
       dummy=first_el(findfile(sfsufts))
       if dummy eq sfsufts then begin    ;This is being run on the SFSU system
          fd0='/d4/files/'                        ;files disk
          fd1='/d4/cepheid/files/'                ;files disk
;         fd5='/k4/kfiles/'                       ;keck files disk
          obd0='/d4/iodspec/'                     ;observation disk
          obd1='/d4/cepheid/cepspec/'             ;observation disk
;         obd5='/d4/kiodspec/'                    ;keck observation disk
          fldsk0='/d4/files/'                     ;filter disk
          fldsk1='/d4/cepheid/files/'             ;filter disk
       endif

; Directories for AAO
; Check to see if this is being run on the AAO system
       aaofts='/mir1/paul/atlas/ftsiod.bin'       ;AAO FTS Atlas
       dummy=first_el(findfile(aaofts))
       if dummy eq aaofts then begin    ;This is being run on the AAO system
          fd0='/mir1/paul/files/'                 ;files disk
          fd1='/mir1/paul/exfiles/'               ;files disk
          fd5='/mir3/paul/files/'                 ;keck files disk
          obd0='/mir1/paul/iodspec/'              ;observation disk
          obd1='/mir1/paul/cepspec/'              ;observation disk
          obd5='/mir3/paul/iodspec/'              ;keck observation disk
          fldsk0='/mir1/paul/files/'              ;filter disk
          fldsk1='/mir1/paul/exfiles/'            ;filter disk
       endif

; Directories for Keck/Waimea
; Check to see if this is being run on the Keck/Waimea system
       keckfts='/s/sdata9/hires/software/gmarcy/login'  ;Keck
       dummy=first_el(findfile(keckfts))
       if dummy eq keckfts then begin    ;This is being run on the Keck system
          fd0='/mir1/paul/files/'                 ;files disk
          fd1='/mir1/paul/exfiles/'               ;files disk
          fd5='/s/sdata9/hires/software/gmarcy/focus/'
                                                  ;keck files disk
          obd0='/mir1/paul/iodspec/'              ;observation disk
          obd1='/mir1/paul/cepspec/'              ;observation disk
          obd5='/s/sdata9/hires/software/gmarcy/iodspec/'
                                                  ;keck observation disk
          fldsk0='/mir1/paul/files/'              ;filter disk
          fldsk1='/mir1/paul/exfiles/'            ;filter disk
       endif

; Directories for SSL
; Check to see if this is being run on the SSL/DENALI system
;       sslfts='/disks/denali/scratch/paulb/atlas/ftseso50.bin'   ;SSL FTS Atlas
;       dummy=first_el(findfile(sslfts))
;       if dummy eq sslfts then begin    ;This is being run on the SSL system
;          fd0='/disks/denali/scratch/paulb/files/'     ;files disk
;          fd1='/disks/denali/scratch/paulb/cfiles/'    ;files disk
;          obd0='/disks/denali/scratch/paulb/iodspec/'  ;observation disk
;          obd1='/disks/denali/scratch/paulb/cepspec/'  ;observation disk
;          fldsk0='/disks/denali/scratch/paulb/files/'  ;filter disk
;          fldsk1='/disks/denali/scratch/paulb/cfiles/' ;filter disk
;       endif

;which disk is which?
          tp = strmid(obnam,0,2)      ;tape series (i.e. ra,rb,rc,rh,rk,rz)
          nb = strmid(obnam,2,2)      ;first two digits of tape number
	  dwr = chip(obnam,gain)

          obdsk=obd0                    ;observation directory
          if tp eq 'rh' then fdsk=fd0   ;files directory
          if tp eq 'ra' then fdsk=fd0
          if tp eq 'rb' then fdsk=fd0
          if tp eq 'rz' then fdsk=fd0   ;Chris McCarthy, UCLA
          if tp eq 'rx' then fdsk=fd0   ;New Hamilton, Big Chip
          if tp eq 'rc' then begin
	     fdsk=fd1                   ;files directory
             obdsk=obd1                 ;observation directory
	  endif
          if tp eq 'rk' then begin      ;Keck HIRES, 2048 chip
             fdsk=fd5                   ;files directory
             obdsk=obd5                 ;observation directory
          endif
          obname=obdsk+obnam            ;observation name including directory
;special Keck instructions for Steve Vogt's "rk1" 4-interleaved run 
          if tp eq 'rk' and nb eq '1.' then obname=strmid(obname,0,strlen(obname)-2)

 	  rdsk,ob,obname,1               ;get the observation from disk
	  fixpix,ob,dewar=dwr            ;  smooth over bad pixels
	  ob=ob*gain
;get proper filter
	  if dwr eq 1 then rdsk,filter,fldsk0+'filt1.dsk'
	  if dwr eq 2 then rdsk,filter,fldsk0+'filt2.dsk'
	  if dwr eq 6 then rdsk,filter,fldsk0+'filt6.dsk'
	  if dwr eq 8 then begin
	     rdsk,filter,fldsk0+'filt8.dsk'
	     filter(553:554,*)=0  &  filter(559,*)=0   ;PB Kludge  5/25/93
          endif
	  if dwr eq 13 then rdsk,filter,fldsk0+'filt13.dsk'
	  if dwr eq 39 then begin
	     filter=ob*0.+1.                ;New Hamilton, Perfect chip?
	     filter(1341,24:51)=-1          ;only CCD flaw?
          endif
	  if dwr eq 98 then begin
	     rdsk,filter,fldsk1+'filt_cep33.dsk'
; No longer trim observation to "look" like pre-fix,  Feb 25, 1996
;	     ob=ob(*,6:30)                         ;orders same as rh, ra
;	     filter=filter(*,6:30)
          endif
	  if dwr eq 99 then begin
	     rdsk,filter,fldsk1+'filt_cep52.dsk'
; No longer trim observation to "look" like pre-fix,  Feb 25, 1996
;	     ob=ob(*,25:49)                        ;orders same as rh, ra
;	     filter=filter(*,25:49)
          endif
	  if tp eq 'rk' then begin              ;Keck set up 
;	     filter=ob*0+1                      ;perfect chip?
	     rdsk,filter,fdsk+'filt_rk5.dsk'    ;GWM Oct 96 filter (rk5 and on)
;special Keck instructions for Steve Vogt's "rk1" 4-interleaved run 
             if nb eq '1.' then begin
;get discontinuity fix file   ** not needed with new G. Marcy reduced data
;	       rascii,hrfix,2,'/mir1/paul/seismo/files/hires_fix.ascii',skip=1
;	       dum=fltarr(7,n_elements(hrfix(0,*)))
;	       dum(0,*)=hrfix(0,*)  &  dum(6,*)=hrfix(1,*)
;	       mixpix,ob,filter,dum,/fixmarr
;there are four interleaved exposures, need to pull them apart
	       interleaf=fix(strmid(obnam,strlen(obnam)-1,1))
	       ob=ob(*,indgen(11)*4+3-interleaf)
	       filter=filter(*,indgen(11)*4+3-interleaf)
;Stupid Kludge   PB 4/7/95
	       dumob=fltarr(2048,12)*0.
	       dumob(*,1:11)=ob
	       ob=dumob
	       dumob(*,1:11)=filter
	       filter=dumob
	     endif
          endif
	  prop_filt,filter,/zero        ;"proper filter" of 0's and 1's
;finished get proper filter

return
end
