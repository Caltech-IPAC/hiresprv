function convert_dsst, dsst, sdstwav, sdst
new = dsst
nchunk = n_elements(new)
for i = 0, nchunk-1 do begin
    counter, i, nchunk
    wls = dwav(new[i])
    new[i].dst = dspline(sdstwav, sdst, wls)
endfor
return, new
end
