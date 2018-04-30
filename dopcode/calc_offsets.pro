pro calc_offsets

nobs_min_pre     = 8
nobs_min_post    = 8
nobs_yr_min_pre  = 4
nobs_yr_min_post = 3
rms_max_pre      = 4.5
rms_max_post     = 4.5
rms_max_tot      = 50.
jitter=2.0
prepost=13237.  ;pre/post Julian Date

keck_st = getenv("DOP_KECK_STRUC") ; get keck structure
rv_outdir = getenv("DOP_RV_OUTDIR")

restore,keck_st
kbc = get_kbcvel()               ; get kbcvel structure
 
i = where(keck.par lt 0.005, n)
if n ge 1 then keck[i].par =  0.001    ;Eliminate zeros in parallax
stars = where(1/keck.par lt 2500.)  ; get keck indices

; exclude stars with better Keplerian fits
stars = stars[where(stars ne (where(keck.name eq '213042'))[0])]
if not keyword_set(doslope) then begin
    stars = stars[where(stars ne (where(keck.name eq '179957'))[0])]
endif

keck_ind  = [0]
nobs_pre  = [0]
nobs_post = [0]
rms_pre   = [0.]
rms_post  = [0.]
offsets   = [0.]
gammas    = [0.]
dvdts     = [0.]
rms       = [0.]
rms_corr  = [0.]
counts    = [0.]
offsets_fix = [0.]

for i=0,n_elements(stars)-1 do begin
    vst_file = rv_outdir+'vst'+keck[stars[i]].name+'.dat' 
    if (file_search(vst_file))[0] ne '' then begin
        ; load vst
        restore,vst_file
        
        ; bin data
        timebin, cf3.jd, cf3.mnvel, cf3.errvel, 12./24., t, v, s
        timebin, cf3.jd, cf3.mnvel, cf3.errvel, 365.*0.66, t_yr, v_yr, s_yr
        
        ; add jitter
        s = sqrt(s^2 + jitter^2)
    
        ; calculate pre/post velocity rms
        if (    n_elements(where(t le prepost))    ge nobs_min_pre     $
            and n_elements(where(t ge prepost))    ge nobs_min_post    $
            and n_elements(where(t_yr le prepost)) ge nobs_yr_min_pre  $
            and n_elements(where(t_yr ge prepost)) ge nobs_yr_min_post $
           ) then begin
            cf_pre  = cf3[where(cf3.jd le prepost)]
            cf_post = cf3[where(cf3.jd gt prepost)]
            v_pre  = v[where(t le prepost)]
            v_post = v[where(t gt prepost)]
            if (    (stddev(v_pre)  le rms_max_pre)  $
                and (stddev(v_post) le rms_max_post) $
                and (stddev(v)      le rms_max_tot)  ) then begin
    
                t0 = median(t)
                group = t*0
                for j=0,n_elements(t)-1 do if t[j] gt prepost then group[j] = 1
            
                offset_solver,t,v,s,group,t0, gamma, dvdt, offset, vout, /doslope
                
                ct = cf_pre.cts
                n_ct = n_elements(ct)
        
                keck_ind  = [keck_ind,  stars[i]]
                nobs_pre  = [nobs_pre,  n_elements(cf_pre)] 
                nobs_post = [nobs_post, n_elements(cf_post)]
                rms_pre   = [rms_pre,   stddev(cf_pre.mnvel)]
                rms_post  = [rms_post,  stddev(cf_post.mnvel)]
                offsets   = [offsets,   offset]        ; offsets are post-pre
                gammas    = [gammas,    gamma]
                dvdts     = [dvdts,     dvdt]
                rms       = [rms,       stddev(v)]     ; rms before correction
                rms_corr  = [rms_corr,  stddev(vout)]  ; rms after correction
                counts    = [counts,    (ct[sort(ct)])[floor(n_ct*0.8 )] ]  ; 80th %ile of counts
                offsets_fix = [offsets_fix, offset_corr(cf3)]

                print, keck[stars[i]].name, '  ' $
                     , keck[stars[i]].sptype+keck[stars[i]].spclass  $
                     , n_elements(cf_pre) $
                     , n_elements(cf_post) $
                     , offset $
                     , gamma $
                     , dvdt*365. $
                     , stddev(v) $
                     , stddev(vout)
                
            endif
        endif
    endif
endfor

