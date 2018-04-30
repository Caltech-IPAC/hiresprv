Pro	Display, image, $
		xs, ys, $
		Title=t, XTitle=xt, YTitle=yt, $
		MIN=minval, MAX=maxval, $
		LOG=log_scaling, $
		LEVELS=l, HIST=hist,$
		ASPECT=aspect, $
		INTERPOLATE=interp, $
		MASKVALUE=maskvalue, $
		PSFINE=psfine, $
		NO_EXPAND=no_expand, $
		NOERASE=noerase, $
		HELP=help

SccsId = '@(#)display.pro 3.3 7/16/93 Fen Tamanaha'
;+
; NAME:
;	DISPLAY
;
; PURPOSE:
;	This procedure will display an image with the TV command that fills
;	the plotting window.  It handles scale, annotations, X and PostScript
;	devices, aspect ratios, logarithmic scaling, and interpolation.  The
;	first colormap entry is reserved for the background (pixels flagged
;	with the MASKVALUE value are mapped to this color) and the last entry
;	is reserved for user defined colored annotations.  The annotation
;	plotted by this procedure are in the color !P.Color.
;
; CATEGORY:
;	Image display.
;
; CALLING SEQUENCE:
;	DISPLAY, Image, XS, YS
;
; INPUTS:
;	Image:	Two-dimensional array to be displayed.
;
; OPTIONAL INPUTS:
;	XS:	Vector of x-axis values.  The length must equal the number of
;		rows in <Image>
;
;	YS:	Vector of y-axis values.  The length must equal the number of
;		columns in <Image>
;
; KEYWORD PARAMETERS:
;	TITLE=	Set this keyword to a string containing the title annotation
;		to be used by PLOT.
;
;	XTITLE=	Set this keyword to a string containing the x-axis annotation
;		to be used by PLOT.
;
;	YTITLE=	Set this keyword to a string containing the y-axis annotation
;		to be used by PLOT.
;
;	ASPECT=	Set this keyword to the aspect ratio (width/height) of the
;		pixels.  /ASPECT is the same as ASPECT=1 and produces square
;		pixels.
;
;	/INTERPOLATE:
;		Set this switch to enable bilinear interpolation for pixels
;		in the expanded image.  See /PS_FINE for information
;		on using this switch on a PostScript device.
;
;	/HIST	Set this for histogram equalization colormap scaling
;
;	MASKVALUE=
;		Set this keyword to the value that pixels with bad data or
;		no data have been flagged with.  These will be mapped to 0B.
;
;	MIN=	The minimum value of <Image> to be considered.  If MIN is not
;		provided, <Image> is searched for its minimum value.  All
;		values less than or equal to MIN are set to 1 in the Result.
;
;	MAX=	The maximum value of <Image> to be considered.  If MAX is not
;		provided, <Image> is searched for its maximum value.  All
;		values greater than or equal to MAX are set to TOP in the
;		Result.
;
;	TOP=	The maximum value of the scaled result.  If TOP is not
;		specified, 255 is used. Note that the minimum value of the
;		scaled result is always 1 (NOT 0 as in BYTSCL).
;
;	LEVELS=	Set this keyword to a vector of data value boundaries between
;		which all elements of <Image> have the same scaled byte
;		value.  e.g. LEVELS=[0,1,2,5] maps all values below 0 and
;		above 5 to 0B, map values between 0 and 1 to 1B, map values
;		between 1 and 2 to 128B, and map values between 2 and 5 to
;		255B.  This does not plot contours.
;
;	/LOG:	Set this switch to cause a logarithmic mapping.  This is
;		overridden by the LEVELS keyword.
;
;	/PS_FINE:
;		Set the switch to enable higher resolution images on a
;		PostScript device.  This is only useful with /INTERPOLATE and
;		will increase the size of the PostScript file.
;
;	/NOERASE:
;		Set the switch to prevent output device from being erased
;		before the image, scales, and annotations are displayed.
;
;	/NO_EXPAND:
;		Set this switch to prevent the image from being expanded
;		to fill the plotting window.  Scaling to byte type is still
;		performed.
;
; SIDE EFFECTS:
;	TV display is altered.
;
; RESTRICTIONS:
;	This routine may work for other devices, but it has only been tested
;	on 'X' and 'PS'.
;
; PROCEDURE:
;	Straight forward.  :-)
;
; EXAMPLE:
;	LoadCT, 3
;	image = SHIFT(DIST(20, 20), 10, 10)
;	scale = FINDGEN(20) - 10.0
;	DISPLAY, image, scale, scale, /INTERPOLATE, TITLE='!6Smooth Slope', $
;		/ASPECT
;	;Use CONTOUR with /OVERPLOT to overlay contours.
;	CONTOUR, image, scale, scale, LEVELS=1.0+FINDGEN(4)*2.0, /OVERPLOT
;
;	DISPLAY		;prints out a "Usage:" line
;
; MODIFICATION HISTORY:
; 	Written by:	Fen Tamanaha, July 10, 1993.  Release 3.1
;	July 13, 1993	Fen: (3.2) Fixed /No_Expand
;	July 16, 1993	Fen: (3.3) Really fixed /No_Expand
;-

    On_Error, 2

