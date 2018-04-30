function second_derivative, func, first=first
dfunc = func - shift(func, 1)
if keyword_set(first) then return, dfunc
return, dfunc - shift(dfunc,1)
end
