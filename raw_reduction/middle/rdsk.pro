Pro RDsk,Var,InFile,Arg3,Arg4
;General purpose routine to restore variables from disk.
; Var (output variable, any type/size) variable to be restored.
; File (input string) name of file from which to restore variable.
; Arg3 is Record (or Comment when file contains only one stored variable).
; Arg4, if it exists, must be Comment.
;   Record (optional input scalar) file index from which to read variable.
;     1=first storage position. May be omitted only if file contains a
;     single variable.
;   Comment (optional output string) comment stored with variable.
;15-Jul-91 JAV	Create.
;11-May-94 JAV  Added on_error trap. 
;10-Sep-94 JAV	Added path expansion.
;25-Aug-99 SF   added logic for eventual byte order swapping
On_Error, 2 

;Verify that enough arguments were passed.
If N_Params() lt 2 Then Begin   ;true: not enough arguments
    Message,/Info,'Syntax: RDsk,Var,File [,Record] [,Comment]'
    RetAll                      ;leave user at top level
EndIf

;If an error occurs below, return to the main program level. 

;flag to determine whether byte order swapping is needed before exiting with an error
first=0					

start:
;Determine whether the requested file exists.
File = InFile                   ;copy to local variable
Siz = Size(File)                ;variable information block
If Siz(N_Elements(Siz)-2) ne 7 Then Begin ;variable type (table B.4)
    Message,'Second argument must be a string specifying the input filename.'
EndIf
File = Expand_Path(File)        ;expand path
Dummy = FindFile(File)          ;number of files found
If N_Elements(Dummy) gt 1 Then Begin ;true: wildcarded filename
    Message,'No wildcards are allowed in filename specification.'
EndIf
Dummy = Dummy(0)                ;convert filename to scalar
If StrLen(Dummy) eq 0 Then Begin ;true: file doesn''t exist
    Message,'Can''t find input file: ' + File
EndIf

;Open file.
;  if first then OpenR,Unit,File,/Get_Lun else
;  OpenR,Unit,File,/Get_Lun,/swap_if_big_endian,/swap_if_little_endian 
try = 1
swap = 1
tryagain:
OpenR,Unit,File,/Get_Lun $
      , swap_if_little_endian=keyword_set(swap) ;$
;        , swap_endian=keyword_set(swap)
FInfo = FStat(Unit)             ;file info block (structure)
FSiz = FInfo.Size               ;file size in bytes
iRec = 1                        ;set current record pointer
If FSiz lt 4 Then Goto,E_BadRec	;file too short

;Determine whether file contains single variable (needed to parse arguments).
Single = 0                      ;assume multiple variables
HLen = Long(0)                  ;init record length header
TLen = Long(0)                  ;init record length tailer
ReadU,Unit,HLen                 ;read record length header

IF Hlen LT 0 THEN begin
    if try gt 1 then Goto,E_BadRec else begin
        try++
        swap = 0
        free_lun, unit
        goto, tryagain
    endelse
endif
If (HLen + 8) gt FSiz  Then begin
    if try gt 1 then Goto,E_BadRec else begin
        try++
        swap = 0
        free_lun, unit
        goto, tryagain
    endelse
endif                           ;true: head points beyond EOF
If (HLen + 8) eq FSiz Then Single = 1 ;true: single variable stored
;Parse and validate optional arguments.
;Two arguments are allowed only when a single variable is stored.
If N_Params() eq 2 Then Begin   ;no extra arguents
    If (not Single) Then Begin  ;multiple stored variables
        Point_Lun,Unit,HLen+4   ;point at record length tailer
        ReadU,Unit,TLen         ;read record length tailer
        If HLen ne TLen Then Goto,E_BadRec Else Goto,E_MulRec
    EndIf Else Record = 1       ;else: single record
EndIf

;Third argument must be Record, unless file contains only one record.
If N_Params() ge 3 Then Begin   ;true: extra arguments
    Siz = Size(Arg3)            ;variable information block
    VTyp = Siz(N_Elements(Siz)-2) ;variable type (table B.4)
    If (VTyp ge 1) and (VTyp le 5) Then Begin ;true: Arg3 is a scalar
        Record = Arg3           ;Arg3=Record
        If Record le 0 Then Begin ;true: invalid record number
            Free_Lun,Unit       ;close file,free unit
            Message,'Record numbers must be positive.'
        EndIf
        CArg = 4                ;return comment in Arg4
    EndIf Else Begin            ;else: Arg3 not a scalar
        If (Single) Then Begin  ;true: Arg3=Comment
            Record = 1          ;set Record to 1
            CArg = 3            ;return comment in Arg3
        EndIf Else Goto,E_MulRec ;else: multiple records
    EndElse
EndIf

