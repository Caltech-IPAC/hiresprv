function rel, tau

  x = cosh(tau)-1
  t = sinh(tau)
  v = tanh(tau)

  return, [t, x, v]
end
