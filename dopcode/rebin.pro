Pro Rebin,Wold,Sold,Wnew,Snew
;Interpolates OR integrates a spectrum onto a new wavelength scale, depending
;  on whether number of pixels per angstrom increases or decreases. Integration
;  is effectively done analytically under a cubic spline fit to old spectrum. 
; Wold (input vector) old wavelngth scale.
; Sold (input vector) old spectrum to be binned.
; Wnew (input vector) new wavelength spectrum.
; Snew (output vector) newly binned spectrum.
;Edit History:
; 10-Oct-90 JAV Create.
; 22-Sep-91 JAV Translated from IDL to ANA.
; 27-Aug-93 JAV Fixed bug in endpoint check: the "or" was essentially an "and".
; 26-Aug-94 JAV	Made endpoint check less restrictive so that identical old and
;		new endpoints are now allowed. Switched to new Solaris library
;		in call_external.
; Nov01 DAF eliminated call_external code; now use internal idl fspline
on_error, 2
If N_Params() lt 4 Then Begin
  Message,/Info,'Syntax: Rebin,Wold,Sold,Wnew,Snew'
  RetAll
EndIf

;Program flags.
  Trace = 0					;(0)1: (don't) print trace info

;Determine spectrum attributes.
  Nold = Long(N_Elements(Wold))			;number of old points
  Nnew = Long(N_Elements(Wnew))			;number of new points
  PSold = (Wold(Nold-1) - Wold(0)) / (Nold-1)	;old pixel scale
  PSnew = (Wnew(Nnew-1) - Wnew(0)) / (Nnew-1)	;new pixel scale

;Verify that new wavelength scale is a subset of old wavelength scale.
  If (Wnew(0) lt Wold(0)) or $
     (Wnew(Nnew-1) gt Wold(Nold-1)) Then Begin
        print,'REBIN: New wavelength scale not subset of old.'
        snew = -1
        return
  EndIf

;Select integration or interpolation depending on change in dispersion.
  If PSnew le PSold Then Begin			;pixel scale decreased

;  Interpolation by cubic spline.
    If Trace Then Message,/Info,'Interpolating onto new wavelength scale.'
    Snew = DblArr(Nnew,/NoZero)			;init inerpolated spectrum
    Dummy = Long(0)
;    Dummy = Call_External('./spline.so','spline' $
;      ,Nold,Double(Wold),Double(Sold),Nnew,Double(Wnew),Snew)
    Snew=fspline(double(wold),double(sold),double(Wnew))
    Snew = Float(Snew)
  End Else Begin				;pixel scale increased

;  Integration under cubic spline.
    If Trace Then Message,/Info,'Integrating onto new wavelength scale.'
    XFac = Fix(PSnew/PSold + 0.5)		;pixel scale expansion factor
    If Trace Then Message,/Info,'Pixel scale expansion factor: ' $
      + StrTrim(String(XFac),2)

;  Construct another wavelength scale (W) with a pixel scale close to that of 
;    the old wavelength scale (Wold), but with the additional constraint that
;    every XFac pixels in W will exactly fill a pixel in the new wavelength
;    scale (Wnew). Optimized for XFac < Nnew.
    dW = 0.5 * (Wnew(2:Nnew-1) - Wnew(0:Nnew-3));local pixel scale
    dW = [dW,2*dW(Nnew-3) - dW(Nnew-4)]		;add trailing endpoint first
    dW = [2*dW(0) - dW(1),dW]			;add leading endpoint last
    W = FltArr(Nnew,XFac)			;initialize W as array
    For i=0,XFac-1 Do Begin			;loop thru subpixels
      W(*,i) = Wnew + dW*(Float(2*i+1)/(2*XFac) - 0.5)	;pixel centers in W
    End
    W = Transpose(W)				;transpose W before Merging
    nIG = Nnew * XFac				;elements in interpolation grid
    W = Reform(W,nIG,/Overwrite)		;make W into 1-dim vector
;  Interpolate old spectrum (Sold) onto wavelength scale W to make S. Then
;    sum every XFac pixels in S to make a single pixel in the new spectrum
;    (Snew). Equivalent to integrating under cubic spline through Sold. 
    S = DblArr(nIG,/NoZero)			;init interpolated old spectrum
;    Dummy = Call_External('./spline.so','spline' $
;      ,Nold,Double(Wold),Double(Sold),nIG,Double(W),S)
    S=fspline(Double(Wold),Double(Sold),Double(W))
    S = Float(S)
    S = S / XFac				;take average in each pixel
    Sdummy = Reform(S,XFac,Nnew)		;initialize Sdummy as array
    Snew = XFac * Rebin(Sdummy,1,Nnew)		;most efficient pixel sum
    Snew = Reform(Snew,Nnew,/Overwrite)		;convert back to vector
  End

End
