pro maskim,im,roff,coff
;Uses predetermined image masks to identify chronic bad pixels in images.
;  Bad pixels are replaced by an average of adjacent points in the same row.
;  The masks are assumed fixed for any given CCD (and associated dewar).
; im (input array (# columns , # rows)) image in which to flag chronic bad
;   pixels.
; [roff (optional input scalar)] row offset of origin of CCD; i.e., row 0
;   of the image would correspond to row roff of the CCD.  Will be zero
;   unless CCD was windowed down and its origin shifted.
; [coff (optional input scalar)] celumn offset of origin of CCD; i.e., column
;   0 of the image would correspond to column coff of the CCD.  Will be zero
;   unless CCD was windowed down and its origin shifted.
; maskid is numeric identifier of mask to use in locating bad
;   pixels.  Recommend this number be the number of the associated dewar.
;Calls MASKBOX, TRACE
;18-Apr-92 JAV	Updated global variable list/interpretations. Implemented case
;		 structure. Cleaned up binned case logic.
;
;04-AUG-92 ECW  Added all of column 781 of dewar #8 as bad col. for use at
;		SFSU
;07-AUG-92 ECW	Added new pixels to mask of dewar #8.
;
;18-Apr-92 JAV	Updated global variable list/interpretations. Implemented case
;		 structure. Cleaned up binned case logic.
;18-Aug-92 JAV	Added dewar 13.3 mask boxes.
;
;18-Sep-92 JAV	Fixed bug that caused masks to be improperly positioned for
;		 binned images with nonzero offsets.
;
;25-JAN-93 ECW Added mask for dewar id number 1 which will mask for one of
;                dewars used on tapes made before using dewar 6.  The number
;                1 was picked arbitrarily and does not correspond to any
;                dewar 1 in use at Lick observatory.
;11-FEB-93 ECW  Added mask for dewar id number 2 which will mask images on
;		 tapes h21-h24.  This is before dewar 6 was used and as 
;		 above the number is picked arbitrarily and is not meant to
;		 correspond to any dewar number used at Lick.    
;20-MAR-93 ECW  Added three more boxes to dewar 8 masking.

;1-July-93 GB  Added mask for dewar 13.4

;
@ham.common					;get common block definition

if n_params() lt 1 then begin
  print,'syntax: maskim,im [,roff [,coff]].'
  retall
end
if n_params() lt 2 then roff = 0			;default is no offset
if n_params() lt 3 then coff = 0			;default is no offset

  trace,25,'MASKIM: Entering routine.'

;Define mask [LoCol,HiCol,LoRow,HiRow] used to locate chronic bad pixels.
  if not keyword_set(ham_id) then begin		;true: no dewar spec
    trace,10,'MASKIM: No dewar id specified, so bad pixels can''t be masked.'
    return					;might as well return
  endif
  maskid = ham_id				;get id from global

;Define mask according to maskid, reporting unknown ids.
;select by dewar id

  case maskid of
    1: begin                             ;dewar #1 is a designated number for
      mask = intarr(4,15)                ;one of the dewars used by G. Marcy
      mask[0,0] = [110,110,176,419]      ;before dewar 6. It was used on
      mask[0,1] = [201,201,370,419]      ;tapes h16-h20. The number does not
      mask[0,2] = [258,258,000,419]      ;relate to any actual dewar number
      mask[0,3] = [435,435,229,419]      ;used at Lick.   7  Eric Williams
      mask[0,4] = [619,619,085,419]
      mask[0,5] = [790,799,000,419]
      mask[0,6] = [654,655,000,419]
      mask[0,7] = [631,631,000,419]
      mask[0,8] = [189,189,000,419]
      mask[0,9] = [662,662,000,419]
      mask[0,10]= [671,671,000,419]
      mask[0,11]= [111,111,170,419]
      mask[0,12]= [736,736,290,419]
      mask[0,13]= [329,329,300,419]
      mask[0,14]= [463,463,000,419]
    end
    2: begin				;dewar #2 is a designated number for
      mask = intarr(4,15)		;the dewar used by G. Marcy for tapes
      mask[0,0] = [110,110,170,419]	;h21-h24.  The id number does not 
      mask[0,1] = [111,111,150,419]	;relate to any actual dewar number
      mask[0,2] = [117,117,000,50]	;used at Lick.
      mask[0,3] = [202,202,370,419]	;Eric Williams
      mask[0,4] = [258,258,000,419]
      mask[0,5] = [435,435,220,419]
      mask[0,6] = [463,463,000,419]
      mask[0,7] = [526,526,000,419]
      mask[0,8] = [619,619,80,419]
      mask[0,9] = [662,662,000,419]
      mask[0,10]= [736,736,250,419]
      mask[0,11]= [757,757,120,419]
      mask[0,12]= [189,189,000,419]
      mask[0,13]= [179,179,000,419]
      mask[0,14]= [655,655,000,419]
    end
    6: begin					;dewar 6 (chip NSF #4)
      mask = intarr(4,9)			;init mask array
      mask[0,0] = [041,042,000,799]		;define mask boxes
      mask[0,1] = [424,426,000,799]
      mask[0,2] = [480,480,000,799]
      mask[0,3] = [549,549,000,799]
      mask[0,4] = [554,554,000,799]
      mask[0,5] = [583,583,000,799]
      mask[0,6] = [604,604,000,799]
      mask[0,7] = [640,640,000,799]
      mask[0,8] = [679,679,000,799]
    end
    8: begin					;dewar 8
      mask = intarr(4,13)			;init mask array
      mask[0,0] = [005,005,774,799]		;define mask boxes
      mask[0,1] = [531,533,611,799]
      mask[0,2] = [556,557,122,799]
      mask[0,3] = [557,557,055,121]
      mask[0,4] = [692,692,436,799]
      mask[0,5] = [781,781,664,799]
      mask[0,6] = [781,781,0,419]
      mask[0,7] = [79,79,38,39]
      mask[0,8] = [169,169,378,380]
      mask[0,9] = [335,335,103,104] 
      mask[0,10]= [305,315,55,65]
      mask[0,11]= [675,695,400,420]
      mask[0,12]= [70,95,70,90]
   end
    13: begin					;dewar 13 (chip FORD #2)
      mask = intarr(4,4)			;init mask array
      mask[0,0] = [785,792,178,1649]		;define mask boxes
      mask[0,1] = [1036,1036,440,1649]
      mask[0,2] = [1275,1277,535,1649]
      mask[0,3] = [1496,1499,318,1649]
    end
    13.3: begin					;dewar 13 (incarnation 3)
      mask = intarr(4,17)			;init mask array
      mask[*,0] = [1451,1467,0,2047]		;hot columns (lax limit)
      mask[*,1] = [1731,1731,0,2047]		;hot column
      mask[*,2] = [235,235,302,2047]		;cold column
      mask[*,3] = [633,633,710,2047]		;cold column
      mask[*,4] = [883,886,0,2047]		;cold columns
      mask[*,5] = [1133,1134,438,2047]		;cold columns
      mask[*,6] = [1372,1374,532,2047]		;cold columns
      mask[*,7] = [1457,1457,0,2047]		;cold column
      mask[*,8] = [1594,1594,316,2047]		;cold column
      mask[*,9] = [1560,1578,736,755]           ;cold blemish ("hockey puck")
;						;cold feature ("hockey stick")
;Other mask information that picky people might want.
     mask[*,10] = [1440,1483,0,2047]		;hot columns (stringent limit)
     mask[*,11] = [1872,2047,0,210]		;hot corner (lax limit)
     mask[*,12] = [1747,2047,0,13]		;\
     mask[*,13] = [1807,2047,14,90]		; \
     mask[*,14] = [1782,2047,91,140]		;  > hot corner
     mask[*,15] = [1807,2047,141,250]		; /   (stringent limit)
     mask[*,16] = [1877,2047,251,320]		;/
    end
    13.4: begin
      mask=intarr(4,3)
      mask[*,0] = [854,861,518,522]		;cold box
      mask[*,1] = [1158,1219,1475,1524]		;half moon hot and cold
      mask[*,2] = [195,220,862,1649]		;scrambled columns
    end
    else: begin					;unknown dewar id
      trace,0,'Unknown dewar id specified, so bad pixels can''t be masked.'
      return					;might as well return
    end
  endcase

;Apply each mask box to image.
  nbox = n_elements(mask[0,*])			;number of mask boxes
  for i=0,nbox-1 do begin			;loop thru boxes
    box = mask[*,i]				;get a box definition
    box = box - [coff,coff,roff,roff]		;align box & im origins
    box = long((box + 0.99) / ham_bin)		;account for binning
    maskbox,im,box				;mask the image in box
  endfor

  trace,25,'MASKIM: Masked pixels adjusted - returning to caller.'
  return
end
