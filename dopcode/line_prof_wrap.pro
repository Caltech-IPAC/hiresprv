function line_prof_wrap, a, prof=prof, y=y, x=x
fit = line_prof(x, a, prof)
return, y-fit
end
