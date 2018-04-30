function velbin, cf
d = cf.jd - floor(min(cf.jd))
v = cf.mnvel
err = cf.errvel

dhist = histogram(d, bin=1./12, min=min(d), rev=ri)
u = where(dhist gt 0, nhist)
vel = replicate({d:0d, v:0d, e:0d}, nhist)
for j = 0, nhist-1 do begin
    i = u[j]
    lo = ri[ri[i]]
    hi = ri[ri[i+1]-1]
    wt = 1./err[lo:hi]^2
    normwt = wt/total(wt)
    vave = total(v[lo:hi] * normwt)
    dave = total(d[lo:hi] * normwt)
    eave = sqrt(1./total(1./err[lo:hi]^2))
    vel[j].d = dave
    vel[j].v = vave
    vel[j].e = eave
endfor
return, vel
end
