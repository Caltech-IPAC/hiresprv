;+
; NAME:
;       READFITS
; PURPOSE:
;       Read a FITS file into IDL data and header variables. 
; EXPLANATION:
;       See http://idlastro.gsfc.nasa.gov/fitsio.html for other ways of
;       reading FITS files with IDL.
;
; CALLING SEQUENCE:
;       Result = READFITS( Filename/Fileunit,[ Header, heap, /NOSCALE, EXTEN_NO=,
;                       NSLICE=, /SILENT, STARTROW =, NUMROW = , HBUFFER=,
;                       /COMPRESS, /No_Unsigned ] )
;
; INPUTS:
;       Filename = Scalar string containing the name of the FITS file  
;                 (including extension) to be read.   If the filename has
;                  a *.gz extension, it will be treated as a gzip compressed
;                  file.   If it has a .Z extension, it will be treated as a
;                  Unix compressed file.
;                                   OR
;       Fileunit - A scalar integer specifying the unit of an already opened
;                  FITS file.  The unit will remain open after exiting 
;                  READFITS().  There are two possible reasons for choosing 
;                  to specify a unit number rather than a file name:
;          (1) For a FITS file with many extensions, one can move to the 
;              desired extensions with FXPOSIT() and then use READFITS().  This
;              is more efficient that repeatedly starting at the beginning of 
;              the file.
;          (2) For reading a FITS file across a Web http: address after opening
;              the unit with the SOCKET procedure (IDL V5.4 or later,
;              Unix and Windows only) 
; OUTPUTS:
;       Result = FITS data array constructed from designated record.
;                If the specified file was not found, then Result = -1
;
; OPTIONAL OUTPUT:
;       Header = String array containing the header from the FITS file.
;              If you don't need the header, then the speed may be improved by
;              not supplying this parameter.
;       heap = For extensions, the optional heap area following the main
;              data array (e.g. for variable length binary extensions).
;
; OPTIONAL INPUT KEYWORDS:
;       /COMPRESS - Signal that the file is gzip compressed.  By default, 
;               READFITS will assume that if the file name extension ends in 
;               '.gz' then the file is gzip compressed.   The /COMPRESS keyword
;               is required only if the the gzip compressed file name does not 
;               end in '.gz'.   Keyword only valid for IDL V5.3 or later.
;
;       EXTEN_NO - positive scalar integer specifying the FITS extension to
;               read.  For example, specify EXTEN = 1 or /EXTEN to read the 
;               first FITS extension.   
;
;       /NOSCALE - If present and non-zero, then the ouput data will not be
;                scaled using the optional BSCALE and BZERO keywords in the 
;                FITS header.   Default is to scale.
;
;       /NO_UNSIGNED -By default, if the header indicates an unsigned integer 
;              (BITPIX = 16, BZERO=2^15, BSCALE=1) then FITS_READ will output 
;               an IDL unsigned integer data type (UINT).   But if /NO_UNSIGNED
;               is set, then the data is converted to type LONG.  
;
;       NSLICE - Non-negative integer scalar specifying which N-1 dimensional 
;                slice of a N-dimensional array to read.   For example, if the 
;                primary image of a file 'wfpc.fits' contains a 800 x 800 x 4 
;                array, then 
;
;                 IDL> im = readfits('wfpc.fits',h, nslice=2)
;                           is equivalent to 
;                 IDL> im = readfits('wfpc.fits',h)
;                 IDL> im = im[*,*,2]
;                 but the use of the NSLICE keyword is much more efficient.
;
;       NUMROW -  Scalar non-negative integer specifying the number of rows 
;                 of the image or table extension to read.   Useful when one 
;                 does not want to read the entire image or table.    
;
;       POINT_LUN  -  Position (in bytes) in the FITS file at which to start
;                 reading.   Useful if READFITS is called by another procedure
;                 which needs to directly read a FITS extension.    Should 
;                 always be a multiple of 2880, and not be used with EXTEN_NO
;                 keyword.
;
;       /SILENT - Normally, READFITS will display the size the array at the
;                 terminal.  The SILENT keyword will suppress this
;
;        STARTROW - Non-negative integer scalar specifying the row
;               of the image or extension table at which to begin reading. 
;               Useful when one does not want to read the entire table.
;
;        HBUFFER - Number of lines in the header, set this to slightly larger
;                than the expected number of lines in the FITS header, to 
;               improve performance when reading very large FITS headers. 
;               Should be a multiple of 36 -- otherwise it will be modified
;               to the next higher multiple of 36.   Default is 180
;
; EXAMPLE:
;       Read a FITS file test.fits into an IDL image array, IM and FITS 
;       header array, H.   Do not scale the data with BSCALE and BZERO.
;
;              IDL> im = READFITS( 'test.fits', h, /NOSCALE)
;
;       If the file contains a FITS extension, it could be read with
;
;              IDL> tab = READFITS( 'test.fits', htab, /EXTEN )
;
;       The function TBGET() can be used for further processing of a binary 
;       table, and FTGET() for an ASCII table.
;       To read only rows 100-149 of the FITS extension,
;
;              IDL> tab = READFITS( 'test.fits', htab, /EXTEN, 
;                                   STARTR=100, NUMR = 50 )
;
;       To read in a file that has been compressed:
;
;              IDL> tab = READFITS('test.fits.gz',h)
;
; ERROR HANDLING:
;       If an error is encountered reading the FITS file, then 
;               (1) the system variable !ERROR is set (via the MESSAGE facility)
;               (2) the error message is displayed (unless /SILENT is set),
;                   and the message is also stored in !ERR_STRING
;               (3) READFITS returns with a value of -1
; RESTRICTIONS:
;       (1) Cannot handle random group FITS
;
; NOTES:
;       (1) If data is stored as integer (BITPIX = 16 or 32), and BSCALE
;       and/or BZERO keywords are present, then the output array is scaled to 
;       floating point (unless /NOSCALE is present) using the values of BSCALE
;       and BZERO.   In the header, the values of BSCALE and BZERO are then 
;       reset to 1. and 0., while the original values are written into the 
;       new keywords O_BSCALE and O_BZERO.     If the BLANK keyword was
;       present, then any input integer values equal to BLANK in the input
;       integer image are unchanged by BSCALE or BZERO
;       
;       (2) The use of the NSLICE keyword is incompatible with the NUMROW
;       or STARTROW keywords.
;
;       (3) READFITS() underwent a substantial rewrite in October 1998 to 
;       eliminate recursive calls, and improve efficiency when reading
;       extensions.
;            1. The NUMROW and STARTROW keywords can now be used when reading
;              a primary image (extension = 0).
;            2. There is no error check for moving past the end of file when
;               reading the data array.
;
;       (4) On some Unix shells, one may get a "Broken pipe" message if reading
;        a UNIX compressed file, and not reading to the end of the file (i.e. 
;        the decompression has not gone to completion).     This is an 
;        informative message only, and should not affect the output of 
;        READFITS().  
;
; PROCEDURES USED:
;       Functions:   SXPAR() 
;       Procedures:  SXADDPAR, SXDELPAR
;
; MODIFICATION HISTORY:
;       Original Version written in 1988, W.B. Landsman   Raytheon STX
;       Revision History prior to October 1998 removed          
;       Major rewrite to eliminate recursive calls when reading extensions
;                  W.B. Landsman  Raytheon STX                    October 1998
;       Add /binary modifier needed for Windows  W. Landsman    April 1999
;       Read unsigned datatypes, added /no_unsigned   W. Landsman December 1999
;       Output BZERO = 0 for unsigned data types   W. Landsman   January 2000
;       Open with /swap_if_little_endian if since V5.1 W. Landsman February 2000
;       Fixed logic error when using NSLICE keyword W. Landsman March 2000
;       Fixed byte swapping problem for compressed files on little endian 
;             machines introduced in Feb 2000     W. Landsman       April 2000
;       Fix error handling so FREE_LUN is called in case of READU error
;						W. Landsman N. Rich, Aug. 2000
;       Assume since V5.1, remove NANvalue keyword  W. Landsman   July 2001 
;       Support the unofficial 64bit integer format W. Landsman   September 2001
;       Option to read a unit number rather than file name W.L    October 2001
;       Fix byte swapping problem for compressed files again (sigh...) 
;                W. Landsman   March 2002
;       Make sure gzip defined when using a unit number W. Landsman Oct. 2002 
;       Assume V5.2 or later            W. Landsman        Jan. 2003
;       Don't read entire header unless needed   W. Landsman  Jan. 2003
;       Added HBUFFER keyword    W. Landsman   Feb. 2003
;-
;
function READFITS, filename, header, heap, COMPRESS = compress, HBUFFER=hbuf, $
                   EXTEN_NO = exten_no, NOSCALE = noscale, NSLICE = nslice, $
                   NO_UNSIGNED = no_unsigned,  NUMROW = numrow, $
                   POINTLUN = pointlun, SILENT = silent, STARTROW = startrow


  On_error,2                    ;Return to user
  ON_IOerror, BAD

