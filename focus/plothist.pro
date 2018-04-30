PRO plothist, arr, xhist,yhist, BIN=bin, overplot=overplot, peak=peak,$
        noplot=noplot,nodata=nodata,Fill=Fill, FCOLOR=Fcolor, FLINE=FLINE, $
        FSPACING=Fspacing, FPATTERN=Fpattern, FORIENTATION=Forientation, $
	BACKGROUND=back, CHANNEL=chan, CHARSIZE=chsiz, $
	CHARTHICK=chthck, COLOR=color, 	FONT=font, LINESTYLE=linest, $
	SUBTITLE=subtit, SYMSIZ=symsiz, THICK=thick, TICKLEN=ticklen, $
	TITLE=title, XCHARSIZE=xchsiz, XMARGIN=xmargn, XMINOR=xminor, $
	XRANGE=xrange, XSTYLE=xstyle, XTICKLEN=xtickln, XTICKNAME=xticknm, $
	XTICKS=xticks, XTICKV=xtickv, XTITLE=xtitle, XTYPE=xtype, $
	YCHARSIZE=ychsiz, YMARGIN=ymargn, YMINOR=yminor, $
	YRANGE=yrange, YSTYLE=ystyle, YTICKLEN=ytickln, YTICKNAME=yticknm, $
	YTICKS=yticks, YTICKV=ytickv, YTITLE=ytitle, YTYPE=ytype
;+
; NAME:
;   PLOTHIST
; PURPOSE:
;    Plot the histogram of an array with the corresponding abcissa.
; CALLING SEQUENCE:
;    plothist, arr, xhist, yhist, [, BIN=bin,   ... plotting keywords]
; INPUTS:
;    arr - The array to plot the histogram of.   It can include negative
;	     values, but non-integral values will be truncated.              
; OPTIONAL OUTPUTS:
;    xhist - X vector used in making the plot  
;               ( = indgen( N_elements(h)) * bin + min(arr) )
;    yhist - Y vector used in making the plot  (= histogram(arr/bin))
; OPTIONAL INPUT KEYWORDS:
;    BIN -  The size of each bin of the histogram,  scalar (not necessarily
;           integral).  If not present (or zero), the bin size is set to 1.
;
;           Any input keyword that can be supplied to the PLOT procedure
;           can also be supplied to PLOTHIST.
;      OVERPLOT - If set, will overplot the data on the current plot.  User
;            must take care that only keywords valid for OPLOT are used.
;      PEAK - if non-zero, then the entire histogram is normalized to have
;             a maximum value equal to the value in PEAK.  If PEAK is
;             negative, the histogram is inverted.
;      FILL - if set, will plot a filled (rather than line) histogram.
;
; The following keywords take effect only if the FILL keyword is set:
;      FCOLOR - color to use for filling the histogram
;      FLINE - if set, will use lines rather than solid color for fill (see
;              the LINE_FILL keyword in the POLYFILL routine)
;      FORIENTATION - angle of lines for fill (see the ORIENTATION keyword
;              in the POLYFILL routine)
;      FPATTERN - the pattern to use for the fill (see the PATTERN keyword
;              in the POLYFILL routine)
;      FSPACING - the spacing of the lines to use in the fill (see the SPACING
;              keyword in the POLYFILL routine)
; EXAMPLE:
;     Create a vector of 1000 values derived from a gaussian of mean 0,
;      and sigma of 1.    Plot the histogram of these value with a bin
;      size of 0.1
;
;      IDL> a = randomn(seed,1000)
;      IDL> plothist,a, bin = 0.1

; To make diagonal lines, ala Fischer:
; plothist, array, /fill,/fline,forientation=45 

; MODIFICATION HISTORY:
;	Written     W. Landsman            January, 1991
;  modified by D. Fischer to put the bins in the right place.
;-
;			Check parameters.
On_error,2

if N_params() LT 1 then begin   
	print, 'Syntax - plothist, arr, [ xhist, yhist , BIN=bin]'
	return
endif

if N_elements( arr ) LT 2 then message, $
      'ERROR - Input array must contain at least 2 elements'
arrmin = min( arr, MAX = arrmax)
if ( arrmin EQ arrmax ) then message, $
       'ERROR - Input array must contain distinct values'
;
if not keyword_set(BIN) then bin = 1. else bin = float(abs(bin))
;
;			Compute the histogram and abcissa.
;
y = fix( ( arr / bin) - (arr LT 0) ) 
yhist = histogram( y )
if keyword_set(Peak) then yhist = yhist * (Peak / float(max(yhist)))

N_hist = N_elements( yhist )
xhist = lindgen( N_hist ) * bin + min(y*bin) + bin/2.

