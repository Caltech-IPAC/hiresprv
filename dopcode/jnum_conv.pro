pro jnum_conv,spec,inst,nsp,sm_end=sm_end,ip,zmom=zmom, bad=bad
ip = inst                         ;Normalize for trim below .001
indx = where(abs(ip) gt 0.001*max(ip),n_indx) ;Use only non-zero INST, incl (-)
if n_indx eq 0 then begin
    bad = 1
    return
endif else bad = 0

ip = double(reverse(ip))

nsp = convol(spec, ip, total(ip),/edge_wrap)
end



