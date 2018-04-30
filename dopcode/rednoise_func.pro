function rednoise_func, p
common rnfunc, tresid
return, -waveletlike(tresid, p[0], p[1], /zeropad)
end
