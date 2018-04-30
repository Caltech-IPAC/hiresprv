function remove_tag, str, tag_name
;+
; NAME:
;   REMOVE_TAG
; PURPOSE:
;   To remove a specified tag from a structure.
;
; CALLING SEQUENCE:
;   NEW_STR = REMOVE_TAG(STRUCTURE, TAG_NAME)
;
; INPUTS:
;   STRUCTURE -- The structure to have a tag removed.
;   TAG_NAME -- Array or scalar containing the name(s) of 
;               the tags to be removed.
; KEYWORD PARAMETERS:
;   NONE
;
; OUTPUTS:
;   NEW_STR -- The structure sans edited tags.
;
; MODIFICATION HISTORY:
;       Written.
;       Tue Mar 12 22:40:24 2002, Erik Rosolowsky <eros@cosmic>
;
;-

tn = tag_names(str)
boolean = intarr(n_elements(tn))
for jj = 0, n_elements(tag_name)-1 do $
  boolean = boolean+(tn eq strupcase(tag_name[jj]))

ind = where(boolean gt 0)
if ind[0] eq -1 then return, str

index = where(1b-(boolean gt 0))
if index[0] eq -1 then return, 0

; Check if structure is array and try to preserve the array.
if n_elements(str) gt 1 then begin
  array = 1b
  temp = str[0]
  new = create_struct(tn[index[0]], temp.([index[0]]))
  if n_elements(index) gt 1 then begin
    for ii = 1, n_elements(index)-1 do begin
      new = create_struct(new, tn[[index[ii]]], temp.([index[ii]]))
    endfor  
  endif

  new = replicate(new, n_elements(str))
  new[*].(0) = str[*].(index[0])

  if n_elements(index) eq 1 then return, new
  for ii = 1, n_elements(index)-1 do begin
       new[*].(ii) = str[*].(index[ii])
  endfor
  return, new
endif else begin
; If not an array, do the simple case.
  temp = str

  new = create_struct(tn[index[0]], temp.([index[0]]))
  if n_elements(index) eq 1 then return, new

  for ii = 1, n_elements(index)-1 do begin
    new = create_struct(new, tn[[index[ii]]], temp.([index[ii]]))
  endfor  
    return, new
endelse

  return, 0
end
