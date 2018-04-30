;+
; NAME:
;      COL_STRUCT
;
;
; PURPOSE:
;      Create an array of structures based on a white-space 
;      delimited string array (e.g. the output from a spawn 
;      command). Each white-space separated "column" is assigned 
;      to a structure field, and each element or "line" in the 
;      string array is assigned to a structure element.
;
; CALLING SEQUENCE:
;      result = col_struct(lines, tagnames [, types=])
;
; INPUTS:
;      LINES: String array containing white-space delimited values
;      TAGNAMES: The name of each column in the string array
;
; KEYWORD PARAMETERS:
;      TYPES: The data type of each structure tag
;             i = integer
;             f = float
;             d = double
;             a = string
;             b = byte
;
; OUTPUTS:
;      An array of structures
;
; CALLS:
;      Uses JJADD_TAG:
;      http://astron.berkeley.edu/~johnjohn/idl.html#JJADD_TAG
;      
; EXAMPLE:
;     
; IDL> spawn,'cat data.txt'
; HD123   00.0123 -40.48939       7.6     standard
; HD423   10.213  -44.40031       8.1     binary
; HD1000  14.213  24.00131        3.2     test
; IDL> spawn,'cat data.txt', lines
; IDL> struct = col_struct(lines, ['star','ra','dec','vmag','notes'] $
; IDL> , types=['a','f','f','f','a'])
; IDL> help, struct, /structure
; ** Structure <2167ce0>, 5 tags, length=36, data length=36, refs=1:
;    STAR            STRING    'HD123'
;    RA              FLOAT         0.0123000
;    DEC             FLOAT          -40.4894
;    VMAG            FLOAT           7.60000
;    NOTES           STRING    'standard'
; IDL> help, struct
; STRUCT          STRUCT    = -> <Anonymous> Array[3]
;
; MODIFICATION HISTORY:
;
;  23 Nov 2005 - JohnJohn created 
;-

function col_struct, lines, tagnames, types=types
nlines = n_elements(lines)
ntags = n_elements(tagnames)
if keyword_set(types) then ntypes = n_elements(types)

for i = 0, ntags-1 do begin
    if keyword_set(types) then begin
        t = strlowcase(strmid(types[i < (ntypes-1)], 0, 1))
        case t of
            'd': val = (make_array(1, /double))[0]
            'a': val = (make_array(1, /string))[0]
            'f': val = (make_array(1, /float))[0]
            'b': val = (make_array(1, /byte))[0]
            'i': val = (make_array(1, /integer))[0]
            else : val = ''
        endcase
    endif else val = ''
    if i eq 0 then struct = create_struct(tagnames[0], val) else $
      struct = jjadd_tag(struct, tagnames[i], val)
endfor

struct = replicate(struct, nlines)
for i = 0, nlines-1 do begin
    parts = strsplit(lines[i], /extract)
    for j = 0, ntags-1 do struct[i].(j) = parts[j]
endfor
return, struct
end