;
; Validate arguments.
;
    nparms = N_Params()
    If ( Keyword_Set(help) ) Then nparms = 0	;force a "Usage:" line
    Case ( nparms ) Of
        1: Begin
            sz = Size(image)
            If ( sz(0) NE 2 ) Then Begin
                Message, '<image> must be an array.'
            EndIf
            xs = FIndGen(sz(1))
            ys = FIndGen(sz(2))
        End
        2: Begin
            sz = Size(image)
            If ( sz(0) NE 2 ) Then Begin
                Message, '<image> must be an array.'
            EndIf
            If ( N_Elements(xs) NE sz(1) ) Then Begin
                Message, '<xs> does not match <image> dimensions.'
            EndIf
            ys = FIndGen(sz(2))
        End
        3: Begin
            sz = Size(image)
            If ( sz(0) NE 2 ) Then Begin
                Message, '<image> must be an array.'
            EndIf
            If ( N_Elements(xs) NE sz(1) ) Then Begin
                Message, '<xs> does not match <image> dimensions.'
            EndIf
            If ( N_Elements(ys) NE sz(2) ) Then Begin
                Message, '<ys> does not match <image> dimensions.'
            EndIf
        End
        Else: Begin
            Message, 'Usage: DISPLAY, image [,xs [,ys]] [,TITLE=] [,XTITLE=] [,YTITLE=]', /Info
	    Message, '           [,MIN=] [,MAX=] [,/LOG] [,LEVELS=] [/HIST]', /Info
            Message, '           [,ASPECT=] [,/INTERPOLATE] [MASKVALUE=]', /Info
	    Message, '           [,/NO_EXPAND] [,/NOERASE] [,/PSFINE]', /Info
            Return
        End
    EndCase
 
;
; The plotting device must be erased to reset the system variables so that
;	IMGEXP will get the default values.  The /NOERASE keyword should
;	be used to prevent this.  One typical situation is when DISPLAY
;	is called after a !P.MULTI change.  An ERASE at this point would
;	destroy the previous plots.
;
    If ( Not Keyword_Set(noerase) ) Then Begin
	Erase
    EndIf

;
; If /PSFINE is set then up the intermediate interpolated image width.
;	This only has an effect on PostScript output.
;
    If (Keyword_Set(psfine) ) Then Begin
	psis = 512.0
    EndIf
    im = ImgExp(image, xs, ys, xscale, yscale, xrange, yrange, $
		Aspect=aspect, Interpolate=Keyword_Set(interp), $
		MaskValue=maskvalue, Position=dev_pos, PS_Interp_Size=psis, $
		No_Expand=Keyword_Set(no_expand))
    sz = Size(im)
    im_x_width = Float(sz(1))                   ;image width
    im_y_width = Float(sz(2))                   ;image height
 
;
; Determine the device coordinates of the plotting regions.
;
    dev_x_width = dev_pos(2) - dev_pos(0) + 1
    dev_y_width = dev_pos(3) - dev_pos(1) + 1
    If ( (im_x_width GT dev_x_width) Or (im_y_width GT dev_y_width) ) Then Begin
	Message, 'Error: Scaled image is larger than plotting window.'
    EndIf

;
; Convert a non-byte type image to byte with IMGSCL.  The bottom entry
;	of the color table is reserved for the background/NODATA color
;	by IMGSCL.  The top color table entry will also be reserved
;	here for annotation color.
;
    If ( sz(sz(0)+1) GT 1 ) Then Begin
    	if keyword_set(hist) then byte_im=hist_equal(im) else $
	byte_im = ImgScl(im, Min=minval, Max=maxval, Top=!D.Table_Size-2, $
			Log=log_scaling, Levels=l, MaskValue=maskvalue)
    EndIf Else Begin
	Message, '<Image> is already byte type. No scaling done.', /Info
	byte_im = im
    EndElse

;
; Put the image on the TV.
;
    TV, byte_im, /Device, dev_pos(0), dev_pos(1), $
		XSize=dev_pos(2)-dev_pos(0), YSize=dev_pos(3)-dev_pos(1)

;
; Manage the title and axis labels.
;
    If ( Keyword_Set(t) ) Then Begin
        title = String(t)
    EndIf Else Begin
        title = ' '
    EndElse
 
    If ( Keyword_Set(xt) ) Then Begin
        xtitle = String(xt)
    EndIf Else Begin
        xtitle = ' '
    EndElse
 
    If ( Keyword_Set(yt) ) Then Begin
        ytitle = String(yt)
    EndIf Else Begin
        ytitle = ' '
    EndElse
 
;
; Overplot annotations.
;
    Plot, [0,1], /NoErase, /NoData, XStyle=1, YStyle=1, $
                /Device, Position=dev_pos, $
                XRange=xrange, YRange=yrange, $
                Title=title, XTitle=xtitle, YTitle=ytitle

    Return
End
