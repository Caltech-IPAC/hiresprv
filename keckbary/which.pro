pro which,proname,count=count,noprint=noprint
;Prints full filenames in IDL !path search order for a particular routine.
; proname (input string) procedure name (.pro will be appended) to find
; count (scalar) number of file matches found.
; /noprint (switch) supresses screen output.
;24-Aug-92 JAV  Create.
;10-Mar-93 JAV  Fixed bug; last directory in !path ignored; pad with ': '
;21-Jan-99 NP	Generalized for more operating systems.

if n_params() lt 1 then begin
  print,'syntax: which, proname(.pro assumed) [,count= ,/noprint]'
  retall
endif

  CASE !VERSION.OS OF
    'vms': BEGIN & separator   = ''  & path_separator = ';' & END
  'Win32': BEGIN & separator   = '\' & path_separator = ';' & END
  'MacOS': BEGIN & separator   = ''  & path_separator = ';' & END
     ELSE: BEGIN & separator   = '/' & path_separator = ':' & END
  ENDCASE

  pathlist = '.' + path_separator + !path + $
             path_separator + ' '        ;build IDL path list
  count = 0                 ;reset file counter
  il = strlen(pathlist) - 1 ;length of path string
  ib = 0                    ;begining substring index
  ie = strpos(pathlist,path_separator,ib)          ;ending substring index
  repeat begin                  ;true: found path separator
    path = strmid(pathlist,ib,ie-ib)        ;extract path element
    fullname = path + separator + proname + '.pro'    ;build full filename
    openr,unit,fullname,error=eno,/get_lun  ;try to open file
    if eno eq 0 then begin          ;true: found file
      count = count + 1             ;increment file counter
      if path eq '.' then begin     ;true: in current directory
        cd,current=dot              ;get current working directory
        fullname=dot+strmid(fullname,1,strlen(fullname)-1)
        if not keyword_set(noprint) then $
          print,fullname + '    <= Current directory' ;print filename + current dir
      endif else begin              ;else: not in current directory
        if not keyword_set(noprint) then $
      print,fullname            ;print full name
      endelse
      free_lun,unit             ;close file
    endif
    ib = ie + 1                 ;point beyond separator
    ie = strpos(pathlist,path_separator,ib)        ;ending substring index
    if ie eq -1 then ie = il            ;point at end of path string
  endrep until ie eq il             ;until end of path reached
  if count eq 0 then begin          ;true: routine not found
    if not keyword_set(noprint) then $
      print,'which: ' + proname + '.pro not found on IDL !path.'
  endif
end
