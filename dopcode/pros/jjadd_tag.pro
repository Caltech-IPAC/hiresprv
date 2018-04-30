;+
; NAME:
;      JJADD_TAG
;
; PURPOSE:
;      Add a tag to a pre-existing array of strutures
;
; CALLING SEQUENCE:
;      new = JJadd_Tag(struct, tag_name, value)
;
; INPUTS:
;      tag_name - The name of a new structure tag to be added
;      value    - The value to be assigned to the new tag
;
; KEYWORD PARAMETERS:
;
;      array_tag - Set this keyword flag if value is an array that
;                  should be inserted into a single tag, e.g. if 
;                  struct.tag_name = fltarr(10)
;
; OUTPUTS:
;
;      A new array of structures
;
; RESTRICTIONS:
;
;      Only works with anonymous structures. But the code is 46%
;      faster than the ICG routine ADD_TAG2. Tested using Tim
;      Robishaw's BENCHMARK.
;
; EXAMPLE:
;
;      struct = {a: 0., b: 'blah'}
;      new = jjadd_tag(struct, 'new', 0b)
;      help,new,/struct
;** Structure <2453f8>, 3 tags, length=32, data length=21, refs=1:
;   A               FLOAT           0.00000
;   B               STRING    'blah'
;   NEW             BYTE         0
;
; MODIFICATION HISTORY:
;
;  20 Apr 2005 - JohnJohn created 
;  20 Apr 2005 - Fixed so that NEW is actually assigned the value
;                VALUE rather than just 0. Thank's Louis!
;-
function jjadd_tag, struct, tagname, valuein, array_tag=array_tag
on_error, 2                     ;If broken, return to sender
nel = n_elements(struct)
nelv = n_elements(valuein)
ntags = n_tags(struct)
if n_params() ne 3 then $
  message,'Correct calling sequence: NEW = jjadd_tag(STRUCT, TAGNAME, VALUE)', /ioerr
tn = tag_names(struct[0])
if total(strmatch(tn, tagname)) then return, struct

if 1-keyword_set(array_tag) then begin
    if nelv ne 1 and nelv ne nel then $
      message,'VALUE must be a scalar or have the same length as STRUCT.',/ioerr

;set up the scalar place-holder variable
    newsingle = create_struct(struct[0], tagname, valuein[0])
endif else begin
    newsingle = create_struct(struct[0], tagname, valuein)
endelse
;set up the output array of structures with the new tag
newarray = replicate(newsingle, nel)
insert = 0b
if nelv eq 1 then newarray.(ntags) = valuein else begin
    value = valuein
    insert = 1b
endelse
for i = 0, nel-1 do begin
    ;;; STRUCT_ASSIGN will set the new tag to 0
    struct_assign, struct[i], newsingle, /nozero
    newarray[i] = newsingle
    if insert then if keyword_set(array_tag) then $
      newarray[i].(ntags) = value else newarray[i].(ntags) = value[i]
endfor
return, newarray
end