if keyword_set(noplot) then return
if keyword_set(nodata) then return
if not keyword_set(PSYM) then psym = 10         ;Default histogram plotting

plot_keywords, $ 
	BACKGROUND=back, CHANNEL=chan, CHARSIZE=chsiz, $
	CHARTHICK=chthck, COLOR=color, 	FONT=font, LINESTYLE=linest, $
	SUBTITLE=subtit, SYMSIZ=symsiz, THICK=thick, TICKLEN=ticklen, $
	TITLE=title, XCHARSIZE=xchsiz, XMARGIN=xmargn, XMINOR=xminor, $
	XSTYLE=xstyle, XTICKLEN=xtickln, XTICKNAME=xticknm, $
	XTICKS=xticks, XTICKV=xtickv, XTITLE=xtitle, XTYPE=xtype, $
	YCHARSIZE=ychsiz, YMARGIN=ymargn, YMINOR=yminor, $
	YRANGE=yrange, YSTYLE=ystyle, YTICKLEN=ytickln, YTICKNAME=yticknm, $
	YTICKS=yticks, YTICKV=ytickv, YTITLE=ytitle, YTYPE=ytype


if not keyword_set(XRANGE) then xrange = [ xhist(0) ,xhist(N_hist-1) ]
;stop
;if not keyword_set(XRANGE) then begin
;xrange = [ xhist(0) ,xhist(N_hist-1) ]
;end else begin
;xrange = [ xhist(0) ,xhist(N_hist-2)-bin/2 ]
;end


 if keyword_set(overplot) then begin
     oplot, [xhist[0] - bin, xhist, xhist[n_hist-1]+ bin] , [0,yhist,0],  $ 
        PSYM = psym, _EXTRA = _extra 
 endif else begin
     plot, [xhist(0) - bin, xhist, xhist(n_hist-1)+ bin] , [0,yhist,0],  $ 
        PSYM = psym, $ 
	BACKGROUND=back, CHANNEL=chan, CHARSIZE=chsiz, $
	CHARTHICK=chthck, COLOR=color, 	FONT=font, LINESTYLE=linest, $
	SUBTITLE=subtit, SYMSIZ=symsiz, THICK=thick, TICKLEN=ticklen, $
	TITLE=title, XCHARSIZE=xchsiz, XMARGIN=xmargn, XMINOR=xminor, $
	XRANGE=xrange, XSTYLE=xstyle, XTICKLEN=xtickln, XTICKNAME=xticknm, $
	XTICKS=xticks, XTICKV=xtickv, XTITLE=xtitle, XTYPE=xtype, $
	YCHARSIZE=ychsiz, YMARGIN=ymargn, YMINOR=yminor, $
	YRANGE=yrange, YSTYLE=ystyle, YTICKLEN=ytickln, YTICKNAME=yticknm, $
	YTICKS=yticks, YTICKV=ytickv, YTITLE=ytitle, YTYPE=ytype
  endelse

 if keyword_set(Fill) then begin
    Xfill = transpose([[Xhist-bin/2.0],[Xhist+bin/2.0]])
    Xfill = reform(Xfill, n_elements(Xfill))
;stop
    Xfill = [Xfill[0], Xfill, Xfill[n_elements(Xfill)-1]]
    Yfill = transpose([[Yhist],[Yhist]])
    Yfill = reform(Yfill, n_elements(Yfill))
    Yfill = [0, Yfill, 0]

xr=xrange
i=where(xfill gt xr(1),nbig)
if nbig ge 1 then begin
    i=where(xfill le xr(1))
    xfill = xfill(i)
    yfill = yfill(i)
end


    if keyword_set(Fcolor) then Fc = Fcolor else Fc = !P.Color
    if keyword_set(Fline) then begin
       if keyword_set(Fspacing) then Fs = Fspacing else Fs = 0
       if keyword_set(Forientation) then Fo = Forientation else Fo = 0
       polyfill, Xfill,Yfill, color=Fc, /line_fill, spacing=Fs, orient=Fo
    endif else begin
       if keyword_set(Fpattern) then begin
          polyfill, Xfill,Yfill, color=Fc, pattern=Fpattern
       endif else begin
          polyfill, Xfill,Yfill, color=Fc
       endelse
    endelse

;   Because the POLYFILL can erase/overwrite parts of the originally plotted
;   histogram, we need to replot it here.
;
    oplot, [xhist[0] - bin, xhist, xhist[n_hist-1]+ bin] , [0,yhist,0],  $ 
       PSYM = psym, _EXTRA = _extra
 endif


return
end