n = n_elements(keck_ind)-1
keck_ind  = keck_ind[1:n-1]
nobs_pre  = nobs_pre[1:n-1] 
nobs_post = nobs_post[1:n-1]
rms_pre   = rms_pre[1:n-1]
rms_post  = rms_post[1:n-1]
offsets   = offsets[1:n-1]
gammas    = gammas[1:n-1]
dvdts     = dvdts[1:n-1]
rms       = rms[1:n-1]
rms_corr  = rms_corr[1:n-1]
counts    = counts[1:n-1]
offsets_fix = offsets_fix[1:n-1]
n = n_elements(keck_ind)

; find correction to counts:
ind = where(offsets le 5.)
coeff = poly_fit(counts[ind],offsets[ind],2)
coeff = [ 1.8375474, -3.5136251e-05, 2.0292513e-10 ]
predicted_offset = poly(counts,coeff)

; plot results
bv_arr = keck[keck_ind].bv
mv_arr = keck[keck_ind].mv
plot,keck[keck_ind].bv, keck[keck_ind].mv, ps=8, yr=[14,3], xtitle='B-V', ytitle='Mv', /nodata
color_arr = 20 + 200 * (offsets+5.)/10.
for i=0,n-1 do color_arr[i] = min( [max([color_arr[i],20.]), 220.])
for i=0,n-1 do oplot, [bv_arr[i]], [mv_arr[i]], ps=8, col=color_arr[i]

; 2nd plot
!p.multi=[0,2,2]
!x.thick=1.
!y.thick=1.
!p.thick=2
!x.charsize=1.0
!y.charsize=1.0
!p.charsize=1.5
!p.charthick=1.5

plot,keck[keck_ind].mv, offsets, ps=8, xtitle='!6 Mv', ytitle='!6 offset [m/s]  (post-pre)'
!p.linestyle=1
;hline,5
;hline,-5
!p.linestyle=2
hline,0
!p.linestyle=6
hline,median(offsets),color=220, thickness=1.
!p.linestyle=0

plot,keck[keck_ind].bv, offsets, ps=8, xtitle='!6 B-V', ytitle='!6 offset [m/s]  (post-pre)'
!p.linestyle=1
;hline,5
;hline,-5
!p.linestyle=2
hline,0
!p.linestyle=6
hline,median(offsets),color=220, thickness=1.
!p.linestyle=0

plot,keck[keck_ind].v, offsets, ps=8, xtitle='!6 V', ytitle='!6 offset [m/s]  (post-pre)'
!p.linestyle=1
;hline,5
;hline,-5
!p.linestyle=2
hline,0
!p.linestyle=6
hline,median(offsets),color=220, thickness=1.
!p.linestyle=0

xtit = textoidl('counts / 10^3  (80th percentile)') 
plot,counts/1000., offsets, ps=8, xtitle=xtit, ytitle='!6 offset [m/s]  (post-pre)'
oplot,findgen(250), poly(1000*findgen(250),coeff)
for i=0,n_elements(offsets)-1 do oplot, [counts[i]/1000.], [offsets[i]-offsets_fix[i]], ps=8, co=150
!p.linestyle=1
;hline,5
;hline,-5
!p.linestyle=2
hline,0
!p.linestyle=6
hline,median(offsets),color=220, thickness=1.
!p.linestyle=0

;stop

; 3rd plot
!p.multi=[0,1,2]
!x.thick=1.
!y.thick=1.
!p.thick=2
!x.charsize=1.0
!y.charsize=1.0
!p.charsize=1.5
!p.charthick=1.5

xtit = textoidl('counts / 10^3  (80th percentile)') 
plot,counts/1000., offsets, ps=8, xtitle=xtit, ytitle='!6 offset [m/s]  (post-pre)'
!p.linestyle=1
!p.linestyle=2
hline,0
!p.linestyle=6
hline,median(offsets),color=220, thickness=1.
!p.linestyle=0

plot,counts/1000., offsets-offsets_fix, ps=8, xtitle=xtit, ytitle='!6 corrected offset [m/s]  (post-pre)'
!p.linestyle=1
!p.linestyle=2
hline,0
!p.linestyle=6
hline,median(offsets),color=220, thickness=1.
!p.linestyle=0


print,'Median offset: ', str(median(offsets))
print,'Mean offset:   ', str(mean(offsets))
print
print,'Median corrected offset: ', str(median(offsets-offsets_fix))
print,'Mean corrected offset:   ', str(mean(offsets-offsets_fix))

; good examples of offsets: 28005

stop

end ; program
