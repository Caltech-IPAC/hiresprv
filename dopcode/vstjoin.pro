function vstjoin, starin, cfk=cfk ; OBSOLETE FOR NEXSCI dopcode
star = strlowcase(starin)
getcf, star, cfjj
if 1-keyword_set(cfp) then getcf, star, cfp, /keck
cfp.mnvel += 100
u = where(stregex(cfp.obnm, 'rk', /bool), nu, comp=c)
j = where(stregex(cfjj.obnm, 'rj', /bool), nj)

if nu gt 1 and nj gt 1 then begin
    cfk = cfp[u]
    cfpost = cfp[c]
    cfknew = replicate(cfjj[0], nu)
    cfknew.bc = cfk.bc
    cfknew.mnvel = cfk.mnvel
    cfknew.mdvel = cfk.mdvel
    cfknew.mnpar = cfk.mnpar
    cfknew.mdpar = cfk.mdpar
    cfknew.obnm = cfk.obnm
    cfknew.iodnm = cfk.iodnm
    cfknew.z = cfk.z
    cfknew.jd = cfk.jd
    cfknew.dewar = cfk.dewar
    cfknew.gain = cfk.gain
    cfknew.cts = cfk.cts
    cfknew.med_all = cfk.med_all
    cfknew.errvel = cfk.errvel
    cfknew.mdchi = cfk.mdchi
    cfknew.nchunk = cfk.nchunk
    cfknew.sp1 = cfk.sp1
    cfknew.sp2 = cfk.sp2
    cfknew.psfpix = cfk.psfpix
    cfknew.psfsig = cfk.psfsig
    match, cfpost.obnm, cfjj.obnm, a, b
    if n_elements(a) gt 1 then begin
        diff = median(cfpost[a].mnvel - cfjj[b].mnvel)
    endif else diff = 100
    cfknew.mnvel -= diff
    cfall = [cfknew, cfjj[j]]
endif else return, cfjj

return, cfall
end
