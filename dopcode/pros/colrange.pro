function colrange, data, range

if n_elements(range) eq 0 then begin
    mm = mm(data*1.)
endif else begin
    mm = mm(range)
endelse
newd = (data-mm[0])/(mm[1]-mm[0])
cols = long(!red*newd)+(!red+!green+1)*long(!red*(1-newd))+(!red+1)*long(!red*(1-2*abs(newd-0.5)))
return, cols

end
