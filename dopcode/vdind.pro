pro vdind,cf,vdname,ind,nik=nik, dsstpath=dsstpath
;This code finds the observations for which VD's have not been CRANKED
;   cf      INPUT  STRUCTURE
;   vdname  INPUT  STRING  eq.  'vdf4496'   'vdh509'  'vdg1614'
;   ind     OUTPUT ARRAY   integer array, indices of CF that have not been analyzed
;
;Created December 23, 1995  R.P.B.
; Sped up June 6, 2009 JohnJohn. New version is 10x faster

nel = n_elements(cf)
rdsi, ob, cf[0].obnm, filter, fdsk;, nik=nik
vdfiles = fdsk+vdname+'_'+cf.obnm
spawn, 'ls '+fdsk+vdname+'_*', ondisk
if ondisk[0] eq '' then begin
    ind = indgen(nel)
    return
endif else begin
    restore, ondisk[0]
    ;;; remove second conditional below for new run
    if vd[0].spst ne dsstpath and vd[0].spst ne '?' then begin
      ;;; DSST PATH used for reduction is stored in SPST field of VD files
      ;;; Check this against the input DSSTPATH, if they don't match then
      ;;; re-reduce with latest DST and overwrite all VD files
        print, '!!!!!!!!!!!!!'
        print, 'Newer DSST found. Overwriting all previous VD files.'
        print, '  or mismatch between vd.spst and dsstpath'
        print, '!!!!!!!!!!!!!'
        ind = indgen(nel)
        return
    endif else begin
        match, vdfiles, ondisk, a, b, count=count
        if count eq nel then ind = -1 else begin
            ind = where(1-histogram(a, bin=1, min=0, max=nel-1), nw)
        endelse
    endelse
endelse

end



