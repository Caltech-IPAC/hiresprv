pro run_all_bstars
;purpose: Find Bstars that are on the 'Good Bstar list' and
;		pass tests like: they have iodine, not too many counts (or too few)
;		typical vdiod name: vdiod708_rj194.137.ad  ; note: no HR

; This program is not a required part of the doppler code. 

files = getenv("DOP_FILES_DIR")
kb_file = getenv("DOP_BARYFILE_STRUC")
restore,kb_file
kb = bcat[where(strmid(bcat.obsnm,0,2) eq 'rj' and bcat.obtype eq 'o' $
					and strmid(bcat.objnm,0,2) eq 'HR',nbstarobs)] 
				;[3905],through j194
	; j runs only and iodine only

tagname='ae'
										
;kb = kb[where(kb.jd gt 15838,nbstarobs)] ; quicker
kb = kb[where(kb.jd gt 16708,nbstarobs)] ;

fn_vdiod = strarr(nbstarobs)
for i=0,nbstarobs-1 do begin

	;Check if the vdiod is already run
	exist = file_search(files+'vdiod*'+kb[i].obsnm+'.'+tagname,count=num)
	if num eq 0 then begin
		make_vdiod,kb[i].obsnm , tag=tagname,/noprint,/keck2
  	endif
endfor

print,'All Bstars with tag: '+tagname+ ' are now complete'






end ; program