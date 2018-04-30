pro rascii,vname,ncol,fname,skip=skip
;Read an ascii file, FNAME, having NCOL columns.
;Result is VNAME
;
;INPUT
;      NCOL    (integer) Number of Columns in ascii file
;      FNAME   (string)  Name of ascii, i.e., 'lines.ascii'
;
;OUTPUT
;      VNAME    fltarr(ncol,number of entries)
;
;KEYWORD
;      SKIP     the number of lines at the top of the file to be skipped
;
;History:  Written by RP Butler
;
     fud='?'  &  crow=-1
     openr,1,fname                  ;open file for reading
     if n_elements(skip) eq 1 then for n=1,skip do readf,1,fud
     vec=fltarr(ncol)  &  vname=fltarr(ncol,long(1.E5/ncol))
     While (eof(1) eq 0) do Begin    ; step through lines in file.
       readf,1,vec                   ; read line in file.
       crow=crow+1                   ;increment index
       vname(*,crow)=vec             ;store line in final vector
     End                             ;end while
     close,1
     vname=vname(*,0:crow)
return
end