; Check for filename input

   if N_params() LT 1 then begin                
      print,'Syntax - im = READFITS( filename, [ h, heap, /NOSCALE, /SILENT,'
      print,'                 EXTEN_NO =, STARTROW = , NUMROW=, NSLICE = ,'
      print,'                 HBUFFER = ,/NO_UNSIGNED, /COMPRESS]'
      return, -1
   endif

   unitsupplied = size(filename,/TNAME) NE 'STRING'

; Set default keyword values

   silent = keyword_set( SILENT )
   if N_elements(exten_no) EQ 0 then exten_no = 0

;  Check if this is a compressed file.    Unix compressed files or gzip 
;  compressed files (on Unix) prior to V5.3 read through a pipe.   Gzip 
;  compressed files since V5.3 are read using the /COMPRESS keyword to OPENR 
                
    unixZ = 0
    if unitsupplied then unit = filename else begin
       len = strlen(filename)
       gzip = strmid(filename,len-3,3) EQ '.gz' 
       if (!VERSION.RELEASE GE '5.3') then $
             compress = keyword_set(compress) or gzip else begin
              compress = 0
              if gzip and (!VERSION.OS_FAMILY EQ 'unix')  then begin
                 ucmprs = 'gzip -cd '
                 unixZ = 1
             endif
       endelse
       if (strmid(filename, len-2, 2) EQ '.Z') and $
                (!VERSION.OS_FAMILY EQ 'unix') then begin 
                 ucmprs = 'uncompress -c '
                 unixZ = 1
       endif
 
