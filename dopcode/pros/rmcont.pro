function rmcont,spec,nmode=nmode,contfunction=contfunction,cf=cf
if keyword_set(contfunction) then begin
    contf,spec,cf,nord=nmode,sbin=22
    specnew = spec/cf
endif else begin
    if not keyword_set(nmode) then nmode = 3
    spectemp = spec/median(spec)
    nel = n_elements(spec)
    fs = fft(shift(spectemp,nel/2),/double)
    window = fltarr(nel)+1.
    fourier_modify,window,0,indgen(nmode)+1
    specnew = float(shift(fft(fs*window,/inverse,/double),nel/2))
endelse
return,specnew
end
