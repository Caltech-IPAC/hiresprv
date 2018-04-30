Pro WDsk,Var,InFile,Arg3,Arg4,New=New,Old=Old,Insert=Insert
;General purpose routine to store variables to disk.
; Var (input variable, any type/size) variable to be stored.
; InFile (input string) name of file in which to store variable.
; Arg3 and Arg4 are Record and/or Comment in any order...
;   Record (optional input scalar) file index at which to store variable.
;     1=first storage position, 0=last storage position.
;   Comment (optional input string) comment to store with variable.
; /New (logical) forces the creation of a new file. Record must be 0 or 1.
; /Old (logical) updates existing file. Error if file doesn''t exist.
; /Append (logical) allows insertion of data in the middle of file.
;   New variable must have the same length as the previous one.
;12-Jul-91 JAV	Create.
;11-May-94 JAV  Added on_error trap. 
;10-Sep-94 JAV	Added path expansion.

;Verify that enough arguments were passed.
  If N_Params() lt 2 Then Begin			;true: not enough arguments
    Message,/Info,'Syntax: WDsk,Var,File [,Record] [,Comment] ' $
      + '[,/New] [,/Old] [/Insert]'
    RetAll					;leave user at top level
  End

;If an error occurs below, return to the main program level. 
  On_Error, 2 

;Assign defaults to optional arguments and parameters.
  Record = 0					;default output record
  Comment = ''					;default null comment
  CLen = Fix(0)					;default zero length comment

;Parse third (non-keyword) argument if it exists.
  If N_Params() ge 3 Then Begin			;true: one optional argument
    Siz = Size(Arg3)				;variable information block
    If Siz(0) ne 0 Then Goto,E_BadArg		;true: argument is array
    VTyp3 = Siz(N_Elements(Siz)-2)		;variable type (table B.4)
    If (VTyp3 ge 1) and (VTyp3 le 5) Then Begin	;true: numerical argument
      Record = Long(Arg3)			;Arg3 is Record number
    EndIf Else Begin				;else: nonnumeric argument
      If VTyp3 eq 7 Then Begin			;true: string argument
        Comment = Arg3				;Arg3 is Comment
        CLen = Fix(StrLen(Comment))		;length of comment
      EndIf Else Goto,E_BadArg			;else: bad Arg3 
    EndElse
  End

;Parse fourth (non-keyword) argument if it exists.
  If N_Params() ge 4 Then Begin			;true: two optional arguments
    Siz = Size(Arg4)				;variable information block
    If Siz(0) ne 0 Then Goto,E_BadArg		;true: argument is array
    VTyp4 = Siz(N_Elements(Siz)-2)		;variable type (table B.4)
    If (VTyp4 ge 1) and (VTyp4 le 5) Then Begin	;true: numerical argument
      If VTyp3 ne 7 Then Goto,E_BadArg		;true: comment missing
      Record = Long(Arg4)			;Arg4 is Record
    EndIf Else Begin				;else: nonnumeric argument
      If VTyp4 eq 7 Then Begin			;true: string argument
        If VTyp3 eq 7 Then Goto,E_BadArg	;true: Record missing
        Comment = Arg4				;Arg4 is Comment
        CLen = Fix(StrLen(Comment))		;length of comment
      EndIf Else Goto,E_BadArg			;else: bad Arg4
    EndElse
  EndIf

;Determine and validate properties of variable to be stored.
  Siz = Size(Var)				;variable information block
  nDim = Byte(Siz(0))				;number of dimensions
  If nDim gt 0 Then Dims = Siz(1:nDim)		;size of each dimension
  VTyp = Byte(Siz(nDim+1))			;variable type code
  nEle = N_Elements(Var)			;number of elements in Var
  If VTyp eq 0 Then Begin			;undefined variable
    Message,'Variable to store is undefined.'
  EndIf
  If VTyp eq 8 Then Begin			;true: passed a structure
    Message,'This program cannot be used to save structures.'
  EndIf
  If VTyp eq 7 Then Begin			;true: string variable
    VSiz = 0					;init string size
    For iEle=0,nEle-1 Do Begin			;loop thru elements
      VSiz = VSiz + StrLen(Var(iEle)) + 2	;accumulate string size(s)
    EndFor
  EndIf Else Begin				;else: numeric variable
    BperE = VTyp				;set bytes per elements
    If VTyp eq 3 Then BperE = 4			;fix integer*2
    If VTyp gt 4 Then BperE = 8			;fix real*8,complex
    VSiz = nEle*BperE				;size of numeric variable
  EndElse
  VSiz = Long(CLen) + 12 + 4*nDim + VSiz	;add in header size

