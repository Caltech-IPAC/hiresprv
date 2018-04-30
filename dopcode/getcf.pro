pro getcf, starin, cf3, kvel=kvel, lvel=lvel, keck=keck, plot=plot, grep=grep, print=print
star = strlowcase(starin)
cf3 = -1

rk_vel_dir = getenv("DOP_RK_VEL_DIR")
rv_out_dir = getenv("DOP_RV_OUTDIR")
planets_dir= getenv("DOP_PLANETS_DIR")
case 1 of 
    keyword_set(keck): file = rk_vel_dir+'vst'+str(star)+'.dat' ;fetches 'rk' obs
    keyword_set(kvel): file = rv_out_dir+'vst'+str(star)+'.dat'
    else: file = planets_dir+'vst'+str(star)+'.dat' ;
endcase
if check_file(file) then restore, file else return
if keyword_set(grep) then begin
    u = where(stregex(cf3.obnm, grep, /bool), nu)
    if nu gt 0 then cf3 = cf3[u]
endif
if keyword_set(plot) then velplot, cf3, 1./12, bincf=cf3
if keyword_set(print) then print, cf3.obnm
end
