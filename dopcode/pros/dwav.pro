function dwav, dsst
ndst = n_elements(dsst.dst)
w = poly(findgen(ndst), [dsst.w0, dsst.w1])
return, w
end
