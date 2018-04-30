pro move_em, driver, tofile
if size(driver,/type) eq 7 then cmrestore, driver, driver
ns = n_elements(driver)
;pre = '/o/johnjohn/planets/vst'
pre = '/o/doppler/planets/vst' ; HTI 6/2014. Never tested
for i = 0, ns - 1 do begin
    file = pre+driver[i].hd+'.dat'
    spawn, 'sync '+file+' '+tofile
endfor
end
