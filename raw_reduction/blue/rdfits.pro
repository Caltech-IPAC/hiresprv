Pro RdFITS,Im,File,Head,NoScale=NoScale,ClipBase=ClipBase,Force=Force
;Read a disk FITS file.
; Im (output array(# columns,# rows)) image from fits file. I*2 and unscaled
;   if ReMap=0; R*4 and scaled if ReMap=1 or ReMap argument unspecified.
; File (input string) name of FITS file
; [ Head (optional output string array(# cards)) ] FITS header cards
; [ /NoScale (keyword logical) ] true: don't use header information to rescale
; [ /ClipBase (keyword logical) ] true: clip last column of image.
; [ Force (keyword scalar) ] forces cetain transformation behavior.
;    0: Oldest wtfits:  Unscaled = (Scaled/BSCALE) - BZERO
;    1: Newer wtfits:   Unscaled = (Scaled/BSCALE) + BZERO
;    2: FITS Standard:  Unscaled = (Scaled*BSCALE) + BZERO
;    Only specify this keyword if you want to override logic in this program.
;11-Apr-91 JAV	Create.
;06-Aug-91 JAV	Translate from ANA to IDL.
;12-Aug-91 JAV	Switched code to expect signed rather than unsigned integers.
;13-Nov-91 JAV	Fixed Buff/IBuff bug for VAX conversion case.
;29-Apr-92 JAV	Added ClipBase capability for Hamilton Reduction package.
;05-Sep-92 JAV	Fixed sign error in applciation of BZero.
;29-Mar-93 JAV	Switched default transformation to standard FITS; inserted
;		 logic to detect and handle files written by older, flawed
;		 versions of wtfits; added Force keyword.
;01-Apr-94 JAV	Allow FRAMENO (used by HIRES) instead of OBSNUM header cards.
If N_Params() lt 2 Then Begin
  Message,/Info,'Syntax: RdFITS,Im,File [,Head,/NoScale,/ClipBase,Force=]'
  RetAll
End

;Program parameters and constants.
  ByteSwap = 0				;byte swap flag (1=swap,0=no swap)
  Months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Nov','Dec']

;Read FITS header.
  FITSHd,File,Head			;read header cards into byte array
  nCards = N_Elements(Head)		;number of header cards
  Hsiz = nCards * StrLen(Head[0])	;header size (in bytes)
  If HSiz mod 2880 ne 0 Then Begin	;true: must fix header size
    HSiz = (Fix(HSiz) / 2880 + 1) * 2880 ;round up to next mult. of 2880
  EndIf

;Set default values for header parameters.
  nCol = -1				;flag value, must exist in header
  nRow = 1				;default to single row
  Bzero = 0.0				;default to no zero offset
  Bscale = 1.0				;default to no scaling
  Obs = 'Unk'				;default observation number
  ObsL = 'Unk'				;default observation number list
  Object = 'Unknown - header card not found.'	;default object string
  NonStd = 2				;default: use stnadard FITS tranform

;Parse header for image information.
  For iCard=0,nCards-1 Do Begin		;loop thru header cards
    Card = Head[iCard]			;extract card
    eqpos=strpos(card,'=')              ;find position of '='
    Tag = strcompress(StrMid(Card,0,eqpos-1),/remove_all) ;identification tag
    If Tag eq 'NAXIS1' Then Begin	;true: # columns card found
      nCol = Long(StrMid(Card,eqpos+1,21))	;get # of columns
    EndIf
    If Tag eq 'NAXIS2' Then Begin	;true: # rows card found
      nRow = Long(StrMid(Card,eqpos+1,21))	;get # of rows
    EndIf
    If Tag eq 'BZERO' Then Begin	;true: BZERO card found
      Bzero = Double(StrMid(Card,eqpos+1,21)+'D0')	;zero point offset
    EndIf
    If Tag eq 'BSCALE' Then Begin	;true: BSCALE card found
      Bscale = Double(StrMid(Card,eqpos+1,21)+'D0')	;scale factor
    EndIf
    If Tag eq 'OBSNUM' or Tag eq 'FRAMENO' Then Begin	;true: id number found
      Obs = StrTrim(StrMid(Card,eqpos+1,21),2)  ;get observation number
    EndIf
    If Tag eq 'OBSLIST' Then Begin	;true: OBSLIST card found
      ObsL = StrTrim(StrMid(Card,eqpos+3,68),2)  ;get list of obs numbers
      ObsL = StrMid(ObsL,0,StrLen(ObsL)-1)  ;remove trailing quote
    EndIf
    If Tag eq 'OBJECT' Then Begin	;true: object ID card found
      Object = StrTrim(StrMid(Card,eqpos+3,39),2)  ;get object ID
    EndIf
;
;The following code block checks whether this file was written by older
; versions of wtfits.pro, which used nonstandard scaling transformations.
;A variety of nonstandard transformations were employed. Unfortunately,
; it is impossible to tell from the header which transformation was used.
;Here, we *guess* based on the write date and the sign of the BZERO term.
    If Tag eq 'COMMENT' Then Begin	;true: object comment card
      If StrMid(Card,11,32) eq 'Written to disk by WTFITS.PRO on' Then Begin
        Message,/Info,'Nonstandard scaling transformation detected:'
	MonStr = StrMid(Card,48,3)	;abbreviation for month when written
	Mon = Where(Months eq MonStr,N)	;find month number
	If N eq 0 Then $
	  Message,'Trouble parsing date in old wtfits COMMENT card.'
	Mon = Mon[0]			;convert to scalar
	Day = Fix(StrMid(Card,52,2))	;day of month when written
	Year = Fix(StrMid(Card,66,2))	;year when written
	WriteDate = Year+ Mon/100.0+ Day/100.0	;date when data file written
	RevDate = 92+ 8/100.0+ 5/100.0		;wtfits changed on 5-Sep-92
	If WriteDate lt RevDate Then Begin	;true: must be older transform
	  NonStd = 0			;flag oldest transformation
	  Message,/Info,'             {Unscaled = (Scaled/BSCALE) - BZERO}'
	EndIf Else Begin		;else: could be either nonstd tranform
	  If BScale lt 0 Then Begin	;BZERO implies oldest nonstd transform	
	    NonStd = 0 			;flag oldest transformation
	    Message,/Info,'  _probably_ {Unscaled = (Scaled/BSCALE) - BZERO}'
	  EndIf Else Begin		;BZERO implies newer nonstd transform
	    NonStd = 1			;flag newer nonstd transformation
	    Message,/Info,'  _probably_ {Unscaled = (Scaled/BSCALE) + BZERO}'
	  EndElse
	EndElse
      EndIf
    EndIf
;End nonstandard scaling detection code. JAV 26-Mar-93.
;
  EndFor

;
;Force a particular scaling transformation, if keyword Force is defined.
  If N_Elements(Force) gt 0 Then Begin	;true: keyword defined
    If (Force ne 0 and Force ne 1 and Force ne 2) Then $
      Message,'Force keyword must be either 0, 1, or 2 - see program header.'
    If Force eq NonStd Then Begin	;true: unneeded force
      Message,/Info,'Unnecessary use of "force=" detected.'
    EndIf Else Begin			;else: must force tranformation type
      NonStd = Force			;force transformation type
      If Force eq 2 Then Begin		; true: forcing standard
	Message,/Info,'Forcing standard FITS scaling transformation:'
	Message,/Info,'             {Unscaled = (Scaled*BSCALE) + BZERO}'
      EndIf Else Begin			; else: forcing nonstandard transform
	Message,/Info,'Forcing nonstandard scaling transformation:'
	If Force eq 1 Then Begin	;  Force=1
	  Message,/Info,'             {Unscaled = (Scaled/BSCALE) + BZERO}'
	EndIf Else Begin		;  Force=0
	  Message,/Info,'             {Unscaled = (Scaled/BSCALE) - BZERO}'
	EndElse
      EndElse
    EndElse
  EndIf
;End scaling transformation forcing code. JAV 26-Mar-93
;

  If nCol eq -1 Then Begin		;true: number of columns not found
    Message,/Info,'Unable to determine number of image columns from header.'
    Message,/Info,'Input number of columns, number of rows'
    read,nCol,nRow
  Endif

;Ouput brief summary of header infomation.
  If ObsL eq 'Unk' Then Begin		;true: single observation
    Message,/Info,'Cols=' + StrTrim(String(nCol),2) + $
      ', Rows=' + StrTrim(String(nRow),2) + $
      ', Obs=' + Obs + ', Object=' + Object
  EndIf Else Begin			;else: coadded observations
    Message,/Info,'Cols=' + StrTrim(String(nCol),2) + $
      ', Rows=' + StrTrim(String(nRow),2) + $
      ', Obs=[' + ObsL + '], Object=' + Object
  EndElse

;Open FITS file for read. Associate variable with file (skipping header).
  OpenR,Unit,File,/Get_Lun		;open file, assign logical unit
  Point_Lun,Unit,HSiz			;skip header

;Read image data and convert to floating point.
  If Keyword_Set(NoScale) Then Begin	;true: will return I*2 array
    message,/info,'Disk FITS image is not being rescaled.' 
    Im = IntArr(nCol,nRow,/NoZero)	;init I*2 image array
    ReadU,Unit,Im			;read integer image
    If Keyword_Set(ClipBase) Then Im = Im[0:nCol-2,*]	;clip last column
  EndIf Else Begin			;else: will return F*4 array
    IBuff = IntArr(nCol,/NoZero)	; init I*2 row buffer
    If Keyword_Set(ClipBase) Then Begin	; true: need to clip last column
      Im = FltArr(nCol-1,nRow,/NoZero)	; init F*4 image array
      Case NonStd Of
	0: Begin				;oldest nonstd tranformation
          For iRow=0,nRow-1 Do Begin		;loop thru rows
            ReadU,Unit,IBuff			;get row from file
            If ByteSwap Then ByteOrder,/SSwap,IBuff  ;convert VAX to IEEE I*2
            Im[*,iRow] = Float(IBuff[0:nCol-2]*BScale - BZero)  ;rescale data
          EndFor
	End
	1: Begin				;newer nonstd transformation
          For iRow=0,nRow-1 Do Begin		;loop thru rows
            ReadU,Unit,IBuff			;get row from file
            If ByteSwap Then ByteOrder,/SSwap,IBuff  ;convert VAX to IEEE I*2
            Im[*,iRow] = Float(IBuff[0:nCol-2]/BScale + BZero)  ;rescale data
          EndFor
	End
	2: Begin				;FITS standard transformation
          For iRow=0,nRow-1 Do Begin		;loop thru rows
            ReadU,Unit,IBuff			;get row from file
            If ByteSwap Then ByteOrder,/SSwap,IBuff  ;convert VAX to IEEE I*2
            Im[*,iRow] = Float(IBuff[0:nCol-2]*BScale + BZero)  ;rescale data
          EndFor
	End
      EndCase
    EndIf Else Begin			; else: don't clip last column
      Im = FltArr(nCol,nRow,/NoZero)	; init F*4 image array
      Case NonStd Of
	0: Begin				;oldest nonstd transformation
          For iRow=0,nRow-1 Do Begin		;loop thru rows
            ReadU,Unit,IBuff			;get row from file
            If ByteSwap Then ByteOrder,/SSwap,IBuff  ;convert VAX to IEEE I*2
            Im[*,iRow] = Float(IBuff/BScale - BZero)  ;rescale data
          EndFor
	End
	1: Begin				;newer nonstd transformation
          For iRow=0,nRow-1 Do Begin		;loop thru rows
            ReadU,Unit,IBuff			;get row from file
            If ByteSwap Then ByteOrder,/SSwap,IBuff  ;convert VAX to IEEE I*2
            Im[*,iRow] = Float(IBuff/BScale + BZero)  ;rescale data
          EndFor
	End
	2: Begin				;FITS standard transformation
          For iRow=0,nRow-1 Do Begin		;loop thru rows
            ReadU,Unit,IBuff			;get row from file
            If ByteSwap Then ByteOrder,/SSwap,IBuff  ;convert VAX to IEEE I*2
            Im[*,iRow] = Float(IBuff*BScale + BZero)  ;rescale data
          EndFor
	End
      EndCase
    EndElse
  EndElse
  Free_Lun,Unit				;free logical unit, close file

End
