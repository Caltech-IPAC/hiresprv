Pro FITSHd,File,Head
;Subroutine to read header of FITS file.
; File (input string) filename specification
; [ Head (optional output string vector(# cards)) ] FITS header cards
;10-Apr-91 JAV	Create.
;24-Jul-91 JAV	Ported from ANA to IDL.
;9-Jan-93  GB  modified to work in case of no END card(eg.Lick summed image)
;26-Feb-93 JAV	Increased MaxCrd from 2*36 to 4*36 to accomodate KAST headers.
If N_Params() lt 1 Then Begin
  Message,/Info,'Syntax: FITSHd,File [,Head]'
  RetAll
EndIf

;Program parameters
  MaxCrd = 8*36				;maximum number of header cards

;Open file and insure records have standard FITS length.
  Head = String(Replicate(32b,80,MaxCrd))  ;init array of header cards
  OpenR,Unit,File,/Get_Lun		;open FITS file for read
  ReadU,Unit,Head			;read header cards + maybe junk
  Free_Lun,Unit				;close FITS file
  EndC = -1 & BlnkC = -1		;clear card number of END card
  For iCrd=MaxCrd-1,0,-1 Do Begin	;loop thru cards from back to front
    If StrMid(Head(iCrd),0,8) eq 'END     ' Then EndC = iCrd
    If StrMid(Head(iCrd),0,8) eq '        ' Then BlnkC = iCrd
  EndFor
  If EndC eq -1 Then Begin
	EndC = BlnkC
	print,'No END card found, EndC set to',BlnkC
  Endif
  If EndC eq -1 Then message,'No Blank cards either'
  Head = head(0:EndC)			;keep only header information

;Dump header cards to screen, if requested.
  If N_Params() lt 2 Then Begin		;true: screen dump requested
    For iCrd=0,EndC Do Begin		;loop thru cards
      If StrTrim(Head(iCrd)) ne '' Then Begin  ;true: non-blank card
        Print,StrTrim(Head(iCrd))	;print without trailing blanks
      EndIf
    EndFor
  EndIf

End