;Skip through records, verifying header/tailer integrity.
FPtr = 0                        ;init pointer to current byte
For iRec=1,Record Do Begin      ;skip intervening records
    If (FPtr + 4) gt FSiz Then Begin ;premature end of file
        If FPtr eq FSiz Then Begin ;true: ran out of records
            Free_Lun,Unit       ;close file,free unit
            Message,'You requested record ' + StrTrim(String(Record),2) + $
                    '. File only contains ' + StrTrim(String(iRec-1),2) + ' record(s).'
        EndIf Else Goto,E_BadRec ;else: too few bytes remain
    EndIf
    Point_Lun,Unit,FPtr         ;adjust IDL's file pointer
    ReadU,Unit,Hlen             ;read record length header
    FPtr = FPtr + HLen + 4      ;point at start of next record
    If (FPtr + 4) gt FSiz Then Goto,E_BadRec ;true: record beyond EOF
    Point_Lun,Unit,FPtr         ;point at record length tailer
    ReadU,Unit,TLen             ;read record length tailer
    FPtr = FPtr + 4             ;update our file pointer
    If HLen ne TLen Then Goto,E_BadRec ;true: bad record structure
EndFor

                                ;Read and validate header information within requested record.
iRec = Record                   ;set current record pointer
If (HLen lt 12) Then Goto,E_BadVar ;true: block doesn't fit
FPtr = FPtr - HLen - 4          ;point into desired record
Point_Lun,Unit,FPtr             ;make IDL point into record
FormType = Fix(-1)              ;init data format type
ReadU,Unit,FormType             ;read data format type
If FormType ne 256 Then Goto,E_BadVar ;true: bad format type
DateTime = BytArr(6)            ;init date/time stamp
ReadU,Unit,DateTime             ;read date/time stamp
CLen = Fix(-1)                  ;init comment length
ReadU,Unit,CLen                 ;read comment length
FPtr = FPtr + 10                ;update our file pointer
If CLen lt 0 Then Goto,E_BadVar ;true: invalid comment size
Comment = ''                    ;init default null Comment
If CLen gt 0 Then Begin         ;true: comment follows
    If (FPtr+CLen+6) gt FSiz Then Goto,E_BadVar	;true: block doesn't fit
    Comment = String(Replicate(32b,CLen)) ;init comment string
    ReadU,Unit,Comment          ;read comment string
EndIf
VTyp = Byte(-1)                 ;init variable type
ReadU,Unit,VTyp                 ;read variable type
If (VTyp lt 0) or (VTyp gt 7) Then Goto,E_BadVar ;true: bad variable type
nDim = Byte(-1)                 ;init number of dimensions
ReadU,Unit,nDim                 ;read number of dimensions
If (nDim lt 0) or (nDim gt 8) Then Goto,E_BadVar ;true: invalid # dimens
If nDim gt 0 Then Begin         ;true: dimensions follow
    Dims = LonArr(nDim)         ;init dimension vector
    ReadU,Unit,Dims             ;read dimension vector
EndIf Else Dims = 1             ;else: single element vector

;Initialize variable and read data from requested record.
If VTyp eq 0 Then Begin         ;true: restoring undefined
    Free_Lun,Unit               ;close file,free ubit
    If Keyword_Set(Var) Then Begin ;true: Var argument defined
        Message,'Can''t restore undefined variable into a defined variable.'
    EndIf
    Return                      ;return without defining Var
End
Var = Make_Array(Dim=Dims,Typ=VTyp,/NoZero) ;init string/numeric variable
nEle = N_Elements(Var)          ;calculate variable length
If VTyp ne 7 Then Begin         ;true: numeric variable
    BperE = VTyp                ;set bytes per element
    If VTyp eq 3 Then BperE = 4 ;fix integer*4 case
    If VTyp gt 4 Then BperE = 8 ;fix real*8,complex cases
    If (12 + CLen + 4*nDim + nEle*BperE) gt FSiz Then Goto,E_BadVar
    ReadU,Unit,Var              ;read variable
EndIf Else Begin                ;else: string variable
    SSiz = 0                    ;init string size read so far
    For iEle=0,nEle-1 Do Begin  ;loop thru elements in array
        SLen = Fix(-1)          ;init string variable length
        ReadU,Unit,SLen         ;read string variable length
        If SLen gt 0 Then Begin ;valid string length
            SBuff = String(Replicate(32b,SLen))	;init string buffer
            SSiz = SSiz + SLen + 2 ;update total string size
            If (12 + CLen + 4*nDim + SSiz) gt FSiz Then Begin
                Message,'Stored string array has improper strucutre.'
            EndIf
            ReadU,Unit,SBuff    ;read one string element
            Var(iEle) = SBuff   ;insert element into array
        EndIf Else If SLen lt 0 Then Goto,E_BadVar ;else: bad string length
    EndFor
EndElse
If nDim eq 0 Then Var = Var(0)  ;true: convert scalars

;Return comment in appropriate argument.
If Keyword_Set(CArg) Then Begin ;true: argument flag exists
    If CArg eq 3 Then Arg3 = Comment Else Arg4 = Comment
EndIf
Free_Lun,Unit                   ;close file,free unit
Return                          ;successful completion exit

;Error exits arrived at via Goto statements. Do not fall though here.
E_BadRec:                       ;bad record error entry point 
if first eq 0 then begin        ;if first time try byte swapping
    first=1                     ;before exiting
    Free_Lun,Unit
    goto,start
endif
Free_Lun,Unit                   ;close file,free unit.
Message,'Record ' + StrTrim(String(iRec),2) + ' has improper structure.'

E_MulRec:
Free_Lun,Unit                   ;close file,free unit
Message,'File has multiple records - specify Record as third argument.'

E_BadVar:
Free_Lun,Unit
Message,'Record structure is fine, but variable information block is bad.'

End
