pro revank, sg, tag
nstar = n_elements(sg)
for i = 0, nstar-1 do begin
    testfile = '~/planets/cf'+sg[i].hd+'_'+tag+'.dat'
    if check_file(testfile) then begin
        jjvank, sg[i].hd, tag, /lick
    endif
endfor

end
