; To produce sgl_rg.driver from sgl_rg.txt, just use
; fm_makedriver, 'sgl_rg'
; June 2014. This program was never tested on the doppler account.
;			when the outfile directory was changed to /o/doppler/  ; HTI

pro fm_makedriver, file, driver,infile=infile, outfile=outfile $
                   , unique=unique, logsheet=logsheet, struct=struct, all=all

; HTI 9/2017 It is not ovious that this program is used in the primary doppler code.
;stop
if keyword_set(all) then begin
    restore, '/mir3/keck_st.dat'
    struct = keck
endif

if keyword_set(struct) then begin
    ;;; e.g. keck_st.dat
    hd = struct.name
endif

if keyword_set(file) then begin
    infile = file+'.txt'
    outfile = file+'.driver'
endif

cond = keyword_set(infile) and 1-keyword_set(logsheet) 
cond = cond and 1-keyword_set(struct)
if cond then begin
    readcol, infile, hd, form='a'
    hd = str(hd)
endif
if keyword_set(logsheet) then begin
    readcol, logsheet, dum, hd, iod, form='i,a,a', /sil
    hd = strlowcase(hd)
    w = where(hd ne 'iodine' and $
              hd ne 'thar' and $
              hd ne 'th-ar' and $
              hd ne 'narrowflat' and $
              hd ne 'wideflat' and $
              hd ne 'dark' and $
              hd ne 'bias' and $
              hd ne 'focus' and $
              1-stregex(hd, 'hr', /fold, /bool), nw); and $
;              strlowcase(iod) eq 'y', nw)
    hd = hd[w]
    unique = 1
endif

if keyword_set(unique) then begin
    u = uniq(hd, sort(hd))
    hd = hd[u]
endif
nh = n_elements(hd)
driver = replicate({done:0b, busy:0b, name:''}, nh)
driver.name = hd
;if 1-keyword_set(outfile) then outfile='/o/johnjohn/morph/fm_driver.dat'
if 1-keyword_set(outfile) then outfile='/o/doppler/morph/fm_driver.dat'
save, driver, file=outfile
end
