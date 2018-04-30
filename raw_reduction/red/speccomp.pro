pro specomp, spec1, spec2

  n1 = 'reduced/rk39.200'
  n2 = '../reduced/rk39.200'

  rdsk, spec1, n1, 1
  rdsk, spec2, n2, 1

  plot, spec2/spec1 

end
