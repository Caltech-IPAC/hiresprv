pro testcolorbar

;pseudo, 100, 100, 100, 100, 22.5, .7, colr
pseudo, 100, 100, 100, 100, 22.5, .68, colr
loadct, 0, /silent
;pseudo, 100, 100, 100, 100, 90.5, 1.2, colr
xplotsizepix = 541
yplotsizepix = 541

xplotsizepix = 541
yplotsizepix = 541
yblank       = 20  ; BLANK SPACE BETWEEN COLORBAR AND IMAGE
ywedge       = 80  ; HEIGHT OF COLORBAR. 
yextrabottom = 50  ; BLANK SPACE AT BOTTOM
yextratop    = 50  ; BLANK SPACE AT TOP
xextraleft   = 80  ; BLANK SPACE AT LEFT
xextraright  = 50  ; BLANK SPACE AT RIGHT
wxsize = xextraleft + xplotsizepix + xextraright
wysize = yextrabottom + yplotsizepix + yblank + ywedge + yextratop
xtvleft   = float(xextraleft)/float(wxsize)
ybarbottom = float(yextrabottom + yplotsizepix + yblank)/float(wysize)

colormin=0
colormax=1

colorbar  = fltarr(xplotsizepix, ywedge)
colordenom = float(colormax-colormin)
color1d   = colormin + findgen(xplotsizepix)*colordenom/(xplotsizepix-1)
for i = 0, ywedge-1 do colorbar[*,i] = color1d

colorbar = (0. > ( float( colormax -colorbar)/colordenom)) < 1.0
colorbar = byte( (0. > (255.*colorbar)) < 255.5)

intmin=1
intmax=2
intbar   = fltarr(xplotsizepix, ywedge)
intdenom = float(intmax-intmin)
int1d    = intmin + findgen(ywedge)*intdenom/(ywedge-1)
for i = 0, xplotsizepix-1 do intbar[i,*] = int1d

intimg1 = (0. > ( float( intbar-intmin)/intdenom) < 1.0)^(1)
redimg = byte( (0 > (intimg1*colr[ colorbar, 0])) < 255)
grnimg = byte( (0 > (intimg1*colr[ colorbar, 1])) < 255)
bluimg = byte( (0 > (intimg1*colr[ colorbar, 2])) < 255)

tv, [[[redimg]], [[grnimg]], [[bluimg]]], $
    xtvleft, ybarbottom, ysize=ybarsize, xsize=xplotsize, $
    /normal, true=3

end; testcolorbar
