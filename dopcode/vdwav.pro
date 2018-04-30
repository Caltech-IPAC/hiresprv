function vdwav, vd
if n_elements(vd) eq 1 then begin
    tags = tag_names(vd)
    dum = where(stregex(tags, 'npix', /bool, /fold), nn)
    if nn eq 0 then x = dindgen(n_elements(vd.wt)) else x = dindgen(vd.npix)
    dum = where(stregex(tags, 'wcof', /bool, /fold), nd)
    if nd gt 0 then begin
        wcof = [vd.w0+vd.wcof[0], vd.wcof[1:*]]
    endif else wcof = [vd.w0+vd.par[11], vd.par[13:14]]
    return, poly(x, wcof)
endif else message, 'VD must be a single element, not the full array!.'
end
