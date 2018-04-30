function getcolor, colorname, colornames, tableindices, $
                   DECOMPOSED=decomposed
;+
; NAME:
;       GETCOLOR
;     
; PURPOSE:
;       This function returns the color table index of the color
;       corresponding to the color name which is input.  If the
;       line plot color names and color table indices are not
;       provided, SETCOLORS is called to set up basic line plot
;       colors. Designed to work correctly on both X Window and 
;       PostScript devices.
;     
; CALLING SEQUENCE:
;      color = getcolor(colorname, names, tableindx)
;
;      OR
;
;      color = getcolor(colorname[, DECOMPOSED=decomposed]) 
;     
; INPUTS:
;       COLORNAME: A string whose value is the name of a line plot
;                  color.  Must not be an array.
;     
; OPTIONAL INPUTS:
;       COLORNAMES: An array of strings which correspond to line
;                   plot colors that are available to the user.
;
;       TABLEINDICES: An array of the color table indices (8-bit) or 
;                     24-bit integers corresponding to the line plot colors.
;     
; OUTPUTS:
;       Function value returned = color table index of input color name.
;
; KEYWORDS:
;       DECOMPOSED = Set this keyword to explicitly use decomposed color
;                    on 24-bit machines. Has no effect on devices which 
;                    do not support decomposed color. Set this keyword
;                    to 0 to turn off decomposed color on 24-bit
;                    devices. If COLORNAMES and TABLEINDICES are set,
;                    this keyword has no effect.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       If the line plot color name COLORNAME is not found in the
;       list of available line plot colors COLORNAMES, the value of
;       the system plot color, !p.color, is returned.  If only
;       COLORNAME is input and color decomposition is not on, the line 
;       plot colors are added to the top of the current color table.
;
; RESTRICTIONS:
;       Only supported by IDL v5.2 or higher. 
;
; PROCEDURES CALLED:
;       FILE_WHICH
;       SETCOLORS
;
; EXAMPLE:
;       Once an array of line plot color names and their corresponding
;       color table indices (8-bit) or 24-bit integers have been
;       established, use GETCOLOR to obtain one of these values:
;
;       IDL> setcolors, NAMES=cnames, VALUES=cindx
;       IDL> plot, findgen(30), color=getcolor('orange',cnames,cindx)
;
;       If no line plot color information exists, call GETCOLOR with
;       only a color name and SETCOLORS will be called to establish
;       a set of basic colors:
;
;       IDL> plot, findgen(30), color=getcolor('cyan')
;
;       If referencing many colors, this is much slower than the
;       the previous example.  However, it's likely that if you're
;       plotting something, you're not aiming for speed anyway!
;
; RELATED PROCEDURES:
;       SETCOLORS
;
; MODIFICATION HISTORY:
;   Written Tim Robishaw, Berkeley 13 Aug 2001
;-

on_error, 2

; A LOT OF ERROR CATCHING INVOLVED!
case 1 of 

    ; FIND IDL VERSION NUMBER... 5.2 OR HIGHER...
    float(!version.release) lt 5.2 : $
      message,'This routine is only supported on IDL version 5.2 or higher', $
      /INFO

    ; ONLY ACCEPTS ONE COLOR NAME...
    size(colorname, /n_dimensions) ne 0 : $
      message, 'COLORNAME cannot be an array!', /INFO

    ; EITHER SEND IN BOTH COLORNAMES AND TABLE INDICES WITH THE COLOR NAME
    ; OR SEND IN JUST THE COLOR NAME...
    N_params() eq 2 : begin
      message, 'Syntax:', /INFO
      message, ' color = getcolor(colorname, names, tableindx)', /INFO
      message, '   OR', /INFO
      message, ' color = getcolor(colorname [, DECOMPOSED=decomposed])', /INFO 
    end

    ; THE REQUESTED COLOR MUST BE A STRING...
    size(colorname, /tname) ne 'STRING' : $
      message, 'COLORNAME must be a string!', /INFO

    ; THE COLORNAMES MUST BE DEFINED...
    N_params() eq 3 AND N_elements(colornames) eq 0 : $
      message, 'COLORNAMES must be defined!', /INFO

    ; TABLEINDICES MUST BE DEFINED...
    N_params() eq 3 AND N_elements(tableindices) eq 0 : $
      message, 'TABLEINDICES must be defined!', /INFO

    ; THE COLORNAMES MUST BE STRINGS...
    N_params() eq 3 AND size(colornames, /tname) ne 'STRING' : $
      message, 'COLORNAMES must be strings!', /INFO

    ; IF ONLY A COLORNAME IS SENT...
    N_params() eq 1 AND N_elements(colorname) ne 0 : $
      begin

        ; CAN'T USE DECOMPOSED IF POSTSCRIPT!!!
        ; do we just set dec=0 if not x-win?
        if (!d.name ne 'X') then decomposed=0 $
        else $
        ; IF DECOMPOSED NOT EXPLICITLY SET, USE CURRENT VALUE...
        if (N_elements(DECOMPOSED) eq 0) $
          then device, get_decomposed=decomposed

        ; IS SETCOLORS ON THE IDL PATH...
        if float(!version.release) ge 5.4 then begin
            found = file_which('setcolors.pro')
            if (found eq '') then begin
                message, 'SETCOLORS.PRO not found on IDL path!', /INFO
                goto, error
            endif
        endif

        ; RUN SETCOLORS TO ESTABLISH THE LINE PLOT COLORS...
        setcolors, NAMES=colornames, VALUES=tableindices, $
          DECOMPOSED=decomposed, /SILENT

        goto, noerror
      end

    ; NO PROBLEMS HERE...
    else : goto, noerror
endcase

error:

; IF THERE WAS AN ERROR, SPLIT...
message, 'Using system plot color: !p.color = '+strtrim(!p.color,2), /INFO
return, !p.color

noerror:

; IS THE REQUESTED COLOR DEFINED?
colorname = strupcase(strtrim(colorname,2))
colorindx = where(strupcase(colornames) eq colorname, match)
if (match eq 0) then begin
    message, 'Color '+colorname+' not found in list of colors:', /INFO
    message, strjoin(colornames,' '), /INFO
    goto, error
endif

; RETURN THE COLOR TABLE INDEX OF THIS COLOR...
return, (tableindices[colorindx])[0]
end; getcolor