;Determine whether the specified file exists.
  File = InFile					;copy to local variable
  Siz = Size(File)				;variable information block
  If Siz(N_Elements(Siz)-2) ne 7 Then Begin	;variable type (table B.4)
    Message,'Second argument must be a string specifying the output filename.'
  EndIf
  File = Expand_Path(InFile)			;expand path
  Dummy = FindFile(File)			;number of files found
  If N_Elements(Dummy) gt 1 Then Begin		;true: wildcarded filename
    Message,'No wildcards are allowed in filename specification.'
  End
  Dummy = Dummy(0)				;convert filename to scalar

;Access a new file. Verify valid file index.
  If Record lt 0 Then Begin			;true: bad index
    Message,'Negative Record numbers are not allowed.'
  EndIf
  If (StrLen(Dummy) eq 0) or KeyWord_Set(New) Then Begin  ;true: new file
    If Keyword_Set(Old) Then Begin		;true: "Old" keyword set
      If Keyword_Set(New) Then Begin		;true: "New" keyword set also!
        Message,'Don''t use both the "/New" and "/Old" keywords together.'
      EndIf Else Begin				;fall thru: no old file
        Message,'Can''t find "/Old" file: ' + File
      EndElse
    EndIf Else Begin				;fall thru: open new file
      If (Record gt 1) Then Begin		;true: bad index
        Message,'Record other than 0 or 1 requested for nonexistent file.'
      EndIf
      OpenW,Unit,File,/Get_Lun,/swap_if_little_endian			;open new file
      WriteU,Unit,VSiz				;write record length header
    EndElse

;Access an existing file. Verify valid file index.
  EndIf Else Begin				;fall thru: access old file
    If Record eq 0 Then Begin			;true: append at end of file
      OpenU,Unit,File,/Get_Lun,/Append,/swap_if_little_endian		;open old file, move to end
      WriteU,Unit,VSiz				;write record length header
    EndIf Else Begin				;fall thru: explicit index
      FPtr = 0					;init pointer to first byte
      iRec = 1					;init record pointer
      HLen = Long(0)				;init record length header
      TLen = Long(0)				;init record length tailer
      OpenU,Unit,File,/Get_Lun,/swap_if_little_endian			;open old file at beginning
      FInfo = FStat(Unit)			;file info block (structure)
      FSiz = FInfo.Size				;file size in bytes
      If Record gt 1 Then Begin			;true: must skip records
        If FSiz lt 4 Then Goto,E_BadRec		;true: file too short
        For iRec=1,Record-1 Do Begin		;loop thru stored variables
          If (FPtr + 4) gt FSiz Then Begin	;true: premature end of file
            If FPtr eq FSiz Then Begin		;true: ran out of records
              Free_Lun,Unit			;close file,free unit
              Message,'File contains ' + StrTrim(String(iRec-1),2) + $
                ' records. Specify Record less than ' + $
                StrTrim(String(iRec+1),2) + '.'
            EndIf Else Goto,E_BadRec		;else: too few bytes remain
          EndIf
          Point_Lun,Unit,FPtr			;adjust IDL''s file pointer
          ReadU,Unit,HLen			;read record length header
          FPtr = FPtr + HLen + 4		;point at start of next record
          If (FPtr + 4) gt FSiz Then Goto,E_BadRec  ;true: record beyond EOF
          Point_Lun,Unit,FPtr			;point at record length tailer
          ReadU,Unit,TLen			;read record length tailer
          FPtr = FPtr + 4			;update our pointer
          If HLen ne TLen Then Goto,E_BadRec	;true: bad record structure
        EndFor
      EndIf					;pointing at byte 0 of Record