;  Go to the start of the file.

       if compress then $
       openr, unit, filename, ERROR=error,/get_lun,/BLOCK,/binary, $
                COMPRESS = compress, /swap_if_little_endian else $
       openr, unit, filename, ERROR=error,/get_lun,/BLOCK,/binary, $
                          /swap_if_little_endian
       if error NE 0 then begin
           message,/con,' ERROR - Unable to locate file ' + filename
           return, -1
       endif

;  Handle Unix compressed files.   On some Unix machines, users might wish to 
;  force use of /bin/sh in the line spawn, ucmprs+filename, unit=unit,/sh

        if unixZ then begin
                free_lun, unit
                spawn, ucmprs + filename, unit=unit                 
                gzip = 1b
        endif
   endelse      
  if keyword_set(POINTLUN) then begin
       if gzip then  readu,unit,bytarr(pointlun,/nozero) $
               else point_lun, unit, pointlun
  endif
  doheader = arg_present(header)
  if doheader  then begin
          if N_elements(hbuf) EQ 0 then hbuf = 180 else begin
                  remain = hbuf mod 36
                  if remain GT 0 then hbuf = hbuf + 36-remain
           endelse
  endif else hbuf = 36

  for ext = 0L, exten_no do begin
               
;  Read the next header, and get the number of bytes taken up by the data.

       block = string(replicate(32b,80,36))
       w = [-1]
       if ((ext EQ exten_no) and (doheader)) then header = strarr(hbuf) $
                                             else header = strarr(36)
       headerblock = 0L
       i = 0L

       while w[0] EQ -1 do begin
          
       if EOF(unit) then begin 
            message,/ CON, $
               'EOF encountered attempting to read extension ' + strtrim(ext,2)
            if not unitsupplied then free_lun,unit
            return,-1
       endif

      readu, unit, block
      headerblock = headerblock + 1
      w = where(strlen(block) NE 80, Nbad)
      if (Nbad GT 0) then begin
           message,'Warning-Invalid characters in header',/INF,NoPrint=Silent
           block[w] = string(replicate(32b, 80))
      endif
      w = where(strmid(block, 0, 8) eq 'END     ', Nend)
      if (headerblock EQ 1) or ((ext EQ exten_no) and (doheader)) then begin
              if Nend GT 0 then  begin
             if headerblock EQ 1 then header = block[0:w[0]]   $
                                 else header = [header[0:i-1],block[0:w[0]]]
             endif else begin
                header[i] = block
                i = i+36
                if i mod hbuf EQ 0 then $
                              header = [header,strarr(hbuf)]
           endelse
          endif
      endwhile

      if (ext EQ 0 ) and (keyword_set(pointlun) EQ 0) then $
             if strmid( header[0], 0, 8)  NE 'SIMPLE  ' then begin
              message,/CON, $
                 'ERROR - Header does not contain required SIMPLE keyword'
                if not unitsupplied then free_lun, unit
                return, -1
      endif

                
