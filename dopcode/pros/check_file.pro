function check_file,fname
spawn,'ls '+fname,result,err
;if strlen(err[0]) eq 0 then exists = 1b else exists = 0b
if result[0] ne '' then exists = 1b else exists = 0b
return,exists
end
