function vartype,var
;Figure out which type a variable is
  types=['UNDEFINED','BYTE','INTEGER','LONGWORD INT','FLOAT','DOUBLE',  $
	'COMPLEX','STRING','STRUCTURE']
  s = size(var)				;not to be confused w/ n_elements)
  return,types(s(n_elements(s)-2))
end