;Test whether inserts into an existing record are allowed and possible.
      If (not EOF(Unit)) Then Begin		;true: not at end of file
        If (not Keyword_Set(Insert)) Then Begin	;shouldn''t be inserting
          Free_Lun,Unit				;close file,free unit
          Message,'You may not insert into file without setting "/Insert".'
        EndIf
        If (FPtr + 4) gt FSiz Then Goto,E_BadRec  ;true: record beyond EOF
        ReadU,Unit,HLen				;read record length header
        FPtr = FPtr + HLen + 4			;point at start of next record
        If (FPtr + 4) gt FSiz Then Goto,E_BadRec  ;true: record beyond EOF
        Point_Lun,Unit,FPtr			;point at record length tailer
        ReadU,Unit,TLen				;read record length tailer
        FPtr = FPtr - HLen			;point back inside this record
        Point_Lun,Unit,FPtr			;adjust IDL''s pointer
        If HLen ne TLen Then Goto,E_BadRec	;true: bad record structure
        If VSiz gt HLen Then Begin		;true: variable won''t fit
          Free_Lun,Unit				;close file,free unit
          Message,'Variable won''t fit into existing record.'
        EndIf
      EndIf Else WriteU,Unit,VSiz		;else: write record len header
    EndElse
  EndElse

;Get date and time string and extract information as byte array.
;Use Fix() rather than Byte() to avoid interpreting string as ASCII codes.
  Months = 'JanFebMarAprMayJunJulAugSepOctNovDec'
  DTStr = SysTime()				;get date and time string
  DateTime = BytArr(6)				;init date/time byte array
  DateTime(0) = Fix(StrMid(DTStr,22,2))		;extract year modulo 1000
  DateTime(1) = StrPos(Months,StrMid(DTStr,4,3)) / 3 + 1
  DateTime(2) = Fix(StrMid(DTStr,8,2))		;extract day
  DateTime(3) = Fix(StrMid(DTstr,11,2))		;extract hour
  DateTime(4) = Fix(StrMid(DTStr,14,2))		;extract minutes
  DateTime(5) = Fix(StrMid(DTStr,17,2))		;extract seconds

;Fall Thru: We are pointed just beyond the record length header longword.
;Write variable header information to file.
  FormType = Fix(256)				;init format type
  WriteU,Unit,FormType				;write format type
  WriteU,Unit,DateTime				;write date/time stamp
  WriteU,Unit,CLen				;write comment length
  If CLen gt 0 Then Begin			;true: non-null comment
    WriteU,Unit,Comment				;write comment
  EndIf
  WriteU,Unit,VTyp				;write variable type
  WriteU,Unit,nDim				;write number of dimensions
  If nDim gt 0 Then Begin			;true: variable is an array
    WriteU,Unit,Dims				;write dimension sizes
  EndIf

;Write variable data to file, looping explicitly through string arrays.
  If VTyp ne 7 Then Begin			;true: numeric variable
    WriteU,Unit,Var				;write variable data
  EndIf Else Begin				;else: string data
    For iEle=0,nEle-1 Do Begin			;loop thru strings in Var
      SLen = Fix(StrLen(Var(iEle)))		;length of string element
      WriteU,Unit,SLen				;write string length
      WriteU,Unit,Var(iEle)			;write string element
    EndFor
  EndElse

;Write record length tailer, close file and return.
  WriteU,Unit,VSiz				;write record length tailer
  Free_Lun,Unit					;close file,free unit
  Return					;successful completion exit

;Error exits arrived at via Goto statements. Do not fall through here.
E_BadArg:
  Message,'Arguments 3 and 4 must be a Record number and/or a Comment string.'

E_BadRec:
  Free_Lun,Unit					;close file,free unit
  Message,'Record ' + StrTrim(String(iRec),2) + ' has improper structure.'

End
