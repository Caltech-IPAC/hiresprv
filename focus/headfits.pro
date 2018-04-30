function HEADFITS, filename, EXTEN = exten
;+
; NAME:
;	HEADFITS
; CALLING SEQUENCE:
;	Result = headfits( filename ,[ EXTEN = ])
; PURPOSE:
;	Read a FITS file header record      
; INPUTS:
;	FILENAME = String containing the name of the FITS file to be read.
; OPTIONAL INPUT KEYWORD:
;       EXTEN  = integer scalar, specifying which FITS extension to read.
;              For example, to read the header of the first extension set
;              EXTEN = 1.   Default is to read the primary FITS header 
;              (EXTEN = 0).
; OUTPUTS:
;	Result of function = FITS header, string array
; EXAMPLE:
;       Read the FITS header of a file 'test.fits' into a string variable, h
;
;         IDL>  h = headfits( 'test.fits')
; MODIFICATION HISTORY:
;	adapted by Frank Varosi from READFITS by Jim Wofford, January, 24 1989
;       Keyword EXTEN added, K.Venkatakrishna, May 1992
;-
On_error,2

If N_params() LT 1 then begin
     print,'Sytax - header = headfits( filename, [ EXTEN = ])
     return, -1
end
 
; Open file and read header information
       	openr,unit,filename, /GET_LUN, /BLOCK
	y = indgen(36*8)
	y2 = y - 8*(y/8) + 80*(y/8)
        offset = 0
        extn = 0
START: 	r = 0
        hdr = assoc(unit, bytarr(2880), offset)
        header = strarr(80, 360)
; Read header one record at a time

        if EOF(unit) then message,' No such extension, End of file reached'

LOOP:
	x = hdr(r)
	temp = string( byte(x,0,80,36) )
        header(r*36) = temp
	name = string( x(y2) )		;Get first 8 char of each line
        pos = strpos( name, 'END     ' )
	if (pos lt 0) then begin
		r = r + 1
		goto, LOOP 
	endif 
    	lastline = 36*r + pos / 8
	header = header(0:lastline)
;                                        IF extension, get the size of the
;                                        data. Find no of records to skip 
        If keyword_set(EXTEN) then begin
        bitpix = sxpar( header, 'BITPIX')
        naxis = sxpar( header, 'NAXIS')
        Nax = sxpar( header, 'NAXIS*' )                  ; Read NAXES
        nbytes = nax(0) * abs( bitpix )/ 8
        if naxis GT 1 then for i = 2, naxis do nbytes = nbytes*nax(i-1) $
                      else nbytes = 0
        nrec = nbytes /2880
        if nbytes GT nrec*2880L then nrec = long( nrec + 1 ) else $
        nrec = long(nrec)                
        point_lun, -unit, pointlun
        pointlun = pointlun + nrec*2880L
        point_lun,unit,pointlun
        offset = pointlun
        extn = extn + 1
        if (extn LE EXTEN) then goto, START 
        endif
	free_lun, unit

return, header
end
