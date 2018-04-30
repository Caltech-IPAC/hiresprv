function repstr,obj,in,out
;+
; NAME:
;    REPSTR
; PURPOSE:
;    String substitution as in many text editors.   Replace all
;    occurences of one substring by another.
; CALLING SEQUENCE:
;    result = repstr(obj,in,out)
; INPUT PARAMETERS:
;    obj    = object string for editing
;    in     = substring of 'obj' to be replaced
;    out    = what 'in' is replaced with
; OUTPUT PARAMETERS:
;    Result returned as function value.  Input object string
;    not changed unless assignment done in calling program.
; PROCEDURE:
;    Searches for 'in', splits 'obj' into 3 pieces, reassembles
;    with 'out' in place of 'in'.  Repeats until all cases done.
; EXAMPLE:
;    If a = 'I am what I am' then print,repstr(a,'am','was')
;    will give 'I was what I was'.
; MODIFICATION HISTORY:
;    Written by Robert S. Hill, ST Systems Corp., 12 April 1989.
;-
sz2 = size(out)
ne2 = n_elements(sz2)
if (sz2(ne2-2) eq 0) then out = ''
l1 = strlen(in)
l2 = strlen(out)
last_pos = 0
lo = 9999
pos = 0
object=obj
while (pos lt lo-l1) and (pos ge 0) do begin
   lo = strlen(object)
   pos = strpos(object,in,last_pos)
   if (pos ge 0) then begin
      first_part = strmid(object,0,pos)
      last_part  = strmid(object,pos+l1,9999)
      object = first_part + out + last_part
   endif
   last_pos = pos + l2
endwhile
return,object
end
