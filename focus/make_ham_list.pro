pro make_ham_list,infilename,outfilename,disk
;
; NAME:
;   make_ham_list 
;
; PURPOSE:
;   Interactively create a list of x and y coordinates of well-formed 
;   th and ar lines in a Hamilton echellogram, for use by focusing routine.
;   Program loads th-ar image, finds lines w/in specified range; draws a
;   contour plot of each line, and a plot showing its position on the CCD,
;   and asks user to accept or reject line for inclusion in a lines list.
;   Lines list of accepted lines is written to '/procedure/ulines.ascii',
;   or to outfile name of user's choice (specified from calling program).
;   This version called from hamfoc.pro, running on shane.ucolick.org.     
;
; PARAMETERS (passed from hamfoc.pro):
;   INFILENAME - File containing arc line image for convolution.
;   OUTFILENAME- File to which linelist will be written.
;   DISK       - Disk selected for i/o (coude or ucscloc)
;
; HISTORY:
;   By T. Misch, Feb '95
;   Modified 12/95: added 'loc' keyword 
;   Modified 5/96 to be called from hamfoc.pro
;
;Define some parameters
; infile=' '
; outfile=' '
 fnum=' '
 k=0
 m=0
 sz=10               ;half width of box around lines
 boxsz = sz*2+1      ;21 x 21 pixels around each Th line.
 keeper=' '
 levs=findgen(10)*1000               ;for box contours
 hues=(10)                
 close,1                             ;clean up any open file
 red=[0,1,1,0,0,1]                   ;set up color tables
 green=[0,1,0,1,0,1]
 blue=[0,1,0,0,1,0]
 tvlct,255*red,255*green,255*blue
infile=infilename
outfile=outfilename
rdfits,im,infile,head                        ;read FITS file into im
numcols=head(3)                              ;extract infor from FITS header
numrows=head(4)
colstart=head(6)
rowstart=head(7)
numcols = fix(StrMid(numcols,20,21))         
numrows = fix(StrMid(numrows,20,21))
colstart = fix(StrMid(colstart,20,21))
rowstart = fix(StrMid(rowstart,20,21))
lastrow=rowstart+numrows
lastcol=colstart+numcols
;
TRYAGAIN:
ham_find,im,xF,yF,numcols,numrows,colstart,rowstart    ;call line finder
;                    xF and yF are returned in FITS coordinate system.
x=xF-colstart & y=yF-rowstart   ;x and y are in IDL coordinate system.
nl=n_elements(x)                    ;get number of lines found
xout=intarr(nl)    ;define arrays to hold lines selected for linelist
yout=intarr(nl)
xrej=intarr(nl)    ;define arrays to hold rejected lines (used in plotting)
yrej=intarr(nl)
;
window,0,xsize=600,ysize=900,xpos=625,ypos=110
!p.multi=[0,1,2]
for j = 0,nl-1 do begin             ;begin LOOP THROUGH ALL LINES
  c1 = x(j)-sz  & c2 = x(j)+sz
  r1 = y(j)-sz  & r2 = y(j)+sz
  box = float(im(c1:c2 , r1:r2))    ;box within image containing Th line
  bckg = median([box(0,0:boxsz-1),box(boxsz-1,0:boxsz-1)])   ;lft, rt edges
  box = box - bckg                  ;sub backgr
;
;begin plotting section
  ctitl='Line '+strtrim(string(j+1),2)+', row '+strtrim(string(yF(j)),2) $
       +', col '+strtrim(string(xF(j)),2)
  contour,box,nlevels=10,c_colors=hues,xstyle=1,ystyle=1,/fill
  contour,box,nlevels=10,/overplot,xstyle=1,ystyle=1,color=1,$
    xtitle='column',ytitle='row'
  plot,xF,yF,ps=1,yrange=[lastrow,rowstart],xrange=[colstart,lastcol],$
    xstyle=1,ystyle=1,color=1,xtitle='column',ytitle='row',/nodata 
  oplot,xF,yF,color=1,ps=1 ;show all lines found but not yet rejected, white 
  oplot,xrej,yrej,color=0,ps=1 ;erase rejected lines
  oplot,xout,yout,color=4,ps=1 ;show all lines chosen thus far, blue, big
  oplot,[xF(j)],[yF(j)],color=2,ps=1  ;show position of current line, red, big
  read,'[A]ccept/[R]eject ',keeper
  if keeper EQ 'A' or keeper EQ 'a' then begin
    xout(k)=xF(j) & yout(k)=yF(j) ;save the keepers to new arrays, FITS coords.
    k=k+1
  end else begin
    xrej(m)=xF(j) & yrej(m)=yF(j) ;save rejects to erase in plot
    m=m+1
  endelse
end                                 ;end LOOP THROUGH ALL LINES
;
;test for minimum number of lines selected
xtrim=where(xout)
ytrim=where(yout)
xtrim=xout(xtrim)
ytrim=yout(ytrim)
  if n_elements(xtrim) lt 6 then begin
    dum=''
    print,''
    print,'At least six lines must be selected.'
    read,'Type return to try again.',dum
    spawn,'clear'
    goto,TRYAGAIN
  endif
;
!p.multi=[0,1,1]
window,0,xsize=600,ysize=450,xpos=625,ypos=560
plot,xtrim,ytrim,yrange=[lastrow,rowstart],xrange=[colstart,lastcol], $
     xstyle=1,ystyle=1,titl='Final line selection',color=1,/nodata, $
     xtitle='columns',ytitle='rows'
oplot,xtrim,ytrim,ps=1,color=4    ;show final line selection
spawn,'clear'
print,''
;print,n_elements(xtrim),' line positions being written to ',outfile
openw,1,outfile
printf,1,'   cols      rows'
for i=0,k-1 do printf,1,xtrim(i),ytrim(i)
close,1
;
end
