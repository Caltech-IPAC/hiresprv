pro ham_find,image,x,y,numcols,numrows,colstart,rowstart

; NAME:
;   HAM_FIND
;
; PURPOSE:
;   Finds arc lines in Hamilton echellogram, for use by UMAKELIST.PRO
;   Adapted from FIND.PRO adapted from DAOPHOT.
;   This version is called from UMAKELIST.PRO
;   This version eliminates flux, and sharpness and roundness criteria.
;   This version hardwires input FWHM at 2.0
;   This version prompts for minimum and maximum DN for threshold detection
;   This version rejects all lines w/in 25 pixels of image edge
;   This version prevents same line being found twice
;   This version outputs x and y in FITS coordinate system
;
; CALLING SEQUENCE:
;   ham_find,image,x,y[,numcols,numrows,colstart,rowstart]
;
; INPUTS:
;   Hamilton echellogram, emission linelamp image.
;   numcols, numrows, colstart, rowstart - parameters passed from MAKELIST,
;                                          extracted from FITS header.
;
; OPTIONAL OUTPUTS:
;   x - vector containing x position of all stars identified by FIND
;   y - vector containing y position of all stars identified by FIND
;   NOTE: x and y are converted to FITS coordinate system of input image.
;
; REVISION HISTORY:
;    Written W. Landsman, STX  February, 1987
;    This version by T. Misch, April, 1995

On_error,2                         ;Return to caller
;
npar   = N_params()
;
maxbox = 13 	;Maximum size of convolution box in pixels 
;
type = size(image)
if ( type(0) NE 2 ) then message, $
     'Image array (first parameter) must be 2 dimensional'
n_x  = type(1) & n_y = type(2)
;
fwhm = 2.0
radius = 0.637*FWHM > 2.001             ;Radius is 1.5 sigma
radsq = radius^2
nhalf = fix(radius) < (maxbox-1)/2   	;
nbox = 2*nhalf + 1	;# of pixels in side of convolution box 
middle = nhalf          ;Index of central pixel
lastro = n_x - nhalf
lastcl = n_y - nhalf
sigsq = (fwhm/2.35482)^2
mask = bytarr(nbox,nbox)      ;Mask identifies valid pixels in convolution box 
c = fltarr(nbox,nbox)	      ;c will contain gaussian convolution kernel
;
dd = indgen(nbox-1) + 0.5 - middle	;Constants need to compute ROUND
dd2 = dd^2
w = 1. - 0.5*(abs(dd)-0.5)/(middle-.5)   
ir = (nhalf-1) > 1
;
row2 = (findgen(Nbox)-nhalf)^2
for i=0,nhalf do begin
	temp = row2 + i^2
	c(0,nhalf-i) = temp         
        c(0,nhalf+i) = temp                           
endfor
mask = fix(c LE radsq)     ;MASK is complementary to SKIP in Stetson's Fortran
good = where(mask,pixels)  ;Value of c are now equal to distance to center
;
c = c*mask               
c(good) = exp(-0.5*c(good)/sigsq)	;Make c into a gaussian kernel
sumc = total(c)
sumcsq = total(c^2) - sumc^2/pixels
sumc = sumc/pixels
c(good) = (c(good) - sumc)/sumcsq
c1 = exp(-.5*row2/sigsq)
sumc1 = total(c1)/nbox
sumc1sq = total(c1^2) - sumc1
c1 = (c1-sumc1)/sumc1sq
sumc = total(w)                         ;Needed for centroid computation
;
message,'Beginning convolution of image', /INF
 h = convol(float(image),c)    ;Convolve image with kernel "c"
    h(0:nhalf-1,*)=0 & h(n_x-nhalf:n_x-1,*)=0
    h(*,0:nhalf-1)=0 & h(*,n_y-nhalf:n_y-1) = 0
message,'Finished convolution of image', /INF
;
 mask(middle,middle) = 0	;From now on we exclude the central pixel
 pixels = pixels -1      ;so the number of valid pixels is reduced by 1
 good = where(mask)      ;"good" identifies position of valid pixels
 xx= (good mod nbox) - middle	;x and y coordinate of valid pixels 
 yy = fix(good/nbox) - middle    ;relative to the center
 offset = yy*n_x + xx
;
 SEARCH: 			    ;Threshold dependent search begins here
