pro trace,level,text
;Routine that prints text to screen, if trace level is less than or equal
;  to global variable ham_trace.
; level (input scalar) indicates significance of text; 0 is most significant,
;   5 less so, and so on up to about 25.
; text (input string) text to be printed out if level is low enough.
;18-Apr-92 JAV	Updated global variable list/interpretations. Gutted all
;		 toggle logic, which now is handled by hamset.pro.

@ham.common					;get common block definition

if n_params() lt 2 then begin
  print,'syntax: trace,level,text'
  retall
endif

  hamset,/silent				;ensure hm_trace defined
  if level le ham_trace then print,'% ',text	;that's all there is to it

end
