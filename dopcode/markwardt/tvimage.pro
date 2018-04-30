;+
; NAME:
;     TVIMAGE
;
; PURPOSE:
;     This purpose of TVIMAGE is to allow you to display an image
;     on the display or in a PostScript file in a particular position.
;     The position is specified by means of the POSITION keyword. In
;     this respect, TVIMAGE works like other IDL graphics commands.
;     Moreover, the TVIMAGE command works identically on the display
;     and in a PostScript file. You don't have to worry about how to
;     "size" the image in PostScript. The output on your display and
;     in the PostScript file will be identical. The major advantage of
;     TVIMAGE is that it can be used in a natural way with other IDL
;     graphics commands in resizeable IDL graphics windows. TVIMAGE
;     is a replacement for TV and assumes the image has been scaled
;     correctly when it is passed as an argument.
;
; AUTHOR:
;       FANNING SOFTWARE CONSULTING:
;       David Fanning, Ph.D.
;       2642 Bradbury Court
;       Fort Collins, CO 80521 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CATEGORY:
;     Graphics display.
;
; CALLING SEQUENCE:
;
;     TVIMAGE, image
;
; INPUTS:
;     image:    A 2D or 3D image array. It should be byte data.
;
; KEYWORD PARAMETERS:
;     _EXTRA:   This keyword picks up any TV keywords you wish to use.
;
;     KEEP_ASPECT_RATIO: Normally, the image will be resized to fit the
;               specified position in the window. If you prefer, you can
;               force the image to maintain its aspect ratio in the window
;               (although not its natural size) by setting this keyword.
;               The image width is fitted first. If, after setting the
;               image width, the image height is too big for the window,
;               then the image height is fitted into the window. The
;               appropriate values of the POSITION keyword are honored
;               during this fitting process. Once a fit is made, the
;               POSITION coordiates are re-calculated to center the image
;               in the window. You can recover these new position coordinates
;               as the output from the POSITION keyword.
;
;     MINUS_ONE: The value of this keyword is passed along to the CMCONGRID
;               command. It prevents CMCONGRID from adding an extra row and
;               column to the resulting array.
;     HALF_HALF: The value of this keyword is passed along to the
;               CMCONGRID command, causing the "extra" row and column to
;               be split evenly between both sides.
;
;     POSITION: The location of the image in the output window. This is
;               a four-element floating array of normalized coordinates of
;               the type given by !P.POSITION or the POSITION keyword to
;               other IDL graphics commands. The form is [x0, y0, x1, y1].
;               The default is [0.15, 0.15, 0.85, 0.85]. Note that this can
;               be an output parameter if the KEEP_ASPECT_RATIO keyword is
;               used.
;
; OUTPUTS:
;     None.
;
; SIDE EFFECTS:
;     Unless the KEEP_ASPECT_RATIO keyword is set, the displayed image
;     may not have the same aspect ratio as the input data set.
;
; RESTRICTIONS:
;     If the POSITION keyword and the KEEP_ASPECT_RATIO keyword are
;     used together, there is an excellent chance the POSITION
;     parameters will change. If the POSITION is passed in as a
;     variable, the new positions will be returned as an output parameter.
;
; EXAMPLE:
;     To display an image with a contour plot on top of it, type:
;
;        filename = FILEPATH(SUBDIR=['examples','data'], 'worldelv.dat')
;        image = BYTARR(360,360)
;        OPENR, lun, filename, /GET_LUN
;        READU, image
;        FREE_LUN, lun
;
;        TVIMAGE, image, POSITION=thisPosition, /KEEP_ASPECT_RATIO
;        CONTOUR, image, POSITION=thisPosition, /NOERASE, XSTYLE=1, $
;            YSTYLE=1, XRANGE=[0,360], YRANGE=[0,360], NLEVELS=10
;
; MODIFICATION HISTORY:
;      Written by:     David Fanning, 20 NOV 1996.
;      Fixed a small bug with the resizing of the image. 17 Feb 1997. DWF.
;      Removed BOTTOM and NCOLORS keywords. This reflects my growing belief
;         that this program should act more like TV and less like a "color
;         aware" application. I leave "color awareness" to the program
;         using TVIMAGE. Added 24-bit image capability. 15 April 1997. DWF.
;      Fixed a small bug that prevented this program from working in the
;          Z-buffer. 17 April 1997. DWF.
;      Fixed a subtle bug that caused me to think I was going crazy!
;          Lession learned: Be sure you know the *current* graphics
;          window! 17 April 1997. DWF.
;      Added support for the PRINTER device. 25 June 1997. DWF.
;      Extensive modifications. 27 Oct 1997. DWF
;          1) Removed PRINTER support, which didn't work as expected.
;          2) Modified Keep_Aspect_Ratio code to work with POSITION keyword.
;          3) Added check for window-able devices (!D.Flags AND 256).
;          4) Modified PostScript color handling.
;      Craig Markwart points out that Congrid adds an extra row and column
;          onto an array. When viewing small images (e.g., 20x20) this can be
;          a problem. Added a Minus_One keyword whose value can be passed
;          along to the Congrid keyword of the same name. 28 Oct 1997. DWF
;-

PRO TVIMAGE, image, KEEP_ASPECT_RATIO=keep, POSITION=position, $
   MINUS_ONE=minusOne, HALF_HALF=halfHalf, _EXTRA=extra

ON_ERROR, 1

   ; Check for image parameter.

