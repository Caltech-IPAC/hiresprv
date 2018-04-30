function gettharinfo, body

; Given the body of a logsheet, output FLATTEXT, which is the text
; which goes into part 7. of the reduction batchfile.
; OLD: Keyword for "eevred", not cosred.
; IN Jason's (cosred) code, TH/AR and Iodine are counted together, in older
; code, only Th/Ar go into this category.

iodlist = $
   ['IODINE','I','I2','IOD','NARROW_FLAT','NARROWFLAT','IODINED5','IFLAT']
thorlist = $
['th-ar','TH-AR','TH_AR','THAR','TH/AR','THORIUM','THORIUM-ARGON','THNE','TH-NE','FOCUS']
noskylist = [iodlist,thorlist] ; don't need a sky subtraction

nums = getwrds(body,0)
targets = getwrds(body,1)

wfind = [-1]
N = n_elements(body)
for i = 0, N-1 do  begin
    if memberof(noskylist,strupcase(targets(i))) then wfind=[wfind,nums(i)]
endfor

if n_elements(wfind) gt 1 then behead,wfind
numtext = strchop(deparse(strtrim(wfind,2)+','),-1)
thtext= "threc = ["+numtext+"]"

return,thtext
end

