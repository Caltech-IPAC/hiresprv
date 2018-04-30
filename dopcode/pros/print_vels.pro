pro print_vels, cf

; print velocities and other quantities from a Keck cf3 structure
; Andrew Howard, 2009
; 
;         accepts a cf structure (e.g. cf3) or starname (e.g. '9407') as input

rv_outdir = getenv("DOP_RV_OUTDIR")
if datatype(cf) eq 'STR' then begin
    restore,rv_outdir+'vst' + cf + '.dat'
    cf = cf3
endif

caldat,cf.jd+2440000.,m,d,y
slash = '/'+strarr(n_elements(y))

format = '(A10, I7, A1, I02, A1, I02, F15.6, F9.2, F9.2, F8.3, I9)'

print,"************************************************************************"
print,"      obnm      UT date             jd    mnvel   errvel   mdchi      cts"
print,"************************************************************************"
forprint, cf.obnm, y,slash,m,slash,d, cf.jd, cf.mnvel, cf.errvel, cf.mdchi, cf.cts, format=format,textout=1

end 