; Get parameters that determine size of data region.
                
       bitpix =  sxpar(header,'BITPIX')
       naxis  = sxpar(header,'NAXIS')
       gcount = sxpar(header,'GCOUNT') > 1
       pcount = sxpar(header,'PCOUNT')
                
       if naxis GT 0 then begin 
            dims = sxpar( header,'NAXIS*')           ;Read dimensions
            ndata = dims[0]
            if naxis GT 1 then for i = 2, naxis do ndata = ndata*dims[i-1]
                        
                endif else ndata = 0
                
                nbytes = (abs(bitpix) / 8) * gcount * (pcount + ndata)

;  Move to the next extension header in the file.

      if ext LT exten_no then begin
                nrec = long((nbytes + 2879) / 2880)
                if nrec GT 0 then begin     
                if gzip then begin 
                        buf = bytarr(nrec*2880L,/nozero)
                        readu,unit,buf 
                        endif else  begin 
                        point_lun, -unit,curr_pos
                        point_lun, unit,curr_pos + nrec*2880L
                endelse
                endif
       endif
       endfor

 case BITPIX of 
           8:   IDL_type = 1          ; Byte
          16:   IDL_type = 2          ; Integer*2
          32:   IDL_type = 3          ; Integer*4
          64:   IDL_type = 14         ; Integer*8   (unofficial)
         -32:   IDL_type = 4          ; Real*4
         -64:   IDL_type = 5          ; Real*8
        else:   begin
                message,/CON, 'ERROR - Illegal value of BITPIX (= ' +  $
                strtrim(bitpix,2) + ') in FITS header'
                if not unitsupplied then free_lun,unit
                return, -1
                end
  endcase     

; Check for dummy extension header

 if Naxis GT 0 then begin 
        Nax = sxpar( header, 'NAXIS*' )   ;Read NAXES
        ndata = nax[0]
        if naxis GT 1 then for i = 2, naxis do ndata = ndata*nax[i-1]

  endif else ndata = 0

  nbytes = (abs(bitpix)/8) * gcount * (pcount + ndata)
 
  if nbytes EQ 0 then begin
        if not SILENT then message, $
                "FITS header has NAXIS or NAXISi = 0,  no data array read",/CON
        if not unitsupplied then free_lun, unit
        return,-1
 endif

; Check for FITS extensions, GROUPS

 groups = sxpar( header, 'GROUPS' ) 
 if groups then message,NoPrint=Silent, $
           'WARNING - FITS file contains random GROUPS', /INF

; If an extension, did user specify row to start reading, or number of rows
; to read?

   if not keyword_set(STARTROW) then startrow = 0
   if naxis GE 2 then nrow = nax[1] else nrow = ndata
   if not keyword_set(NUMROW) then numrow = nrow
   if exten_no GT 0 then begin
        xtension = strtrim( sxpar( header, 'XTENSION' , Count = N_ext),2)
        if N_ext EQ 0 then message, /INF, NoPRINT = Silent, $
                'WARNING - Header missing XTENSION keyword'
   endif 
      
   if (exten_no GT 0) and ((startrow NE 0) or (numrow NE nrow)) then begin
        if startrow GE nax[1] then begin
           message,'ERROR - Specified starting row ' + strtrim(startrow,2) + $
          ' but only ' + strtrim(nax[1],2) + ' rows in extension',/CON
           if not unitsupplied then free_lun,unit
           return,-1
        endif 
        nax[1] = nax[1] - startrow    
        nax[1] = nax[1] < numrow
        sxaddpar, header, 'NAXIS2', nax[1]
        if gzip then begin
                if startrow GT 0 then begin
                        tmp=bytarr(startrow*nax[0],/nozero)
                        readu,unit,tmp
                endif 
        endif else begin 
              point_lun, -unit, pointlun          ;Current position
              point_lun, unit, pointlun + startrow*nax[0]
    endelse
    endif else if (N_elements(NSLICE) EQ 1) then begin
        lastdim = nax[naxis-1]
        if nslice GE lastdim then message,/CON, $
        'ERROR - Value of NSLICE must be less than ' + strtrim(lastdim,2)
        nax = nax[0:naxis-2]
        sxdelpar,header,'NAXIS' + strtrim(naxis,2)
        naxis = naxis-1
        sxaddpar,header,'NAXIS',naxis
        ndata = ndata/lastdim
        nskip = nslice*ndata*abs(bitpix/8) 
        if gzip then begin 
            if (Ndata GT 0) then  begin 
                  buf = bytarr(nskip,/nozero)
                  readu,unit,buf   
             endif
        endif else begin 
                   point_lun, -unit, currpoint          ;Current position
                   point_lun, unit, currpoint + nskip
        endelse
  endif


  if not (SILENT) then begin   ;Print size of array being read

         if exten_no GT 0 then message, $
                     'Reading FITS extension of type ' + xtension, /INF
         snax = strtrim(NAX,2)
         st = snax[0]
         if Naxis GT 1 then for I=1,NAXIS-1 do st = st + ' by '+SNAX[I] $
                            else st = st + ' element'
         st = 'Now reading ' + st + ' array'
         if (exten_no GT 0) and (pcount GT 0) then st = st + ' + heap area'
         message,/INF,st   
   endif

