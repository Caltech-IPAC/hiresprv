pro velprint, cfin, outfile=outfile, obnm=obnm, ra=ra, dec=dec, fulljd=fulljd
cf = cfin
if n_elements(ra) gt 0 and n_elements(dec) gt 0 then begin
    cf.jd = helio_jd(cf.jd+4d4, ra, dec)-4d4
endif
if keyword_set(fulljd) then cf.jd += 2.44d6
if keyword_set(obnm) then begin
    form = '(a10,2x,f17.6,2(2x,f10.4))'
    forp, cf.obnm, cf.jd, cf.mnvel, cf.errvel, form=form, outfile=outfile
endif else begin
    form = '(f17.6,2(2x,f10.4))'
    forp, cf.jd, cf.mnvel, cf.errvel, form=form, outfile=outfile
endelse
end
