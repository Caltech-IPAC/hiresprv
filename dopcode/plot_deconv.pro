pro plot_deconv, dspec, spec, diffin, truespec=truespec, psf=psf $
                 , second_derivative=sd
wset, 30
;sd=1
first=0
if keyword_set(sd) then begin
    title = 'Second Derivative of line'
    dd = second_derivative(dspec, first=first)
    if keyword_set(first) then yr = [-1,1] else yr=[-0.6, 1]
    plot, dd, yr=yr*max(dd)*1.1, title=title,/ys
    oplot, second_derivative(spec, first=first), co=!red
    goto, skip
endif
plot, spec+0.2, yr=[-0.3, 1.6], /ys, ps=8, syms=0.4
oplot, dspec, co=!green, ps=-8, syms=0.4
if keyword_set(truespec) then begin
    sh = ccpeak(spec, truespec)
    ts = shift_interp(truespec, -sh)
    oplot, ts, ps=8, syms=0.4
    diff = dspec - ts
endif else diff = diffin
if keyword_set(psf) then begin
    r_conv, dspec, psf, a
    oplot, a+0.2, co=!red, ps=-8, syms=0.4
endif
if n_elements(diff) gt 0 then begin
    oplot, diff-0.15, ps=8, syms=0.4
;    xyouts, 50, 0.1, 'SNR = '+sigfig(1./stdev(diff), 3), chars=2
endif
skip:
wset, 0
device,copy = [0,0,1200,900,0,0,30]
;wait, 0.1
end