; Read Data in a single I/O call

    data = make_array( DIM = nax, TYPE = IDL_type, /NOZERO)

     readu, unit, data
    if unixZ then if not is_ieee_big() then ieee_to_host,data
    if (exten_no GT 0) and (pcount GT 0) then begin
        theap = sxpar(header,'THEAP')
        skip = theap - N_elements(data)
        if skip GT 0 then begin 
                temp = bytarr(skip,/nozero)
                readu, unit, skip
        endif
        heap = bytarr(pcount*gcount*abs(bitpix)/8)
        readu, unit, heap
    endif

    if not unitsupplied then free_lun, unit

; Scale data unless it is an extension, or /NOSCALE is set
; Use "TEMPORARY" function to speed processing.  

   do_scale = not keyword_set( NOSCALE )
   if (do_scale and (exten_no GT 0)) then do_scale = xtension EQ 'IMAGE' 
   if do_scale then begin

          Nblank = 0
          if bitpix GT 0 then begin
                blank = sxpar( header, 'BLANK', Count = N_blank) 
                if N_blank GT 0 then $ 
                        blankval = where( data EQ blank, Nblank)
          endif

          Bscale = float( sxpar( header, 'BSCALE' , Count = N_bscale))
          Bzero = float( sxpar(header, 'BZERO', Count = N_Bzero ))
 
; Check for unsigned integer (BZERO = 2^15) or unsigned long (BZERO = 2^31)

          if not keyword_set(No_Unsigned) then begin
            no_bscale = (Bscale EQ 1) or (N_bscale EQ 0)
            unsgn_int = (bitpix EQ 16) and (Bzero EQ 32768) and no_bscale
            unsgn_lng = (bitpix EQ 32) and (Bzero EQ 2147483648) and no_bscale
            unsgn = unsgn_int or unsgn_lng
           endif else unsgn = 0

          if unsgn then begin
                 sxaddpar, header, 'BZERO', 0
                 sxaddpar, header, 'O_BZERO', bzero, $
                          'Original Data is unsigned Integer'
                   if unsgn_int then $ 
                        data =  uint(data) - 32768U else $
                   if unsgn_lng then  data = ulong(data) - 2147483648UL 
                
          endif else begin
 
          if N_Bscale GT 0  then $ 
               if ( Bscale NE 1. ) then begin
                   data = temporary(data) * Bscale 
                   sxaddpar, header, 'BSCALE', 1.
                   sxaddpar, header, 'O_BSCALE', Bscale,' Original BSCALE Value'
               endif

         if N_Bzero GT 0  then $
               if (Bzero NE 0) then begin
                     data = temporary( data ) + Bzero
                     sxaddpar, header, 'BZERO', 0.
                     sxaddpar, header, 'O_BZERO', Bzero,' Original BZERO Value'
               endif
        
        endelse

        if (Nblank GT 0) and ((N_bscale GT 0) or (N_Bzero GT 0)) then $
                data[blankval] = blank

        endif

; Return array

        return, data

; Come here if there was an IO_ERROR
    
 BAD:   print,!ERROR_STATE.MSG
        if (not unitsupplied) and (N_elements(unit) GT 0) then free_lun, unit
        if N_elements(data) GT 0 then return,data else return, -1
 end 
