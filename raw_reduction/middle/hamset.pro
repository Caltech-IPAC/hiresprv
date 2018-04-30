pro hamset,trace=trace,image=image,dord=dord,id=id,xwid=xwid, $
           bg = bg, bin = bin, silent = silent, $
           cosmic_sig = cosmic_sig, pbg = pbg, gain = gain
;Tool for setting Hamilton reduction package's global variables.
;  Sets unset globals to their default value unless specified by keyword.
;  Sets global variables to values specified by keywords.
;  Prints values and meanings of global variables unless called with /silent.
;See below for meanings of global variable keywords.
;See comments in file ham.common for instructions on adding a global variable.
;18-Apr-92 JAV Create.
;21-Apr-92 JAV Add "spike" global and "silent" flag.
;06-May-92 JAV Add "obase" global.
;10-Jun-92 ECW Add "clip" global.  /clip will result in the clipping base col.
;27-feb-95 GWM skywid and skyedg added for Keck sky subtraction
;22-feb-01 JTW added skywid keyword and made xwid default to
;          "optimally" determined value, making skywid and skyedg obsolete

@ham.common		;get common block definition

;Define default values for global variables.
  dtrace = 15		;trace level: 0=minimal, 5,10,15,20,25 for more info
  dimage = 0		;image type: 0=fits, 1=rdsk/wdsk format
  ddord = 2		;1=Use Default Order locations, 0=Use star image to get orders
                        ;2=Use SHIFTED Default Order Locations to match observed
  did = 10		;chip id (for mask): 1,2,6,8,13 have masks, others don't
                        ;chip 29 refers to Keck HIRES
                        ;if id=29, sky subtraction is done.
			;chip 13 has 3 incarnations from Berkeley.(13,13.3,13.4)
  dxwid = 0.		;default to optimal extraction width
                        ;xwid > 1 means it will extract that width in pixels

  dbg = 0                ;background: 0=troughs only, 1=2.5" decker correction
                         ;if id=29, sky subtraction is done.
			 
  dbin = 1		;pixel binning: 1=1x1, 2=2x2
  dcosmic_sig = 3.       ;cosmic ray rejection threshold
  dpbg = 0.           ;background noise in counts 
;  dgain = 4.76          ;gain of HIRES
;  dgain = 1.2          ;gain of HIRES mosaic, chip #2 - green
  dgain = 2.          ;gain of HIRES mosaic, chip #2 - green

;Set global variables to default values, if they are undefined upon entry.
  if n_elements(ham_trace) eq 0 then ham_trace = dtrace
  if n_elements(ham_image) eq 0 then ham_image = dimage
  if n_elements(ham_dord) eq 0 then ham_dord = ddord
  if n_elements(ham_id) eq 0 then ham_id = did
  if n_elements(ham_xwid) eq 0 then ham_xwid = dxwid
  if n_elements(ham_bg) eq 0 then ham_bg = dbg

  if n_elements(ham_bin) eq 0 then ham_bin = dbin
  if n_elements(ham_cosmic_sig) eq 0 then ham_cosmic_sig = dcosmic_sig
  if n_elements(ham_pbg) eq 0 then ham_pbg = dpbg
  if n_elements(ham_gain) eq 0 then ham_gain = dgain

;Set global variables to new values specified by keyword arguments.
  if n_elements(trace) gt 0 then ham_trace = trace
  if n_elements(image) gt 0 then ham_image = image
  if n_elements(dord)  gt 0 then ham_dord = dord 
  if n_elements(id) gt 0 then ham_id = id
  if n_elements(xwid) gt 0 then ham_xwid = xwid
  if n_elements(bg) gt 0 then ham_bg = bg
  if n_elements(bin) gt 0 then ham_bin = bin
  if n_elements(cosmic_sig) gt 0 then ham_cosmic_sig=cosmic_sig
  if n_elements(pbg) gt 0 then ham_pbg = pbg
  if n_elements(gain) gt 0 then ham_gain = gain

;Print values and meanings of global variables, unless /silent set.
  if not keyword_set(silent) then begin
    message,/info,'keyword=value (default) description.'
    message,/info,'trace=' + strtrim(string(ham_trace),2) $
	+ ' (' + strtrim(string(dtrace),2) $
 	+ ') trace level: 0=minimal, 5,10,15,20,25 for more info.'
    message,/info,'image=' + strtrim(string(ham_image),2) $
	+ ' (' + strtrim(string(dimage),2) $
 	+ ') image format: 0=fits, 1=wdsk/rdsk format.'
    message,/info,'dord=' + strtrim(string(ham_dord),2) $
	+ ' (' + strtrim(string(ddord),2) $
 	+ ') force use of default order locations: 0=false, 1=true, 2=true+shifted.'
    message,/info,'id=' + strtrim(string(ham_id),2) $
	+ ' (' + strtrim(string(did),2) $
 	+ ') dewar id [for mask]: 1,2,6,8,13 have masks, others don''t.'
    message,/info,'xwid=' + strtrim(string(ham_xwid,form='(f9.3)'),2) $
	+ ' (' + strtrim(string(dxwid,form='(f9.3)'),2) $
 	+ ') order extraction fractional width: 0.0="optimal."'
    message,/info,'bin=' + strtrim(string(ham_bin),2) $
	+ ' (' + strtrim(string(dbin),2) $
 	+ ') pixel binning: 1=no binning, 2=2x2 binning.'
    message,/info,'cosmic_sig=' + strtrim(string(ham_cosmic_sig),2) $
	+ ' (' + strtrim(string(dcosmic_sig),2) $
 	+ ') sigma above background'
    message,/info,'pbg=' + strtrim(string(ham_pbg),2) $
	+ ' (' + strtrim(string(dpbg),2) $
 	+ ') counts of background noise'
    message,/info,'gain=' + strtrim(string(ham_gain),2) $
	+ ' (' + strtrim(string(dgain),2)+ ')'
  endif
end
