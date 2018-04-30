function find_offset, obnm, ref, plot=plot
rdsi, r, ref
rdsi, s, obnm

start = 6
finish = 17
nord = finish-start+1
offset = fltarr(nord)
range = fillarr(1, 1000, 3000)
for i = start, finish do begin
    ind = i - start
    rspec = rmcont(r[range, i])
    sspec = rmcont(s[range, i])
    offset[ind] = ccpeak(sspec, rspec, 200, ccf=ccf)
    if keyword_set(plot) then begin
        plot, ccf, title='Order: '+str(i)
        cursor, x0, y0, /up
        if x0 lt !x.crange[0] then stop
    endif
endfor
x = fillarr(1, start, finish)
a = robust_poly_fit(x, offset, 1)
return, a
end