;
 spawn,'clear'
 print,' '
 read,'Enter minimum DN for line detection: ',hmin
 read,'Enter maximum DN for line detection: ',hmax
;
 index = where ((h GE hmin) and (h LE hmax)) ;Valid image pixels w/in range 
;
 for i=0,pixels-1 do begin                             
	stars = where (h(index) GE h(index+offset(i)))
	index = index(stars)
 endfor 
; 
 ix = index mod n_x              ;X index of local maxima
 iy = index/n_x                  ;Y index of local maxima
;
 ngood = N_elements(index)       
;
 nstar = 0       	;NSTAR counts all stars meeting selection criteria
 badcntrd=0
 if (npar GE 2) then begin 	;Create output X and Y arrays 
  	x = fltarr(ngood) & y = x
 endif
;
 print,format='(/8x,a)','     LINE     X       Y      DN'
 print,format='(8x,a)','    -----------------------------'
;
;  Loop over star positions; compute statistics
;
for i = 0,ngood-1 do begin   
temp = float(image(ix(i)-nhalf:ix(i)+nhalf,iy(i)-nhalf:iy(i)+nhalf))
d = h(ix(i),iy(i))         ;"d" is actual pixel intensity        
;
; Find X centroid
;
deriv = shift(temp,-1,0) - temp
deriv = total( deriv(0:nbox-2,middle-ir:middle+ir),2)
sumd = total(w*deriv)
sumxd = total(w*dd*deriv)
sumxsq = total(w*dd2) 
if ( sumxd GE 0. ) then begin
	badcntrd = badcntrd + 1
	goto,REJECT           ;Cannot compute X centroid
endif
dx =sumxsq*sumd/(sumc*sumxd)
if abs(dx) GT nhalf then begin
	badcntrd = badcntrd + 1
	goto,REJECT           ;X centroid too far from local X maxima
endif
xcen = ix(i)-dx               ;Convert back to big image coordinates
;
; Find Y centroid                 
;
deriv = shift(temp,0,-1) - temp 
deriv = total( deriv(middle-ir:middle+ir,0:nbox-2), 1 )
sumd = total( w*deriv )
sumxd = total( w*dd*deriv )
sumxsq = total( w*dd2 )
if (sumxd GE 0) then begin
	badcntrd = badcntrd + 1
	goto,REJECT  
endif
dy =sumxsq*sumd/(sumc*sumxd)
if abs(dy) GT nhalf then begin
	badcntrd = badcntrd + 1
	goto,REJECT 
endif
ycen = iy(i) - dy
;
; Reject lines w/in 25 pixels of edge of image
;
if ((xcen-25 LE 0) or (xcen+25 GE numcols)) then goto,REJECT
if ((ycen-25 LE 0) or (ycen+25 GE numrows)) then goto,REJECT 
;
; Prevent lines from being found more than once
;
spacing=2                  ;rejection radius of neighboring lines
if (nstar GT 0) then begin
  if ((xcen+spacing GE lastx) and (xcen-spacing LE lastx)) then $
    if ((ycen+spacing GE lasty) and (ycen-spacing LE lasty)) then goto,REJECT 
endif
;
; This star has met all selection criteria.
; Save results in FITS coordinate system and display.
;
x(nstar) = round(xcen+colstart)
y(nstar) = round(ycen+rowstart)
; 
print,format='(12x,i4,3i8)',nstar+1,x(nstar),y(nstar),round(d)
lastx=xcen & lasty=ycen
nstar = nstar+1
REJECT: 
endfor

nstar = nstar-1		;NSTAR is now the index of last star found
if (npar GE 2) then x=x(0:nstar)  & y = y(0:nstar) 
	
FINISH:
lastrow=rowstart+numrows
lastcol=colstart+numcols
;plot positions of lines found this pass
!p.multi=[0,1,1]
window,0,xsize=600,ysize=450,xpos=625,ypos=560
plot,x,y,ps=1,title='Lines Found',xtitle='columns',$
  ytitle='rows',xstyle=1,ystyle=1,$
  yrange=[lastrow,rowstart],xrange=[colstart,lastcol]
ans='' 
print,' '
read,'        Enter new thresholds [Y/N]? ',ans
spawn,'clear'
if (ans EQ 'y') or (ans EQ 'Y') then goto,SEARCH
return                                      
end
