pro diag, units, text, prefix=prefix, stop=stop, retall=retall
;
;Print a multi-line diagnostic message to the specifed file units.
;
;Mandatory Inputs:
;
; units (scalar or vector integer) list of logical file units where text
;   will be written. unit -1 is standard output. unit -2 is standard error.
;   unit -3 suppresses output.
;
; text (scalar or vector string) lines of text that will be written to units.
;
;Optional Inputs:
;
; [prefix=] (string) prefix to write before each line of text. if prefix is
;   not specifed, then is set to '<routine_name>@<line_number>: '
;
; [/stop] (switch) causes program control to halt in the calling routine
;   after witing the specified text.
;
; [/retall] (switch) causes program control to return to the top level after
;   the specified text is written.
;
;History:
;
; 2008-Feb-29 Valenti  Coded initial version.

;Check syntax.
  if n_params() lt 2 then begin
    print, 'syntax: diag, units, text [,prefix= ,/stop ,/retall]'
    print, "  e.g.: diag, [-1,unit], pre='', 'file not found', /ret"
    return
  endif

;Verify that unit is specified.
  nunit = n_elements(units)
  if nunit eq 0 then message, 'output unit(s) not defined'

;Exit without printing output, if units has flag value of -3.
  if nunit eq 1 and units[0] eq -3 then return

;Get traceback information, if needed.
  if n_elements(prefix) eq 0 or keyword_set(return) then begin
;
;   callstack = scope_traceback(/struct)		;does not compile...
;   caller = callstack[n_elements(callstack)-2]		;...for version < 6.2
;
    help, /trace, output=help_trace
    words = strsplit(help_trace[1], /extract)
    if n_elements(words) eq 2 then begin
      caller = { routine: words[1], line: -1 }
    endif else begin
      caller = { routine: words[1], line: long(words[2]) }
    endelse
  endif

;If prefix is not specified, set prefix to the name of the calling routine.
  if n_elements(prefix) eq 0 then begin
    if caller.routine eq '$MAIN$' then begin
      prefix = 'main'
    endif else begin
      prefix = strlowcase(caller.routine) + '@' + strtrim(caller.line, 2)
    endelse
    prefix = prefix + ': '
  endif

;Loop through lines of output text, printing to every specified unit.
  ntext = n_elements(text)
  for itext=0, ntext-1 do begin
    for iunit=0, nunit-1 do begin
      printf, units[iunit], prefix + text[itext]
    endfor
  endfor

;Stop execution in calling routine, if requested.
  if keyword_set(stop) then begin
    on_error, 2					;return to caller on error
    message, /noname, /noprefix, ''
  endif

;Break to top level context, if requested.
  if keyword_set(retall) then retall

end
