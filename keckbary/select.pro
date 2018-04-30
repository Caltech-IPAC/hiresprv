function select,selector,item
;This function checks if the input ITEM is contained in the 
;array SELECTOR.  		ECW	10-15-93

dum=where(strpos(selector,item),cnt)
found=cnt ne n_elements(selector)

return, found
end