np = N_PARAMS()
IF np EQ 0 THEN MESSAGE, 'You must pass an image argument.'

   ; Check image size.

s = SIZE(image)
IF s(0) LT 2 OR s(0) GT 3 THEN $
   MESSAGE, 'Argument does not appear to be an image. Returning...'

   ; 2D image.

IF s(0) EQ 2 THEN BEGIN
   imgXsize = FLOAT(s(1))
   imgYsize = FLOAT(s(2))
   true = 0
ENDIF

   ; 3D image.

IF s(0) EQ 3 THEN BEGIN
IF (s(1) NE 3L) AND (s(2) NE 3L) AND (s(3) NE 3L) THEN $
   MESSAGE, 'Argument does not appear to be a 24-bit image. Returning...'
   IF s(1) EQ 3 THEN true = 1 ; Pixel interleaved
   IF s(2) EQ 3 THEN true = 2 ; Row interleaved
   IF s(3) EQ 3 THEN true = 3 ; Band interleaved
   CASE true OF
      1: BEGIN
         imgXsize = FLOAT(s(2))
         imgYsize = FLOAT(s(3))
         END
      2: BEGIN
         imgXsize = FLOAT(s(1))
         imgYsize = FLOAT(s(3))
         END
      3: BEGIN
         imgXsize = FLOAT(s(1))
         imgYsize = FLOAT(s(2))
         END
   ENDCASE
ENDIF

   ; Check for keywords.

IF N_ELEMENTS(position) EQ 0 THEN position = [0.15, 0.15, 0.85, 0.85] $
   ELSE position = FLOAT(position)
minusOne = Keyword_Set(minusOne)
halfHalf = Keyword_Set(halfHalf)

   ; Maintain aspect ratio (ratio of height to width)?

IF KEYWORD_SET(keep) THEN BEGIN

      ; Find aspect ratio of image.

   ratio = FLOAT(imgYsize) / imgXSize

      ; Find the proposed size of the image in pixels without aspect
      ; considerations.

   xpixSize = (position(2) - position(0)) * !D.X_VSize
   ypixSize = (position(3) - position(1)) * !D.Y_VSize

      ; Try to fit the image width. If you can't maintain
      ; the aspect ratio, fit the image height.

   trialX = xpixSize
   trialY = trialX * ratio
   IF trialY GT ypixSize THEN BEGIN
      trialY = ypixSize
      trialX = trialY / ratio
   ENDIF

      ; Recalculate the position of the image in the window.

   position(0) = (((xpixSize - trialX) / 2.0) / !D.X_VSize) + position(0)
   position(2) = position(0) + (trialX/FLOAT(!D.X_VSize))
   position(1) = (((ypixSize - trialY) / 2.0) / !D.Y_Size)  + position(1)
   position(3) = position(1) + (trialY/FLOAT(!D.Y_VSize))

ENDIF

   ; Calculate the image size and start locations.

xsize = (position(2) - position(0)) * !D.X_VSIZE
ysize = (position(3) - position(1)) * !D.Y_VSIZE
xstart = position(0) * !D.X_VSIZE
ystart = position(1) * !D.Y_VSIZE

   ; Display the image. Sizing different for PS device.

IF (!D.NAME EQ 'PS') THEN BEGIN

      ; Need a gray-scale color table if this is a true
      ; color image.

   IF true GT 0 THEN LOADCT, 0, /Silent
   TV, image, xstart, ystart, XSIZE=xsize, $
      YSIZE=ysize, _EXTRA=extra, True=true

ENDIF ELSE BEGIN

      ; If the image is 24-bit but the display is 8-bit
      ; then COLOR_QUAN processing is required.

   IF (!D.Flags AND 256) GT 0 THEN BEGIN
      thisWindow = !D.Window
      Window, XSize=10, YSize=10, /Free, /Pixmap
      WDelete, !D.Window
      WSet, thisWindow
   ENDIF
   ncolors = !D.N_Colors
   IF ncolors LE 256 AND true GT 0 THEN BEGIN
      TV, CMCONGRID(COLOR_QUAN(image, true, red, green, blue, $
         Colors=!D.N_Colors), CEIL(xsize), CEIL(ysize), $
         MINUS_ONE=minusOne, HALF_HALF=halfHalf), $
        xstart, ystart, _EXTRA=extra
      TVLCT, red, green, blue
      RETURN
   ENDIF

   CASE true OF
      0: TV, CMCONGRID(image, CEIL(xsize), CEIL(ysize), /INTERP, $
                  MINUS_ONE=minusOne, HALF_HALF=halfHalf), $
        xstart, ystart, _EXTRA=extra
      1: TV, CMCONGRID(image, 3, CEIL(xsize), CEIL(ysize), /INTERP, $
            MINUS_ONE=minusOne, HALF_HALF=halfHalf), $
        xstart, ystart, _EXTRA=extra, True=1
      2: TV, CMCONGRID(image, CEIL(xsize), 3, CEIL(ysize), /INTERP, $
            MINUS_ONE=minusOne, HALF_HALF=halfHalf), $
        xstart, ystart, _EXTRA=extra, True=2
      3: TV, CMCONGRID(image, CEIL(xsize), CEIL(ysize), 3, /INTERP, $
            MINUS_ONE=minusOne, HALF_HALF=halfHalf), $
        xstart, ystart, _EXTRA=extra, True=3
  ENDCASE
ENDELSE
END


